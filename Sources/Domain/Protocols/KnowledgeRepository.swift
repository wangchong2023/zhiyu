// KnowledgeRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：知识库仓库协议。
// 遵循 Repository Pattern 屏蔽底层存储细节 (SQL/GRDB)。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 契约下沉：从 L1 迁移至 L1.5 领域层，实现依赖倒置。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// [Domain] 知识库仓库协议
/// 负责处理所有与 KnowledgePage 相关的持久化操作。
public protocol KnowledgeRepository: Sendable {
    func fetchAll() async throws -> [KnowledgePage]
    func fetch(id: UUID) async throws -> KnowledgePage?
    func save(_ page: KnowledgePage) async throws
    func delete(id: UUID) async throws
    func search(query: String) async throws -> [KnowledgePage]
    func fetchBacklinks(for id: UUID) async throws -> [UUID]
    func renameTag(old: String, to new: String) async throws
    func deleteTag(_ tag: String) async throws
    func count() async throws -> Int
}
