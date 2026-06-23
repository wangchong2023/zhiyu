//
//  ModelLabView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：大模型多用例测试实验室主容器视图，负责状态持有、用例格栅与沙盒面板的分发组合，
//  以及配置弹窗与拦截遮罩的统一挂载。各功能子视图已拆分至 View/Sections/ 目录下的独立文件。
//

import SwiftUI

/// 大模型测试实验室主视图
@MainActor
public struct ModelLabView: View {

    // MARK: - 环境与外部依赖

    enum Constants {
        static let chatScrollHeight: CGFloat = 280
        static let stopIconSize: CGFloat = 20
        static let stopPadding: CGFloat = 10
        static let chatBubblePadding: CGFloat = 14
    }

    @State var modelManager = GlobalModelManager.shared
    @State var labManager = ModelLabManager()
    @StateObject private var themeManager = ThemeManager.shared

    /// 当需要跳回商店时的外部闭包回调
    public var onGoToStore: () -> Void

    // MARK: - 局部交互状态

    @State var testPrompt: String = ""
    @State var tempTemperature: Double = 0.7
    @State var tempTopP: Double = 0.9
    @State var tempTopK: Int = 40
    @State var tempMaxTokens: Int = 2048

    // 参数配置面板
    @State var showConfigSheet: Bool = false
    @State var useGPU: Bool = false
    @State var enableThinking: Bool = false
    @State var enableSpeculativeDecoding: Bool = false

    @State var selectedConfigTab: Int = 0
    @State var systemPromptText: String = L10n.ModelManager.Lab.defaultSystemPrompt

    private let parametersStore = InferenceParametersStore.shared

    var matchedPreset: ParameterPreset? {
        for p in ParameterPreset.allCases {
            let v = p.parameters
            if abs(tempTemperature - v.temperature) < 0.01,
               abs(tempTopP - v.topP) < 0.01,
               tempTopK == v.topK,
               tempMaxTokens == v.maxTokens { return p }
        }
        return nil
    }

    var isCustomMode: Bool { matchedPreset == nil }

    // 多模态/视觉特定状态
    @State var isImageSelected: Bool = false

    // 语音速记特定状态
    @State var isAudioRecording: Bool = false
    @State var isAudioCompleted: Bool = false

    // 多轮对话特定状态
    @State var chatHistory: [LabChatMessage] = []
    @State var chatInputText: String = ""

    // MARK: - 布局网格

    let columns = [
        GridItem(.adaptive(minimum: DesignSystem.Vault.gridCardMin, maximum: DesignSystem.Vault.gridCardMax), spacing: DesignSystem.medium)
    ]

    public init(onGoToStore: @escaping () -> Void) {
        self.onGoToStore = onGoToStore
    }

    public var body: some View {
        ZStack {
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
        .onChange(of: tempTemperature) { _, _ in autoSave() }
        .onChange(of: tempTopP) { _, _ in autoSave() }
        .onChange(of: tempTopK) { _, _ in autoSave() }
        .onChange(of: tempMaxTokens) { _, _ in autoSave() }
        .onAppear {
            if let activeModel = getActiveModel() {
                loadParametersForModel(activeModel.modelId)
            }
        }
        .onChange(of: modelManager.activeModelId) { _, newModelId in
            loadParametersForModel(newModelId)
        }
    }
}
