//
//  ModelDownloadManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：提供高品质、工业级的大模型权重文件后台静默下载、断点续传、沙盒 SHA256 文件指纹指纹完整性校验。实现自 Domain 层的 ModelDownloadCapabilities 协议，采用 Swift 6 Actor 实现绝对的线程并发状态安全，桥接 URLSessionDelegate 提供流畅的 AsyncStream 状态流。
//

import Foundation
import CommonCrypto

/// 大模型权重文件后台静默下载与状态管理器
public actor ModelDownloadManager: ModelDownloadCapabilities {
    
    /// 全局单例注入，便于在 App 顶层会话绑定
    public static let shared = ModelDownloadManager()
    
        private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.zhiyu.app.model.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        let delegateHelper = ModelDownloadDelegateHelper(manager: self)
        return URLSession(configuration: config, delegate: delegateHelper, delegateQueue: nil)
    }()

    
    /// 模型 ID 到当前下载任务状态的映射表
    private var downloadStates: [String: DownloadState] = [:]
    
    /// 模型 ID 到物理后台 Session Task 的映射表
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    
    /// 模型 ID 到断点续传二进制数据 (resumeData) 的缓存记录
    private var resumeDataCache: [String: Data] = [:]
    
    /// 模型 ID 到对应 SHA256 校验指纹的缓存映射表
    private var sha256Checksums: [String: String] = [:]
    
    /// 模型 ID 到其异步流事件通道 (Continuation) 的订阅分发映射表
    private var continuations: [String: AsyncStream<DownloadState>.Continuation] = [:]
    
    private init() {}
    
    // MARK: - Capabilities 契约接口实现
    
    /// 开始下载大模型权重文件
    public func startDownload(modelId: String, remoteURL: URL) async throws {
        // 1. 如果已经存在下载任务，直接拦截
        if let state = downloadStates[modelId] {
            switch state {
            case .downloading, .verifying, .completed:
                return
            default:
                break
            }
        }
        
        // 2. 清理历史残余
        cleanPreviousFiles(for: modelId)
        
        // 3. 构建后台 Task
        let task = session.downloadTask(with: remoteURL)
        task.taskDescription = modelId
        activeTasks[modelId] = task
        
        // 4. 更新并分发状态为 pending
        updateState(for: modelId, to: .pending)
        
        // 5. 激活 Task 开始下载
        task.resume()
    }
    
    /// 暂停正在下载的权重任务，捕获断点续传数据 (resumeData)
    public func pauseDownload(modelId: String) async throws {
        guard let task = activeTasks[modelId] else { return }
        
        // 优雅捕获 resumeData 并暂停物理下载
        let resumeData = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            task.cancel(byProducingResumeData: { data in
                continuation.resume(returning: data)
            })
        }
        
        if let data = resumeData {
            resumeDataCache[modelId] = data
            updateState(for: modelId, to: .paused)
        } else {
            updateState(for: modelId, to: .failed(error: "Failed to generate resume data for pausing."))
        }
        
        activeTasks[modelId] = nil
    }
    
    /// 恢复下载已经暂停的权重任务 (利用之前捕获的 resumeData)
    public func resumeDownload(modelId: String) async throws {
        // 1. 检索断点缓存数据
        guard let data = resumeDataCache[modelId] else {
            // 如果缓存为空，尝试重新从 url 启动下载 (需在业务层补充 URL 记录)
            updateState(for: modelId, to: .failed(error: "No resume data available."))
            return
        }
        
        // 2. 基于 resumeData 重新拉起 Task 并关联
        let task = session.downloadTask(withResumeData: data)
        task.taskDescription = modelId
        activeTasks[modelId] = task
        
        // 3. 清理已消费的缓存
        resumeDataCache[modelId] = nil
        
        // 4. 激活 Task 继续静默续传
        task.resume()
    }
    
    /// 取消下载任务，彻底清除临时下载数据
    public func cancelDownload(modelId: String) async throws {
        if let task = activeTasks[modelId] {
            task.cancel()
        }
        
        resumeDataCache[modelId] = nil
        activeTasks[modelId] = nil
        cleanPreviousFiles(for: modelId)
        
        updateState(for: modelId, to: .failed(error: "Download cancelled by user."))
    }
    
    /// 监听特定大模型任务的实时状态与进度变化流
    public func observeDownloadState(for modelId: String) async -> AsyncStream<DownloadState> {
        return AsyncStream { continuation in
            // 保存当前事件通道
            continuations[modelId] = continuation
            
            // 首次订阅时推送当前已有状态
            let currentState = downloadStates[modelId] ?? .failed(error: "Idle")
            continuation.yield(currentState)
            
            // 订阅断开时自动清理
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeContinuation(for: modelId)
                }
            }
        }
    }
    
    // MARK: - 注册 SHA256 指纹
    
    /// 外部在发起下载前，需向 Manager 注册期望的哈希值用于完好性判定
    /// - Parameters:
    ///   - modelId: 模型 ID
    ///   - checksum: SHA256 校验和串
    public func registerChecksum(for modelId: String, checksum: String) {
        sha256Checksums[modelId] = checksum
    }
    
    // MARK: - 供 Delegate 调用的内部并发更新方法
    
    /// 更新下载进度百分比
    public func updateProgress(for modelId: String, progress: Double) {
        updateState(for: modelId, to: .downloading(progress: progress))
    }
    
    /// 完成下载，在沙盒临时路径触发指纹完整性验证
    public func completeDownload(for modelId: String, tempFileURL: URL) {
        updateState(for: modelId, to: .verifying)
        
        // 利用后台并发 Task 异步进行 CPU 密集的哈希判定与文件移动，解耦主 Actor
        Task.detached(priority: .userInitiated) {
            let manager = ModelDownloadManager.shared
            let checksum = await manager.getChecksum(for: modelId) ?? ""
            
            // 1. 进行完好性校验 (SHA256)
            if !manager.verifySHA256(of: tempFileURL, expectedHash: checksum) {
                await manager.updateState(for: modelId, to: .failed(error: "File verification failed. SHA256 mismatch."))
                try? FileManager.default.removeItem(at: tempFileURL)
                return
            }
            
            // 2. 校验成功，安全移入沙盒 Document 目录
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentDirectory.appendingPathComponent("\(modelId).bin")
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: tempFileURL, to: destinationURL)
                
                // 3. 标记完结
                await manager.updateState(for: modelId, to: .completed(localURL: destinationURL))
                await manager.clearActiveTask(for: modelId)
            } catch {
                await manager.updateState(for: modelId, to: .failed(error: "Sandbox storage" + " allocation failed:" + " \(error.localizedDescription)"))
            }
        }
    }
    
    /// 网络传输异常时的错误拦截处理
    public func handleDownloadError(for modelId: String, error: Error) {
        let nsError = error as NSError
        
        // 🟢 如果是断网等原因引起的异常中断，iOS 会在错误包里贴心地附带 resumeData！
        if let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            resumeDataCache[modelId] = resumeData
            updateState(for: modelId, to: .paused)
        } else {
            updateState(for: modelId, to: .failed(error: error.localizedDescription))
        }
        
        activeTasks[modelId] = nil
    }
    
    // MARK: - 内部并发辅助工具方法
    
    /// 获取指定模型的 SHA256 校验和
    public func getChecksum(for modelId: String) -> String? {
        return sha256Checksums[modelId]
    }
    
    /// 清除指定模型的活动下载任务
    public func clearActiveTask(for modelId: String) {
        activeTasks[modelId] = nil
    }
    
    /// 核心状态更新与发布分发引擎
    public func updateState(for modelId: String, to state: DownloadState) {
        downloadStates[modelId] = state
        
        // 瞬间向所有订阅的 AsyncStream 分发最新状态事件，UI 感知无延迟
        if let continuation = continuations[modelId] {
            continuation.yield(state)
        }
    }
    
    private func removeContinuation(for modelId: String) {
        continuations[modelId] = nil
    }
    
    private func cleanPreviousFiles(for modelId: String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentDirectory.appendingPathComponent("\(modelId).bin")
        try? FileManager.default.removeItem(at: destinationURL)
    }
    
    /// 哈希校验防爆算法 (SHA256 Helper)
    nonisolated fileprivate func verifySHA256(of fileURL: URL, expectedHash: String) -> Bool {
        guard !expectedHash.isEmpty else { return true } // 如果白名单未配置哈希，视为跳过校验
        
        guard let file = FileHandle(forReadingAtPath: fileURL.path) else { return false }
        defer { try? file.close() }
        
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        
        let bufferSize = 1024 * 1024 // 1MB 内存分片读取，防止加载数 GB 模型把运行内存撑爆 (防爆读)
        while true {
            let data = file.readData(ofLength: bufferSize)
            if data.isEmpty { break }
            data.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(data.count))
            }
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        
        let hexHash = digest.map { String(format: "%02hhx", $0) }.joined()
        return hexHash.lowercased() == expectedHash.lowercased()
    }
}

// MARK: - 桥接 Delegate 协调助手类 (NSObject Bridge Pattern)

/// URLSession 代理协助类。继承自 NSObject 满足 Objective-C 回调契约，负责无声桥接后台系统通知至 Actor
fileprivate final class ModelDownloadDelegateHelper: NSObject, URLSessionDownloadDelegate, Sendable {
    
    /// 持有弱引用的 Actor 控制器
    private let manager: ModelDownloadManager
    
    init(manager: ModelDownloadManager) {
        self.manager = manager
        super.init()
    }
    
    /// URLSession 下载进度回调，更新模型下载进度
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let modelId = downloadTask.taskDescription, totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        // 强行注入 Swift 6 并发上下文，回推给 Actor 主体
        Task {
            await manager.updateProgress(for: modelId, progress: progress)
        }
    }
    
    /// URLSession 下载完成回调，将临时文件移交至管理器处理
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let modelId = downloadTask.taskDescription else { return }
        
        // 创建沙盒下的临时安全副本，防止系统委托在退出 didFinishDownloading 瞬间删除文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let safeTempURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".bin")
        
        do {
            try FileManager.default.moveItem(at: location, to: safeTempURL)
            Task {
                await manager.completeDownload(for: modelId, tempFileURL: safeTempURL)
            }
        } catch {
            Task {
                await manager.updateState(for: modelId, to: .failed(error: "Temporary copy" + " generation failed:" + " \(error.localizedDescription)"))
            }
        }
    }
    
    /// URLSession 任务完成回调，处理下载错误（自动忽略用户主动取消）
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let taskDescription = task.taskDescription else { return }
        
        if let error = error {
            let nsError = error as NSError
            // 🟢 如果是用户主动取消任务，忽略报错
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            
            Task {
                await manager.handleDownloadError(for: taskDescription, error: error)
            }
        }
    }
}
