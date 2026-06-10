//
//  DatabaseWriterProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：提取重复的 dbWriter 动态计算属性至协议扩展，消除 4 个 Repository 中的 11 行重复样板。
//

import Foundation
@preconcurrency import GRDB

/// 提供动态 `dbWriter` 计算属性的协议。
///
/// 默认实现从 `DatabaseManager.shared.dbWriter` 获取当前活跃的数据库写入器，
/// 支持多 Vault 热插拔切换。若尚未初始化（如测试冷启动），则降级创建内存数据库队列。
protocol DatabaseWriterProvider: AnyObject {
    var dbWriter: any DatabaseWriter { get async }
}

extension DatabaseWriterProvider {
    var dbWriter: any DatabaseWriter {
        get async {
            await MainActor.run {
                if let writer = DatabaseManager.shared.dbWriter {
                    return writer
                }
                do { return try DatabaseQueue() } catch {
                    fatalError("无法创建内存数据库(DatabaseWriterProvider): \(error)")
                }
            }
        }
    }
}
