//
//  InferenceParametersView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/05.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：推理参数调节视图，修改即生效，提供温度、Top-P、Top-K、Max Tokens 等参数的可视化调节界面。
//

import SwiftUI

/// 推理参数调节视图
@MainActor
public struct InferenceParametersView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var modelManager = GlobalModelManager()

    // MARK: - 状态管理

    @State private var temperature: Double = 0.7
    @State private var topP: Double = 0.9
    @State private var topK: Int = 40
    @State private var maxTokens: Int = 2048
    @State private var hoveredTitle: String?  // 当前悬浮的参数标题

    /// 当前位置是否匹配某个预设（不匹配时按钮不高亮）
    private var matchedPreset: ParameterPreset? {
        for p in ParameterPreset.allCases {
            let v = p.parameters
            if abs(temperature - v.temperature) < 0.01, abs(topP - v.topP) < 0.01,
               topK == v.topK, maxTokens == v.maxTokens { return p }
        }
        return nil
    }

    private let parametersStore = InferenceParametersStore.shared

    // MARK: - 预设模板

    private enum ParameterPreset: String, CaseIterable {
        case balanced
        case creative
        case precise

        var displayName: String {
            switch self {
            case .creative:
                return L10n.ModelManager.Parameters.presetCreative
            case .balanced:
                return L10n.ModelManager.Parameters.presetBalanced
            case .precise:
                return L10n.ModelManager.Parameters.presetPrecise
            }
        }

        var icon: String {
            switch self {
            case .creative:
                return "paintbrush.fill"
            case .balanced:
                return "scale.3d"
            case .precise:
                return "target"
            }
        }

        var parameters: (temperature: Double, topP: Double, topK: Int, maxTokens: Int) {
            switch self {
            case .creative:
                return (1.2, 0.95, 50, 2048)
            case .balanced:
                return (0.7, 0.9, 40, 2048)
            case .precise:
                return (0.3, 0.85, 20, 1024)
            }
        }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.large) {
                // 预设模板选择
                presetSelector

                // 温度调节
                parameterSlider(
                    title: L10n.ModelManager.Parameters.temperature,
                    value: $temperature,
                    range: 0.0...2.0,
                    tip: L10n.ModelManager.Parameters.tipTemperature
                )

                // Top-P 调节
                parameterSlider(
                    title: L10n.ModelManager.Parameters.topP,
                    value: $topP,
                    range: 0.0...1.0,
                    tip: L10n.ModelManager.Parameters.tipTopP
                )

                // Top-K 调节
                parameterIntSlider(
                    title: L10n.ModelManager.Parameters.topK,
                    value: $topK,
                    range: 1...100,
                    tip: L10n.ModelManager.Parameters.tipTopK
                )

                // Max Tokens 调节
                parameterIntSlider(
                    title: L10n.ModelManager.Parameters.maxTokens,
                    value: $maxTokens,
                    range: 128...4096,
                    tip: L10n.ModelManager.Parameters.tipMaxTokens
                )

            }
            .padding(DesignSystem.medium)
        }
        .onAppear {
            // 首次加载当前模型的参数
            loadParametersForModel(modelManager.activeModelId)
        }
        .onChange(of: modelManager.activeModelId) { _, newModelId in
            // 模型切换时自动加载对应参数
            loadParametersForModel(newModelId)
        }
    }

    // MARK: - 子视图组件

    /// 当前模型选择器
    private var currentModelSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Parameters.currentModel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)

            Menu {
                ForEach(modelManager.remoteManifests.filter { modelManager.isModelLocalReady(for: $0.modelId) }) { manifest in
                    Button(action: {
                        modelManager.activeModelId = manifest.modelId
                        loadParametersForModel(manifest.modelId)
                    }) {
                        HStack {
                            Text(manifest.displayName)
                            if modelManager.activeModelId == manifest.modelId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(getActiveModelName())
                        .foregroundStyle(.appText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.appSecondary)
                }
                .padding()
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
            }
        }
    }

    /// 预设模板选择器（预设锁定 + 自定义按钮）
    private var presetSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Parameters.presetTemplate)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)

            HStack(spacing: DesignSystem.small) {
                ForEach(ParameterPreset.allCases, id: \.self) { preset in
                    presetButton(for: preset)
                }
                // "自定义"按钮 — 解锁参数编辑
                customButton
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    /// 自定义模式按钮
    private var customButton: some View {
        let isCustom = matchedPreset == nil
        return Button(action: {
            if let preset = matchedPreset {
                // 从已锁定预设进入自定义：微调后 matchedPreset 自动变 nil
                temperature = preset.parameters.temperature + 0.01
            }
        }) {
            VStack(spacing: DesignSystem.tiny) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                Text(L10n.ModelManager.Parameters.custom)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.small)
            .background(isCustom ? Color.appAccent : Color.appBackground)
            .foregroundStyle(isCustom ? .white : .appText)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        }
        .buttonStyle(.plain)
        .disabled(isCustom) // 已在自定义模式时禁用
    }

    /// 预设按钮
    private func presetButton(for preset: ParameterPreset) -> some View {
        Button(action: { applyPreset(preset) }) {
            VStack(spacing: DesignSystem.tiny) {
                Image(systemName: preset.icon)
                    .font(.title3)
                Text(preset.displayName)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.small)
            .background(matchedPreset == preset ? Color.appAccent : Color.appBackground)
            .foregroundStyle(matchedPreset == preset ? .white : .appText)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        }
        .buttonStyle(.plain)
    }

    /// 是否可编辑参数（仅自定义模式）
    private var isCustomMode: Bool { matchedPreset == nil }

    /// 参数滑块（Double 类型）
    private func parameterSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, tip: String) -> some View {
        let isHovered = hoveredTitle == title
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(isHovered ? .appAccent : .appSecondary.opacity(0.5))
            }
            .onHover { hovering in hoveredTitle = hovering ? title : nil }
            .overlay(alignment: .top) {
                if isHovered {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(tip)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .offset(y: -28)
                }
            }

            Slider(value: value, in: range)
                .tint(.appAccent)
                .disabled(!isCustomMode)

            HStack {
                Text(String(format: "%.1f", range.lowerBound))
                    .font(.caption2).foregroundStyle(.appSecondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption.weight(.bold)).foregroundStyle(.appAccent)
                Spacer()
                Text(String(format: "%.1f", range.upperBound))
                    .font(.caption2).foregroundStyle(.appSecondary)
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    /// 参数滑块（Int 类型）
    private func parameterIntSlider(title: String, value: Binding<Int>, range: ClosedRange<Int>, tip: String) -> some View {
        let isHovered = hoveredTitle == title
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(isHovered ? .appAccent : .appSecondary.opacity(0.5))
            }
            .onHover { hovering in hoveredTitle = hovering ? title : nil }
            .overlay(alignment: .top) {
                if isHovered {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill").font(.caption2).foregroundStyle(.orange)
                        Text(tip).font(.caption2).foregroundStyle(.appSecondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .offset(y: -28)
                }
            }

            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1.0)
                .tint(.appAccent).disabled(!isCustomMode)

            HStack {
                Text("\(range.lowerBound)").font(.caption2).foregroundStyle(.appSecondary)
                Spacer()
                Text("\(value.wrappedValue)").font(.caption.weight(.bold)).foregroundStyle(.appAccent)
                Spacer()
                Text("\(range.upperBound)").font(.caption2).foregroundStyle(.appSecondary)
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    // MARK: - 辅助方法

    private func getActiveModelName() -> String {
        if let manifest = modelManager.remoteManifests.first(where: { $0.modelId == modelManager.activeModelId }) {
            return manifest.displayName
        }
        return L10n.ModelManager.Parameters.selectModel
    }

    private func applyPreset(_ preset: ParameterPreset) {
        let params = preset.parameters
        withAnimation(.easeInOut(duration: 0.3)) {
            temperature = params.temperature
            topP = params.topP
            topK = params.topK
            maxTokens = params.maxTokens
        }
        HapticFeedback.shared.trigger(.success)
    }

    private func loadParametersForModel(_ modelId: String) {
        // 尝试从持久化存储加载该模型的参数配置
        if let config = parametersStore.loadParameters(for: modelId) {
            // 找到保存的配置，恢复参数
            withAnimation(.easeInOut(duration: 0.3)) {
                temperature = config.temperature
                topP = config.topP
                topK = config.topK
                maxTokens = config.maxTokens

                // 恢复预设参数（matchedPreset 自动计算）
            }
        } else {
            // 未找到保存的配置，使用默认 balanced 预设
            applyPreset(.balanced)
        }
    }

    private func autoSave() {
        // 构建配置对象
        let config = InferenceParametersConfig(
            modelId: modelManager.activeModelId,
            presetName: matchedPreset?.rawValue ?? "custom",
            temperature: temperature,
            topP: topP,
            topK: topK,
            maxTokens: maxTokens
        )

        // 保存到持久化存储
        parametersStore.saveParameters(config)

        // 触发成功反馈
        HapticFeedback.shared.trigger(.success)
    }

    /// 根据参数值匹配最接近的预设
    private func matchPreset(temperature: Double, topP: Double, topK: Int, maxTokens: Int) -> ParameterPreset {
        for preset in ParameterPreset.allCases {
            let params = preset.parameters
            if abs(params.temperature - temperature) < 0.01 &&
               abs(params.topP - topP) < 0.01 &&
               params.topK == topK &&
               params.maxTokens == maxTokens {
                return preset
            }
        }
        // 如果没有完全匹配，返回 balanced 作为默认
        return .balanced
    }
}

// MARK: - 预览

#if DEBUG
#Preview {
    InferenceParametersView()
        .environmentObject(ThemeManager.shared)
}
#endif
