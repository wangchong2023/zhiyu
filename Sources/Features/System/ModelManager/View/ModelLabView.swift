//
//  ModelLabView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：构建大模型多用例测试实验室 (AI Model Lab) UI。
//  支持 7 大用例的场景化切换、暗黑霓虹毛玻璃卡片格栅、动态能力检测拦截、参数微调交互、以及流式性能监控指标的可视化渲染。
//

import SwiftUI

/// 大模型测试实验室主视图
@MainActor
public struct ModelLabView: View {
    
    // MARK: - 环境与外部依赖
    
    private enum Constants {
        static let chatScrollHeight: CGFloat = 280
        static let stopIconSize: CGFloat = 20
        static let stopPadding: CGFloat = 10
        static let chatBubblePadding: CGFloat = 14
    }
    
    @State private var modelManager = GlobalModelManager()
    @State private var labManager = ModelLabManager()
    @StateObject private var themeManager = ThemeManager.shared
    
    /// 当需要跳回商店时的外部闭包回调
    public var onGoToStore: () -> Void
    
    // MARK: - 局部交互状态
    
    @State private var testPrompt: String = ""
    @State private var tempTemperature: Double = 0.7
    @State private var tempTopP: Double = 0.9
    @State private var tempTopK: Int = 40
    @State private var tempMaxTokens: Int = 2048
    
    // 参数配置面板
    @State private var showConfigSheet: Bool = false
    @State private var useGPU: Bool = false
    @State private var enableThinking: Bool = false
    @State private var enableSpeculativeDecoding: Bool = false
    
    // 多模态/视觉特定状态
    @State private var isImageSelected: Bool = false
    
    // 语音速记特定状态
    @State private var isAudioRecording: Bool = false
    @State private var isAudioCompleted: Bool = false
    
    // 多轮对话特定状态
    @State private var chatHistory: [LabChatMessage] = []
    @State private var chatInputText: String = ""
    
    // MARK: - 布局网格
    
    private let columns = [
        GridItem(.adaptive(minimum: DesignSystem.Vault.gridCardMin, maximum: DesignSystem.Vault.gridCardMax), spacing: DesignSystem.medium)
    ]
    
    public init(onGoToStore: @escaping () -> Void) {
        self.onGoToStore = onGoToStore
    }
    
    public var body: some View {
        ZStack {
            // 暗黑星空渐变背景以彰显 Wow Factor
            LinearGradient(
                colors: [Color.theme.black, Color(red: DesignSystem.Opacity.ghost, green: DesignSystem.Opacity.ghost, blue: DesignSystem.Opacity.glass)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.large) {
                    if let selectedUseCase = labManager.selectedUseCase {
                        // 进入单独用例的沙盒测试面板
                        useCaseDetailPanel(for: selectedUseCase)
                    } else {
                        // 展示格栅主页
                        labHeaderView
                        useCaseGridView
                    }
                }
                .padding(DesignSystem.medium)
            }
            
            // 无可用本地模型时的毛玻璃引导遮罩拦截
            if !hasActiveLocalModel() {
                noModelMaskView
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: labManager.selectedUseCase)
        .sheet(isPresented: $showConfigSheet) {
            configurationSheet
        }
    }
    
    // MARK: - 子视图组件
    
    /// 实验室头部导语区
    private var labHeaderView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack {
                Text(L10n.ModelManager.laboratoryTitle)
                    .font(.system(size: DesignSystem.iconHuge - DesignSystem.tiny, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                // 活跃模型指示器
                if let activeModel = getActiveModel() {
                    HStack(spacing: DesignSystem.standardPadding) {
                        Circle()
                            .fill(Color.theme.green)
                            .frame(width: DesignSystem.small, height: DesignSystem.small)
                        
                        Text(activeModel.displayName)
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .foregroundStyle(.white.opacity(DesignSystem.Opacity.prominent))
                    }
                    .padding(.horizontal, DesignSystem.standardPadding + 2)
                    .padding(.vertical, DesignSystem.standardPadding / 2)
                    .background(Color.theme.white.opacity(DesignSystem.Opacity.subtle))
                    .clipShape(Capsule())
                }
            }
            
            Text(L10n.ModelManager.Lab.exploreOther)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignSystem.small)
    }
    
    /// 用例卡片列表
    private var useCaseGridView: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.medium) {
            ForEach(UseCaseType.allCases) { useCase in
                useCaseCard(for: useCase)
            }
        }
    }
    
    /// 用例格栅单卡
    private func useCaseCard(for useCase: UseCaseType) -> some View {
        let activeModel = getActiveModel()
        let isCompatible = activeModel.map { labManager.isModelCompatible($0, for: useCase) } ?? false
        
        return Button {
            if isCompatible {
                HapticFeedback.shared.trigger(.selection)
                labManager.selectedUseCase = useCase
                // 同步初始化默认超参
                if let model = activeModel {
                    tempTemperature = model.defaultParameters.temperature
                    tempTopP = model.defaultParameters.topP
                    tempTopK = model.defaultParameters.topK
                    tempMaxTokens = model.defaultParameters.maxTokens
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.small) {
                // 用例图标与兼容状态
                HStack {
                    Image(systemName: useCase.icon)
                        .font(.title2)
                        .foregroundStyle(isCompatible ? .cyan : .secondary)
                    
                    Spacer()
                    
                    if !isCompatible {
                        Text(L10n.ModelManager.Lab.unsupported)
                            .font(.system(size: DesignSystem.iconTiny - 2))
                            .padding(.horizontal, DesignSystem.standardPadding)
                            .padding(.vertical, DesignSystem.standardPadding / 3)
                            .background(Color.theme.red.opacity(DesignSystem.Opacity.medium))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, DesignSystem.standardPadding)
                
                Text(useCase.title)
                    .font(.headline)
                    .foregroundStyle(isCompatible ? .white : .secondary)
                
                Text(useCase.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignSystem.medium)
            .frame(height: DesignSystem.Metrics.sourceCardHeight + DesignSystem.large, alignment: .topLeading)
            // 暗黑毛玻璃态 (Glassmorphism)
            .background(.ultraThinMaterial.opacity(isCompatible ? DesignSystem.Opacity.shadow : DesignSystem.Opacity.glass))
            .cornerRadius(DesignSystem.mediumRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                    .stroke(
                        LinearGradient(
                            colors: isCompatible ? [.cyan.opacity(DesignSystem.Opacity.disabled), .purple.opacity(DesignSystem.Opacity.subtle)] : [.gray.opacity(DesignSystem.Opacity.subtle)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isCompatible ? .cyan.opacity(DesignSystem.Opacity.light) : .clear, radius: DesignSystem.shadowRadius, x: 0, y: DesignSystem.shadowY)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 实验室专属沙盒交互面板
    
    private func useCaseDetailPanel(for useCase: UseCaseType) -> some View {
        VStack(spacing: DesignSystem.medium) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    labManager.stopSimulation()
                    labManager.selectedUseCase = nil
                }) {
                    HStack(spacing: DesignSystem.standardPadding / 2) {
                        Image(systemName: "chevron.left")
                        Text(L10n.ModelManager.Lab.back)
                    }
                    .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Menu {
                    ForEach(modelManager.remoteManifests) { model in
                        if modelManager.isModelLocalReady(for: model.modelId) {
                            Button {
                                HapticFeedback.shared.trigger(.selection)
                                modelManager.activeModelId = model.modelId
                                // 同步默认超参
                                tempTemperature = model.defaultParameters.temperature
                                tempTopP = model.defaultParameters.topP
                                tempTopK = model.defaultParameters.topK
                                tempMaxTokens = model.defaultParameters.maxTokens
                            } label: {
                                HStack {
                                    Text(model.displayName)
                                    if model.modelId == getActiveModel()?.modelId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(getActiveModel()?.displayName ?? useCase.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.theme.white.opacity(DesignSystem.Opacity.subtle))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // 参数配置按钮（仿参考图右上角 Configurations 入口）
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    showConfigSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                        .padding(DesignSystem.standardPadding)
                        .background(Color.theme.white.opacity(DesignSystem.Opacity.subtle))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, DesignSystem.small)
            
            if useCase == .aiChat {
                aiChatSandboxView
            } else {
                standardSandboxView(for: useCase)
            }
        }
        .id(useCase.rawValue)
    }

    /// 多轮对话聊天沙盒视图
    @ViewBuilder
    private var aiChatSandboxView: some View {
        // 实时性能评估看板
        metricsMonitorBoard
        
        // 聊天对话列表与气泡流
        VStack(spacing: DesignSystem.medium) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignSystem.medium) {
                        ForEach(chatHistory) { msg in
                            HStack {
                                if msg.isUser {
                                    Spacer()
                                    Text(msg.text)
                                        .padding(.horizontal, Constants.chatBubblePadding)
                                        .padding(.vertical, DesignSystem.standardPadding + 2)
                                        .background(Color.theme.cyan.opacity(DesignSystem.Opacity.soft))
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                                        .padding(.leading, DesignSystem.large * 2)
                                } else {
                                    Text(msg.text)
                                        .padding(.horizontal, Constants.chatBubblePadding)
                                        .padding(.vertical, DesignSystem.standardPadding + 2)
                                        .background(Color.theme.white.opacity(DesignSystem.Opacity.light))
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                                        .padding(.trailing, DesignSystem.large * 2)
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                        
                        // 正在流式生成时的临时显示占位符
                        if labManager.isGenerating && !labManager.generatedText.isEmpty {
                            HStack {
                                Text(labManager.generatedText)
                                    .padding(.horizontal, Constants.chatBubblePadding)
                                    .padding(.vertical, DesignSystem.standardPadding + 2)
                                    .background(Color.theme.white.opacity(DesignSystem.Opacity.light))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                                    .padding(.trailing, DesignSystem.large * 2)
                                Spacer()
                            }
                            .id("generating_anchor")
                        }
                    }
                    .padding(.vertical, DesignSystem.small)
                }
                .frame(height: Constants.chatScrollHeight) // 消息滚动区域限高
                .onChange(of: chatHistory) { _, _ in
                    if let last = chatHistory.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: labManager.generatedText) { _, _ in
                    if labManager.isGenerating {
                        proxy.scrollTo("generating_anchor", anchor: .bottom)
                    }
                }
            }
            
            // 底部多轮输入发送区
            HStack(spacing: DesignSystem.small) {
                TextField(L10n.ModelManager.Lab.chatInputPlaceholder, text: $chatInputText)
                    .textFieldStyle(.plain)
                    .padding(DesignSystem.standardPadding + 4)
                    .background(Color.theme.white.opacity(DesignSystem.Opacity.ghost))
                    .cornerRadius(DesignSystem.smallRadius)
                    .foregroundStyle(.white)
                    .onSubmit {
                        sendChatMessage()
                    }
                
                Button(action: sendChatMessage) {
                    if labManager.isGenerating {
                        Button(action: { labManager.stopSimulation() }) {
                            Image(systemName: "stop.fill")
                                .foregroundStyle(.white)
                                .frame(width: Constants.stopIconSize, height: Constants.stopIconSize)
                                .padding(Constants.stopPadding)
                                .background(Color.theme.red)
                                .clipShape(Circle())
                        }
                    } else {
                        Text(L10n.ModelManager.Lab.send)
                            .bold()
                            .padding(.horizontal, DesignSystem.medium)
                            .padding(.vertical, DesignSystem.standardPadding + 2)
                            .background(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.theme.gray.opacity(DesignSystem.Opacity.disabled) : Color.theme.cyan)
                            .foregroundStyle(.white)
                            .cornerRadius(DesignSystem.smallRadius)
                    }
                }
                .disabled(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !labManager.isGenerating)
            }
        }
        .padding(DesignSystem.medium)
        .background(.white.opacity(DesignSystem.Opacity.faint))
        .cornerRadius(DesignSystem.mediumRadius)
    }

    /// 设置特定用例场景的初始预设 prompt
    private func setupDefaultPrompt(for useCase: UseCaseType) {
        switch useCase {
        case .askImage:
            testPrompt = L10n.ModelManager.Lab.Prompt.askImage
        case .aiChat:
            testPrompt = L10n.ModelManager.Lab.Prompt.chat
        case .agentSkills:
            testPrompt = L10n.ModelManager.Lab.Prompt.agentSkills
        case .promptLab:
            testPrompt = L10n.ModelManager.Lab.Prompt.promptLab
        case .tinyGarden:
            testPrompt = L10n.ModelManager.Lab.Prompt.tinyGarden
        case .mobileActions:
            testPrompt = L10n.ModelManager.Lab.Prompt.mobileActions
        default:
            testPrompt = ""
        }
    }

    /// 通用 Prompt 文本域（如适用）
    @ViewBuilder
    private func promptEditorView(for useCase: UseCaseType) -> some View {
        if useCase != .audioScribe {
            TextEditor(text: $testPrompt)
                .padding(DesignSystem.standardPadding)
                .frame(height: DesignSystem.Metrics.iconBoxSize * 2)
                .background(Color.theme.white.opacity(DesignSystem.Opacity.ghost))
                .cornerRadius(DesignSystem.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.theme.white.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if testPrompt.isEmpty {
                            Text(L10n.ModelManager.Lab.placeholderInput)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DesignSystem.standardPadding + 4)
                                .padding(.vertical, DesignSystem.standardPadding + 4)
                        }
                    },
                    alignment: .topLeading
                )
                .font(.body)
                .foregroundStyle(Color.theme.white)
        }
    }

    /// 运行控制按键组件
    @ViewBuilder
    private func controlButton(for useCase: UseCaseType) -> some View {
        if labManager.isGenerating {
            Button(action: {
                labManager.stopSimulation()
            }) {
                Text(L10n.ModelManager.Lab.stopInference)
                    .padding(.horizontal, DesignSystem.large - 8)
                    .padding(.vertical, DesignSystem.standardPadding + 2)
                    .background(Color.theme.red.opacity(DesignSystem.Opacity.shadow))
                    .foregroundStyle(Color.theme.red)
                    .cornerRadius(DesignSystem.smallRadius)
            }
        } else {
            Button(action: {
                Task {
                    guard let model = getActiveModel() else { return }
                    HapticFeedback.shared.trigger(.selection)
                    await labManager.runSimulation(for: useCase, model: model, prompt: testPrompt)
                }
            }) {
                Text(L10n.ModelManager.Lab.runTest)
                    .bold()
                    .padding(.horizontal, DesignSystem.large - 4)
                    .padding(.vertical, DesignSystem.standardPadding + 2)
                    .background(
                        LinearGradient(
                            colors: [Color.theme.cyan, Color.theme.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(Color.theme.white)
                    .cornerRadius(DesignSystem.smallRadius)
                    .shadow(color: Color.theme.cyan.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.shadowRadius)
            }
            .disabled(testPrompt.isEmpty && useCase != .audioScribe)
            .opacity((testPrompt.isEmpty && useCase != .audioScribe) ? DesignSystem.Opacity.soft : DesignSystem.Opacity.solid)
        }
    }

    /// 单轮沙盒交互测试视图
    @ViewBuilder
    private func standardSandboxView(for useCase: UseCaseType) -> some View {
        VStack(spacing: DesignSystem.medium) {
            // 实时性能评估看板
            metricsMonitorBoard
            
            // 核心功能测试交互区
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                Text(L10n.ModelManager.Lab.configureInputs)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(DesignSystem.Opacity.prominent))
                
                // 根据用例分发特殊输入源组件
                switch useCase {
                case .askImage:
                    askImageInputs
                case .audioScribe:
                    audioScribeInputs
                case .promptLab:
                    promptLabSliders
                default:
                    EmptyView()
                }
                
                promptEditorView(for: useCase)
                
                HStack {
                    Spacer()
                    controlButton(for: useCase)
                }
            }
            .padding(DesignSystem.medium)
            .background(.white.opacity(DesignSystem.Opacity.faint))
            .cornerRadius(DesignSystem.mediumRadius)
            
            // 推理流输出展示板
            outputScribeBoard
        }
        .id(useCase.rawValue)
        .onAppear {
            setupDefaultPrompt(for: useCase)
        }
    }
    
    /// 实时评估性能指标看板
    private var metricsMonitorBoard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Lab.performanceMetrics)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            
            HStack(spacing: 0) {
                metricItem(
                    title: L10n.ModelManager.Lab.speed,
                    value: String(format: "%.1f", labManager.currentStats.speed),
                    unit: "Tok/s"
                )
                Divider().background(Color.theme.white.opacity(DesignSystem.Opacity.subtle)).padding(.vertical, DesignSystem.standardPadding)
                metricItem(
                    title: L10n.ModelManager.Lab.prefillLatency,
                    value: "\(labManager.currentStats.prefillLatency)",
                    unit: "ms"
                )
                Divider().background(Color.theme.white.opacity(DesignSystem.Opacity.subtle)).padding(.vertical, DesignSystem.standardPadding)
                metricItem(
                    title: L10n.ModelManager.Lab.firstTokenLatency,
                    value: "\(labManager.currentStats.firstTokenLatency)",
                    unit: "ms"
                )
                Divider().background(Color.theme.white.opacity(DesignSystem.Opacity.subtle)).padding(.vertical, DesignSystem.standardPadding)
                metricItem(
                    title: L10n.ModelManager.Lab.memoryUsage,
                    value: String(format: "%.0f", labManager.currentStats.memoryUsage),
                    unit: "MB"
                )
            }
            .background(Color.theme.black.opacity(DesignSystem.Opacity.medium))
            .cornerRadius(DesignSystem.smallRadius)
        }
        .padding(DesignSystem.medium)
        .background(.white.opacity(DesignSystem.Opacity.atomic))
        .cornerRadius(DesignSystem.mediumRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                .stroke(Color.theme.cyan.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
        )
    }
    
    private func metricItem(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: DesignSystem.iconTiny - 2))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundStyle(.white)
                .contentTransition(.numericText()) // 开启数字翻滚动效
            
            Text(unit)
                .font(.system(size: DesignSystem.iconTiny - 4, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 流式输出面板
    private var outputScribeBoard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Lab.outputResult)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(DesignSystem.Opacity.prominent))
            
            ScrollView {
                Text(labManager.generatedText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white.opacity(DesignSystem.Opacity.prominent))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .frame(height: DesignSystem.Vault.cardHeight)
            .padding(DesignSystem.standardPadding + 4)
            .background(Color.theme.black.opacity(DesignSystem.Opacity.medium))
            .cornerRadius(DesignSystem.smallRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                    .stroke(Color.theme.white.opacity(DesignSystem.Opacity.subtle), lineWidth: 1)
            )
        }
        .padding(DesignSystem.medium)
        .background(.white.opacity(DesignSystem.Opacity.faint))
        .cornerRadius(DesignSystem.mediumRadius)
    }
    
    // MARK: - 特有场景交互组件
    
    /// Ask Image 输入项
    private var askImageInputs: some View {
        HStack(spacing: DesignSystem.medium) {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                isImageSelected.toggle()
            }) {
                VStack(spacing: DesignSystem.standardPadding) {
                    if isImageSelected {
                        // 展现模拟工作台图片
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.cyan)
                        Text("workspace_bench.jpg")
                            .font(.caption)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "plus.viewfinder")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(L10n.ModelManager.Lab.selectImage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: DesignSystem.Metrics.sourceCardWidth + DesignSystem.tiny, height: DesignSystem.Metrics.boxHeight)
                .background(Color.theme.white.opacity(DesignSystem.Opacity.ghost))
                .cornerRadius(DesignSystem.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.theme.white.opacity(DesignSystem.Opacity.subtle), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding / 2) {
                Text(L10n.ModelManager.Lab.visualParams)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Text(L10n.ModelManager.Lab.visualDesc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, DesignSystem.standardPadding - 2)
    }
    
    /// Audio Scribe 输入项
    private var audioScribeInputs: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack(spacing: DesignSystem.medium) {
                Button {
                    HapticFeedback.shared.trigger(.selection)
                    if isAudioRecording {
                        isAudioRecording = false
                        isAudioCompleted = true
                        testPrompt = L10n.ModelManager.Lab.audioReady
                    } else {
                        isAudioRecording = true
                        isAudioCompleted = false
                        labManager.generatedText = ""
                    }
                } label: {
                    HStack {
                        Image(systemName: isAudioRecording ? "stop.circle.fill" : "record.circle")
                            .foregroundStyle(isAudioRecording ? .red : .cyan)
                        Text(isAudioRecording ? L10n.ModelManager.Lab.stopRecording : L10n.ModelManager.Lab.recordAudio)
                    }
                    .padding(.horizontal, DesignSystem.standardPadding + 8)
                    .padding(.vertical, DesignSystem.standardPadding + 2)
                    .background(Color.theme.white.opacity(DesignSystem.Opacity.light))
                    .cornerRadius(DesignSystem.smallRadius)
                }
                .buttonStyle(.plain)
                
                if isAudioRecording {
                    HStack(spacing: DesignSystem.standardPadding / 2) {
                        ForEach(0..<6) { _ in
                            RoundedRectangle(cornerRadius: DesignSystem.borderWidth * 2)
                                .fill(Color.theme.cyan)
                                .frame(width: DesignSystem.borderWidth * 4, height: CGFloat.random(in: DesignSystem.standardPadding...DesignSystem.large))
                                .animation(.easeInOut(duration: 0.25).repeatForever(), value: isAudioRecording)
                        }
                    }
                }
            }
            
            if isAudioCompleted {
                Text(L10n.ModelManager.Lab.audioCompleted)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.bottom, DesignSystem.standardPadding - 2)
    }
    
    /// Prompt Lab 滑块项
    private var promptLabSliders: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            sliderRow(title: "Temperature", val: $tempTemperature, range: 0.0...2.0, spec: "%.2f")
            sliderRow(title: "Top-P", val: $tempTopP, range: 0.0...1.0, spec: "%.2f")
        }
        .padding(.bottom, DesignSystem.standardPadding - 2)
    }
    
    private func sliderRow(title: String, val: Binding<Double>, range: ClosedRange<Double>, spec: String) -> some View {
        VStack(spacing: DesignSystem.standardPadding / 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: spec, val.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.cyan)
            }
            Slider(value: val, in: range)
                .tint(.cyan)
        }
    }
    
    // MARK: - 参数配置 Sheet（仿 Google AI Edge Gallery Configurations）
    
    /// 参数配置底部弹出 Sheet
    private var configurationSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.medium) {
                    // Model Configs / System Prompt 分段
                    Picker("", selection: .constant(0)) {
                        Text(L10n.ModelManager.Lab.modelConfigs).tag(0)
                        Text(L10n.ModelManager.Lab.systemPrompt).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DesignSystem.medium)
                    .padding(.top, DesignSystem.small)
                    
                    VStack(spacing: DesignSystem.medium) {
                        // Max Tokens
                        paramSheetSlider(
                            title: L10n.ModelManager.Parameters.maxTokens,
                            value: Binding(
                                get: { Double(tempMaxTokens) },
                                set: { tempMaxTokens = Int($0) }
                            ),
                            range: 256...8192,
                            step: 256,
                            displayValue: "\(tempMaxTokens)"
                        )
                        
                        // TopK
                        paramSheetSlider(
                            title: L10n.ModelManager.Parameters.topK,
                            value: Binding(
                                get: { Double(tempTopK) },
                                set: { tempTopK = Int($0) }
                            ),
                            range: 1...100,
                            step: 1,
                            displayValue: "\(tempTopK)"
                        )
                        
                        // TopP
                        paramSheetSlider(
                            title: L10n.ModelManager.Parameters.topP,
                            value: $tempTopP,
                            range: 0.0...1.0,
                            step: 0.05,
                            displayValue: String(format: "%.2f", tempTopP)
                        )
                        
                        // Temperature
                        paramSheetSlider(
                            title: L10n.ModelManager.Parameters.temperature,
                            value: $tempTemperature,
                            range: 0.0...2.0,
                            step: 0.05,
                            displayValue: String(format: "%.2f", tempTemperature)
                        )
                        
                        Divider().padding(.vertical, DesignSystem.standardPadding)
                        
                        // CPU / GPU 加速器选择
                        VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                            Text("Accelerator")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 0) {
                                Button(action: { useGPU = false }) {
                                    Text("CPU")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignSystem.standardPadding + 4)
                                        .background(useGPU ? Color.clear : Color.theme.white.opacity(DesignSystem.Opacity.light))
                                        .foregroundStyle(useGPU ? Color.secondary : Color.theme.white)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { useGPU = true }) {
                                    Text("GPU")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignSystem.standardPadding + 4)
                                        .background(useGPU ? Color.theme.white.opacity(DesignSystem.Opacity.light) : Color.clear)
                                        .foregroundStyle(useGPU ? Color.theme.white : Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(Color.theme.white.opacity(DesignSystem.Opacity.ghost))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                        }
                        
                        Divider().padding(.vertical, DesignSystem.standardPadding)
                        
                        // 高级开关
                        Toggle(L10n.ModelManager.Lab.enableThinking, isOn: $enableThinking)
                            .tint(.cyan)
                        
                        Toggle(L10n.ModelManager.Lab.enableSpeculativeDecoding, isOn: $enableSpeculativeDecoding)
                            .tint(.cyan)
                    }
                    .padding(.horizontal, DesignSystem.medium)
                }
            }
            .navigationTitle(L10n.ModelManager.Lab.configurations)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.ModelManager.Parameters.save) {
                        showConfigSheet = false
                    }
                    .foregroundStyle(.cyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    /// 参数配置 Sheet 中单行滑块组件
    private func paramSheetSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        displayValue: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.standardPadding / 2) {
            Text(title)
                .font(.subheadline)
            
            HStack(spacing: DesignSystem.medium) {
                Slider(value: value, in: range, step: step)
                    .tint(.cyan)
                
                Text(displayValue)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: DesignSystem.Metrics.smallIconBoxSize, alignment: .trailing)
                    .padding(.horizontal, DesignSystem.standardPadding)
                    .padding(.vertical, DesignSystem.standardPadding / 2)
                    .background(Color.theme.white.opacity(DesignSystem.Opacity.subtle))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardPadding))
            }
        }
    }
    
    // MARK: - 引导与拦截遮罩
    
    private var noModelMaskView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: DesignSystem.iconDisplay + DesignSystem.iconTiny))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, DesignSystem.standardPadding + 2)
                    
                    Text(L10n.ModelManager.Lab.noActiveModelTitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.theme.white)
                    
                    Text(L10n.ModelManager.Lab.noActiveModelSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.large)
                    
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        onGoToStore()
                    }) {
                        Text(L10n.ModelManager.Lab.goToStore)
                            .bold()
                            .padding(.horizontal, DesignSystem.large)
                            .padding(.vertical, DesignSystem.standardPadding + 4)
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(Color.theme.white)
                            .cornerRadius(DesignSystem.smallRadius + 2)
                            .shadow(color: .cyan.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.shadowRadius)
                    }
                    .padding(.top, DesignSystem.standardPadding + 2)
                }
                .padding(DesignSystem.large)
                .background(Color.theme.black.opacity(DesignSystem.Opacity.disabled))
                .cornerRadius(DesignSystem.largeRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                        .stroke(Color.theme.white.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
                )
                .padding(DesignSystem.large)
            )
    }
    
    // MARK: - 逻辑辅助
    
    private func sendChatMessage() {
        let text = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && !labManager.isGenerating else { return }
        
        // 1. 追加用户消息
        let userMsg = LabChatMessage(isUser: true, text: text)
        chatHistory.append(userMsg)
        chatInputText = ""
        
        // 2. 异步启动推理
        Task {
            guard let model = getActiveModel() else { return }
            HapticFeedback.shared.trigger(.selection)
            // 调用已有的 runSimulation 模拟回复
            await labManager.runSimulation(for: .aiChat, model: model, prompt: text)
            
            // 推理结束后，把流式生成的文本转入历史对话消息，并清空生成缓冲区
            let aiMsg = LabChatMessage(isUser: false, text: labManager.generatedText)
            chatHistory.append(aiMsg)
            labManager.generatedText = ""
        }
    }
    
    private func hasActiveLocalModel() -> Bool {
        // 白名单中任何一个模型在本地就绪，代表可以进入实验室
        for manifest in modelManager.remoteManifests where modelManager.isModelLocalReady(for: manifest.modelId) {
            return true
        }
        return false
    }
    
    private func getActiveModel() -> LLMManifest? {
        let activeId = modelManager.activeModelId
        if let model = modelManager.remoteManifests.first(where: { $0.modelId == activeId }) {
            return model
        }
        // Fallback: 找第一个本地就绪的
        for manifest in modelManager.remoteManifests where modelManager.isModelLocalReady(for: manifest.modelId) {
            return manifest
        }
        return modelManager.remoteManifests.first
    }
}

/// 实验室专属多轮聊天消息结构体
public struct LabChatMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let isUser: Bool
    public let text: String
    
    public init(id: UUID = UUID(), isUser: Bool, text: String) {
        self.id = id
        self.isUser = isUser
        self.text = text
    }
}
