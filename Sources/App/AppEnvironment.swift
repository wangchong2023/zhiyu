// AppEnvironment.swift
//
// 作者: Wang Chong
// 功能说明: 应用程序全局 environment 管理器，负责 L0-L2 层的初始化顺序编排与全局状态持有。
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
    
    private init() {
        print("🎬 [AppEnvironment] 开始执行初始化...")
        
        // 1. 执行模块化注册 (L0 - L2)
        CoreModuleRegistrar.register(in: ServiceContainer.shared)
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        DomainModuleRegistrar.register(in: ServiceContainer.shared)
        
        // 2. 初始化业务层 Stores
        // 确保在依赖注册完成后再实例化，防止 @Inject 导致的崩溃
        self.ingestStore = IngestStore()
        self.synthesisStore = SynthesisStore()
        self.store = AppStore()
        
        // 3. 配置全局 UI 样式 (iOS)
        #if os(iOS)
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.appAccent)
        #endif
        
        print("🚀 [AppEnvironment] 初始化完成 at \(Date())")
    }
    
    /// 获取平台环境信息
    var platformEnv: any AppEnvironmentProtocol {
        ServiceContainer.shared.resolve((any AppEnvironmentProtocol).self)
    }
}
