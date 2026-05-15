// SystemStatsModels.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：资源监控模块相关数据模型
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 从 SystemStatsView 提取，支持架构解耦。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 每日 AI 使用统计
public struct DailyAIUsage: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let dateString: String
    public let tokens: Int
    public let requests: Int
    
    public init(date: Date, dateString: String, tokens: Int, requests: Int) {
        self.date = date
        self.dateString = dateString
        self.tokens = tokens
        self.requests = requests
    }
}

/// 每月 Token 统计
public struct MonthlyToken: Identifiable, Sendable {
    public let id = UUID()
    public let month: String
    public let total: Int
    
    public init(month: String, total: Int) {
        self.month = month
        self.total = total
    }
}

/// 存储分类统计
public struct StorageCategory: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Int64
    public let count: Int
    public let color: Color
    
    public init(label: String, value: Int64, count: Int, color: Color) {
        self.label = label
        self.value = value
        self.count = count
        self.color = color
    }
}
