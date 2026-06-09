//
//  RAGEvaluationServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 RAGEvaluationService 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class RAGEvaluationServiceTests: XCTestCase {
    
    private var mockLLM: MockLLMService!
    private var governanceStore: (any RAGGovernanceRepository)!
    private var evaluationService: RAGEvaluationService!
    
    override func setUp() async throws {
        try await super.setUp()
        await setupFullMockEnvironment()
        
        mockLLM = try XCTUnwrap(ServiceContainer.shared.resolve((any LLMServiceProtocol).self) as? MockLLMService)
        governanceStore = ServiceContainer.shared.resolve((any RAGGovernanceRepository).self)
        evaluationService = RAGEvaluationService(llmService: mockLLM, governanceStore: governanceStore)
    }
    
    override func tearDown() async throws {
        mockLLM = nil
        governanceStore = nil
        evaluationService = nil
        try await super.tearDown()
    }
    
    // MARK: - 正常打分与落库测试 (Pass)
    
    /// 验证当 LLM 裁判给出高分时，报告被正确划归为 "Pass" 状态，并成功落入 SQLite 数据库
    func testEvaluationPassStatusAndPersistence() async throws {
        // 1. 模拟裁判输出合格的高分 JSON 字符串
        mockLLM.generateHandler = { prompt, systemPrompt in
            XCTAssertTrue(systemPrompt.contains("Judge"))
            return """
            {
                "faithfulness": 0.95,
                "relevance": 0.88,
                "context_precision": 0.92
            }
            """
        }
        
        let query = "什么是量子纠缠？"
        let answer = "量子纠缠是微观粒子间的一种强关联现象。"
        let context = "量子纠缠是指两个或多个粒子在空间上分离，但其量子态相互关联。"
        
        // 2. 执行评估
        let report = await evaluationService.evaluate(query: query, answer: answer, context: context)
        
        // 3. 断言报告的各项指标
        XCTAssertEqual(report.query, query)
        XCTAssertEqual(report.answer, answer)
        XCTAssertEqual(report.faithfulness, 0.95)
        XCTAssertEqual(report.relevance, 0.88)
        XCTAssertEqual(report.precision, 0.92)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.pass) // "Pass"
        
        // 4. 从 SQLite 治理仓储拉出最近的一条记录，验证数据真实落库
        let records = try await governanceStore.fetchRAGEvaluations(limit: 1)
        XCTAssertEqual(records.count, 1)
        if let firstRecord = records.first {
            XCTAssertEqual(firstRecord.query, query)
            XCTAssertEqual(firstRecord.answer, answer)
            XCTAssertEqual(firstRecord.faithfulness, 0.95)
            XCTAssertEqual(firstRecord.relevance, 0.88)
            XCTAssertEqual(firstRecord.precision, 0.92)
        }
    }
    
    // MARK: - 中等分数测试 (Warning)
    
    /// 验证当 LLM 裁判给出中等分数时，报告被正确划归为 "Warning" 状态
    func testEvaluationWarningStatus() async {
        mockLLM.generateHandler = { prompt, systemPrompt in
            return """
            {
                "faithfulness": 0.65,
                "relevance": 0.70,
                "context_precision": 0.68
            }
            """
        }
        
        let report = await evaluationService.evaluate(query: "警告测试", answer: "中等回答", context: "部分上下文")
        
        XCTAssertEqual(report.faithfulness, 0.65)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.warning) // "Warning"
    }
    
    // MARK: - 低分测试 (Fail)
    
    /// 验证当 LLM 裁判给出极低分数时，报告被正确标记为 "Fail" 状态
    func testEvaluationFailStatus() async {
        mockLLM.generateHandler = { prompt, systemPrompt in
            return """
            {
                "faithfulness": 0.35,
                "relevance": 0.40,
                "context_precision": 0.30
            }
            """
        }
        
        let report = await evaluationService.evaluate(query: "失败测试", answer: "答非所问", context: "完备上下文")
        
        XCTAssertEqual(report.faithfulness, 0.35)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.fail) // "Fail"
    }
    
    // MARK: - 降级防卫测试 (Degraded Error)
    
    /// 验证当 LLM 损坏输出或超时时，评估服务能够平稳拦截异常，优雅降级为 0 分 error 报告
    func testEvaluationDegradedOnInvalidJSON() async {
        // 模拟 LLM 发生网络中断或输出乱码，非有效 JSON
        mockLLM.generateHandler = { prompt, systemPrompt in
            return "Server Timeout, Raw HTML error..."
        }
        
        let report = await evaluationService.evaluate(query: "网络故障测试", answer: "无回答", context: "空上下文")
        
        XCTAssertEqual(report.faithfulness, 0.0)
        XCTAssertEqual(report.relevance, 0.0)
        XCTAssertEqual(report.precision, 0.0)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.error) // "Error"
    }
    
    /// 验证当 LLM 评测抛出强异常（如网络连接断开）时，评估服务能够捕获 error 并优雅降级为 0 分 error 报告
    func testEvaluationDegradedOnLLMError() async {
        // 模拟 LLM 发生物理网络连接报错，强行抛出 Error
        mockLLM.generateHandler = { _, _ in
            throw URLError(.cannotConnectToHost)
        }
        
        let report = await evaluationService.evaluate(query: "抛出异常测试", answer: "网络崩溃", context: "空上下文")
        
        XCTAssertEqual(report.faithfulness, 0.0)
        XCTAssertEqual(report.relevance, 0.0)
        XCTAssertEqual(report.precision, 0.0)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.error) // "Error"
    }
    
    // MARK: - JSON 字段缺失测试

    /// 验证当 LLM 裁判返回的 JSON 中缺少部分指标字段时，评估服务能够平稳使用 0.0 兜底，并成功生成报告并持久化
    func testEvaluationMissingJSONKeys() async {
        mockLLM.generateHandler = { prompt, systemPrompt in
            return "{}"
        }

        let report = await evaluationService.evaluate(query: "字段缺失测试", answer: "局部回答", context: "部分上下文")

        XCTAssertEqual(report.faithfulness, 0.0)
        XCTAssertEqual(report.relevance, 0.0)
        XCTAssertEqual(report.precision, 0.0)
        XCTAssertEqual(report.hallucinationRate, 0.0)
        XCTAssertEqual(report.citationAccuracy, 0.0)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.fail) // "Fail"
    }

    // MARK: - 新指标全维度解析测试 (Phase 2)

    /// 验证 LLM 返回 5 维指标（含幻觉率与引用准确度）时全部正确解析并持久化
    func testEvaluationFiveDimensionalParsingAndPersistence() async throws {
        mockLLM.generateHandler = { prompt, systemPrompt in
            // 验证 prompt 包含新维度关键词
            XCTAssertTrue(prompt.contains("hallucination_rate"))
            return """
            {
                "faithfulness": 0.92,
                "relevance": 0.85,
                "context_precision": 0.88,
                "hallucination_rate": 0.08,
                "citation_accuracy": 0.90
            }
            """
        }

        let query = "什么是暗物质？"
        let answer = "暗物质是一种不发光、不反射电磁辐射的物质，通过引力效应被间接探测到。"
        let context = "暗物质是宇宙中占比约 27% 的不可见物质，其存在由星系旋转曲线和引力透镜效应证实。"

        let report = await evaluationService.evaluate(query: query, answer: answer, context: context)

        // 断言所有 5 维指标
        XCTAssertEqual(report.faithfulness, 0.92)
        XCTAssertEqual(report.relevance, 0.85)
        XCTAssertEqual(report.precision, 0.88)
        XCTAssertEqual(report.hallucinationRate, 0.08)
        XCTAssertEqual(report.citationAccuracy, 0.90)
        XCTAssertEqual(report.status, L10n.AI.Eval.Status.pass)

        // 验证数据库持久化
        let records = try await governanceStore.fetchRAGEvaluations(limit: 1)
        XCTAssertEqual(records.count, 1)
        if let first = records.first {
            XCTAssertEqual(first.faithfulness, 0.92)
            XCTAssertEqual(first.relevance, 0.85)
            XCTAssertEqual(first.precision, 0.88)
            XCTAssertEqual(first.hallucinationRate, 0.08)
            XCTAssertEqual(first.citationAccuracy, 0.90)
        }
    }

    /// 验证新指标部分缺失时使用 0.0 兜底（向后兼容旧版 JSON）
    func testEvaluationPartialNewMetricsDefaultToZero() async {
        mockLLM.generateHandler = { _, _ in
            // 旧版 JSON 不含 hallucination_rate 和 citation_accuracy
            return """
            {
                "faithfulness": 0.78,
                "relevance": 0.82,
                "context_precision": 0.75
            }
            """
        }

        let report = await evaluationService.evaluate(query: "旧格式测试", answer: "兼容回答", context: "部分上下文")

        XCTAssertEqual(report.faithfulness, 0.78)
        XCTAssertEqual(report.relevance, 0.82)
        XCTAssertEqual(report.precision, 0.75)
        // 新字段缺失时应兜底为 0.0
        XCTAssertEqual(report.hallucinationRate, 0.0)
        XCTAssertEqual(report.citationAccuracy, 0.0)
    }

    // MARK: - 五维均值计算测试

    /// 验证 calculateAverageRAGScores 返回 5 维均值的正确性
    func testCalculateAverageRAGScoresFiveDimensional() async throws {
        // 写入两条已知评估记录
        try await governanceStore.saveRAGEvaluation(RAGEvaluation(
            query: "Q1", answer: "A1",
            faithfulness: 0.9, relevance: 0.8, precision: 0.7,
            hallucinationRate: 0.1, citationAccuracy: 0.9,
            evaluatorModel: "test-model"
        ))
        try await governanceStore.saveRAGEvaluation(RAGEvaluation(
            query: "Q2", answer: "A2",
            faithfulness: 0.7, relevance: 0.6, precision: 0.5,
            hallucinationRate: 0.3, citationAccuracy: 0.7,
            evaluatorModel: "test-model"
        ))

        let avg = try await governanceStore.calculateAverageRAGScores(days: 365)

        // (0.9 + 0.7) / 2 = 0.8
        XCTAssertEqual(avg.faithfulness, 0.8, accuracy: 0.001)
        XCTAssertEqual(avg.relevance, 0.7, accuracy: 0.001)
        XCTAssertEqual(avg.precision, 0.6, accuracy: 0.001)
        // (0.1 + 0.3) / 2 = 0.2
        XCTAssertEqual(avg.hallucinationRate, 0.2, accuracy: 0.001)
        // (0.9 + 0.7) / 2 = 0.8
        XCTAssertEqual(avg.citationAccuracy, 0.8, accuracy: 0.001)
    }

    /// 空数据库时 calculateAverageRAGScores 返回全 0
    func testCalculateAverageRAGScoresEmptyDatabase() async throws {
        let avg = try await governanceStore.calculateAverageRAGScores(days: 30)

        XCTAssertEqual(avg.faithfulness, 0.0)
        XCTAssertEqual(avg.relevance, 0.0)
        XCTAssertEqual(avg.precision, 0.0)
        XCTAssertEqual(avg.hallucinationRate, 0.0)
        XCTAssertEqual(avg.citationAccuracy, 0.0)
    }
}
