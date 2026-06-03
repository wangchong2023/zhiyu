//
//  DemoDataGenerator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Utility 模块，提供相关的结构体或工具支撑。
//
import Foundation
import GRDB

/// 演示数据生成器
///
/// 职责：用于快速填充知识库，展示图谱、检索及 AI 分析能力。
/// 该类仅用于 Demo 或开发测试阶段，不应包含任何核心业务逻辑。
struct DemoDataGenerator {
    
    /// 执行演示数据生成
    /// - Parameter store: 目标存储对象
    /// - Returns: 生成的页面数量
    /// 执行演示数据生成
    /// - Parameter store: 目标存储对象
    /// - Returns: 生成的页面数量
    static func generate(in store: any AnyPageStore) async throws -> Int {
        print("DemoData_Starting")
        
        try await store.performBatchWrite { db in
            // 1. 先清理所有的外键关联从表以避免自引用及外键级联顺序冲突导致的 SQLite constraint failed 错误
            // 按照依赖关系的反向顺序进行物理清理
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            
            // 2. 在同一个事务中清理旧数据，防止并发观察导致 I/O Error
            try KnowledgePage.deleteAll(db)
            try TokenUsage.deleteAll(db)
            try LLMCallLog.deleteAll(db)
            
            let pagesToCreate: [(String, PageType, String, [String])] = [
                (L10n.Common.Demo.aiAgent.title, .concept, L10n.Common.Demo.aiAgent.content + "", [L10n.Common.Tags.ai, L10n.Common.Tags.agent]),
                (L10n.Common.Demo.planning.title, .concept, L10n.Common.Demo.planning.content + "", [L10n.Common.Tags.ai, L10n.Common.Tags.planning]),
                (L10n.Common.Demo.memory.title, .concept, L10n.Common.Demo.memory.content + "", [L10n.Common.Tags.ai, L10n.Common.Tags.memory, L10n.Common.Tags.rag]),
                (L10n.Common.Demo.toolUse.title, .concept, L10n.Common.Demo.toolUse.content + "", [L10n.Common.Tags.ai, L10n.Common.Tags.toolUse]),
                (L10n.Common.Demo.llm.title, .concept, L10n.Common.Demo.llm.content + "", [L10n.Common.Tags.ai, L10n.Common.Tags.llm]),
                (L10n.Common.Demo.memoryMgmt.title, .concept, L10n.Common.Demo.memoryMgmt.content + " [[\(L10n.Common.Demo.vectorDB.title)]]", [L10n.Common.Tags.architecture]),
                (L10n.Common.Demo.toolchain.title, .concept, L10n.Common.Demo.toolchain.content + " [[\(L10n.Common.Demo.secureEnv.title)]]", [L10n.Common.Tags.tools]),
                (L10n.Common.Demo.chunking.title, .concept, L10n.Common.Demo.chunking.content + " [[\(L10n.Common.Demo.memory.title)]]", [L10n.Common.Tags.nlp]),
                (L10n.Common.Demo.vectorDB.title, .concept, L10n.Common.Demo.vectorDB.content + " [[\(L10n.Common.Demo.chunking.title)]]", [L10n.Common.Tags.storage]),
                (L10n.Common.Demo.secureEnv.title, .concept, L10n.Common.Demo.secureEnv.content + " [[\(L10n.Common.Demo.aiAgent.title)]]", [L10n.Common.Tags.security]),
                (L10n.Common.Demo.transformer.title, .concept, L10n.Common.Demo.transformer.content + " [[\(L10n.Common.Demo.embedding.title)]]", [L10n.Common.Tags.theory]),
                (L10n.Common.Demo.embedding.title, .concept, L10n.Common.Demo.embedding.content, [L10n.Common.Tags.theory]),
                (L10n.Common.Demo.gateway.title, .concept, L10n.Common.Demo.gateway.content, [L10n.Common.Tags.network]),
                (L10n.Common.Demo.toolInterface.title, .concept, L10n.Common.Demo.toolInterface.content + " [[\(L10n.Common.Demo.aiAgent.title)]]", [L10n.Common.Tags.protocol]),
                (L10n.Common.Demo.consistency.title, .concept, L10n.Common.Demo.consistency.content, [L10n.Common.Tags.quality]),
                (L10n.Common.Demo.topology.title, .concept, L10n.Common.Demo.topology.content, [L10n.Common.Tags.visual]),
                (L10n.Common.Demo.hybridSearch.title, .concept, L10n.Common.Demo.hybridSearch.content + " [[\(L10n.Common.Demo.embedding.title)]]", [L10n.Common.Tags.performance])
            ]
            
            for (title, type, content, tags) in pagesToCreate {
                let page = KnowledgePage(title: title, pageType: type, content: content, tags: tags)
                try page.save(db)
            }
            
            // 2. 模拟注入 AI 时延与 Token 记录，方便资源监控页面演示
            let models = ["GPT-4o", "Claude-3.5-Sonnet", "DeepSeek-V3"]
            let calendar = Calendar.current
            
            // 2. 注入 AI 调用日志 (LLM Call Logs) - 模拟最近 50 次请求
            for _ in 0..<50 {
                let model = models.randomElement() ?? "GPT-4o"
                let prompt = Int.random(in: 200...1000)
                let completion = Int.random(in: 100...2000)
                let latency = Int.random(in: 400...4500)
                let date = calendar.date(byAdding: .hour, value: -Int.random(in: 1...720), to: Date())!
                
                var log = LLMCallLog(
                    model: model,
                    promptTokens: prompt,
                    completionTokens: completion,
                    latencyMS: latency,
                    status: "success",
                    createdAt: date
                )
                try log.insert(db)
                
                var usage = TokenUsage(
                    model: model,
                    promptTokens: prompt,
                    completionTokens: completion,
                    createdAt: date
                )
                try usage.insert(db)
            }
        }
        
        print("DemoData_Finished")
        return AppConstants.Demo.defaultPageCount
    }
 
    /// 执行图谱压力测试数据生成
    /// - Parameters:
    ///   - store: 目标存储对象
    ///   - targetCount: 生成的节点数量，默认为 1000
    /// - Returns: 生成的页面数量
    static func generateStressTest(in store: any AnyPageStore, count targetCount: Int = 1000) async throws -> Int {
        print("StressTestData_Starting")
        
        try await store.performBatchWrite { db in
            // 1. 先清理所有的外键关联从表以避免自引用及外键级联顺序冲突导致的 SQLite constraint failed 错误
            // 按照依赖关系的反向顺序进行物理清理
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            try db.execute(sql: "")
            
            // 2. 在同一个事务中清理旧数据
            try KnowledgePage.deleteAll(db)
            
            // 预生成标题列表，用于建立随机链接
            let titles = (1...targetCount).map { "StressNode_\($0)" }
            let types: [PageType] = [.concept, .entity, .source, .comparison, .map]
            
            var localCount = 0
            for i in 0..<targetCount {
                let title = titles[i]
                let type = types[i % types.count]
                
                // 随机选择 1-3 个其他节点建立链接
                var content = ""
                let linkCount = Int.random(in: 1...3)
                var linkedIndices = Set<Int>()
                while linkedIndices.count < linkCount {
                    let randIdx = Int.random(in: 0..<targetCount)
                    if randIdx != i {
                        linkedIndices.insert(randIdx)
                    }
                }
                
                for _ in linkedIndices {
                    content += ""
                }
                
                let page = KnowledgePage(
                    title: title,
                    pageType: type,
                    content: content,
                    tags: ["StressTest", "Performance"]
                )
                
                try page.save(db)
                localCount += 1
                
                if localCount % 100 == 0 {
                    print("")
                }
            }
        }
        
        print("")
        return targetCount
    }
}
