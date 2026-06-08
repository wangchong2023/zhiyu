//
//  SystemStatsModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：系统设置：LLM 配置、性能监控、插件管理、iCloud、备份。
//
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