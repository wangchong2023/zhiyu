// VaultRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域层：笔记本/知识库元数据仓储协议，定义多库管理在全局库上的数据访问契约。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Domain] 笔记本/知识库元数据仓储协议，实现多库隔离元数据的解耦存储。
public protocol VaultRepository: Sendable {
    /// 获取所有笔记本元数据列表 (按最后访问时间降序排列)
    func fetchAllVaults() async throws -> [Vault]
    
    /// 保存或更新单个笔记本元数据
    func saveVault(_ vault: Vault) async throws
    
    /// 更新指定笔记本的最后访问时间戳为当前时间
    func updateLastAccessed(id: UUID) async throws
    
    /// 从元数据表中物理删除指定笔记本
    func deleteVault(id: UUID) async throws
}
