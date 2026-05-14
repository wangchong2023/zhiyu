// TestMocks.swift
// 
// 作者: Wang Chong
// 功能说明: 整合测试中常用的 Mock 类，解决重构后的命名冲突与重复定义问题。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import Foundation
import XCTest
import Combine
import GRDB
@testable import ZhiYu

// MARK: - Mock Logger
final class MockLogger: LoggerProtocol, @unchecked Sendable {
    var logEntries: [LogEntry] = []
    var logEntriesPublisher: AnyPublisher<[LogEntry], Never> { Just([]).eraseToAnyPublisher() }
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?, status: LogStatus?, failureReason: String?) {}
    func debug(_ message: String, file: String, function: String, line: Int) {}
    func error(_ message: String, error: Error?, file: String, function: String, line: Int) {}
    func saveToDisk() {}
    func loadFromDisk() {}
    func clearAllLogs() {}
    func logTimed<T>(action: LogAction, target: String, module: String?, details: String, operation: () throws -> T) rethrows -> T { try operation() }
}

// MARK: - Mock LLM Service
@preconcurrency
final class MockLLMService: NSObject, LLMServiceProtocol, @unchecked Sendable {
    var objectWillChange = ObservableObjectPublisher()
    var isProcessing = false
    var isEnabled = true
    func chat(query: String, pages: [KnowledgePage]) async throws -> ChatMessage { ChatMessage(role: .assistant, content: "") }
    func chatStream(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error> { AsyncThrowingStream { $0.finish() } }
    func generate(prompt: String, systemPrompt: String) async throws -> String { "" }
    func smartIngest(title: String, rawContent: String, pages: [KnowledgePage]) async throws -> SmartIngestResult {
        SmartIngestResult(compiledContent: "", suggestedTags: [], suggestedType: "", relatedTitles: [], summary: "")
    }
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] { [] }
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String { "" }
    func analyzeForRefactoring(pages: [KnowledgePage]) async throws -> [RefactorSuggestion] { [] }
    func rewriteQuery(_ query: String) async -> String { query }
    func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] { candidates }
}

// MARK: - XCTestCase Extension
extension XCTestCase {
    @MainActor
    func setupFullMockEnvironment() {
        ServiceContainer.shared.reset()
        DatabaseManager.shared.reset()
        
        // 1. Core Services (L0)
        let logger = MockLogger()
        ServiceContainer.shared.register(logger, for: (any LoggerProtocol).self)
        
        let testDBURL = URL(string: "file::memory:?cache=shared")!
        let sqliteStore = SQLiteStore(dbURL: testDBURL)
        ServiceContainer.shared.register(sqliteStore, for: SQLiteStore.self)
        
        ServiceContainer.shared.register(HapticFeedback.shared, for: HapticFeedback.self)
        ServiceContainer.shared.register(Router.shared, for: Router.self)
        ServiceContainer.shared.register(DeepLinkService(), for: DeepLinkService.self)
        ServiceContainer.shared.register(PerformanceService(), for: PerformanceService.self)
        ServiceContainer.shared.register(AccessibilityService(), for: AccessibilityService.self)
        ServiceContainer.shared.register(SnapshotService(), for: SnapshotService.self)
        ServiceContainer.shared.register(WorkflowService.shared, for: WorkflowService.self)
        ServiceContainer.shared.register(DataCoordinator(), for: DataCoordinator.self)
        
        // 2. Storage Services (L1)
        ServiceContainer.shared.register(BackupService(), for: BackupService.self)
        ServiceContainer.shared.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        // 使用真正的内存数据库队列进行测试
        let dbQueue = try! DatabaseQueue()
        let pageStore = KnowledgePageStore(dbWriter: dbQueue)
        ServiceContainer.shared.register(pageStore, for: KnowledgePageStore.self)
        
        let embeddingManager = EmbeddingManager(repository: pageStore)
        ServiceContainer.shared.register(embeddingManager, for: EmbeddingManager.self)
        
        // 3. Domain Services (L2)
        ServiceContainer.shared.register(LinkService(), for: LinkService.self)
        ServiceContainer.shared.register(IngestService(), for: IngestService.self)
        ServiceContainer.shared.register(LintService(), for: LintService.self)
        ServiceContainer.shared.register(UndoService(), for: UndoService.self)
        ServiceContainer.shared.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        
        let llm = MockLLMService()
        ServiceContainer.shared.register(llm, for: (any LLMServiceProtocol).self)
        ServiceContainer.shared.register(AISynthesisService.shared, for: AISynthesisService.self)
        ServiceContainer.shared.register(PromptService.shared, for: PromptService.self)
        
        let evaluationService = RAGEvaluationService(llmService: llm, store: pageStore)
        ServiceContainer.shared.register(evaluationService, for: RAGEvaluationService.self)
        
        ServiceContainer.shared.register(PluginRegistry.shared, for: PluginRegistry.self)
    }
}
