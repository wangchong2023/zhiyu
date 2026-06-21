//
//  LocalModelManagerView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/05.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：本地大模型管理统一入口，集成模型市场、参数调优、服务器配置、智能路由四大核心功能模块。
//

import SwiftUI

/// 本地大模型管理统一入口视图
/// 采用 Tab 切换架构，整合模型市场和参数调优两大核心功能模块
@MainActor
public struct LocalModelManagerView: View {

    // MARK: - 环境注入

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @StateObject private var themeManager = ThemeManager.shared

    // MARK: - 状态管理

    /// 当前选中的 Tab 索引
    /// 0: 模型市场, 1: 测试实验室
    @State private var selectedTab: Tab = .store

    // MARK: - Tab 枚举

    private enum Tab: Int, CaseIterable {
        case store = 0
        case laboratory = 1

        var title: String {
            switch self {
            case .store:
                return L10n.ModelManager.storeTitle
            case .laboratory:
                return L10n.ModelManager.laboratoryTitle
            }
        }

        var icon: String {
            switch self {
            case .store:
                return "square.stack.3d.up.fill"
            case .laboratory:
                return "flask.fill"
            }
        }
    }

    // MARK: - 布局常量 (Layout Constants)
    private struct Layout {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.7
        static let tabHorizontalPadding: CGFloat = 18
        static let tabVerticalPadding: CGFloat = 8
        static let selectorSpacing: CGFloat = 4
        static let selectorBorderWidth: CGFloat = 1.0
    }

    public init() {}

    public var body: some View {
        // 直接返回 VStack，使用父视图统一渲染的渐变背景，规避 ignoresSafeArea 拦截点击事件的问题
        VStack(spacing: 0) {
            // 自定义精致胶囊型 Tab 选择器
            tabSelector

            // 内容区域
            TabView(selection: $selectedTab) {
                ModelStoreView(onGoToLab: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .laboratory
                    }
                })
                .tag(Tab.store)

                ModelLabView(onGoToStore: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = .store
                    }
                })
                .tag(Tab.laboratory)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    // MARK: - 子视图组件

    /// 顶部精致胶囊型 Tab 选择器，减少主屏纵向高度占用，提升可视面积
    private var tabSelector: some View {
        HStack(spacing: Layout.selectorSpacing) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: Layout.springResponse, dampingFraction: Layout.springDamping)) {
                        selectedTab = tab
                    }
                    HapticFeedback.shared.trigger(.selection)
                }) {
                    Text(tab.title)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, Layout.tabHorizontalPadding)
                        .padding(.vertical, Layout.tabVerticalPadding)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.appAccent : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? Color.theme.white : .appSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.tiny)
        .background(Capsule().fill(Color.appCard.opacity(DesignSystem.Opacity.prominent)))
        .overlay(
            Capsule()
                .stroke(Color.appBorder.opacity(DesignSystem.Opacity.prominent), lineWidth: Layout.selectorBorderWidth)
        )
        .padding(.vertical, DesignSystem.medium)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - 预览

#if DEBUG
#Preview {
    NavigationStack {
        ZStack {
            // 在预览模式下在最外层包裹背景，确保预览效果与真机运行时一致
            ThemeManager.shared.pageBackground()
                .ignoresSafeArea()
            LocalModelManagerView()
        }
        .environment(AppStore())
        .environment(Router())
        .environmentObject(ThemeManager.shared)
    }
}
#endif
