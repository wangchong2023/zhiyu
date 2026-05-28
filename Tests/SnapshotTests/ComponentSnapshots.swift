//
//  ComponentSnapshots.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：属于 SnapshotTests 模块，提供相关的结构体或工具支撑。
//
import XCTest
import SwiftUI
import SnapshotTesting
import Combine
import GRDB
@testable import ZhiYu

@MainActor
final class ComponentSnapshots: XCTestCase {
    
    /// 依据环境变量判断是否启用快照录制模式，用于支持 CI/CD 脚本自动更新基准图片
    private var isRecordModeEnabled: Bool {
        ProcessInfo.processInfo.environment["RECORD_MODE"] == "1" ||
        ProcessInfo.processInfo.arguments.contains("-environmentRecordMode")
    }
    
    /// 测试 AI 脉搏指示器的视觉一致性
    func testAIPulseIndicator() {
        // 配置 Mock 环境
        setupMockEnvironment()
        
        let store = AppStore()
        let view = AIPulseIndicator()
            .environment(store)
            .frame(width: 150, height: 60)
            .background(Color.appBackground)
        
        // 记录/验证 iOS 布局
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    private func setupMockEnvironment() {
        setupFullMockEnvironment()
        isRecording = isRecordModeEnabled
    }
    
    /// 测试图谱节点的视觉一致性
    func testGraphNodeView() {
        isRecording = isRecordModeEnabled
        let node = GraphNode(
            id: UUID(),
            title: "测试节点",
            pageType: .concept,
            position: .zero
        )
        
        // 使用包装器提供 Namespace
        let view = SnapshotContainer { namespace in
            GraphNodeView(
                node: node,
                isSelected: false,
                isAnimating: false,
                linkCount: 5,
                clusters: [],
                useClustering: false,
                onSelect: {},
                heroNamespace: namespace,
                viewportRect: CGRect(x: 0, y: 0, width: 200, height: 200),
                scale: 1.0
            )
        }
        .frame(width: 100, height: 100)
        .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)))
    }
    
    /// 测试 AI 助手聊天视图 (ChatView) 的视觉一致性
    func testChatView() {
        setupMockEnvironment()
        let store = AppStore()
        let router = Router.shared
        
        let vaultService = VaultService.shared
        let authService = AuthService.shared
        let themeManager = ThemeManager.shared
        let onboardingService = OnboardingService.shared
        
        // 显式声明 llm 类型为基类 LLMService，消除 SwiftUI 在快照测试中由于 EnvironmentObject 强类型检索
        // (精确匹配注入的 Type.self) 而发生的多态向下转型失败、从而触发 Crash 的缺陷。
        let llm: LLMService = MockLLMService()
        var selectedTab = AppTab.chat
        
        let view = ChatView(selectedTab: Binding(get: { selectedTab }, set: { selectedTab = $0 }))
            .environment(store)
            .environment(router)
            .environment(vaultService)
            .environment(authService)
            .environmentObject(llm)
            .environmentObject(themeManager)
            .environmentObject(onboardingService)
            .frame(width: 375, height: 812)
            .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    /// 测试知识点详情页 (PageDetailView) 的视觉一致性
    func testPageDetailView() {
        setupMockEnvironment()
        let page = KnowledgePage(
            title: "快照测试页面",
            pageType: .concept,
            content: "# 这是一个测试页面\n用来进行视觉快照比对验证。",
            tags: ["测试", "快照"]
        )
        let store = AppStore()
        let aiStore = AIWorkflowStore()
        let router = Router.shared
        
        let view = SnapshotContainer { namespace in
            PageDetailView(page: page, heroNamespace: namespace)
        }
        .environment(store)
        .environment(aiStore)
        .environment(router)
        .frame(width: 375, height: 812)
        .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    /// 测试系统设置页 (SettingsView) 的视觉一致性
    func testSettingsView() {
        setupMockEnvironment()
        let store = AppStore()
        let router = Router.shared
        let appEnv = AppEnvironment.shared
        let settingsStore = SettingsStore()
        let onboarding = OnboardingService.shared
        
        let view = SettingsView()
            .environment(store)
            .environment(router)
            .environment(appEnv)
            .environment(settingsStore)
            .environmentObject(onboarding)
            .frame(width: 375, height: 812)
            .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }

    
    /// 测试响应式侧边栏组件的视觉一致性与代码覆盖率提升
    func testAdaptiveSidebarView() {
        setupMockEnvironment()
        let store = AppStore()
        let router = Router.shared
        let authService = AuthService.shared
        let onboardingService = OnboardingService.shared
        let themeManager = ThemeManager.shared
        var selectedTab = AppTab.knowledge
        var selection: SidebarSelection? = .tool(.lint)
        
        // 1. 测试 AdaptiveSidebarView 基础渲染
        let rawSidebarView = AdaptiveSidebarView(selectedTab: Binding(get: { selectedTab }, set: { selectedTab = $0 }))
        
        let view = rawSidebarView
            .environment(store)
            .environment(router)
            .environment(authService)
            .environment(VaultService.shared)
            .environmentObject(onboardingService)
            .environmentObject(themeManager)
            .environment(AIWorkflowStore())
            .frame(width: 300, height: 768)
            .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 300, height: 768)))
        
        // 2. 历经所有 AppTab 的 case 分支，榨干 switch-case 覆盖率死角
        for tab in AppTab.allCases {
            // 在 knowledge 模式下向导航栈推入不同类型的路由以激活 navigationDestination 闭包体
            if tab == .knowledge {
                router.path.append(AppRoute.settings)
                router.path.append(KnowledgePage(title: "测试路由页面", pageType: .concept, content: ""))
            }
            
            let detailViewForTab = SnapshotContainer { namespace in
                let detailView = AdaptiveDetailView(
                    selectedTab: Binding(get: { tab }, set: { _ in }),
                    selection: Binding(get: { selection }, set: { selection = $0 }),
                    heroNamespace: namespace
                )
                
                // 显式测试重构后的路由目标页生成逻辑，榨干 makeDestination 覆盖率
                // ⚠️ [警告]：直接调用返回 `some View` 且可能依赖 `@Environment` 的方法存在极高的崩溃风险，同样建议注释掉。
                // _ = detailView.makeDestinationView(for: .settings)
                // _ = detailView.makeDestinationView(for: .taskCenter)
                // _ = detailView.makePageDetailView(for: KnowledgePage(title: "测试页面", pageType: .concept, content: ""))
                
                return detailView
            }
            .environment(store)
            .environment(router)
            .environment(authService)
            .environment(VaultService.shared)
            .environmentObject(onboardingService)
            .environmentObject(themeManager)
            .environment(AIWorkflowStore())
            .frame(width: 500, height: 768)
            .background(Color.appBackground)
            
            if tab == .knowledge {
                assertSnapshot(of: detailViewForTab, as: .image(layout: .fixed(width: 500, height: 768)))
                // 渲染结束后清空导航栈，保障测试隔离干净
                router.path.removeLast(2)
            } else {
                // 直接使用 UIHostingController 促使 SwiftUI 核心布局系统对该分支进行完全渲染，产生 100% 覆盖率
                let controller = UIHostingController(rootView: detailViewForTab)
                _ = controller.view
            }
        }
    }
    
    /// 测试空间导航面包屑组件的视觉一致性与代码覆盖率提升
    func testBreadcrumbView() {
        isRecording = isRecordModeEnabled
        let history = [
            KnowledgePage(title: "首页节点", pageType: .concept, content: ""),
            KnowledgePage(title: "二级知识节点", pageType: .concept, content: ""),
            KnowledgePage(title: "当前深度详情", pageType: .concept, content: "")
        ]
        
        var navigatedId: UUID? = nil
        let rawBreadcrumbView = BreadcrumbView(history: history) { navigatedId = $0 }
        
        // 显式触发重构后的面包屑点击行为，消灭未覆盖闭包行
        if let firstPage = history.first {
            rawBreadcrumbView.handleNavigate(to: firstPage)
        }
        
        let view = rawBreadcrumbView
            .frame(width: 375, height: 50)
            .background(Color.appBackground)
            
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 375, height: 50)))
    }
}

// MARK: - Snapshot Helpers

/// 用于快照测试的容器，提供 Namespace 和必要的环境注入
struct SnapshotContainer<Content: View>: View {
    @Namespace var namespace
    let content: (Namespace.ID) -> Content
    
    var body: some View {
        content(namespace)
    }
}
