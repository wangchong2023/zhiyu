// KnowledgeRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 知识库仓库协议：定义领域模型与持久化层之间的契约。
// 遵循 Repository Pattern 屏蔽底层存储细节 (SQL/GRDB)，实现业务逻辑与持久化的彻底解耦。
// 版本: 1.0
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// [Infra] 知识库仓库协议
/// 负责处理所有与 KnowledgePage 相关的持久化操作。
protocol KnowledgeRepository: Sendable {
    
    // MARK: - 基础 CRUD
    
    /// 获取所有页面
    func fetchAll() async throws -> [KnowledgePage]
    
    /// 根据 ID 获取单个页面
    func fetch(id: UUID) async throws -> KnowledgePage?
    
    /// 根据标题获取单个页面
    func fetch(title: String) async throws -> KnowledgePage?
    
    /// 保存或更新页面
    func save(_ page: KnowledgePage) async throws
    
    /// 删除页面
    func delete(id: UUID) async throws
    
    /// 批量保存页面 (用于导入/同步)
    func saveAll(_ pages: [KnowledgePage]) async throws
    
    // MARK: - 特殊查询
    
    /// 获取置顶页面
    func fetchPinned() async throws -> [KnowledgePage]
    
    /// 根据类型过滤页面
    func fetch(type: PageType) async throws -> [KnowledgePage]
    
    /// 获取最近更新的页面
    func fetchRecentlyUpdated(limit: Int) async throws -> [KnowledgePage]
    
    /// 检查标题是否存在
    func exists(title: String) async throws -> Bool
    
    /// 全文搜索
    func search(query: String) async throws -> [KnowledgePage]
    
    /// 获取反向链接 (指向该页面的 ID 列表)
    func fetchBacklinks(for id: UUID) async throws -> [UUID]

    // MARK: - 标签管理
    
    /// 重命名全局标签
    func renameTag(_ oldTag: String, to newTag: String) async throws
    
    /// 删除全局标签
    func deleteTag(_ tag: String) async throws
    
    // MARK: - 统计信息
    
    /// 获取所有页面总数
    func count() async throws -> Int
    
    /// 获取特定类型的页面总数
    func count(type: PageType) async throws -> Int
    
    /// [危险] 删除所有数据
    func deleteAll() async throws
}
