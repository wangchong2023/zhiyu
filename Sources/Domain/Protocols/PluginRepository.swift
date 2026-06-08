//
//  PluginRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：插件持久化仓储协议，定义插件元数据与统计的 CRUD 及搜索能力。
//
import Foundation

/// [Domain] 插件仓储协议
/// 负责插件元数据、安装状态及运行时统计的持久化操作。
public protocol PluginRepository: Sendable {
    /// 获取所有已安装插件记录
    func fetchAllInstalled() async throws -> [PluginRecord]

    /// 按 ID 获取单个插件记录
    func fetch(id: String) async throws -> PluginRecord?

    /// 保存或更新插件记录（upsert）
    func save(_ record: PluginRecord) async throws

    /// 删除指定插件记录
    func delete(id: String) async throws

    /// FTS5 全文搜索插件（按名称、作者）
    func search(query: String) async throws -> [PluginRecord]

    /// 增量更新插件运行时统计
    func updateStats(id: String, loadDuration: Double?, unloadDuration: Double?,
                     totalExecutionTime: Double?, callCount: Int?, status: String?) async throws

    /// 清空所有插件记录（用于测试重置）
    func deleteAll() async throws
}