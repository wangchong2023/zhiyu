// LLMSettingsView.swift
//
// 作者: Wang Chong
// 功能说明: struct LLMSettingsView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI

// MARK: - LLM Settings View
@MainActor
struct LLMSettingsView: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(AppRouter.self) var router
    @EnvironmentObject var llmService: LLMService
    @State private var testing = false
    @State private var testResult: TestResult?
    @State private var showAPIKey = false
    @State private var isConfigExpanded = true // 默认展开，方便用户发现
    
    enum TestResult {
        case success(latency: Int)
        case failure(code: String, message: String, latency: Int?)
    }
    
    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            Form {
                // Enable/Disable
                Section {
                    Toggle(isOn: $llmService.isEnabled) {
                        Label(Localized.tr("llm.enableAssistant"), systemImage: "sparkles")
                            .foregroundStyle(.appText)
                    }
                    .tint(.appAccent)
                } header: {
                    Text(Localized.tr("llm.status"))
                }
                
                // Karpathy Mode
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Localized.tr("ondevice.assistMode"))
                            .font(.headline)
                            .foregroundStyle(.appText)
                        Text(Localized.tr("ondevice.assistDesc"))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    .padding(.vertical, DesignSystem.tiny)
                    
                    Toggle(Localized.tr("ondevice.enableAutoScan"), isOn: $llmService.autoScan)
                        .tint(.appAccent)
                    
                    Toggle(Localized.tr("ondevice.autoRefactor"), isOn: $llmService.autoRefactor)
                        .tint(.appAccent)
                } header: {
                    Text(L10n.Settings.tr("advancedMaintenance"))
                }
                
                // Provider
                Section {
                    ForEach(LLMProvider.allCases) { provider in
                        Button(action: {
                            let selectedProvider = provider
                            testResult = nil
                            llmService.provider = selectedProvider
                            if !selectedProvider.defaultBaseURL.isEmpty {
                                llmService.baseURL = selectedProvider.defaultBaseURL
                            }
                            if !selectedProvider.defaultModel.isEmpty {
                                llmService.model = selectedProvider.defaultModel
                            }
                            withAnimation {
                                isConfigExpanded = true
                            }
                        }) {
                            HStack {
                                Image(systemName: provider.icon)
                                    .foregroundStyle(.appAccent)
                                Text(provider.displayName)
                                    .foregroundStyle(.appText)
                                Spacer()
                                if llmService.provider == provider {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.appAccent)
                                }
                            }
                        }
                    }
                } header: {
                    Text(Localized.tr("llm.provider"))
                }
                
                // Configuration
                Section {
                    #if !os(watchOS)
                    DisclosureGroup(isExpanded: $isConfigExpanded) {
                        configurationContent
                    } label: {
                        Label(Localized.tr("llm.configuration"), systemImage: "slider.horizontal.3")
                            .foregroundStyle(.appText)
                    }
                    #else
                    configurationContent
                    #endif
                }
                
                // Test Connection
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if testing {
                                ProgressView()
                                    .tint(.appAccent)
                            } else {
                                Image(systemName: "bolt.horizontal.fill")
                                    .foregroundStyle(.appAccent)
                            }
                            Text(testing ? Localized.tr("llm.testing") : Localized.tr("llm.testConnection"))
                                .foregroundStyle(.appText)
                        }
                    }
                    .disabled(testing || llmService.apiKey.isEmpty || llmService.baseURL.isEmpty)
                    .opacity(llmService.apiKey.isEmpty || llmService.baseURL.isEmpty ? 0.6 : 1.0)
                    
                    if let result = testResult {
                        VStack(alignment: .leading, spacing: 8) {
                            switch result {
                            case .success(let latency):
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(Localized.tr("ondevice.connected"))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Text("\(latency) \(L10n.Dashboard.unitMs)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.appSecondary)
                                }
                            case .failure(let code, let message, let latency):
                                HStack(alignment: .top) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(Localized.trf("ondevice.errorFormat", "\(code)"))
                                            .font(.subheadline.bold())
                                        Text(message)
                                            .font(.caption)
                                            .foregroundStyle(.appSecondary)
                                    }
                                    Spacer()
                                    if let l = latency {
                                        Text("\(l) \(L10n.Dashboard.unitMs)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.appSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, DesignSystem.tiny)
                    }
                } header: {
                    Text(Localized.tr("llm.validation"))
                }
                
                // Info
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "lock.shield", text: Localized.tr("llm.info.localKey"))
                        InfoRow(icon: "doc.text", text: Localized.tr("llm.info.contextSent"))
                        InfoRow(icon: "network", text: Localized.tr("llm.info.openAICompatible"))
                        InfoRow(icon: "arrow.down.doc", text: Localized.tr("llm.info.smartIngest"))
                    }
                } header: {
                    Text(Localized.tr("llm.info"))
                }
            }
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .listRowBackground(Color.appCard.opacity(0.8))
            .scrollContentBackground(.hidden)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(Localized.tr("llm.title"))
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    /// 配置内容视图（API Key / Base URL / Model 输入）
    private var configurationContent: some View {
        VStack(spacing: 20) {
            // API Key
            VStack(alignment: .leading, spacing: 6) {
                Text(Localized.tr("llm.apiKey"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                HStack {
                    if showAPIKey {
                        TextField("sk-...", text: $llmService.apiKey)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.appText)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-...", text: $llmService.apiKey)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.appText)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.appSecondary)
                    }
                }
                .padding()
                .background(Color.appCard.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.appBorder.opacity(0.8), lineWidth: 1)
                )
            }
            // Base URL
            VStack(alignment: .leading, spacing: 6) {
                Text(Localized.tr("llm.apiAddress"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                TextField("https://api.example.com/v1", text: $llmService.baseURL)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.appText)
                    .padding()
                    .background(Color.appCard.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                            .stroke(Color.appBorder.opacity(0.8), lineWidth: 1)
                    )
                    #if !os(watchOS)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    #endif
            }
            // Model
            VStack(alignment: .leading, spacing: 6) {
                Text(Localized.tr("llm.model"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                TextField("model-name", text: $llmService.model)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.appText)
                    .padding()
                    .background(Color.appCard.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                            .stroke(Color.appBorder.opacity(0.8), lineWidth: 1)
                    )
                    #if !os(watchOS)
                    .autocapitalization(.none)
                    #endif
            }
            // Model suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedModels, id: \.self) { model in
                        Button(action: { llmService.model = model }) {
                            Text(model)
                                .font(.caption)
                                .padding(.horizontal, DesignSystem.medium - 2)
                                .padding(.vertical, DesignSystem.small - 2)
                                .background(llmService.model == model ? Color.appAccent.opacity(0.2) : Color.appCard.opacity(0.8))
                                .clipShape(Capsule())
                                .foregroundStyle(llmService.model == model ? .appAccent : .appSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.small)
    }
    
    private var suggestedModels: [String] {
        llmService.provider.suggestedModels
    }
    
    private func testConnection() {
        testing = true
        testResult = nil
        
        Task {
            do {
                let res = try await llmService.validateAPIKey()
                await MainActor.run {
                    testing = false
                    if res.isSuccess {
                        testResult = .success(latency: res.latencyMS)
                    } else {
                        testResult = .failure(code: res.errorCode ?? "ERR", message: res.errorMessage ?? "Unknown Error", latency: res.latencyMS)
                    }
                }
            } catch {
                await MainActor.run {
                    testing = false
                    testResult = .failure(code: "CATCH", message: error.localizedDescription, latency: nil)
                }
            }
        }
    }
}
