// ModuleRegistrar.swift
//
// 作者: Wang Chong
// 功能说明: 定义模块化注册协议与各层级服务的自动化注册逻辑，用于解耦 ZhiYuApp 的初始化过程。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 初始版本，实现 L0-L2 模块化注册。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

// MARK: - 注册协议
/// 模块注册器协议：定义统一的注入入口
@MainActor
protocol ModuleRegistrar {
    static func register(in container: ServiceContainer)
}

// MARK: - 基础设施模块 (L0)
@MainActor
struct CoreModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        let logger = Logger()
        container.register(logger as any LoggerProtocol, for: (any LoggerProtocol).self)
        #if os(iOS) && !os(watchOS)
        container.register(iOSBackgroundTaskProvider(), for: (any BackgroundTaskProtocol).self)
        #else
        container.register(StubBackgroundTaskProvider(), for: (any BackgroundTaskProtocol).self)
        #endif
        
        let sqliteStore = SQLiteStore()
        container.register(sqliteStore, for: SQLiteStore.self)

        #if os(macOS)
        container.register(MacPasteboardService(), for: (any PasteboardProtocol).self)
        #elseif os(watchOS)
        container.register(WatchPasteboardService(), for: (any PasteboardProtocol).self)
        #else
        container.register(iOSPasteboardService(), for: (any PasteboardProtocol).self)
        #endif

        #if targetEnvironment(simulator) || os(watchOS)
        container.register(StubCollaborationProvider(), for: (any CollaborationProviderProtocol).self)
        #else
        container.register(MultipeerCollaborationProvider(), for: (any CollaborationProviderProtocol).self)
        #endif

        #if os(watchOS)
        container.register(WatchPDFService(), for: (any PDFServiceProtocol).self)
        #else
        container.register(iOSPDFService(), for: (any PDFServiceProtocol).self)
        #endif

        #if os(iOS)
        container.register(ActivityService.shared, for: ActivityService.self)
        #endif
        
        #if os(macOS)
        container.register(MacAppEnvironment(), for: (any AppEnvironmentProtocol).self)
        #elseif os(watchOS)
        container.register(WatchAppEnvironment(), for: (any AppEnvironmentProtocol).self)
        #else
        container.register(iOSAppEnvironment(), for: (any AppEnvironmentProtocol).self)
        #endif
        
        #if os(macOS)
        container.register(MacHapticService(), for: (any HapticFeedbackProtocol).self)
        #elseif os(watchOS)
        container.register(WatchHapticService(), for: (any HapticFeedbackProtocol).self)
        #else
        container.register(iOSHapticService(), for: (any HapticFeedbackProtocol).self)
        #endif
        
        #if os(macOS)
        container.register(StubWatchSyncService(), for: (any WatchSyncProtocol).self)
        #elseif os(watchOS)
        container.register(WatchWatchSyncService(), for: (any WatchSyncProtocol).self)
        #else
        container.register(iOSWatchSyncService(), for: (any WatchSyncProtocol).self)
        #endif
        
        container.register(AppRouter.shared, for: AppRouter.self)
        
        // 注册其他平台级服务
        container.register(DeepLinkService(), for: DeepLinkService.self)
        container.register(PerformanceService(), for: PerformanceService.self)
        container.register(AccessibilityService(), for: AccessibilityService.self)
        container.register(SnapshotService(), for: SnapshotService.self)
        container.register(WorkflowService.shared, for: WorkflowService.self)

        }
}

// MARK: - 存储模块 (L1)
@MainActor
struct StorageModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        print("📦 [DI] 开始注册存储模块...")
        container.register(BackupService(), for: BackupService.self)
        container.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        if let writer = DatabaseManager.shared.dbWriter {
            print("✅ [DI] 数据库写入器已就绪，注册 KnowledgePageStore")
            let pageStore = KnowledgePageStore(dbWriter: writer)
            container.register(pageStore, for: KnowledgePageStore.self)
            
            let embeddingManager = EmbeddingManager(repository: pageStore)
            container.register(embeddingManager, for: EmbeddingManager.self)
            
            // 异步加载缓存
            Task {
                await embeddingManager.loadInitialCache()
            }
        } else {
            print("⚠️ [DI] 警告：数据库写入器尚未就绪！注册空壳 KnowledgePageStore 以防崩溃。")
            // 这是一个保护性注册，防止 resolve 崩溃。
            // 实际上 SQLiteStore 初始化是同步的，不应发生此情况。
            let dummyStore = KnowledgePageStore(dbWriter: try! DatabaseQueue())
            container.register(dummyStore, for: KnowledgePageStore.self)
        }
    }
}

// MARK: - 领域能力模块 (L2)
@MainActor
struct DomainModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        print("🚀 [DI] 开始注册领域能力模块...")
        // 0. 认证与库服务
        container.register(AuthService.shared, for: AuthService.self)
        container.register(VaultService.shared, for: VaultService.self)
        
        // 1. 逻辑与处理器
        container.register(LinkService(), for: LinkService.self)
        container.register(IngestService(), for: IngestService.self)
        container.register(LintService(), for: LintService.self)
        container.register(UndoService(), for: UndoService.self)
        container.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        
        #if os(watchOS)
        container.register(WatchOCRService(), for: (any OCRServiceProtocol).self)
        #else
        container.register(iOSOCRService(), for: (any OCRServiceProtocol).self)
        #endif
        
        #if os(watchOS)
        container.register(WatchSpeechService(), for: (any SpeechServiceProtocol).self)
        #else
        container.register(iOSSpeechService(), for: (any SpeechServiceProtocol).self)
        #endif
        
        // 2. AI 能力
        let llm = LLMService.shared
        container.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        container.register(llm, for: LLMService.self)
        container.register(AISynthesisService.shared, for: AISynthesisService.self)
        container.register(PromptService.shared, for: PromptService.self)
        
        print("⚖️ [DI] 正在初始化 RAGEvaluationService...")
        // 检查 KnowledgePageStore 是否已注册
        if container.hasService(for: KnowledgePageStore.self) {
            let evaluationService = RAGEvaluationService(
                llmService: llm,
                store: container.resolve(KnowledgePageStore.self)
            )
            container.register(evaluationService, for: RAGEvaluationService.self)
        } else {
            print("❌ [DI] 错误：KnowledgePageStore 未注册！将导致 RAGEvaluationService 初始化失败。")
            // 这里我们先不 fatalError，让 resolve 的诊断信息更清晰
        }
        
        // 3. 插件系统
        container.register(PluginRegistry.shared, for: PluginRegistry.self)
        
        // 4. 注册协调器 (Coordination) - 必须在所有依赖项就绪后
        container.register(DataCoordinator(), for: DataCoordinator.self)
        print("✅ [DI] 领域能力模块注册完成")
    }
}
