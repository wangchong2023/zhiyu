//
//  SyncCoordinatorDelegate.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Protocols 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 同步协调代理协议 (L1.5-Domain)
/// 抽象同步操作所需的 App 层数据访问与变更能力，使 L1 无需直接依赖 L3 AppStore
/// 注意：不要求 Sendable，因实现类为 @MainActor 隔离，主线程已提供并发安全保证。
@MainActor
public protocol SyncCoordinatorDelegate: AnyObject {
    /// 当前全量页面数据
    var pages: [KnowledgePage] { get }
    /// 当前全量日志数据
    var logEntries: [LogEntry] { get }
    /// 用指定页面集合替换本地全量数据
    func replaceLocalData(with pages: [KnowledgePage])
    /// 持久化当前内存状态到磁盘
    func saveToDisk() async
}
