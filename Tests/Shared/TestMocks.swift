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
final class MockLLMService: LLMService, @unchecked Sendable {
    override var isProcessing: Bool { get { _isProcessing } set { _isProcessing = newValue } }
    private var _isProcessing = false
    
    override var isEnabled: Bool { get { _isEnabled } set { _isEnabled = newValue } }
    private var _isEnabled = true
    
    var generateHandler: (@Sendable (String, String) async throws -> String)?
    var chatStreamHandler: (@Sendable (String, [ChatMessageDTO], [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error>)?
    
    override func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO { ChatMessageDTO(role: .assistant, content: "") }
    
    override func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        if let handler = chatStreamHandler {
            return handler(query, history, pages)
        }
        return AsyncThrowingStream { $0.finish() }
    }
    
    override func generate(prompt: String, systemPrompt: String) async throws -> String {
        if let handler = generateHandler {
            return try await handler(prompt, systemPrompt)
        }
        return "智宇是一款优秀的基于 RAG 的知识管理应用，具备双向链接功能。"
    }
    override func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO {
        SmartIngestResultDTO(title: title, compiledContent: "", suggestedTags: [], suggestedType: "", relatedTitles: [], summary: "")
    }
    override func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] { [] }
    override func foldContent(existingContent: String, newContent: String, title: String) async throws -> String { "" }
    override func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO] { [] }
    override func rewriteQuery(_ query: String) async -> String { query }
    override func expandQuery(_ query: String) async -> [String] { [query] }
    override func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable] { candidates }
    override func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] { chunks }
    override func generateHypotheticalDocument(query: String) async -> String { query }
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
        
        #if os(macOS)
        ServiceContainer.shared.register(MacHapticService() as any HapticFeedbackProtocol, for: (any HapticFeedbackProtocol).self)
        #elseif os(watchOS)
        ServiceContainer.shared.register(WatchHapticService() as any HapticFeedbackProtocol, for: (any HapticFeedbackProtocol).self)
        #else
        ServiceContainer.shared.register(iOSHapticService() as any HapticFeedbackProtocol, for: (any HapticFeedbackProtocol).self)
        #endif
        
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
        
        ServiceContainer.shared.register(LLMConfigManager(), for: LLMConfigManager.self)
        ServiceContainer.shared.register(AIAnalyticsService(), for: AIAnalyticsService.self)
        
        let llm = MockLLMService()
        ServiceContainer.shared.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        ServiceContainer.shared.register(llm, for: LLMService.self)

        // 注册 Mock 环境下的 EmbeddingManager 和仓库，加固向量同步功能
        let vectorRepo = VectorDataRepository(dbWriter: dbQueue)
        let embeddingManager = EmbeddingManager(repository: vectorRepo)
        ServiceContainer.shared.register(embeddingManager, for: EmbeddingManager.self)
        
        let knowledgeRepo = KnowledgePageRepository(dbWriter: dbQueue)
        ServiceContainer.shared.register(knowledgeRepo as any KnowledgeRepository, for: (any KnowledgeRepository).self)
        
        let governanceRepo = AIGovernanceRepository(dbWriter: dbQueue)
        ServiceContainer.shared.register(governanceRepo as any GovernanceRepository, for: (any GovernanceRepository).self)

        if let globalWriter = DatabaseManager.shared.globalWriter {
            let vaultRepo = SQLiteVaultRepository(dbWriter: globalWriter)
            ServiceContainer.shared.register(vaultRepo as any VaultRepository, for: (any VaultRepository).self)
            
            let fileSigRepo = SQLiteFileSignatureRepository(dbWriter: globalWriter)
            ServiceContainer.shared.register(fileSigRepo as any FileSignatureRepository, for: (any FileSignatureRepository).self)
        }

        ServiceContainer.shared.register(BackupService(), for: BackupService.self)
        ServiceContainer.shared.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        // 3. Domain Services (L2)
        ServiceContainer.shared.register(AuthService.shared as any AuthServiceProtocol, for: (any AuthServiceProtocol).self)
        ServiceContainer.shared.register(VaultService.shared as any VaultServiceProtocol, for: (any VaultServiceProtocol).self)
        // 注册设置存储中心以供测试沙盒内需要注入 SettingsStore 的类能正常解析，避免测试时闪退
        ServiceContainer.shared.register(SettingsStore(), for: SettingsStore.self)
        
        ServiceContainer.shared.register(LinkService(), for: LinkService.self)
        ServiceContainer.shared.register(IngestService(), for: IngestService.self)
        ServiceContainer.shared.register(LintService(), for: LintService.self)
        ServiceContainer.shared.register(UndoService(), for: UndoService.self)
        ServiceContainer.shared.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        // 注册知识页面核心管理器，供 AppStore 等服务 @Inject 注入，确保单测数据读写与修改流正常 (@DIP)
        ServiceContainer.shared.register(KnowledgePageManager(), for: KnowledgePageManager.self)
        // 注册系统维护服务，健全单测生命周期的全局重置与清理链路 (@DIP)
        ServiceContainer.shared.register(MaintenanceService(), for: MaintenanceService.self)
        ServiceContainer.shared.register(ChatService.shared as any ChatServiceProtocol, for: (any ChatServiceProtocol).self)
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
        
        // 4. Data Sync Coordination (L1.5) & Sibling Stores - 必须在底层所有 Mock 物理仓储和 L1 基础设施就绪后注册，以防时序竞争崩溃
        ServiceContainer.shared.register(IngestStore(), for: IngestStore.self)
        ServiceContainer.shared.register(SynthesisStore(), for: SynthesisStore.self)
        ServiceContainer.shared.register(DataCoordinator(), for: DataCoordinator.self)
        
        // 5. L2 Features & Sidebar Row Components Dependencies
        // 注册知识页面状态存储中心，防止插件卸载/加载等环节因获取不到 KnowledgeStore 导致测试崩溃 (@DIP)
        ServiceContainer.shared.register(KnowledgeStore(), for: KnowledgeStore.self)
    }
}

// MARK: - Mock Knowledge Page
public struct MockPage: KnowledgePageRepresentable, Hashable {
    public var id = UUID()
    public var title: String
    public var content: String
    public var tags: [String] = []
    public var pageType: PageType = .concept
    
    public init(id: UUID = UUID(), title: String, content: String, tags: [String] = [], pageType: PageType = .concept) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.pageType = pageType
    }
}
