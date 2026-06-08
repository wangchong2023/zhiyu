//
//  RAGPerformanceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 RAGPerformance 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class RAGPerformanceTests: XCTestCase {
    var llmService: LLMService!
    var largeCandidates: [KnowledgePage] = []
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        setupFullMockEnvironment()

        // 由于 RerankService 是一个真实服务单例，获取其实例
        llmService = LLMService.shared
        
        // 构建用于压测性能的大规模文本语料假数据 (1000 篇 Page)
        var mockPages: [KnowledgePage] = []
        for i in 0..<1000 {
            // 设置部分相关的语料
            let keyword = (i % 50 == 0) ? "Apple Vision Pro 空间计算" : "这是一段与苹果设备完全不相关的随机填充文档测试内容"
            
            let page = KnowledgePage(
                title: "MockPage_\(i)",
                pageType: .source,
                content: "这是第 \(i) 篇测试文档，它包含的特征短语是：\(keyword)"
            )
            mockPages.append(page)
        }
        self.largeCandidates = mockPages
    }
    
    @MainActor
    override func tearDown() async throws {
        self.largeCandidates = []
        self.llmService = nil
        // 允许当前协程事件循环排水，确保未完成的异步任务执行完毕
        try? await Task.sleep(nanoseconds: 50_000_000)
        DatabaseManager.shared.reset()
        ServiceContainer.shared.reset()
        try await super.tearDown()
    }
    
    /// 测量 1000 篇长文档在单次 Rerank 重排计算下消耗的 CPU 时钟周期
    func testRerankAlgorithmPerformance() {
        // 设置性能度量基线，并确保不会发生严重的降级（Regression）
        // 这里重点测试算法本身的 String 匹配复杂度与重排排序复杂度
        let query = "Apple Vision Pro 空间"
        
        self.measure {
            let expectation = XCTestExpectation(description: "Rerank Computation")
            
            Task {
                // 执行检索与重排
                do {
                    _ = try await llmService.rerank(query: query, candidates: self.largeCandidates)
                } catch {
                    XCTFail("重排过程发生错误: \(error)")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}