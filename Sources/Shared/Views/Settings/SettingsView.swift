// SettingsView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了“设置”页面，负责管理应用的外观（主题/语言）、AI 配置、数据同步/备份以及安全隐私设置。
// 核心功能点：
// 1. 系统配置：动态切换色彩模式（深色/浅色）与多语言环境。
// 2. AI 实验室：配置远程及本地 LLM 模型，管理提示词合成系统。
// 3. 数据生命周期：处理 iCloud 双向同步、数据库备份导出、以及危险的“重置数据”操作（带确认对话框）。
// 4. 安全中心：控制隐私模式（隐藏敏感内容）与面容 ID/指纹保护，通过 SecurityService 进行硬件鉴权。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 完善中文文档，修复面容ID开关在硬件不可用时未正确置灰的问题
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import UniformTypeIdentifiers

/// 设置页面主视图
/// 负责协调系统偏好、AI 配置、数据同步及安全隐私的交互界面
struct SettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(SettingsStore.self) var settingsStore
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var llmService: LLMService
    @ObservedObject var onboardingService: OnboardingService
    @State private var showResetConfirmation = false
    @State private var isExportingAll = false
    #if ICLOUD_ENABLED
    @State private var coordinator = iCloudSyncCoordinator()
    #endif
    @State private var selectedLanguage: LanguageMode = Localized.languageMode
    @Binding var languageForceUpdate: Bool
    @State private var showFolderImporterForImport = false
    @State private var showClearAllConfirmation = false
    
    /**
     * @description: 触发硬件层面的生物识别认证（FaceID/TouchID）
     * @return {Bool} 认证是否成功
     */
    @MainActor
    private func authenticate() async -> Bool {
        await store.securityService.authenticateWithBiometrics()
    }
    
    var body: some View {
        @Bindable var store = store
        
        let privacyBinding = Binding<Bool>(
            get: { settingsStore.isPrivacyModeEnabled },
            set: { newValue in
                Task {
                    if await authenticate() {
                        settingsStore.isPrivacyModeEnabled = newValue
                        HapticFeedback.shared.trigger(.success)
                    }
                }
            }
        )
        
        let biometricBinding = Binding<Bool>(
            get: { settingsStore.isBiometricEnabled },
            set: { newValue in
                Task {
                    if await authenticate() {
                        settingsStore.isBiometricEnabled = newValue
                        HapticFeedback.shared.trigger(.success)
                    }
                }
            }
        )

        List {
            // ── 外观 ──
            Section {
                Picker(selection: $themeManager.colorSchemeMode) {
                    ForEach(ColorSchemeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                } label: {
                    Label(L10n.Settings.tr("systemTheme"), systemImage: "paintbrush.fill")
                        .foregroundStyle(.appText)
                }
                .tint(.primary)
                .id(languageForceUpdate)
                
                Picker(selection: $selectedLanguage) {
                    ForEach(LanguageMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                } label: {
                    Label(L10n.Settings.tr("systemLanguage"), systemImage: "globe")
                        .foregroundStyle(.appText)
                }
                .tint(.primary)
                .onChange(of: selectedLanguage) { _, newValue in
                    Localized.languageMode = newValue
                    languageForceUpdate.toggle()
                }
            } header: {
                Text(L10n.Settings.Section.appearance)
            }
            .listRowBackground(Color.appCard.opacity(AppUI.secondaryOpacity)) // 0.8

            // ── AI 能力 ──
            Section {
                SettingsNavigationRow(icon: "antenna.radiowaves.left.and.right", title: L10n.Settings.llmSettings, identifier: "settings.llm") {
                    LLMSettingsView()
                }
                
                SettingsNavigationRow(icon: "cpu", title: L10n.Settings.onDeviceLLM, identifier: "settings.ondevice") {
                    OnDeviceLLMSettingsView()
                }
                
                SettingsNavigationRow(icon: "terminal", title: L10n.Settings.promptLab, identifier: "settings.prompts") {
                    PromptWorkshopView()
                }
            } header: {
                Text(L10n.Settings.Section.ai)
            }
            .listRowBackground(Color.appCard.opacity(0.8))

            // ── 数据同步 ──
            Section {
                #if ICLOUD_ENABLED
                SettingsNavigationRow(icon: "icloud.fill", title: L10n.Settings.iCloudSync, identifier: "settings.icloud") {
                    iCloudSyncView(coordinator: coordinator)
                }
                #endif
                
                SettingsNavigationRow(icon: "archivebox.fill", title: L10n.Settings.backupRestore, identifier: "settings.backup") {
                    BackupView()
                }
                
            Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    Label(L10n.Settings.resetData, systemImage: "trash.fill")
                }
                .accessibilityIdentifier("settings.reset")
                .alert(L10n.Settings.resetConfirmationTitle, isPresented: $showResetConfirmation) {
                    Button(L10n.Common.tr("cancel"), role: .cancel) { }
                    Button(L10n.Common.tr("confirmReset"), role: .destructive) {
                        store.resetAllData()
                        HapticFeedback.shared.trigger(.success)
                    }
                } message: {
                    Text(L10n.Settings.resetConfirmationMessage)
                }
            } header: {
                Text(L10n.Settings.Section.data)
            }
            .listRowBackground(Color.appCard.opacity(0.8))

            // ── 安全与隐私 ──
            Section {
                Toggle(isOn: privacyBinding) {
                    Label {
                        VStack(alignment: .leading, spacing: AppUI.atomic) { // 2
                            Text(L10n.Settings.privacyMode)
                            Text(L10n.Settings.privacyModeDesc)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                    } icon: {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(.appAccent)
                    }
                }
                .accessibilityIdentifier("settings.privacy")
                
                Toggle(isOn: biometricBinding) {
                    Label {
                        Text(L10n.Settings.biometricProtection)
                    } icon: {
                        Image(systemName: "faceid")
                            .foregroundStyle(.blue)
                    }
                }
                .disabled(!store.securityService.biometricsAvailable)
                .accessibilityIdentifier("settings.biometric")

                SettingsNavigationRow(icon: "clock.arrow.circlepath", title: L10n.Settings.operationLog, identifier: "settings.log") {
                    LogView()
                }
            }
 header: {
                Text(L10n.Settings.Section.security)
            }
            .listRowBackground(Color.appCard.opacity(0.8))
            
            // ── 开发者选项 ──
            #if DEBUG
            Section {
                SettingsNavigationRow(icon: "hammer.fill", title: L10n.Settings.Section.developer, identifier: "settings.developer") {
                    DeveloperSettingsView(onboardingService: onboardingService)
                }
            }
            .listRowBackground(Color.appCard.opacity(0.8))
            #endif

            Section {
                SettingsNavigationRow(icon: "books.vertical.circle.fill", title: L10n.Settings.about, identifier: "settings.about") {
                    SettingsAboutView()
                }
            }
            .listRowBackground(Color.appCard.opacity(0.8))
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
        .background(AppUI.Background.meshGradient())
        .navigationTitle(L10n.Settings.title)
        // 导入文件夹
        .fileImporter(
            isPresented: $showFolderImporterForImport,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Transfer.Import.externalVault, target: url.lastPathComponent)
                    Task {
                        let _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        await MainActor.run {
                            Task {
                                await store.ingestFolder(at: url)
                            }
                            TaskCenter.shared.updateTask(taskID, status: .completed)
                            HapticFeedback.shared.trigger(.success)
                        }
                    }
                }
            case .failure(let error):
                HapticFeedback.shared.trigger(.error)
                ToastManager.shared.show(type: .error, message: error.localizedDescription)
            }
        }
    }
    
    private func exportAllAsMarkdown() -> String {
        var output = "# \(L10n.Transfer.tr("export.header"))\n\n"
        output += "\(L10n.Transfer.tr("export.exportTime")): \(Date().formatted())\n"
        output += "\(L10n.Transfer.tr("export.totalPages")): \(store.totalPages)\n\n---\n\n"
        
        for type in PageType.allCases {
            let typePages = store.pages.filter { $0.type == type }
            if typePages.isEmpty { continue }
            
            output += "## \(type.displayName) (\(typePages.count))\n\n"
            
            for page in typePages.sorted(by: { $0.title < $1.title }) {
                output += "---\n\n"
                output += "### \(page.title)\n\n"
                output += "- \(L10n.Transfer.tr("export.type")): \(page.type.displayName)\n"
                output += "- \(L10n.Transfer.tr("export.status")): \(page.status.displayName)\n"
                output += "- \(L10n.Transfer.tr("export.confidence")): \(page.confidence.displayName)\n"
                if !page.tags.isEmpty {
                    output += "- \(L10n.Transfer.tr("export.tags")): \(page.tags.joined(separator: ", "))\n"
                }
                if !page.aliases.isEmpty {
                    output += "- \(L10n.Transfer.tr("export.aliases")): \(page.aliases.joined(separator: ", "))\n"
                }
                output += "- \(L10n.Transfer.tr("export.created")): \(page.created.formatted())\n"
                output += "- \(L10n.Transfer.tr("export.updated")): \(page.updated.formatted())\n\n"
                output += page.content
                output += "\n\n"
            }
        }
        
        return output
    }
}
