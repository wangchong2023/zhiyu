//
//  AppEnvironment.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：App 模块的 AppEnvironment 实现。
//
import SwiftUI
import Observation
import GRDB
/// 应用程序全局环境
/// 负责协调服务初始化、生命周期管理及全局状态（Stores）持有
@Observable
@MainActor
final class AppEnvironment {
    /// 全局单例
    static let shared = AppEnvironment()
    
    // ── 核心业务状态 ──
    let store: AppStore
    let ingestStore: IngestStore
    let synthesisStore: SynthesisStore
    let router: Router
    
    // ── 系统级状态 ──
    let themeManager: ThemeManager
    let llmService: LLMService
    let llmConfig: LLMConfigManager
    
    private init() {
        Logger.shared.info("[AppEnvironment] Starting initialization...")
        
        // 0. 准备底层物理存储 (@P0: 确保护航数据库在注册前就绪)
        // 注意：在实际多库模式下，此处应由 VaultService 驱动，但为了保证系统稳定性与 DI 完整性，
        // 我们在此处初始化默认存储路径，迁移至 App Group 共享容器。
        do {
            let fileManager = FileManager.default
            let appGroupIdentifier = "group.com.zhiyu.app"
            
            // 旧的沙盒独立路径
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw NSError(domain: "Insight", code: -1) }
            let oldDbURL = appSupport.appendingPathComponent(AppConstants.Storage.databaseName)
            
            // 新的 App Group 共享路径（若不可用，回退到沙盒路径）
            let dbURL: URL
            let baseGlobalURL: URL

            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
                dbURL = groupURL.appendingPathComponent(AppConstants.Storage.databaseName)
                baseGlobalURL = groupURL
            } else {
                Logger.shared.warning("[AppEnvironment] App Group unavailable, falling back to sandbox path")
                dbURL = oldDbURL
                baseGlobalURL = appSupport
            }

            // 数据无缝热迁移（如果旧库存在且新库不存在）
            if fileManager.fileExists(atPath: oldDbURL.path) && !fileManager.fileExists(atPath: dbURL.path) {
                Logger.shared.info("[AppEnvironment] Performing database App Group hot migration...")
                try fileManager.moveItem(at: oldDbURL, to: dbURL)

                // 迁移关联文件 (如 global.sqlite3)
                let oldGlobal = appSupport.appendingPathComponent(AppConstants.Storage.globalDatabaseName)
                let newGlobal = baseGlobalURL.appendingPathComponent(AppConstants.Storage.globalDatabaseName)
                if fileManager.fileExists(atPath: oldGlobal.path) && !fileManager.fileExists(atPath: newGlobal.path) {
                    try? fileManager.moveItem(at: oldGlobal, to: newGlobal)
                }
            }
            
            if CommandLine.arguments.contains("-UITest_MockData") {
                let memoryQueue = try DatabaseQueue()
                try DatabaseManager.shared.setupForTesting(with: memoryQueue)
                Logger.shared.info("[AppEnvironment] Core database ready (In-Memory Mock)")
            } else {
                try DatabaseManager.shared.setup(at: dbURL)
                Logger.shared.info("[AppEnvironment] Core database ready (App Group): \(dbURL.lastPathComponent)")
            }
        } catch {
            Logger.shared.error("[AppEnvironment] Critical: Database initialization failed", error: error)
            // 生产环境下可考虑弹出警报，开发环境下此处失败将导致后续 register 报错并 panic
        }
        
        // 1. 执行模块化注册 (L0 - L3)
        CoreModuleRegistrar.register(in: ServiceContainer.shared)
        StorageModuleRegistrar.register(in: ServiceContainer.shared)

        // L1 插件系统
        ServiceContainer.shared.register(PluginRegistry.shared, for: PluginRegistry.self)

        // L2 领域模块 — 按依赖顺序：Auth → Knowledge → AI
        AuthModuleRegistrar.register(in: ServiceContainer.shared)
        KnowledgeModuleRegistrar.register(in: ServiceContainer.shared)
        AIModuleRegistrar.register(in: ServiceContainer.shared)

        // L3 应用模块
        AppModuleRegistrar.register(in: ServiceContainer.shared)
        
        // 1.5 在模块注册完成后，解析/初始化系统级与依赖注入相关的单例属性，防止提前 resolve 导致的冷启动时序闪退
        self.router = Router.shared
        self.themeManager = ThemeManager.shared
        self.llmConfig = ServiceContainer.shared.resolve(LLMConfigManager.self)
        self.llmService = LLMService.shared
        
        // 2. 初始化业务层 Stores
        // 确保在依赖注册完成后再实例化，防止 @Inject 导致的崩溃
        self.ingestStore = IngestStore()
        self.synthesisStore = SynthesisStore()
        self.store = AppStore()
        
        // 3. 将核心 Store 注册到 DI 容器，支持各处 @Inject 调用
        let container = ServiceContainer.shared
        container.register(self.store, for: AppStore.self)
        container.register(self.ingestStore, for: IngestStore.self)
        container.register(self.synthesisStore, for: SynthesisStore.self)
        container.register(self.store.searchStore, for: SearchStore.self)
        container.register(self.store.aiWorkflowStore, for: AIWorkflowStore.self)
        container.register(self.store.aiWorkflowStore as any AIWorkflowCapabilities, for: (any AIWorkflowCapabilities).self)
        container.register(self.store.aiInsightStore, for: AIInsightStore.self)
        container.register(self.store.tagStore, for: TagStore.self)
        
        // 4. 配置全局 UI 样式 (iOS)
        #if os(iOS)
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.appAccent)
        #endif
        
        // 5. 异步触发数据种子化 (确保所有 DI 注册已完成且主线程已释放)
        Task {
            await self.store.seedDefaultContent()
            // 🎬 异步安全触发数据同步编排，此时所有底层注册和上层 Store 均已彻底就绪，避免时序闪退
            ServiceContainer.shared.resolve(DataCoordinator.self).sync()
        }
        
        Logger.shared.info("[AppEnvironment] Initialization" + " completed at" + " \(Date())")
    }
    
    /// 获取平台环境信息
    var platformEnv: any AppEnvironmentProtocol {
        ServiceContainer.shared.resolve((any AppEnvironmentProtocol).self)
    }
}
