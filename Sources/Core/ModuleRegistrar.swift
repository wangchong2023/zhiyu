// ModuleRegistrar.swift
//
// 作者: Wang Chong
// 功能说明: 定义模块化注册协议与各层级服务的自动化注册逻辑，用于解耦 ZhiYuApp 的初始化过程。
// 版本: 1.1
// 修改记录:
//   - 2026-05-07: 初始版本，实现 L0-L2 模块化注册。
//   - 2026-05-10: 标准化代码注释与 SRS 溯源。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

// MARK: - 注册协议
/// 模块注册器协议：定义统一的注入入口 (@SR-04: 模块化沙盒管控基础)
@MainActor
protocol ModuleRegistrar {
    /// 在指定的容器中注册模块服务
    static func register(in container: ServiceContainer)
}

// MARK: - 基础设施模块 (L0)
/// 核心基础设施注册器：负责日志、平台适配、基础 UI 路由等底层服务
@MainActor
struct CoreModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        // @SRS-7.1: 初始化全局日志系统
        let logger = Logger()
        container.register(logger as any LoggerProtocol, for: (any LoggerProtocol).self)
        
        #if os(iOS) && !os(watchOS)
        container.register(iOSBackgroundTaskProvider(), for: (any BackgroundTaskProtocol).self)
        #else
        container.register(StubBackgroundTaskProvider(), for: (any BackgroundTaskProtocol).self)
        #endif
        
        // @RR-01: 初始化 SQLite 核心存储层
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

        #if os(macOS)
        container.register(MacOSSecurityScopedStorage(), for: SecurityScopedStorageProtocol.self)
        #elseif os(watchOS)
        container.register(WatchSecurityScopedStorage(), for: SecurityScopedStorageProtocol.self)
        #else
        container.register(iOSSecurityScopedStorage(), for: SecurityScopedStorageProtocol.self)
        #endif

        #if os(macOS)
        container.register(CoreMLModelCompiler(), for: MLModelCompilerProtocol.self)
        #elseif os(watchOS)
        container.register(WatchModelCompiler(), for: MLModelCompilerProtocol.self)
        #else
        container.register(CoreMLModelCompiler(), for: MLModelCompilerProtocol.self)
        #endif

        #if os(macOS)
        container.register(MacOSBiometricAuthProvider(), for: BiometricAuthProviderProtocol.self)
        #elseif os(watchOS)
        container.register(WatchBiometricAuthProvider(), for: BiometricAuthProviderProtocol.self)
        #else
        container.register(iOSBiometricAuthProvider(), for: BiometricAuthProviderProtocol.self)
        #endif

        #if os(iOS) && !targetEnvironment(macCatalyst) && !os(watchOS)
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
        
        container.register(Router.shared, for: Router.self)
        
        // 注册其他平台级服务
        container.register(DeepLinkService(), for: DeepLinkService.self)
        container.register(PerformanceService(), for: PerformanceService.self)
        container.register(AccessibilityService(), for: AccessibilityService.self)
        container.register(SnapshotService(), for: SnapshotService.self)
        container.register(WorkflowService.shared, for: WorkflowService.self)

        }
}

// MARK: - 存储模块 (L1)
/// 存储模块注册器：负责数据库管理、备份、加密及向量索引初始化 (@SR-02, @RR-01)
@MainActor
struct StorageModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        print("📦 [DI] 开始注册存储模块...")
        container.register(BackupService(), for: BackupService.self)
        container.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        container.register(AIInsightStore(), for: AIInsightStore.self)
        
        // @PR-05: 优化数据库冷启动加载时间
        if let writer = DatabaseManager.shared.dbWriter {
            print("✅ [DI] 数据库写入器已就绪，注册 KnowledgePageStore")
            let pageStore = KnowledgePageStore(dbWriter: writer)
            container.register(pageStore, for: KnowledgePageStore.self)
            
            let embeddingManager = EmbeddingManager(repository: pageStore)
            container.register(embeddingManager, for: EmbeddingManager.self)
            
            // 异步加载向量缓存以确保启动性能
            Task {
                await embeddingManager.loadInitialCache()
            }
        } else {
            print("⚠️ [DI] 警告：数据库写入器尚未就绪！注册空壳 KnowledgePageStore 以防崩溃。")
            // 这是一个保护性注册，防止 resolve 崩溃。
            let dummyStore = KnowledgePageStore(dbWriter: try! DatabaseQueue())
            container.register(dummyStore, for: KnowledgePageStore.self)
        }
    }
}

// MARK: - 领域能力模块 (L2)
/// 领域模块注册器：负责业务逻辑、AI 合成、插件系统及任务调度 (@PR-02, @SR-04)
@MainActor
struct DomainModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        print("🚀 [DI] 开始注册领域能力模块...")
        // 0. 认证与库服务 (@SR-03: 集成 LocalAuthentication)
        container.register(AuthService.shared as any AuthServiceProtocol, for: (any AuthServiceProtocol).self)
        container.register(VaultService.shared as any VaultServiceProtocol, for: (any VaultServiceProtocol).self)
        container.register(AuthService.shared, for: AuthService.self)
        container.register(VaultService.shared, for: VaultService.self)
        
        // 1. 逻辑与处理器
        container.register(LinkService(), for: LinkService.self)
        container.register(IngestService(), for: IngestService.self)
        container.register(LintService(), for: LintService.self)
        container.register(UndoService(), for: UndoService.self)
        container.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        
        container.register(ChatService.shared as any ChatServiceProtocol, for: (any ChatServiceProtocol).self)
        container.register(ChatService.shared, for: ChatService.self)
        
        // 2. 应用层核心
        container.register(Router.shared, for: Router.self)
        
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
        
        // 2. AI 能力 (@PR-02: 混合检索链路优化)
        let llm = LLMService.shared
        container.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        container.register(llm, for: LLMService.self)
        container.register(AISynthesisService.shared as any AISynthesisServiceProtocol, for: (any AISynthesisServiceProtocol).self)
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
        }
        
        // 3. 插件系统 (@SR-04: API 访问白名单管控)
        container.register(PluginRegistry.shared, for: PluginRegistry.self)
        
        // 4. 注册协调器 (Coordination) - 必须在所有依赖项就绪后
        container.register(DataCoordinator(), for: DataCoordinator.self)
        print("✅ [DI] 领域能力模块注册完成")
    }
}
