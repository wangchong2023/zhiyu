//
//  AISynthesisServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 AISynthesisService 的纯逻辑及边界条件开展单元测试。
//
//  架构说明：
//  AISynthesisService 是单例 actor，其 llm 在首次 init() 时从 ServiceContainer 捕获。
//  LLMServiceProtocol 是 @MainActor 协议，Mock 的 init() 也被主线程隔离，
//  只能在 @MainActor setUp 中创建。
//  关键修复：每次 setUp 通过 AISynthesisService.shared.updateLLMForTesting()
//  直接替换 actor 内部 llm 引用，保证测试设置的 generateResult 被服务实际使用。
//

import XCTest
import Combine
@testable import ZhiYu

final class AISynthesisServicePureLogicTests: XCTestCase {

    // MARK: - 实例 Mock（在 @MainActor setUp 内创建）

    /// LLM Mock：每次测试独立创建，通过 updateLLMForTesting 注入到 actor 内部
    private var mockLLM: MockFullLLMService!
    /// Logger Mock：注册到 ServiceContainer，供 @Inject logger 懒加载使用
    private var mockLogger: MockLoggerProtocol!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        // 在 @MainActor 上下文中创建 Mock（规避 @MainActor 协议 init 隔离限制）
        let llm = MockFullLLMService()
        let logger = MockLoggerProtocol()
        self.mockLLM = llm
        self.mockLogger = logger

        // 注册到 ServiceContainer 供 @Inject logger 解析
        ServiceContainer.shared.reset()
        ServiceContainer.shared.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        ServiceContainer.shared.register(logger as any LoggerProtocol, for: (any LoggerProtocol).self)

        // 【核心修复】直接替换 actor 内部 llm 引用：
        // AISynthesisService.shared 是单例，init() 只执行一次，llm 引用固化。
        // 通过 #if DEBUG 方法 updateLLMForTesting 强制将本次测试的 mockLLM
        // 注入到 actor 内部，确保 generate() 调用的是当前测试的 Mock 实例。
        await AISynthesisService.shared.updateLLMForTesting(llm)
    }

    @MainActor
    override func tearDown() async throws {
        ServiceContainer.shared.reset()
        mockLLM = nil
        mockLogger = nil
        try await super.tearDown()
    }

    // MARK: - generateInsightfulQuestions 空输入防护

    /// 验证当传入空页面列表时，AI 合成服务应返回空数组而不抛出异常。
    @MainActor
    func testGenerateInsightfulQuestions_emptyPages() async throws {
        let service = AISynthesisService.shared
        let result = try await service.generateInsightfulQuestions(pages: [])
        XCTAssertTrue(result.isEmpty, "空页面列表应返回空数组")
    }

    // MARK: - predictFollowUpQuestions 后续提问预测测试

    /// 验证当历史记录为空时，应直接返回空数组而不用请求大模型。
    @MainActor
    func testPredictFollowUpQuestions_emptyHistory() async throws {
        let service = AISynthesisService.shared
        let result = try await service.predictFollowUpQuestions(history: [], pages: [])
        XCTAssertTrue(result.isEmpty, "空历史记录应直接返回空数组")
    }

    /// 验证当 LLM 正常返回标准的 JSON 数组时，能正确解析出推荐问题。
    @MainActor
    func testPredictFollowUpQuestions_success() async throws {
        // 直接通过实例 Mock 设置响应，与 AISynthesisService.shared.llm 首次捕获的是同一引用
        mockLLM.generateResult = "[\"后续问题一\", \"后续问题二\", \"后续问题三\"]"

        let history = [
            ChatMessage(role: .user, content: "你好"),
            ChatMessage(role: .assistant, content: "你好！有什么我可以帮你的吗？")
        ]

        let result = try await AISynthesisService.shared.predictFollowUpQuestions(history: history, pages: [])
        XCTAssertEqual(result.count, 3, "应该返回 3 个预测的问题")

        // guard 防止 count 不为 3 时下标越界二次崩溃
        guard result.count == 3 else { return }
        XCTAssertEqual(result[0], "后续问题一")
        XCTAssertEqual(result[1], "后续问题二")
        XCTAssertEqual(result[2], "后续问题三")
    }

    /// 验证当 LLM 返回非规范的 JSON 或其他错误文本时，能优雅防护并返回空数组。
    @MainActor
    func testPredictFollowUpQuestions_fallback() async throws {
        mockLLM.generateResult = "This is not a JSON array"

        let history = [
            ChatMessage(role: .user, content: "你好")
        ]

        let result = try await AISynthesisService.shared.predictFollowUpQuestions(history: history, pages: [])
        XCTAssertTrue(result.isEmpty, "解析失败时应该优雅返回空数组")
    }
}

// MARK: - Mock: LLMServiceProtocol

/// 最小化 LLMServiceProtocol 实现
/// 注意：LLMServiceProtocol 是 @MainActor 协议，此 Mock 类隐式继承主 Actor 隔离，
/// 因此只能在 @MainActor 上下文中初始化（setUp async throws 满足此条件）
final class MockFullLLMService: LLMServiceProtocol {
    var isEnabled: Bool = false
    var provider: LLMProvider = .custom
    var apiKey: String = ""
    var baseURL: String = ""
    var model: String = ""
    var autoScan: Bool = false
    var autoRefactor: Bool = false

    /// 支持动态注入的模拟响应文本，每次 setUp 清空以隔离测试状态
    var generateResult: String = ""

    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        ChatMessageDTO(role: .assistant, content: "")
    }
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func generate(prompt: String, systemPrompt: String, maxTokens: Int) async throws -> String { generateResult }
    func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO {
        SmartIngestResultDTO(title: "", compiledContent: "", suggestedTags: [], suggestedType: "", relatedTitles: [], summary: "")
    }
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] { [] }
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String { "" }
    func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO] { [] }
    func rewriteQuery(_ query: String) async -> String { query }
    func expandQuery(_ query: String) async -> [String] { [query] }
    func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable] { candidates }
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] { chunks }
    func generateHypotheticalDocument(query: String) async -> String { query }
}

// MARK: - Mock: LoggerProtocol

/// 最小化 LoggerProtocol 实现
/// 修复根因：AISynthesisService 通过 @Inject 懒加载 logger，
/// predictFollowUpQuestions 调用 logger.debug 时触发解析，
/// 若未注册则 ServiceContainer.resolve 触发 fatalError 导致测试崩溃
final class MockLoggerProtocol: LoggerProtocol {

    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?,
                startTime: Date?, endTime: Date?, module: String?, status: LogStatus?, failureReason: String?) {}

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {}
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {}
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {}
    func error(_ message: String, error: Error?, file: String = #file, function: String = #function, line: Int = #line) {}

    func logTimed<T>(action: LogAction, target: String, module: String?, details: String, operation: () throws -> T) rethrows -> T {
        try operation()
    }

    func saveToDisk() async {}
    func loadFromDisk() async {}
    func clearAllLogs() async {}
    func getLogEntries() async -> [LogEntry] { [] }

    var logEntriesPublisher: AnyPublisher<[LogEntry], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
