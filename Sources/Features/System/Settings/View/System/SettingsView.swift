//
//  SettingsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Settings 界面的 UI 视图层组件。
//
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Environment(AppEnvironment.self) var appEnv
    @Environment(\.dismiss) var dismiss
    @Environment(SettingsStore.self) var settingsStore
    @EnvironmentObject var onboardingService: OnboardingService
    @ObservedObject var themeManager: ThemeManager = ThemeManager.shared
    
    /// 设置分类枚举，表示各个设置大类
    private enum SettingsSection: String, CaseIterable, Identifiable {
        case appearance      // 界面外观
        case ai              // AI设置
        case security        // 安全隐私
        case data            // 数据与日志
        case plugins         // 插件与扩展
        case feedback        // 反馈改进
        case about           // 关于软件

        static var allCases: [SettingsSection] {
            return [.appearance, .ai, .security, .data, .plugins, .feedback, .about]
        }

        var id: String { rawValue }

        /// 各分类的本地化展示名称
        var displayName: String {
            switch self {
            case .appearance:
                return L10n.Settings.Section.appearance
            case .ai:
                return L10n.Settings.Section.ai
            case .security:
                return L10n.Settings.Section.security
            case .data:
                return L10n.Settings.Section.data
            case .plugins:
                return L10n.Settings.Section.plugins
            case .feedback:
                return L10n.Settings.Feedback.title
            case .about:
                return L10n.Settings.Section.about
            }
        }

        /// 各分类对应的系统 SF Symbol 图标名称
        var iconName: String {
            switch self {
            case .appearance:
                return DesignSystem.Icons.settingsAppearance
            case .ai:
                return DesignSystem.Icons.settingsAI
            case .security:
                return DesignSystem.Icons.settingsSecurity
            case .data:
                return DesignSystem.Icons.settingsData
            case .plugins:
                return DesignSystem.Icons.settingsPlugins
            case .feedback:
                return "bubble.left.and.bubble.right.fill"
            case .about:
                return DesignSystem.Icons.settingsAbout
            }
        }
    }
    
    @State private var selectedLanguage: LanguageMode = Localized.languageMode
    @State private var languageChanged = false
    @State private var showInjectConfirmation = false
    @State private var isInjecting = false
    /// Lite 用户尝试开启安全功能时弹出升级提示
    @State private var showUpgradeSheet = false
    /// 当前大屏布局下选中的设置分类，默认选中“外观”
    @State private var selectedSection: SettingsSection? = .appearance
    
    var body: some View {
        @Bindable var router = router
        
        Group {
            #if targetEnvironment(macCatalyst)
            // macOS Catalyst 下采用自定义的左右固定分栏 (HStack) 布局，符合 Mac 平台多窗口及大屏偏好设置的操作习惯
            HStack(spacing: 0) {
                sidebarColumn
                    .frame(width: DesignSystem.Metrics.settingsSidebarWidth)
                
                Divider()
                    .background(Color.appBorder.opacity(DesignSystem.Opacity.shadow))
                
                ZStack {
                    themeManager.pageBackground()
                        .ignoresSafeArea()
                    
                    NavigationStack {
                        detailColumn(for: selectedSection, router: router)
                    }
                                    }
                .frame(maxWidth: .infinity)
            }
            #else
            // iOS、iPadOS 端一律采用平铺的单列表结构。在 iPad 居中 Sheet 弹窗（600x550 物理像素）中能够独享完整宽度，
            // 规避分栏拥挤，且常用设置项一键直达，免除“左选分类、右改配置”的二级菜单操作，极大简化交互复杂度
            NavigationStack {
                ZStack {
                    themeManager.pageBackground()
                        .ignoresSafeArea()

                    compactList
                }
                                .navigationTitle(L10n.Settings.title)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        doneButton(router: router)
                    }
                }
            }
            #endif
        }
        .environment(\.locale, router.currentLocale)
        .appToast()
        .alert(L10n.Settings.injectConfirm.title, isPresented: $showInjectConfirmation) {
            Button(L10n.Common.confirm) {
                Task {
                    isInjecting = true
                    let result = await store.generateInitialNotebooks()
                    isInjecting = false

                    try? await Task.sleep(nanoseconds: 300_000_000)

                    HapticFeedback.shared.trigger(result.total > 0 ? .success : .error)
                    let total = result.total
                    let details = result.details
                    if total > 0 {
                        let prefix = String(format: L10n.Settings.InjectDemo.injectedNotebooks, details.count)
                        let suffix = L10n.Settings.InjectDemo.pageUnit
                        let sep = L10n.Settings.InjectDemo.itemsSeparator
                        var vaultsDesc = ""
                        for (i, detail) in details.enumerated() {
                            if i > 0 { vaultsDesc += sep }
                            vaultsDesc += detail.name + String(detail.count) + suffix
                        }
                        let msg = prefix + vaultsDesc
                        ToastManager.shared.show(type: .success, message: msg)
                    } else {
                        ToastManager.shared.show(type: .error, message: L10n.Settings.InjectDemo.errorMessage)
                    }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Settings.injectConfirm.message)
        }
    }
    
    /// 构建小屏下的紧凑设置列表
    private var compactList: some View {
        List {
            appearanceSection
                .appListRowBackground()
            
            aiSection
                .appListRowBackground()
            
            dataManagementSection
                .appListRowBackground()

            PluginExtensionsSection()
                .appListRowBackground()

            securitySection(store: store)
                .appListRowBackground()

            feedbackSection
                .appListRowBackground()

            aboutSection
                .appListRowBackground()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    /// 构建大屏左侧分类侧边栏（气泡圆角卡片样式，具备呼吸感与选中高亮）
    private var sidebarColumn: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(SettingsSection.allCases) { section in
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        selectedSection = section
                    }) {
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: section.iconName)
                                .font(.subheadline)
                                .foregroundStyle(selectedSection == section ? .white : .appAccent)
                                .frame(width: DesignSystem.IconSize.standard, alignment: .center)
                            Text(section.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(selectedSection == section ? .white : .appText)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius, style: .continuous)
                                .fill(selectedSection == section ? Color.appAccent : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .background(Color.appCard.opacity(DesignSystem.Opacity.disabled)) // 侧边栏微暗色半透明质感
    }
    
    /// 根据当前选中的分类，渲染右侧具体详情面板
    /// - Parameters:
    ///   - section: 当前选中的设置大类
    ///   - router: 路由实例，用于触发全局事件
    @ViewBuilder
    private func detailColumn(for section: SettingsSection?, router: Router) -> some View {
        if let section = section {
            Group {
                switch section {
                case .about:
                    // 直接渲染 AboutView，消除冗余的中间列表层
                    AboutView()
                case .feedback:
                    // 直接渲染 FeedbackView，消除”点击反馈 -> 出现列表项 -> 再点击”的冗余交互
                    FeedbackView()
                        .environmentObject(themeManager)
                case .plugins:
                    // 插件页：有已安装插件时展示列表，无插件时展示空状态引导
                    PluginExtensionsDetailView()
                default:
                    List {
                        switch section {
                        case .appearance:
                            appearanceSection
                                .appListRowBackground()
                        case .ai:
                            aiSection
                                .appListRowBackground()
                        case .security:
                            securitySection(store: store)
                                .appListRowBackground()
                        case .data:
                            dataManagementSection
                                .appListRowBackground()
                        case .plugins, .feedback, .about:
                            EmptyView()
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(section.displayName)
            // macOS 偏好设置采用小字居中 (inline) 标题样式，完美契合 macOS 视觉规范
            // 同时彻底解决由于 NavigationStack 宽度被约束而导致的 Large Title 偏左贴近侧边栏分割线的排版缺陷
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    doneButton(router: router)
                }
            }
        } else {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 48)) // Dynamic Type
                    .foregroundStyle(.appAccent)
                Text(L10n.Settings.selectCategoryTip)
                    .font(.headline)
                    .foregroundStyle(.appText)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    doneButton(router: router)
                }
            }
        }
    }
    
    /// 统一的设置页完成保存按钮组件
    /// - Parameter router: 路由实例
    @ViewBuilder
    private func doneButton(router: Router) -> some View {
        Button(L10n.Common.done) {
            router.isShowingSettingsSheet = false
            dismiss()
        }
        .bold()
    }
    
    private var appearanceSection: some View {
        Section {
            Picker(selection: $themeManager.colorSchemeMode) {
                ForEach(ColorSchemeMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label(L10n.Settings.systemTheme, systemImage: "paintbrush.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .indigo))
            }

            Picker(selection: $selectedLanguage) {
                ForEach(LanguageMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label(L10n.Settings.systemLanguage, systemImage: "globe")
                    .labelStyle(ColorfulIconLabelStyle(color: .blue))
            }
            .onChange(of: selectedLanguage) { _, newValue in
                Localized.languageMode = newValue
                languageChanged = true
                router.triggerLanguageRefresh()
            }
        } header: {
            Text(L10n.Settings.Section.appearance)
        }
        .id(router.currentLocale)
    }
    
    private var aiSection: some View {
        Section {
            NavigationLink {
                SmartRoutingView()
            } label: {
                Label(L10n.Settings.smartRouting, systemImage: "arrow.triangle.branch")
                    .labelStyle(ColorfulIconLabelStyle(color: .purple))
            }

            NavigationLink {
                LLMSettingsView()
            } label: {
                Label(L10n.Settings.llmSettings, systemImage: "network")
                    .labelStyle(ColorfulIconLabelStyle(color: .cyan))
            }

            NavigationLink {
                LocalModelManagerView()
            } label: {
                Label(L10n.Settings.localModelManager, systemImage: "cpu")
                    .labelStyle(ColorfulIconLabelStyle(color: .orange))
            }

            NavigationLink {
                PromptWorkshopView()
            } label: {
                Label(L10n.Settings.promptSettings, systemImage: "terminal.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .gray))
            }
        } header: {
            Text(L10n.Settings.Section.ai)
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            #if ICLOUD_ENABLED
            NavigationLink {
                iCloudSyncView()
            } label: {
                Label(L10n.Settings.iCloudSync, systemImage: "icloud.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .blue))
            }
            #endif
            
            NavigationLink {
                BackupView()
            } label: {
                Label(L10n.Settings.backupRestore, systemImage: "archivebox.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .brown))
            }
            
            NavigationLink {
                LogView()
            } label: {
                Label(L10n.Settings.operationLog, systemImage: "list.bullet.rectangle.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .mint))
            }
            
            NavigationLink {
                SystemStatsView()
            } label: {
                Label(L10n.Common.usage, systemImage: "chart.bar.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .teal))
            }
            
            // 恢复初始数据：生成默认的演示笔记本
            Button(action: { showInjectConfirmation = true }) {
                HStack {
                    Label(L10n.Settings.rebuildInitialNotebooks, systemImage: "arrow.counterclockwise")
                        .labelStyle(ColorfulIconLabelStyle(color: .red))
                    Spacer()
                    if isInjecting {
                        ProgressView()
                    }
                }
            }
            .disabled(isInjecting)
        } header: {
            Text(L10n.Settings.Section.data)
        }
    }
    
    private func securitySection(store: AppStore) -> some View {
        @Bindable var settingsStore = settingsStore
        let hasFeature = AuthSession.shared.currentUser?.hasPrivacySecurity == true
        let showBiometric = appEnv.platformEnv.interactionStyle == .touch
        
        // 自定义 Binding：Lite 用户尝试开启时拦截并弹出升级提示
        let privacyBinding = Binding<Bool>(
            get: { settingsStore.isPrivacyModeEnabled },
            set: { newValue in
                if hasFeature {
                    settingsStore.isPrivacyModeEnabled = newValue
                } else if newValue {
                    // Lite 用户尝试开启 → 弹出升级提示，不修改状态
                    showUpgradeSheet = true
                } else {
                    settingsStore.isPrivacyModeEnabled = newValue
                }
            }
        )
        let biometricBinding = Binding<Bool>(
            get: { settingsStore.isBiometricEnabled },
            set: { newValue in
                if hasFeature {
                    settingsStore.isBiometricEnabled = newValue
                } else if newValue {
                    showUpgradeSheet = true
                } else {
                    settingsStore.isBiometricEnabled = newValue
                }
            }
        )
        
        return Section {
            Toggle(isOn: privacyBinding) {
                Label(L10n.Settings.privacyMode, systemImage: "eye.slash.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .purple))
            }
            
            if showBiometric {
                Toggle(isOn: biometricBinding) {
                    Label(L10n.Settings.biometricProtection, systemImage: "faceid")
                        .labelStyle(ColorfulIconLabelStyle(color: .green))
                }
            }
        } header: {
            Text(L10n.Settings.Section.security)
        } footer: {
            // 帮助文案：说明隐私模式与生物识别的作用。若支持生物识别，则使用合并后的一句话描述，否则使用基础描述。
            if showBiometric {
                Text(L10n.Settings.privacyCombinedDesc)
            } else {
                Text(L10n.Settings.privacyModeDesc)
            }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            SubscriptionPlanView()
        }
    }
    
    private var feedbackSection: some View {
        Section {
            NavigationLink {
                FeedbackView()
                    .environmentObject(themeManager)
            } label: {
                Label(L10n.Settings.Feedback.title, systemImage: "bubble.left.and.bubble.right.fill")
                    .labelStyle(ColorfulIconLabelStyle(color: .blue))
            }
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label(L10n.Settings.Section.about, systemImage: "info.circle")
                    .labelStyle(ColorfulIconLabelStyle(color: .gray))
            }
        }
    }
}

/// A custom label style that adds an iOS-Settings-like colored rounded background to the icon
struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DesignSystem.medium) {
            configuration.icon
                .font(.system(size: 16, weight: .medium)) // Dynamic Type
                .foregroundStyle(.white)
                .frame(width: DesignSystem.Metrics.settingsIconFrameSize, height: DesignSystem.Metrics.settingsIconFrameSize)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius, style: .continuous))
            
            configuration.title
        }
    }
}
