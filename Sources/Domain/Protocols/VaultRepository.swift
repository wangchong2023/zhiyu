//
//  VaultRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Protocols 模块，提供相关的结构体或工具支撑。
//
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
