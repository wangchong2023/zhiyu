//
//  ViewFactory.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：属于 App 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 视图工厂：负责将抽象路由转换为真实视图
/// 进化版本：基于 ViewProvider 注册表实现插件化视图发现
@MainActor
struct ViewFactory {
    /// 视图提供者注册表
    private static var providers: [FeatureDomain: any ViewProvider] = [:]
    
    /// 注册领域视图提供者
    static func register(_ provider: any ViewProvider, for domain: FeatureDomain) {
        providers[domain] = provider
    }
    
    @ViewBuilder
    static func makeView(for route: AppRoute) -> some View {
        if let view = providers[route.domain]?.makeView(for: route) {
            view
        } else {
            // 兜底逻辑：如果未找到提供者或视图，显示 404
            ContentUnavailableView(
                L10n.Common.Error.notFound,
                systemImage: "exclamationmark.magnifyingglass",
                description: Text("No view provider registered for domain: \(route.domain.rawValue)")
            )
        }
    }
}


// MARK: - 包装器 (用于处理复杂的 Binding 或依赖)

struct PageDetailWrapper: View {
    let id: UUID
    @Environment(AppStore.self) var store
    
    var body: some View {
        if let page = store.pages.first(where: { $0.id == id }) {
            PageDetailView(page: page)
        } else {
            ContentUnavailableView(L10n.Common.Error.notFound, systemImage: "doc.questionmark")
        }
    }
}

struct SynthesisViewWrapper: View {
    @Environment(Router.self) var router
    var body: some View {
        SynthesisView(selection: Binding(
            get: { router.sidebarSelection },
            set: { router.sidebarSelection = $0 }
        ), selectedTab: Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        ))
    }
}

struct SettingsViewWrapper: View {
    var body: some View {
        SettingsView()
    }
}

struct LintWrapper: View {
    @Environment(Router.self) var router
    var body: some View {
        LintView(selection: Binding(
            get: { router.sidebarSelection },
            set: { router.sidebarSelection = $0 }
        ))
    }
}

struct GraphWrapper: View {
    @Namespace var heroNamespace
    @Environment(Router.self) var router
    var body: some View {
        @Bindable var router = router
        GraphContainerView(heroNamespace: heroNamespace, selectedTab: $router.selectedTab)
    }
}
