//
//  ModuleRegistrar.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：App 模块的 ModuleRegistrar 实现。
//
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

    /// 注册
    static func register(in container: ServiceContainer) {
        // @SRS-7.1: 初始化全局日志系统
        let logger = Logger.shared
        container.register(logger as any LoggerProtocol, for: (any LoggerProtocol).self)
        
        // 委托平台注册器注入平台特有服务（消除 15 个 #if os 宏，收敛为单一分发点）
        #if os(macOS)
        MacPlatformRegistrar.registerServices(in: container)
        #elseif os(watchOS)
        WatchPlatformRegistrar.registerServices(in: container)
        #else
        iOSPlatformRegistrar.registerServices(in: container)
        #endif
        
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

    /// 注册
    static func register(in container: ServiceContainer) {
        print("[DI] Starting registration of storage module...")
        
        // 注册 VaultDatabaseSwitcher 协议服务以支持依赖倒置 (DIP)
        container.register(DatabaseManager.shared as any VaultDatabaseSwitcher, for: (any VaultDatabaseSwitcher).self)
        
        // @RR-01: 初始化 SQLite 核心存储层
        // 智宇架构核心：数据库必须在 Storage 模块注册前就绪，否则视为不可恢复的配置错误
        guard let writer = DatabaseManager.shared.dbWriter else {
            fatalError("[DI] Database initialization failed: dbWriter is nil. Please check the DatabaseManager initialization sequence.")
        }
        
        let sqliteStore = SQLiteStore(dbWriter: writer)
        container.register(sqliteStore as any AnyPageStoreCapabilities, for: (any AnyPageStoreCapabilities).self)
        
        container.register(BackupService(), for: BackupService.self)
        container.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        // 业务特定的 InsightStore 现由 AppStore 统一实例化并注册，确保状态单一源
        
        // @PR-05: 优化数据库冷启动加载时间
        // 此时 writer 已由上方 guard 确认存在
        print("[DI] Database writer is ready, registering vertical repositories...")
        
        let knowledgeRepo = KnowledgePageRepository(dbWriter: writer)
        container.register(knowledgeRepo as any KnowledgeRepository, for: (any KnowledgeRepository).self)
        container.register(knowledgeRepo, for: KnowledgePageRepository.self)
        
        let vectorRepo = VectorDataRepository(dbWriter: writer)
        container.register(vectorRepo as any VectorRepository, for: (any VectorRepository).self)
        container.register(vectorRepo, for: VectorDataRepository.self)
        
        let governanceRepo = AIGovernanceRepository(dbWriter: writer)
        container.register(governanceRepo as any GovernanceRepository, for: (any GovernanceRepository).self)
        container.register(governanceRepo, for: AIGovernanceRepository.self)
        
        // 注册全新的 Vault 笔记本与 FileSignature 文件签名仓储协议 (纯 ORM，无 raw SQL)
        if let globalWriter = DatabaseManager.shared.globalWriter {
            let vaultRepo = SQLiteVaultRepository(dbWriter: globalWriter)
            container.register(vaultRepo as any VaultRepository, for: (any VaultRepository).self)
            
            let fileSigRepo = SQLiteFileSignatureRepository(dbWriter: globalWriter)
            container.register(fileSigRepo as any FileSignatureRepository, for: (any FileSignatureRepository).self)
        }
        // 4. 向量与 AI 检索层
        let embeddingManager = EmbeddingManager(repository: vectorRepo)
        container.register(embeddingManager as any EmbeddingProvider, for: (any EmbeddingProvider).self)
        container.register(embeddingManager, for: EmbeddingManager.self)

        
        // 注册 VectorIndexableStore 协议（L0 层向量检索能力），让 L2 可通过 DIP 访问
        container.register(sqliteStore as any VectorIndexableStore, for: (any VectorIndexableStore).self)
        
        // 注册文档文本提取基础设施服务，遵循依赖倒置契约 (@SRP)
        container.register(DocumentExtractionService() as any DocumentExtractionServiceProtocol, for: (any DocumentExtractionServiceProtocol).self)
        
        // 异步加载向量缓存以确保启动性能
        Task {
            await embeddingManager.loadInitialCache()
        }
    }
}

// MARK: - 领域能力模块 (L2)
/// 领域模块注册器：负责业务逻辑、AI 合成、插件系统及任务调度 (@PR-02, @SR-04)
@MainActor
struct DomainModuleRegistrar: ModuleRegistrar {

    /// 注册
    static func register(in container: ServiceContainer) {
        print("[DI] Starting registration of domain capability modules...")
        // 0. 认证与库服务 (@SR-03: 集成 LocalAuthentication)
        container.register(AuthService.shared as any AuthServiceProtocol, for: (any AuthServiceProtocol).self)
        container.register(VaultService.shared as any VaultServiceProtocol, for: (any VaultServiceProtocol).self)
        container.register(AuthService.shared, for: AuthService.self)
        container.register(VaultService.shared, for: VaultService.self)
        // 提前实例化并注册全局唯一的设置存储中心，供 AppStore 及各层级视图 @Inject 调用，彻底阻断循环依赖评估闪退 (@SRP)
        container.register(SettingsStore(), for: SettingsStore.self)
        
        // 1. 逻辑与处理器
        container.register(LinkService(), for: LinkService.self)
        container.register(IngestService(), for: IngestService.self)
        container.register(LintService(), for: LintService.self)
        container.register(UndoService(), for: UndoService.self)
        container.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        container.register(KnowledgePageManager(), for: KnowledgePageManager.self)
        // KnowledgeStore 由 AppStore 统一创建并注册，此处不再重复
        container.register(MaintenanceService(), for: MaintenanceService.self)
        
        container.register(ChatService.shared as any ChatServiceProtocol, for: (any ChatServiceProtocol).self)
        container.register(ChatService.shared, for: ChatService.self)
        
        // 2. 应用层核心
        
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
        container.register(LLMConfigManager(), for: LLMConfigManager.self)
        container.register(AIAnalyticsService(), for: AIAnalyticsService.self)
        container.register(RAGOrchestrator(), for: RAGOrchestrator.self)

        // 注册远程配置服务
        container.register(RemoteConfigService() as any RemoteConfigCapabilities, for: (any RemoteConfigCapabilities).self)

        container.register(ChatRunner(), for: (any LLMChatServiceProtocol).self)
        container.register(IngestProcessor(), for: (any LLMKnowledgeServiceProtocol).self)
        container.register(QueryReranker(), for: (any LLMRetrievalServiceProtocol).self)
        
        let llm = LLMService.shared
        container.register(llm as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        container.register(llm, for: LLMService.self)
        container.register(AISynthesisService.shared as any AISynthesisServiceProtocol, for: (any AISynthesisServiceProtocol).self)
        container.register(AISynthesisService.shared, for: AISynthesisService.self)
        container.register(PromptService.shared, for: PromptService.self)
        
        print("[DI] Initializing RAGEvaluationService...")
        // 检查 GovernanceRepository 是否已注册
        if container.hasService(for: (any GovernanceRepository).self) {
            let evaluationService = RAGEvaluationService(
                llmService: llm,
                governanceStore: container.resolve((any GovernanceRepository).self)
            )
            container.register(evaluationService, for: RAGEvaluationService.self)
        } else {
            print("[DI] Error: GovernanceRepository not registered! RAGEvaluationService initialization will fail.")
        }
        
        // 3. 插件系统 (@SR-04: API 访问白名单管控)
        container.register(PluginRegistry.shared, for: PluginRegistry.self)
        
        // 4. 注册协调器 (Coordination) - 必须在所有依赖项就绪后
        container.register(DataCoordinator(), for: DataCoordinator.self)
        print("[DI] Domain capability module registration completed")
    }
}

// MARK: - 应用模块 (L3)
/// 应用层注册器：负责路由、全局环境等顶层服务注册
@MainActor
struct AppModuleRegistrar: ModuleRegistrar {

    /// 注册
    static func register(in container: ServiceContainer) {
        print("[DI] Starting registration of application modules...")
        container.register(Router.shared, for: Router.self)
        
        // 注册视图提供者 (View Factory Evolution)
        ViewFactory.register(KnowledgeViewProvider(), for: .knowledge)
        ViewFactory.register(AIViewProvider(), for: .ai)
        ViewFactory.register(InsightViewProvider(), for: .insight)
        ViewFactory.register(SystemViewProvider(), for: .system)
    }
}
