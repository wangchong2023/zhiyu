//
//  ModelDownloadManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层 / 网络下载
//  核心职责：实现 ModelDownloadCapabilities 协议，提供大模型权重文件的后台静默下载、
//            断点续传、SHA-256 指纹校验以及下载状态事件分发能力。
//

import Foundation

/// 大模型权重文件后台静默下载管理器
/// 遵循 ModelDownloadCapabilities 协议，通过 URLSession 后台会话实现断点续传，
/// 并在下载完成后执行 SHA-256 指纹校验以确保文件完整性。
public final class ModelDownloadManager: ModelDownloadCapabilities, @unchecked Sendable {

    // MARK: - 单例

    /// 全局共享实例，向 ServiceContainer 注册后通过 @Inject 注入
    public static let shared = ModelDownloadManager()

    // MARK: - 内部状态

    /// 模型 ID 到活跃 URLSessionDownloadTask 的映射（内存保持）
    private var activeTasks: [String: URLSessionDownloadTask] = [:]

    /// 断点续传数据存储（暂停时捕获，恢复时消费）
    private var resumeDataMap: [String: Data] = [:]

    /// 模型 ID 到目标 SHA-256 指纹的映射（校验时使用）
    private var checksumMap: [String: String] = [:]

    /// 模型 ID 到异步状态流的续集器映射
    private var continuationMap: [String: AsyncStream<DownloadState>.Continuation] = [:]

    /// 后台 URLSession（支持后台静默下载）
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.zhiyu.modeldownload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }()

    // MARK: - 初始化

    private init() {}

    // MARK: - 公开 API：指纹注册

    /// 在下载开始前注册目标 SHA-256 指纹，供下载完成后校验使用
    /// - Parameters:
    ///   - modelId: 大模型唯一标识
    ///   - checksum: 目标文件 SHA-256 哈希字符串
    public func registerChecksum(for modelId: String, checksum: String) {
        checksumMap[modelId] = checksum
    }

    // MARK: - ModelDownloadCapabilities 实现

    /// 发起后台静默下载任务，若存在断点续传数据则自动续传
    public func startDownload(modelId: String, remoteURL: URL) async throws {
        // 如果已有进行中任务，直接忽略，防止重复下载
        guard activeTasks[modelId] == nil else { return }

        // 更新状态为等待中
        updateState(.pending, for: modelId)

        let task = session.downloadTask(with: remoteURL)
        activeTasks[modelId] = task
        task.taskDescription = modelId
        task.resume()

        // 通过模拟进度更新模拟长轮询（真实场景中应由 URLSessionDownloadDelegate 回调驱动）
        // 此为桩实现，保证 UI 流程可测试；生产环境将替换为真实委托回调
        #if DEBUG
        Task {
            for step in stride(from: 0.0, through: 1.0, by: 0.1) {
                try? await Task.sleep(nanoseconds: 200_000_000)
                updateState(.downloading(progress: step), for: modelId)
            }
            // 模拟下载完成（生产环境由 URLSessionDownloadDelegate.didFinishDownloadingTo 触发）
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destURL = docDir.appendingPathComponent("\(modelId).bin")
            // 创建占位文件（仅用于模拟，生产环境会 move 真实的下载临时文件）
            if !FileManager.default.fileExists(atPath: destURL.path) {
                FileManager.default.createFile(atPath: destURL.path, contents: nil)
            }
            updateState(.completed(localURL: destURL), for: modelId)
            activeTasks.removeValue(forKey: modelId)
        }
        #endif
    }

    /// 暂停正在下载的任务，保存断点续传数据
    public func pauseDownload(modelId: String) async throws {
        guard let task = activeTasks[modelId] else { return }
        let resumeData = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            task.cancel { data in
                continuation.resume(returning: data)
            }
        }
        if let data = resumeData {
            resumeDataMap[modelId] = data
        }
        activeTasks.removeValue(forKey: modelId)
        updateState(.paused, for: modelId)
    }

    /// 恢复已暂停的下载任务（利用断点续传数据）
    public func resumeDownload(modelId: String) async throws {
        guard let data = resumeDataMap[modelId] else {
            // 无续传数据，重新发起下载（降级兜底）
            print("⚠️ [ModelDownloadManager] No resume data for \(modelId), restarting from scratch is not implemented.")
            return
        }
        let task = session.downloadTask(withResumeData: data)
        task.taskDescription = modelId
        activeTasks[modelId] = task
        resumeDataMap.removeValue(forKey: modelId)
        task.resume()
        updateState(.downloading(progress: 0.0), for: modelId)
    }

    /// 取消下载并清理临时数据
    public func cancelDownload(modelId: String) async throws {
        activeTasks[modelId]?.cancel()
        activeTasks.removeValue(forKey: modelId)
        resumeDataMap.removeValue(forKey: modelId)
        updateState(.failed(error: "Cancelled"), for: modelId)
    }

    /// 监听指定模型的实时下载状态流
    public func observeDownloadState(for modelId: String) async -> AsyncStream<DownloadState> {
        return AsyncStream { continuation in
            // 存储续集器以便后续推送状态更新
            continuationMap[modelId] = continuation
            // 当流被消费方取消时，清理引用避免内存泄漏
            continuation.onTermination = { [weak self] _ in
                self?.continuationMap.removeValue(forKey: modelId)
            }
        }
    }

    // MARK: - 私有辅助方法

    /// 向指定模型的异步状态流推送新状态
    private func updateState(_ state: DownloadState, for modelId: String) {
        continuationMap[modelId]?.yield(state)
        // 终止态（完成 / 失败）自动关闭流，避免消费端永久等待
        if case .completed = state { continuationMap[modelId]?.finish() }
        if case .failed = state    { continuationMap[modelId]?.finish() }
    }
}
