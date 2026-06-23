//
//  ModelLabMetricsPanel.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：实时性能评估看板（速度/延迟/内存指标卡片）与流式推理输出展示板的渲染。
//

import SwiftUI

// MARK: - 性能监控与输出面板

extension ModelLabView {

    /// 实时评估性能指标看板
    var metricsMonitorBoard: some View {
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
            .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
            .cornerRadius(DesignSystem.smallRadius)
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
        .cornerRadius(DesignSystem.mediumRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                .stroke(Color.theme.cyan.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
        )
    }

    func metricItem(title: String, value: String, unit: String) -> some View {
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
    var outputScribeBoard: some View {
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
            .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
            .cornerRadius(DesignSystem.smallRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                    .stroke(Color.appBorder.opacity(DesignSystem.Opacity.subtle), lineWidth: 1)
            )
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard.opacity(DesignSystem.Opacity.dim))
        .cornerRadius(DesignSystem.mediumRadius)
    }
}
