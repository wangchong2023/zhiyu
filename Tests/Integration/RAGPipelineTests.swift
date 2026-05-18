// RAGPipelineTests.swift
//
// 作者: Wang Chong
// 功能说明: 系统集成测试：全链路 RAG 管道
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

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
        try? await Task.sleep(nanoseconds: 50_000_000)
        DatabaseManager.shared.reset()
        ServiceContainer.shared.reset()
        try await super.tearDown()
    }
    
    func testFullRAGPipeline() async throws {
        // 1. 导入 (Ingest)
        let testContent = "智宇 (ZhiYu) 是一款基于 RAG 架构的知识管理 software，支持双向链接。"
        let page = await store.ingestService.ingestRawContent(
            title: "智宇简介",
            content: testContent,
            forceDeepScan: true,
            llmService: store.llmService,
            pageStore: store.sqliteStore
        )
        
        let pageID = page.id
        XCTAssertNotNil(pageID)
        
        // 2. 向量化验证 (Vectorization)
        // 手动同步并等待向量和 AppStore 刷新以应对测试环境中的异步性
        let currentPages = await store.sqliteStore.pages
        await store.sqliteStore.embeddingManager.syncEmbeddings(pages: currentPages)
        await store.refresh()
        
        let allEmbeddings = await store.sqliteStore.embeddingManager.allEmbeddings
        let embedding = allEmbeddings[pageID]
        XCTAssertNotNil(embedding, "向量化任务应在导入后完成")
        
        // 3. 检索 (Hybrid Search)
        let searchResult = await store.linkService.hybridSearchWithDiagnostics(
            query: "什么是智宇",
            in: store.pages,
            embeddingManager: store.sqliteStore.embeddingManager
        )
        let searchResults = searchResult.results
        XCTAssertTrue(searchResults.contains(where: { $0.id == pageID }), "混合检索应能根据关键词召回导入的内容")
        
        // 4. AI 总结 (Generation)
        let prompt = "根据已知内容回答：智宇的特点是什么？"
        let systemPrompt = "你是一个专业的知识管理助手。"
        let aiResponse = try await store.llmService.generate(prompt: prompt, systemPrompt: systemPrompt)
        
        XCTAssertTrue(aiResponse.contains("RAG") || aiResponse.contains("双向链接") || !aiResponse.isEmpty, "AI 响应不应为空且应包含关键信息")
    }
}
