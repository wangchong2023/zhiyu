//
//  ParameterPreset.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：定义大模型推理参数预设模板（创意/均衡/精准），封装各预设的温温度、Top-P、Top-K、
//  MaxTokens 默认值以及对应的展示名称与 SF Symbol 图标。
//

import Foundation

/// 推理参数预设模板
enum ParameterPreset: String, CaseIterable {
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

    struct InferenceParams {
        var temperature: Double
        var topP: Double
        var topK: Int
        var maxTokens: Int
    }

    var parameters: InferenceParams {
        switch self {
        case .creative:
            return InferenceParams(temperature: 1.2, topP: 0.95, topK: 50, maxTokens: 2048)
        case .balanced:
            return InferenceParams(temperature: 0.7, topP: 0.9, topK: 40, maxTokens: 2048)
        case .precise:
            return InferenceParams(temperature: 0.3, topP: 0.85, topK: 20, maxTokens: 1024)
        }
    }
}
