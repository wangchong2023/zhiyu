//
//  ImportRecordRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：导入原始内容仓储协议

import Foundation

public protocol ImportRecordRepository: Sendable {
    func save(_ record: ImportRecord) async throws
    func fetchAll(category: String?, limit: Int) async throws -> [ImportRecord]
    func fetchByID(_ id: String) async throws -> ImportRecord?
    func updateStatus(id: String, status: String, completedAt: Date?) async throws
    func updatePageID(id: String, pageID: String) async throws
    func fetchInProgress() async throws -> [ImportRecord]
    func totalStorageSize() async throws -> Int64
}
