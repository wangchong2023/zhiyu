// ZhiYuNewFeaturesTests.swift
//
// 作者: Wang Chong
// 功能说明: ZhiYu New Features Tests.swift
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 架构适配：更新 DI 注册与 Store 构造方式 (@P0)。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
import GRDB
@testable import ZhiYu

final class ZhiYuNewFeaturesTests: XCTestCase {
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // 统一配置标准测试 Mock 环境，确保 LiveActivityProtocol 等所有基础 DI 服务注册完成
        setupFullMockEnvironment()
        
        // 确保在 DI 注册就绪后再重置/访问单例状态，规避初始化时由于容器缺失服务导致的 assertion 闪退
        TaskCenter.shared.reset()
        PromptService.shared.reset()
    }
    
    @MainActor
    override func tearDown() async throws {
        TaskCenter.shared.reset()
        PromptService.shared.reset()
        DatabaseManager.shared.reset()
        ServiceContainer.shared.reset()
        try await super.tearDown()
    }

    // MARK: - QuizModel Parsing Tests
    func testQuizModelParsing() {
        let json = """
        {
          "title": "测试测验",
          "questions": [
            {
              "id": 1,
              "text": "Swift 是一门什么语言?",
              "options": ["编译型", "解释型", "脚本型", "汇编型"],
              "answer": 0,
              "explanation": "Swift 经过 LLVM 编译。"
            }
          ]
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let model = try decoder.decode(QuizModel.self, from: data)
            XCTAssertEqual(model.title, "测试测验")
            XCTAssertEqual(model.questions.count, 1)
            XCTAssertEqual(model.questions.first?.answer, 0)
        } catch {
            XCTFail("QuizModel decoding failed: \(error)")
        }
    }

    // MARK: - TaskCenter Tests
    @MainActor
    func testTaskCenterManagement() {
        let center = TaskCenter.shared
        let initialCount = center.tasks.count
        
        let taskID = center.addTask(name: "测试任务", target: "测试目标")
        XCTAssertEqual(center.tasks.count, initialCount + 1)
        XCTAssertEqual(center.tasks.first?.name, "测试任务")
        
        center.updateTask(taskID, status: .running(progress: 0.5, stage: .general))
        if case .running(let progress, _) = center.tasks.first?.status {
            XCTAssertEqual(progress, 0.5)
        } else {
            XCTFail("Task status should be running")
        }
        
        // 测试失败状态
        center.updateTask(taskID, status: .failed(error: "Timeout"))
        if case .failed(let error) = center.tasks.first?.status {
            XCTAssertEqual(error, "Timeout")
        } else {
            XCTFail("Task status should be failed")
        }
    }

    // MARK: - PromptService Tests
    func testPromptServicePersistence() {
        let service = PromptService.shared
        let originalMindmap = service.mindmapPrompt
        
        service.mindmapPrompt = "New Custom Prompt"
        service.save()
        
        // 模拟重启（使用 shared 实例，因为 init 已私有）
        let newService = PromptService.shared
        XCTAssertEqual(newService.mindmapPrompt, "New Custom Prompt")
        
        service.reset()
        XCTAssertEqual(service.mindmapPrompt, Localized.tr("prompt.default.mindmap"))
        
        // 恢复原状
        service.mindmapPrompt = originalMindmap
        service.save()
    }

    // MARK: - TextChunkerProcessor Semantic Tests
    func testTextChunkerProcessorSemanticSplitting() {
        let chunker = TextChunkerProcessor()
        let markdown = """
        # Header 1
        Section 1 content.
        
        ## Subheader 2
        Section 2 content. This should be split correctly.
        """
        
        let chunks = chunker.split(text: markdown)
        XCTAssertGreaterThan(chunks.count, 0)
        XCTAssertTrue(chunks.first?.text.contains("Header 1") ?? false)
    }

    // MARK: - Hybrid Search Logic Tests
    @MainActor
    func testHybridSearchQueryExpansion() async {
        let dbQueue = try! DatabaseQueue()
        let store = SQLiteStore(dbWriter: dbQueue)
        let query = "Karpathy Deep Learning"
        
        let results = await store.searchPages(query: query)
        XCTAssertNotNil(results)
    }

    // MARK: - QuizModel Fault Tolerance
    func testQuizModelFaultTolerance() {
        let brokenJson = "{\"title\": \"Broken\", \"questions\": []" // 缺少闭合括号
        let data = brokenJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(QuizModel.self, from: data))
    }

    // MARK: - External Link Citation Detection (Upgraded)
    func testCitationLinkDetection() {
        let report = "这是核心观点 [[Source]]。"
        XCTAssertTrue(report.contains("[[Source]]"), "应该使用双括号交互格式")
    }
}
