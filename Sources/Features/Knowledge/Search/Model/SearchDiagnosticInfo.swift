// SearchDiagnosticInfo.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：搜索诊断数据结构
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
