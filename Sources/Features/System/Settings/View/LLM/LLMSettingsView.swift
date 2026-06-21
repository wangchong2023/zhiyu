//
//  LLMSettingsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 LLMSettings 界面的 UI 视图层组件。
//
@preconcurrency import SwiftUI

// MARK: - LLM Settings View
@MainActor
struct LLMSettingsView: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(Router.self) var router
    @EnvironmentObject var llmService: LLMService
    @Environment(LLMConfigManager.self) var config
    @State private var testing = false
    @State private var testResult: TestResult?
    @State private var showAPIKey = false
    @State private var isConfigExpanded = true // 默认展开，方便用户发现
    
    enum TestResult {
        case success(latency: Int, streamOK: Bool, streamTested: Bool)
        case failure(code: String, message: String, latency: Int?, streamTested: Bool)
    }
    
    var body: some View {
        @Bindable var config = config
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            Form {
                // Enable/Disable
                Section {
                    Toggle(isOn: $config.isEnabled) {
                        Label(L10n.AI.LLM.enableAssistant, systemImage: DesignSystem.Icons.sparkles)
                            .foregroundStyle(.appText)
                    }
                    .tint(.appAccent)
                } header: {
                    Text(L10n.AI.LLM.status)
                }
                .appListRowBackground()
                
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        Text(L10n.AI.OnDevice.assistMode)
                            .font(.headline)
                            .foregroundStyle(.appText)
                        Text(L10n.AI.OnDevice.assistDesc)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    .padding(.vertical, DesignSystem.tiny)
                    
                    Toggle(L10n.AI.OnDevice.enableAutoScan, isOn: $config.autoScan)
                        .tint(.appAccent)
                    
                    Toggle(L10n.AI.OnDevice.autoRefactor, isOn: $config.autoRefactor)
                        .tint(.appAccent)
                } header: {
                    Text(L10n.Settings.advancedMaintenance)
                }
                .appListRowBackground()
                
                Section {
                    ForEach(LLMProvider.allCases) { provider in
                        Button(action: {
                            let selectedProvider = provider
                            testResult = nil
                            config.provider = selectedProvider
                            if !selectedProvider.defaultBaseURL.isEmpty {
                                config.baseURL = selectedProvider.defaultBaseURL
                            }
                            if !selectedProvider.defaultModel.isEmpty {
                                config.model = selectedProvider.defaultModel
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
                                if config.provider == provider {
                                    Image(systemName: DesignSystem.Icons.check)
                                        .foregroundStyle(.appAccent)
                                }
                            }
                        }
                    }
                } header: {
                    Text(L10n.AI.LLM.Provider.title)
                }
                .appListRowBackground()
                
                Section {
                    #if !os(watchOS)
                    DisclosureGroup(isExpanded: $isConfigExpanded) {
                        configurationContent
                    } label: {
                        Label(L10n.AI.LLM.configuration, systemImage: "slider.horizontal.3")
                            .foregroundStyle(.appText)
                    }
                    #else
                    configurationContent
                    #endif
                }
                .appListRowBackground()
                
                // Test Connection
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if testing {
                                ProgressView()
                                    .tint(.appAccent)
                            } else {
                                Image(systemName: DesignSystem.Icons.bolt)
                                    .foregroundStyle(.appAccent)
                            }
                            Text(testing ? L10n.AI.LLM.testing : L10n.AI.LLM.testConnection)
                                .foregroundStyle(.appText)
                        }
                    }
                    .disabled(testing || config.apiKey.isEmpty || config.baseURL.isEmpty)
                    .opacity(config.apiKey.isEmpty || config.baseURL.isEmpty ? 0.6 : 1.0)
                    
                    if let result = testResult {
                        VStack(alignment: .leading, spacing: DesignSystem.small) {
                            switch result {
                            case .success(let latency, _, _):
                                HStack {
                                    Image(systemName: DesignSystem.Icons.checkCircle)
                                        .foregroundStyle(.green)
                                    Text(L10n.AI.OnDevice.connected)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Text(L10n.AI.LLM.latency("\(latency) \(L10n.Dashboard.unitMs)"))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.appSecondary)
                                }
                            case .failure(let code, let message, let latency, _):
                                HStack(alignment: .top) {
                                    Image(systemName: DesignSystem.Icons.errorCircle)
                                        .foregroundStyle(.red)
                                    VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                                        Text(L10n.AI.OnDevice.errorFormat("\(code)"))
                                            .font(.subheadline.bold())
                                        Text(message)
                                            .font(.caption)
                                            .foregroundStyle(.appSecondary)
                                    }
                                    Spacer()
                                    if let latency = latency {
                                        Text(L10n.AI.LLM.latency("\(latency) \(L10n.Dashboard.unitMs)"))
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.appSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, DesignSystem.tiny)
                    }
                } header: {
                    Text(L10n.AI.LLM.validation)
                } footer: {
                    VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                        InfoRow(icon: "lock.shield", text: L10n.AI.LLM.info.localKey)
                        InfoRow(icon: "doc.text", text: L10n.AI.LLM.info.contextSent)
                        InfoRow(icon: "network", text: L10n.AI.LLM.info.openAICompatible)
                        InfoRow(icon: "arrow.down.doc", text: L10n.AI.LLM.info.smartIngest)
                    }
                    .padding(.top, DesignSystem.small)
                    Text(L10n.AI.LLM.infoString)
                        .padding(.top, DesignSystem.small)
                }
                .appListRowBackground()
            }
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden)
        }
    }
    
    /// 配置内容视图（API Key / Base URL / Model 输入）
    private var configurationContent: some View {
        @Bindable var config = config
        return VStack(spacing: DesignSystem.wide) {
            // API Key
            VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                Text(L10n.AI.LLM.apiKey)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                HStack {
                    if showAPIKey {
                        TextField("sk-...", text: $config.apiKey)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.appText)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-...", text: $config.apiKey)
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
                .background(Color.appCard.opacity(DesignSystem.Opacity.prominent))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.appBorder.opacity(DesignSystem.Opacity.prominent), lineWidth: 1)
                )
            }
            // Base URL
            VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                Text(L10n.AI.LLM.apiAddress)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                TextField("https://api.example.com/v1", text: $config.baseURL)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.appText)
                    .padding()
                    .background(Color.appCard.opacity(DesignSystem.Opacity.prominent))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                            .stroke(Color.appBorder.opacity(DesignSystem.Opacity.prominent), lineWidth: 1)
                    )
                    #if !os(watchOS)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    #endif
            }
            // Model
            VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                Text(L10n.AI.LLM.model)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
                TextField("model-name", text: $config.model)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.appText)
                    .padding()
                    .background(Color.appCard.opacity(DesignSystem.Opacity.prominent))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                            .stroke(Color.appBorder.opacity(DesignSystem.Opacity.prominent), lineWidth: 1)
                    )
                    #if !os(watchOS)
                    .autocapitalization(.none)
                    #endif
            }
            // Model suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.small) {
                    ForEach(suggestedModels, id: \.self) { model in
                        Button(action: { config.model = model }) {
                            Text(model)
                                .font(.caption)
                                .padding(.horizontal, DesignSystem.medium - 2)
                                .padding(.vertical, DesignSystem.small - 2)
                                .background(config.model == model ? Color.appAccent.opacity(DesignSystem.Opacity.medium) : Color.appCard.opacity(DesignSystem.Opacity.prominent))
                                .clipShape(Capsule())
                                .foregroundStyle(config.model == model ? .appAccent : .appSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.small)
    }
    
    private var suggestedModels: [String] {
        config.provider.suggestedModels
    }
    
    func testConnection() {
        testing = true
        testResult = nil
        
        Task {
            do {
                let res = try await llmService.validateAPIKey()
                await MainActor.run {
                    testing = false
                    if res.isSuccess {
                        testResult = .success(latency: res.latencyMS, streamOK: res.streamOK, streamTested: res.streamTested)
                    } else {
                        testResult = .failure(code: res.errorCode ?? "ERR", message: res.errorMessage ?? "Unknown_Error", latency: res.latencyMS, streamTested: res.streamTested)
                    }
                }
            } catch {
                await MainActor.run {
                    testing = false
                    testResult = .failure(code: "CATCH", message: error.localizedDescription, latency: nil, streamTested: false)
                }
            }
        }
    }
}
