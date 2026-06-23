//
//  ModelLabSandboxPanel.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：实验室沙盒面板的顶部导航栏（返回、模型选择、配置入口）与通用单轮沙盒交互视图
//  （Prompt 编辑、运行控制按键），按用例类型分发特殊输入源组件。
//

import SwiftUI

// MARK: - 沙盒面板

extension ModelLabView {

    // MARK: - 实验室专属沙盒交互面板

    func useCaseDetailPanel(for useCase: UseCaseType) -> some View {
        VStack(spacing: DesignSystem.medium) {
            // 顶部导航栏
            useCaseDetailHeader(for: useCase)
                .padding(.bottom, DesignSystem.small)

            if useCase == .aiChat {
                aiChatSandboxView
            } else {
                standardSandboxView(for: useCase)
            }
        }
        .id(useCase.rawValue)
    }

    /// 实验室沙盒面板的顶部导航与配置栏视图
    /// - Parameter useCase: 当前使用的用例类型
    /// - Returns: 顶部状态和配置项的 HStack 视图
    func useCaseDetailHeader(for useCase: UseCaseType) -> some View {
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

            modelSelectionMenu(for: useCase)

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
    }

    /// 实验室沙盒面板的模型选择下拉菜单视图，仅列出本地已下载就绪的模型
    /// - Parameter useCase: 当前使用的用例类型
    /// - Returns: 模型选择的 Menu 下拉视图
    func modelSelectionMenu(for useCase: UseCaseType) -> some View {
        Menu {
            ForEach(modelManager.remoteManifests) { model in
                if modelManager.isModelLocalReady(for: model.modelId) {
                    Button {
                        HapticFeedback.shared.trigger(.selection)
                        modelManager.activeModelId = model.modelId
                        loadParametersForModel(model.modelId)
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
    }

    /// 设置特定用例场景的初始预设 prompt
    func setupDefaultPrompt(for useCase: UseCaseType) {
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
    func promptEditorView(for useCase: UseCaseType) -> some View {
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
    func controlButton(for useCase: UseCaseType) -> some View {
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
    func standardSandboxView(for useCase: UseCaseType) -> some View {
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
            .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
            .cornerRadius(DesignSystem.mediumRadius)

            // 推理流输出展示板
            outputScribeBoard
        }
        .id(useCase.rawValue)
        .onAppear {
            setupDefaultPrompt(for: useCase)
        }
    }
}
