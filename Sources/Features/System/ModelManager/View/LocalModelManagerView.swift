//
//  LocalModelManagerView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/05.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：本地大模型管理统一入口，集成模型商店、参数调优、服务器配置、智能路由四大核心功能模块。
//

import SwiftUI

/// 本地大模型管理统一入口视图
/// 采用 Tab 切换架构，整合模型商店和参数调优两大核心功能模块
@MainActor
public struct LocalModelManagerView: View {

    // MARK: - 环境注入

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @StateObject private var themeManager = ThemeManager.shared

    // MARK: - 状态管理

    /// 当前选中的 Tab 索引
    /// 0: 模型商店, 1: 参数调节
    @State private var selectedTab: Tab = .store

    // MARK: - Tab 枚举

    private enum Tab: Int, CaseIterable {
        case store = 0
        case parameters = 1

        var title: String {
            switch self {
            case .store:
                return L10n.ModelManager.storeTitle
            case .parameters:
                return L10n.ModelManager.parametersTitle
            }
        }

        var icon: String {
            switch self {
            case .store:
                return "square.stack.3d.up.fill"
            case .parameters:
                return "slider.horizontal.3"
            }
        }
    }

    public init() {}

    public var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义 Tab 选择器
                tabSelector

                // 内容区域
                TabView(selection: $selectedTab) {
                    ModelStoreView()
                        .tag(Tab.store)

                    InferenceParametersView()
                        .tag(Tab.parameters)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(L10n.Settings.localModelManager)
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - 子视图组件

    /// 顶部 Tab 选择器
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.medium) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, DesignSystem.medium)
            .padding(.vertical, DesignSystem.small)
        }
        .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
        .overlay(
            Rectangle()
                .frame(height: DesignSystem.Metrics.customSize1)
                .foregroundStyle(Color.appBorder.opacity(DesignSystem.Opacity.dim)),
            alignment: .bottom
        )
    }

    /// 单个 Tab 按钮
    private func tabButton(for tab: Tab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
            HapticFeedback.shared.trigger(.selection)
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? .appAccent : .appSecondary)

                Text(tab.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(selectedTab == tab ? .appAccent : .appSecondary)

                Rectangle()
                    .frame(height: DesignSystem.atomic)
                    .foregroundStyle(selectedTab == tab ? .appAccent : .clear)
            }
            .frame(width: DesignSystem.Metrics.customSize80)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 预览

#if DEBUG
#Preview {
    NavigationStack {
        LocalModelManagerView()
            .environment(AppStore())
            .environment(Router())
            .environmentObject(ThemeManager.shared)
    }
}
#endif
