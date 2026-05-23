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
        case developer       // 开发者设置
        case about           // 关于软件

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
            case .developer:
                return L10n.Settings.Section.developer
            case .about:
                return L10n.Settings.Section.about
            }
        }

        /// 各分类对应的系统 SF Symbol 图标名称
        var iconName: String {
            switch self {
            case .appearance:
                return "paintbrush.fill"
            case .ai:
                return "network"
            case .security:
                return "eye.slash.fill"
            case .data:
                return "archivebox.fill"
            case .plugins:
                return "puzzlepiece.fill"
            case .developer:
                return "hammer.fill"
            case .about:
                return "info.circle"
            }
        }
    }
    
    @State private var selectedLanguage: LanguageMode = Localized.languageMode
    @State private var languageChanged = false
    @State private var showResetConfirmation = false
    /// 当前大屏布局下选中的设置分类，默认选中“外观”
    @State private var selectedSection: SettingsSection? = .appearance
    
    var body: some View {
        @Bindable var router = router
        
        Group {
            if appEnv.platformEnv.screenClass == .compact {
                // 紧凑屏下：采用原汁原味的 NavigationStack 包裹纵向单列表形式
                NavigationStack {
                    ZStack {
                        themeManager.pageBackground()
                            .ignoresSafeArea()
                        
                        compactList
                    }
                    .navigationTitle(L10n.Settings.title)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            doneButton(router: router)
                        }
                    }
                }
            } else {
                // 宽屏/大屏下：采用左右分栏 (Master-Detail) 极佳体验布局
                NavigationSplitView {
                    ZStack {
                        themeManager.pageBackground()
                            .ignoresSafeArea()
                        
                        sidebarColumn
                    }
                    .navigationTitle(L10n.Settings.title)
                } detail: {
                    ZStack {
                        themeManager.pageBackground()
                            .ignoresSafeArea()
                        
                        NavigationStack {
                            detailColumn(for: selectedSection, router: router)
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            }
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
            
            developerSection
                .appListRowBackground()
            
            aboutSection
                .appListRowBackground()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    /// 构建大屏左侧分类侧边栏
    private var sidebarColumn: some View {
        List(SettingsSection.allCases, selection: $selectedSection) { section in
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: section.iconName)
                    .font(.subheadline)
                    .foregroundStyle(.appAccent)
                    .frame(width: 24, alignment: .center)
                Text(section.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.appText)
            }
            .tag(section)
            .appListRowBackground()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    /// 根据当前选中的分类，渲染右侧具体详情面板
    /// - Parameters:
    ///   - section: 当前选中的设置大类
    ///   - router: 路由实例，用于触发全局事件
    @ViewBuilder
    private func detailColumn(for section: SettingsSection?, router: Router) -> some View {
        if let section = section {
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
                case .plugins:
                    PluginExtensionsSection()
                        .appListRowBackground()
                case .developer:
                    developerSection
                        .appListRowBackground()
                case .about:
                    aboutSection
                        .appListRowBackground()
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle(section.displayName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton(router: router)
                }
            }
        } else {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.appAccent)
                Text(L10n.Settings.selectCategoryTip)
                    .font(.headline)
                    .foregroundStyle(.appText)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            if languageChanged {
                router.triggerLanguageRefresh()
            }
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
            }
            
            Picker(selection: $selectedLanguage) {
                ForEach(LanguageMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label(L10n.Settings.systemLanguage, systemImage: "globe")
            }
            .onChange(of: selectedLanguage) { _, newValue in
                Localized.languageMode = newValue
                languageChanged = true
            }
        } header: {
            Text(L10n.Settings.Section.appearance)
        }
    }
    
    private var aiSection: some View {
        Section {
            NavigationLink {
                LLMSettingsView()
            } label: {
                Label(L10n.Settings.llmSettings, systemImage: "network")
            }
            
            NavigationLink {
                OnDeviceLLMSettingsView()
            } label: {
                Label(L10n.Settings.onDeviceLLM, systemImage: "cpu")
            }
            
            NavigationLink {
                PromptWorkshopView()
            } label: {
                Label(L10n.Settings.promptLab, systemImage: "terminal.fill")
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
            }
            #endif
            
            NavigationLink {
                BackupView()
            } label: {
                Label(L10n.Settings.backupRestore, systemImage: "archivebox.fill")
            }
            
            NavigationLink {
                LogView()
            } label: {
                Label(L10n.Settings.operationLog, systemImage: "list.bullet.rectangle.fill")
            }
            
            // 数据重置：清理开发数据与沙盒存储
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label(L10n.Settings.resetData, systemImage: "trash.fill")
            }
        } header: {
            Text(L10n.Settings.Section.data)
        }
    }
    
    private func securitySection(store: AppStore) -> some View {
        @Bindable var settingsStore = settingsStore
        return Section {
            Toggle(isOn: $settingsStore.isPrivacyModeEnabled) {
                Label(L10n.Settings.privacyMode, systemImage: "eye.slash.fill")
            }
            
            if appEnv.platformEnv.interactionStyle == .touch { 
                Toggle(isOn: $settingsStore.isBiometricEnabled) {
                    Label(L10n.Settings.biometricProtection, systemImage: "faceid")
                }
            }
        } header: {
            Text(L10n.Settings.Section.security)
        }
    }
    
    /// 开发者独立设置区域，介于系统维护与关于之间
    private var developerSection: some View {
        Section {
            NavigationLink {
                DeveloperSettingsView(onboardingService: onboardingService)
            } label: {
                Label(L10n.Settings.Section.developer, systemImage: "hammer.fill")
            }
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label(L10n.Settings.Section.about, systemImage: "info.circle")
            }
        }
        .confirmationDialog(L10n.Settings.resetOnboarding.title, isPresented: $showResetConfirmation) {
            Button(L10n.Settings.clearAll.action, role: .destructive) {
                store.clearAllDeveloperData()
            }
        } message: {
            Text(L10n.Settings.resetOnboarding.message)
        }
    }
}
