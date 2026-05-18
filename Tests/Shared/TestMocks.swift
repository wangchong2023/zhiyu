// TestMocks.swift
// 
// 作者: Wang Chong
// 功能说明: 整合测试中常用的 Mock 类，解决重构后的命名冲突与重复定义问题。
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 架构适配：对齐 Swift 6 Actor 与 DIP 协议结构 (@P0)。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import Foundation
import XCTest
import Combine
import GRDB
import LocalAuthentication
@testable import ZhiYu

// MARK: - Mock Logger
final class MockLogger: LoggerProtocol, @unchecked Sendable {
    var logEntries: [LogEntry] = []
    var logEntriesPublisher: AnyPublisher<[LogEntry], Never> { Just([]).eraseToAnyPublisher() }
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?, status: LogStatus?, failureReason: String?) {}
    func debug(_ message: String, file: String, function: String, line: Int) {}
    func info(_ message: String, file: String, function: String, line: Int) {}
    func warning(_ message: String, file: String, function: String, line: Int) {}
    func error(_ message: String, error: Error?, file: String, function: String, line: Int) {}
    func saveToDisk() async {}
    func loadFromDisk() async {}
    func clearAllLogs() async {}
    func logTimed<T>(action: LogAction, target: String, module: String?, details: String, operation: () throws -> T) rethrows -> T { try operation() }
    func getLogEntries() async -> [LogEntry] { [] }
}

// MARK: - Mock LLM Service
@MainActor
@preconcurrency
final class MockLLMService: NSObject, LLMServiceProtocol, @unchecked Sendable {
    var objectWillChange = ObservableObjectPublisher()
    var isProcessing = false
    var isEnabled = true
    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO { ChatMessageDTO(role: .assistant, content: "") }
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> { AsyncThrowingStream { $0.finish() } }
    func generate(prompt: String, systemPrompt: String) async throws -> String {
        return "智宇是一款优秀的基于 RAG 的知识管理应用，具备双向链接功能。"
    }
    func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO {
        SmartIngestResultDTO(title: title, compiledContent: "", suggestedTags: [], suggestedType: "", relatedTitles: [], summary: "")
    }
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] { [] }
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String { "" }
    func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO] { [] }
    func rewriteQuery(_ query: String) async -> String { query }
    func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable] { candidates }
}

// MARK: - Mock Biometric Auth Provider
final class MockBiometricAuthProvider: BiometricAuthProviderProtocol, @unchecked Sendable {
    var authenticationPolicy: LAPolicy { .deviceOwnerAuthentication }
    func canEvaluatePolicy(context: LAContext) -> Bool { false }
    func evaluatePolicy(context: LAContext, reason: String) async -> Bool { false }
}

// MARK: - XCTestCase Extension
extension XCTestCase {
    @MainActor
    func setupFullMockEnvironment() {
        ServiceContainer.shared.reset()
        DatabaseManager.shared.reset()
        
        // 1. Core Services (L0)
        let logger = MockLogger()
        ServiceContainer.shared.register(logger as any LoggerProtocol, for: (any LoggerProtocol).self)
        
        ServiceContainer.shared.register(HapticFeedback.shared, for: HapticFeedback.self)
        ServiceContainer.shared.register(Router.shared, for: Router.self)
        ServiceContainer.shared.register(DeepLinkService(), for: DeepLinkService.self)
        ServiceContainer.shared.register(PerformanceService(), for: PerformanceService.self)
        ServiceContainer.shared.register(AccessibilityService(), for: AccessibilityService.self)
        ServiceContainer.shared.register(SnapshotService(), for: SnapshotService.self)
        ServiceContainer.shared.register(WorkflowService.shared, for: WorkflowService.self)
        
        ServiceContainer.shared.register(MockBiometricAuthProvider() as any BiometricAuthProviderProtocol, for: (any BiometricAuthProviderProtocol).self)
        ServiceContainer.shared.register(DummyActivityService() as any LiveActivityProtocol, for: (any LiveActivityProtocol).self)
        // 注册平台级不支持的搜索索引器，保障测试套件后台同步不崩溃 (@SRS-7.1)
        ServiceContainer.shared.register(UnsupportedSearchIndexer() as any SearchIndexerProtocol, for: (any SearchIndexerProtocol).self)
        
        // 注册协作提供商服务以支持协作测试和同步逻辑，避免测试运行时闪退
        #if targetEnvironment(simulator) || os(watchOS)
        ServiceContainer.shared.register(StubCollaborationProvider() as any CollaborationProviderProtocol, for: (any CollaborationProviderProtocol).self)
        #else
        ServiceContainer.shared.register(MultipeerCollaborationProvider() as any CollaborationProviderProtocol, for: (any CollaborationProviderProtocol).self)
        #endif
        
        // 注册平台特定的设备环境适配服务，保障协作及排版功能获取正常设备名称和能力集
        #if os(macOS)
        ServiceContainer.shared.register(MacAppEnvironment() as any AppEnvironmentProtocol, for: (any AppEnvironmentProtocol).self)
        #elseif os(watchOS)
        ServiceContainer.shared.register(WatchAppEnvironment() as any AppEnvironmentProtocol, for: (any AppEnvironmentProtocol).self)
        #else
        ServiceContainer.shared.register(iOSAppEnvironment() as any AppEnvironmentProtocol, for: (any AppEnvironmentProtocol).self)
        #endif
        
        // 2. Storage Services (L1)
        let dbQueue = try! DatabaseQueue()
        // 绑定外部测试数据库写入器，并同步跑完所有 Schema 架构迁移以建立完整的物理表、虚拟表与触发器
        try! DatabaseManager.shared.setupForTesting(with: dbQueue)
        
        let sqliteStore = SQLiteStore(dbWriter: dbQueue)
        ServiceContainer.shared.register(sqliteStore as any AnyPageStoreCapabilities, for: (any AnyPageStoreCapabilities).self)
        ServiceContainer.shared.register(sqliteStore, for: SQLiteStore.self)
        
        // 注册 Mock 环境下的 EmbeddingManager 和仓库，加固向量同步功能
        let vectorRepo = VectorDataRepository(dbWriter: dbQueue)
        let embeddingManager = EmbeddingManager(repository: vectorRepo)
        ServiceContainer.shared.register(embeddingManager, for: EmbeddingManager.self)
        
        let knowledgeRepo = KnowledgePageRepository(dbWriter: dbQueue)
        ServiceContainer.shared.register(knowledgeRepo as any KnowledgeRepository, for: (any KnowledgeRepository).self)
        
        let governanceRepo = AIGovernanceRepository(dbWriter: dbQueue)
        ServiceContainer.shared.register(governanceRepo as any GovernanceRepository, for: (any GovernanceRepository).self)

        ServiceContainer.shared.register(BackupService(), for: BackupService.self)
        ServiceContainer.shared.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        // 3. Domain Services (L2)
        ServiceContainer.shared.register(AuthService.shared as any AuthServiceProtocol, for: (any AuthServiceProtocol).self)
        ServiceContainer.shared.register(VaultService.shared as any VaultServiceProtocol, for: (any VaultServiceProtocol).self)
        
        ServiceContainer.shared.register(LinkService(), for: LinkService.self)
        ServiceContainer.shared.register(IngestService(), for: IngestService.self)
        ServiceContainer.shared.register(LintService(), for: LintService.self)
        ServiceContainer.shared.register(UndoService(), for: UndoService.self)
        ServiceContainer.shared.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        ServiceContainer.shared.register(ChatService.shared as any ChatServiceProtocol, for: (any ChatServiceProtocol).self)
        
        let llm = MockLLMService()
        ServiceContainer.shared.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        ServiceContainer.shared.register(AISynthesisService.shared, for: AISynthesisService.self)
        ServiceContainer.shared.register(PromptService.shared, for: PromptService.self)
        
        let evaluationService = RAGEvaluationService(llmService: llm, governanceStore: governanceRepo)
        ServiceContainer.shared.register(evaluationService, for: RAGEvaluationService.self)
        
        ServiceContainer.shared.register(PluginRegistry.shared, for: PluginRegistry.self)
        
        #if os(iOS)
        ServiceContainer.shared.register(iOSOCRService() as any OCRServiceProtocol, for: (any OCRServiceProtocol).self)
        ServiceContainer.shared.register(iOSSpeechService() as any SpeechServiceProtocol, for: (any SpeechServiceProtocol).self)
        ServiceContainer.shared.register(iOSWatchSyncService() as any WatchSyncProtocol, for: (any WatchSyncProtocol).self)
        #endif
        
        // 4. Data Sync Coordination (L1.5) - 必须在底层所有 Mock 物理仓储和 L1 基础设施就绪后注册，以防时序竞争崩溃
        ServiceContainer.shared.register(DataCoordinator(), for: DataCoordinator.self)
    }
}
