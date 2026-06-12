//
//  UserProfileMenu.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

struct UserProfileMenu: View {
    @Environment(AuthService.self) var authService
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var onboardingService: OnboardingService
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showProfile = false
    @State private var showAbout = false
    @State private var showWatchMenu = false

    @State private var showPlugins = false

    @State private var showDeveloper = false
    @State private var showMenuPopover = false
    @State private var showPlan = false
    
    var body: some View {
        #if os(watchOS)
        Button(action: { showWatchMenu = true }) {
            profileLabel
        }
        .accessibilityIdentifier("userProfileMenuButton")
        .sheet(isPresented: $showWatchMenu) {
            List {
                Button(action: { showSettings = true; showWatchMenu = false }) {
                    Label(L10n.Common.settings, systemImage: DesignSystem.Icons.settings)
                }

                Button(role: .destructive, action: { authService.logout(); showWatchMenu = false }) {
                    Label(L10n.Common.logout, systemImage: DesignSystem.Icons.logout)
                }
            }
        }
        .sheet(isPresented: $showAbout) { aboutStack }
        #else
        // iOS, iPadOS, macOS (Catalyst) 等非 watch 平台使用定制的高级毛玻璃悬浮菜单 (CustomProfilePopover)
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            showMenuPopover = true
        }) {
            profileLabel
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("userProfileMenuButton")
        .popover(isPresented: $showMenuPopover, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            CustomProfilePopover(
                showProfile: $showProfile,
                showPlan: $showPlan,

                showPlugins: $showPlugins,

                showDeveloper: $showDeveloper,
                showMenuPopover: $showMenuPopover
            )
            .environment(authService)
            .environment(store)
            .environment(router)
            .environmentObject(themeManager)
            .environmentObject(onboardingService)
            .presentationCompactAdaptation(.popover)
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                UserProfileView()
            }
            .environment(authService)
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $showPlan) {
            NavigationStack {
                SubscriptionPlanView()
            }
            .environment(authService)
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $showAbout) { aboutStack.environment(store).environmentObject(themeManager) }

        .sheet(isPresented: $showPlugins) {
            NavigationStack {
                PluginCenterView()
            }
        }

        .sheet(isPresented: $showDeveloper) {
            NavigationStack {
                DeveloperSettingsView()
            }
            .environment(store)
            .environment(store.knowledgeStore)
            .environment(store.settingsStore)
            .environmentObject(onboardingService)
        }
        #endif
    }
    
    private var profileLabel: some View {
        Group {
            if authService.isGuest {
                Image(systemName: DesignSystem.Icons.personCrop)
                    .font(.system(size: DesignSystem.bodyFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            } else {
                Image(systemName: DesignSystem.Icons.personCropFill)
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .foregroundStyle(.appAccent)
        // 1. 限制头像视觉大小为 medium 尺寸
        .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
        // 2. 使用 xlarge 框架扩展其透明外包，使其达到 HIG 推荐的 44x44 物理像素点击热区
        .frame(width: DesignSystem.IconSize.xlarge, height: DesignSystem.IconSize.xlarge)
        // 3. 将点击热区设为完整的正方形矩形，大幅提升边缘点击灵敏度
        .contentShape(Rectangle())
    }
    
    private var aboutStack: some View {
        NavigationStack {
            AboutView()
        }
    }
}
// MARK: - 自定义个人中心悬浮弹窗
struct CustomProfilePopover: View {
    @Environment(AuthService.self) var authService
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    
    private enum Constants {
        static let menuWidth: CGFloat = 260
        static let iconBoxSize: CGFloat = 30
    }
    
    @State private var showSignOutAlert = false

    @Binding var showProfile: Bool
    @Binding var showPlan: Bool

    @Binding var showPlugins: Bool

    @Binding var showDeveloper: Bool
    @Binding var showMenuPopover: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 头部：头像与用户信息
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                showMenuPopover = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showProfile = true }
            }) {
                HStack(spacing: DesignSystem.medium) {
                    if let url = authService.currentUser?.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.appBorder
                        }
                        .frame(width: DesignSystem.IconSize.huge, height: DesignSystem.IconSize.huge)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.appAccent)
                            .frame(width: DesignSystem.IconSize.huge, height: DesignSystem.IconSize.huge)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.name ?? L10n.Auth.profileAndQuota)
                            .font(.headline)
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        if let subText = authService.currentUser?.email {
                            Text(subText)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .padding(DesignSystem.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            AppDivider()

            // 菜单列表
            ScrollView {
                VStack(spacing: DesignSystem.small) {
                    menuRow(icon: "gearshape.fill", color: .blue, title: L10n.Common.settings) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { router.isShowingSettingsSheet = true }
                    }
                    
                    menuRow(icon: "star.fill", color: .yellow, title: L10n.Auth.subscription) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showPlan = true }
                    }
                    
                    menuRow(icon: "puzzlepiece.extension.fill", color: .orange, title: L10n.Plugin.title) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showPlugins = true }
                    }
                    
                    #if DEBUG
                    menuRow(icon: "hammer.fill", color: .gray, title: L10n.Settings.Section.developer) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showDeveloper = true }
                    }
                    #endif
                    
                    Divider()
                        .padding(.vertical, DesignSystem.tiny)
                        .opacity(DesignSystem.Opacity.soft)
                    
                    menuRow(icon: DesignSystem.Icons.logout, color: .red, title: L10n.Common.logout, textColor: .red) {
                        showMenuPopover = false
                        authService.logout()
                    }
                    .accessibilityIdentifier("logoutButton")
                }
                .padding(DesignSystem.small)
            }
        }
        .frame(width: Constants.menuWidth)
        .background(
            themeManager.pageBackground().ignoresSafeArea()
        )
    }
    
    private func menuRow(icon: String, color: Color, title: String, textColor: Color = .appText, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            action()
        }) {
            HStack(spacing: DesignSystem.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(DesignSystem.Opacity.glass))
                        .frame(width: Constants.iconBoxSize, height: Constants.iconBoxSize)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold)) // Dynamic Type
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(textColor)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.small)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
