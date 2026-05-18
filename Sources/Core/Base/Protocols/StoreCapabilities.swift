// StoreCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：定义存储层的细粒度能力协议，用于在不暴露具体存储实现的情况下提供高级功能（如向量化、搜索）。
// 版本: 1.3
// 修改记录:
//   - 2026-05-16: 架构对齐：聚合存储能力，定义 AnyPageStoreCapabilities。
//   - 2026-05-16: 接口对齐：补全协议，确保 AppStore 通过协议调用底层所有事务。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 具备向量化能力的存储协议
public protocol VectorIndexableStore: Sendable {
    var embeddingManager: EmbeddingManager { get }
}

/// 具备监控与可观测性的存储协议
public protocol MonitorableStore: Sendable {
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?)
}

/// 通用页面存储操作协议 (类型抹除)
public protocol AnyPageStore: Sendable {
    /// 异步获取全量页面镜像
    var pages: [KnowledgePage] { get async }
    
    /// 获取页面全量列表 (带异常处理)
    func fetchAllPages() async throws -> [KnowledgePage]
    
    /// 从磁盘重载
    func reloadFromDisk() async
    
    /// 全量替换页面
    func replaceAllPages(_ newPages: [KnowledgePage]) async
    
    /// 重置数据库
    func resetDatabase() async throws
    
    /// 执行批量数据库写入操作
    func performBatchWrite(_ block: @escaping @Sendable (Database) throws -> Void) async throws

    /// 创建页面
    func createPage(
        title: String,
        pageType: PageType,
        customIcon: String?,
        content: String,
        tags: [String],
        sourceURL: String?,
        rawSnippet: String?,
        fileSize: Int64?,
        sourceType: String?
    ) async throws -> KnowledgePage

    /// 创建页面 (类型抹除封装版)
    @discardableResult
    func anyCreatePage(
        title: String,
        pageType: PageType,
        customIcon: String?,
        content: String,
        tags: [String],
        sourceURL: String?,
        rawSnippet: String?,
        fileSize: Int64?,
        sourceType: String?,
        forceDeepScan: Bool
    ) async -> KnowledgePage
    
    /// 更新页面
    func updatePage(_ page: KnowledgePage) async throws
    
    /// 更新页面 (类型抹除封装版)
    func anyUpdatePage(_ page: KnowledgePage, forceDeepScan: Bool) async
    
    /// 物理删除页面
    func deletePage(_ page: KnowledgePage) async throws
    
    /// 删除页面 (类型抹除封装版)
    func anyDeletePage(_ page: KnowledgePage) async
    
    /// 同步远程页面
    func syncRemotePage(_ page: KnowledgePage) async

    /// 获取反向引用
    func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage]

    /// 搜索页面
    func searchPages(query: String) async -> [KnowledgePage]

    /// 标签管理
    func renameTag(_ oldTag: String, to newTag: String) async
    func deleteTag(_ tag: String) async

    /// 填充默认引导内容
    func seedDefaultContent(logger: @escaping @Sendable (LogAction, String, String) -> Void) async

    /// 记录审计日志
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?)
}

/// 聚合存储能力协议 (L0-Base)
public typealias AnyPageStoreCapabilities = AnyPageStore & VectorIndexableStore
