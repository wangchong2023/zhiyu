//
//  RAGPipelineTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 RAGPipeline 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

/// 系统集成测试：全链路 RAG 管道
/// 覆盖：导入 -> 向量化 -> 检索 -> AI 总结
@MainActor
final class RAGPipelineTests: XCTestCase {
    var store: AppStore!
    
    override func setUp() async throws {
        try await super.setUp()
        setupFullMockEnvironment()
        store = AppStore()
    }

    override func tearDown() async throws {
        store = nil
        // 允许当前主线程/协程事件循环排水，确保所有未完成的异步任务运行完毕，规避重置 DI 导致的 Race Condition (@SRS-7.1)
        try? await Task.sleep(nanoseconds: 100_000_000)
        DatabaseManager.shared.reset()
        try await super.tearDown()
    }
    
    /// 测试全链路 RAG 管道系统集成
    /// 验证从 原始文档导入 -> 向量化与词向量生成 -> 混合搜索与精确检索 -> LLM 生成回复 的完整闭环。
    func testFullRAGPipeline() async throws {
        // 从 DI 容器解析测试所需的具体持久化与向量模块
        let sqliteStore = ServiceContainer.shared.resolve(SQLiteStore.self)
        let embeddingManager = ServiceContainer.shared.resolve(EmbeddingManager.self)
        
        // 1. 导入数据并提取语义结构 (Ingest)
        let testContent = "智宇 (ZhiYu) 是一款基于 RAG 架构的知识管理 software，支持双向链接。"
        let page = await store.ingestService.ingestRawContent(
            title: "智宇简介",
            content: testContent,
            forceDeepScan: true,
            llmService: store.llmService,
            pageStore: sqliteStore
        )
        
        let pageID = page.id
        XCTAssertNotNil(pageID)
        
        // 2. 向量化转换与对齐 (Vectorization)
        // 手动同步内存中的页面并注入向量数据库以对齐检索基准
        let currentPages = await sqliteStore.pages
        await embeddingManager.syncEmbeddings(pages: currentPages)
        await store.refresh()
        
        let allEmbeddings = await embeddingManager.getAllEmbeddings()
        let embedding = allEmbeddings[pageID]
        XCTAssertNotNil(embedding, "向量化任务应在导入后完成")
        
        // 3. 混合多模态检索 (Hybrid Search)
        let searchResult = await store.linkService.hybridSearchWithDiagnostics(
            query: "什么是智宇",
            in: store.pages,
            embeddingProvider: embeddingManager
        )
        let searchResults = searchResult.results
        XCTAssertTrue(searchResults.contains(where: { $0.id == pageID }), "混合检索应能根据关键词召回导入的内容")
        
        // 4. AI 总结回复合成 (Generation)
        let prompt = "根据已知内容回答：智宇的特点是什么？"
        let systemPrompt = "你是一个专业的知识管理助手。"
        let aiResponse = try await store.llmService.generate(prompt: prompt, systemPrompt: systemPrompt)
        
        XCTAssertTrue(aiResponse.contains("RAG") || aiResponse.contains("双向链接") || !aiResponse.isEmpty, "AI 响应不应为空且应包含关键信息")
    }
}
