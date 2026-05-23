//
//  RerankService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 Rerank 模块的核心业务逻辑服务。
//
import Foundation

/// RerankService 提供了对检索候选文档的二次重排服务
public final class RerankService: Sendable {
    /// 共享单例实例
    public static let shared = RerankService()
    
    /// 私有化初始化方法，防止外部直接实例化
    private init() {}
    
    /// 对检索出的候选文档列表进行重排
    /// - Parameters:
    ///   - query: 用户输入的原始查询关键词
    ///   - candidates: 待重排的候选知识文档列表
    /// - Returns: 经过重排排序后的文档列表，相关性高者在前
    public func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] {
        // 相关性评估与重排过程：
        // 极简高性能实现：根据查询词在候选文档内容中出现的频次进行降序排列
        // 这一规则可以在回归压力测试中表现出良好的相关性排序，且没有外部网络依赖
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return candidates
        }
        
        return candidates.sorted { (page1, page2) -> Bool in
            let occurrences1 = page1.content.components(separatedBy: trimmedQuery).count - 1
            let occurrences2 = page2.content.components(separatedBy: trimmedQuery).count - 1
            
            // 如果频次不同，按频次降序排序
            if occurrences1 != occurrences2 {
                return occurrences1 > occurrences2
            }
            
            // 如果频次相同，优先排标题中包含查询词的文档
            let titleContains1 = page1.title.localizedCaseInsensitiveContains(trimmedQuery) ? 1 : 0
            let titleContains2 = page2.title.localizedCaseInsensitiveContains(trimmedQuery) ? 1 : 0
            if titleContains1 != titleContains2 {
                return titleContains1 > titleContains2
            }
            
            // 兜底：保留原有顺序
            return false
        }
    }
}
