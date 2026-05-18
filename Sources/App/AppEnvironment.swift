// AppEnvironment.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：应用程序全局 environment 管理器，负责 L0-L2 层的初始化顺序编排与全局状态持有。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

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
    let router: Router = Router.shared
    
    // ── 系统级状态 ──
    let themeManager: ThemeManager = ThemeManager.shared
    let llmService: LLMService = LLMService.shared
    let llmConfig: LLMConfigManager = ServiceContainer.shared.resolve(LLMConfigManager.self)
    
    private init() {
        print("🎬 [AppEnvironment] 开始执行初始化...")
        
        // 0. 准备底层物理存储 (@P0: 确保护航数据库在注册前就绪)
        // 注意：在实际多库模式下，此处应由 VaultService 驱动，但为了保证系统稳定性与 DI 完整性，
        // 我们在此处初始化默认存储路径。
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbURL = appSupport.appendingPathComponent(AppConstants.Storage.databaseName)
            try DatabaseManager.shared.setup(at: dbURL)
            print("📦 [AppEnvironment] 核心数据库已就绪: \(dbURL.lastPathComponent)")
        } catch {
            print("❌ [AppEnvironment] 数据库初始化严重失败: \(error)")
            // 生产环境下可考虑弹出警报，开发环境下此处失败将导致后续 register 报错并 panic
        }
        
        // 1. 执行模块化注册 (L0 - L3)
        CoreModuleRegistrar.register(in: ServiceContainer.shared)
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        DomainModuleRegistrar.register(in: ServiceContainer.shared)
        AppModuleRegistrar.register(in: ServiceContainer.shared)
        
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
        container.register(self.store.settingsStore, for: SettingsStore.self)
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
        
        print("🚀 [AppEnvironment] 初始化完成 at \(Date())")
    }
    
    /// 获取平台环境信息
    var platformEnv: any AppEnvironmentProtocol {
        ServiceContainer.shared.resolve((any AppEnvironmentProtocol).self)
    }
}
