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
        container.register(logger, for: (any LoggerProtocol).self)
        
        let sqliteStore = SQLiteStore()
        container.register(sqliteStore, for: SQLiteStore.self)
        
        container.register(HapticFeedback.shared, for: HapticFeedback.self)
        container.register(AppRouter.shared, for: AppRouter.self)
        
        // 注册其他平台级服务
        container.register(DeepLinkService(), for: DeepLinkService.self)
        container.register(PerformanceService(), for: PerformanceService.self)
        container.register(AccessibilityService(), for: AccessibilityService.self)
        #if canImport(WatchConnectivity)
        container.register(WatchConnectivityService.shared, for: WatchConnectivityService.self)
        #endif
        container.register(SnapshotService(), for: SnapshotService.self)
        container.register(WorkflowService.shared, for: WorkflowService.self)

        }
}

// MARK: - 存储模块 (L1)
@MainActor
struct StorageModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        container.register(BackupService(), for: BackupService.self)
        container.register(VaultStorageSecurityService(), for: VaultStorageSecurityService.self)
        
        if let writer = DatabaseManager.shared.dbWriter {
            let pageStore = KnowledgePageStore(dbWriter: writer)
            container.register(pageStore, for: KnowledgePageStore.self)
            
            let embeddingManager = EmbeddingManager(repository: pageStore)
            container.register(embeddingManager, for: EmbeddingManager.self)
            
            // 异步加载缓存
            Task {
                await embeddingManager.loadInitialCache()
            }
        }
    }
}

// MARK: - 领域能力模块 (L2)
@MainActor
struct DomainModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        // 1. 逻辑与处理器
        container.register(LinkService(), for: LinkService.self)
        container.register(IngestService(), for: IngestService.self)
        container.register(LintService(), for: LintService.self)
        container.register(UndoService(), for: UndoService.self)
        container.register(KnowledgeInsightService(), for: KnowledgeInsightService.self)
        container.register(PDFProcessor.shared, for: PDFProcessor.self)
        container.register(OCRProcessor.shared, for: OCRProcessor.self)
        
        // 2. AI 能力
        let llm = LLMService.shared
        container.register(llm, for: (any LLMServiceProtocol).self)
        container.register(llm, for: LLMService.self)
        container.register(AISynthesisService.shared, for: AISynthesisService.self)
        container.register(PromptService.shared, for: PromptService.self)
        
        let evaluationService = RAGEvaluationService(
            llmService: llm,
            store: container.resolve(KnowledgePageStore.self)
        )
        container.register(evaluationService, for: RAGEvaluationService.self)
        
        // 3. 插件系统
        container.register(PluginRegistry.shared, for: PluginRegistry.self)
        
        // 4. 注册协调器 (Coordination) - 必须在所有依赖项就绪后
        container.register(DataCoordinator(), for: DataCoordinator.self)
    }
}
