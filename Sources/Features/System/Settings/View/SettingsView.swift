// SettingsView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：应用设置主视图，负责多维度偏好管理。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Environment(AppEnvironment.self) var appEnv
    @Environment(\.dismiss) var dismiss
    @Environment(SettingsStore.self) var settingsStore
    @EnvironmentObject var onboardingService: OnboardingService
    @ObservedObject var themeManager: ThemeManager = ThemeManager.shared
    
    @State private var selectedLanguage: LanguageMode = Localized.languageMode
    @State private var languageChanged = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                List {
                    appearanceSection
                        .appListRowBackground()
                    
                    aiSection
                        .appListRowBackground()
                    
                    dataManagementSection
                        .appListRowBackground()

                    // 插件配置扩展
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
            .navigationTitle(L10n.Settings.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // 完成按钮：保存状态并退出偏好设置页面
                    Button(L10n.Common.done) {
                        if languageChanged {
                            router.triggerLanguageRefresh()
                        }
                        // 双重保险：环境 dismiss + 路由状态同步
                        router.isShowingSettingsSheet = false
                        dismiss()
                    }
                    .bold()
                }
            }
        }
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
