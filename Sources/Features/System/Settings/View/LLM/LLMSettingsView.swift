//
//  LLMSettingsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：构建 LLMSettings 界面的 UI 视图层组件。
//
import SwiftUI

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
    @State private var isProvidersExpanded = false // 默认折叠，减少首屏空间占用
    
    enum TestResult {
        case success(latency: Int, streamOK: Bool, streamTested: Bool)
        case failure(code: String, message: String, latency: Int?, streamTested: Bool)
    }
    
    var body: some View {
        @Bindable var config = config
        // 直接返回 Form，利用父视图统一的渐变背景，解决多层 ignoresSafeArea 导致的点击命中测试拦截问题
        Form {
            // Enable/Disable & Background options combined in 1 Section
            Section {
                Toggle(isOn: $config.isEnabled) {
                    Label(L10n.AI.LLM.enableAssistant, systemImage: DesignSystem.Icons.sparkles)
                        .foregroundStyle(.appText)
                }
                .tint(.appAccent)
                
                Toggle(isOn: Binding(
                    get: { config.autoScan && config.autoRefactor },
                    set: { newValue in
                        config.autoScan = newValue
                        config.autoRefactor = newValue
                    }
                )) {
                    VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                        Text(L10n.AI.OnDevice.assistMode)
                            .font(.body.bold())
                            .foregroundStyle(.appText)
                        Text(L10n.AI.OnDevice.assistDesc)
                            .font(.caption)
                            .foregroundStyle(.appText.opacity(DesignSystem.subtleOpacity))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, DesignSystem.tiny)
                }
                .tint(.appAccent)
            } header: {
                Text(L10n.AI.LLM.serviceStatus)
            }
            .appListRowBackground()
            
            // Provider & Config combined to form a single continuous block, default collapsed
            Section {
                // 1. 模型提供商默认折叠
                DisclosureGroup(isExpanded: $isProvidersExpanded) {
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
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
                        
                        Divider()
                            .padding(.vertical, DesignSystem.small)
                        
                        // 2. 模型配置
                        configurationContent
                    }
                    .padding(.top, DesignSystem.small)
                } label: {
                    Label(L10n.AI.LLM.Provider.title, systemImage: "cpu")
                        .foregroundStyle(.appText)
                }
            } header: {
                Text(L10n.AI.LLM.providerConfig)
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
            }
            .appListRowBackground()
        }
        #if !os(watchOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
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
