//
//  SearchDiagnosticInfo.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 搜索诊断数据结构
public struct SearchDiagnosticInfo: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let query: String
    public let rewrittenQuery: String
    public let ftsCount: Int
    public let vectorCount: Int
    public let rrfTopResults: [ResultScore]

    public init(id: UUID = UUID(), query: String, rewrittenQuery: String, ftsCount: Int, vectorCount: Int, rrfTopResults: [ResultScore]) {
        self.id = id
        self.query = query
        self.rewrittenQuery = rewrittenQuery
        self.ftsCount = ftsCount
        self.vectorCount = vectorCount
        self.rrfTopResults = rrfTopResults
    }
    
    public struct ResultScore: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let ftsRank: Int
        public let vectorRank: Int
        public let finalScore: Double

        public init(id: UUID, title: String, ftsRank: Int, vectorRank: Int, finalScore: Double) {
            self.id = id
            self.title = title
            self.ftsRank = ftsRank
            self.vectorRank = vectorRank
            self.finalScore = finalScore
        }
    }
}
