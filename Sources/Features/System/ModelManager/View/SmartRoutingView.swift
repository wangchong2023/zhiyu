//
//  SmartRoutingView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/05.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：智能路由配置视图，提供端云混合策略、任务路由规则、网络状态监控等配置界面。云端模型选择已集成到在线大模型配置中。
//

import SwiftUI

/// 智能路由配置视图
@MainActor
public struct SmartRoutingView: View {

    // MARK: - 环境注入

    @StateObject private var themeManager = ThemeManager.shared
    @State private var modelManager = GlobalModelManager()

    // MARK: - 状态管理

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.large) {
                // 端云混合策略
                cloudEscalationSection

                // 任务路由规则
                routingRulesSection

                // 网络状态监控
                networkStatusSection

                // 高级设置
                advancedSettingsSection
            }
            .padding(DesignSystem.medium)
        }
        .navigationTitle(L10n.Settings.smartRouting)
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - 子视图组件

    /// 端云混合策略
    private var cloudEscalationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.cloudEscalationTitle)
                .font(.headline)
                .foregroundStyle(.appText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.ModelManager.Routing.cloudEscalationToggle)
                        .font(.subheadline)
                        .foregroundStyle(.appText)

                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(L10n.ModelManager.Routing.cloudEscalationDesc)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { modelManager.isCloudEscalationEnabled },
                    set: { modelManager.isCloudEscalationEnabled = $0 }
                ))
                .labelsHidden()
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    /// 任务路由规则
    private var routingRulesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.taskRules)
                .font(.headline)
                .foregroundStyle(.appText)

            VStack(spacing: DesignSystem.small) {
                routingRuleRow(
                    icon: "lock.fill",
                    iconColor: .red,
                    task: L10n.ModelManager.Routing.taskSemanticChunking,
                    rule: L10n.ModelManager.Routing.strategyForceLocal
                )

                routingRuleRow(
                    icon: "lock.fill",
                    iconColor: .red,
                    task: L10n.ModelManager.Routing.taskLinkDiscovery,
                    rule: L10n.ModelManager.Routing.strategyForceLocal
                )

                routingRuleRow(
                    icon: "arrow.triangle.branch",
                    iconColor: .blue,
                    task: L10n.ModelManager.Routing.taskSynthesis,
                    rule: L10n.ModelManager.Routing.strategySmartRouting
                )

                routingRuleRow(
                    icon: "arrow.triangle.branch",
                    iconColor: .blue,
                    task: L10n.ModelManager.Routing.taskChat,
                    rule: L10n.ModelManager.Routing.strategySmartRouting
                )

                routingRuleRow(
                    icon: "arrow.triangle.branch",
                    iconColor: .blue,
                    task: L10n.ModelManager.Routing.taskTagGeneration,
                    rule: L10n.ModelManager.Routing.strategySmartRouting
                )
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    /// 路由规则行
    private func routingRuleRow(icon: String, iconColor: Color, task: String, rule: String) -> some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(task)
                .font(.subheadline)
                .foregroundStyle(.appText)

            Spacer()

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.appSecondary)

            Text(rule)
                .font(.caption.weight(.medium))
                .foregroundStyle(.appAccent)
        }
        .padding(.vertical, DesignSystem.small)
        .padding(.horizontal, DesignSystem.medium)
        .background(Color.appBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    /// 网络状态监控
    private var networkStatusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.networkMonitoring)
                .font(.headline)
                .foregroundStyle(.appText)

            VStack(spacing: DesignSystem.small) {
                statusRow(
                    label: L10n.ModelManager.Routing.networkCurrent,
                    value: "WiFi",
                    status: .healthy
                )

                statusRow(
                    label: L10n.ModelManager.Routing.networkLatency,
                    value: "23ms",
                    status: .healthy
                )

                statusRow(
                    label: L10n.ModelManager.Routing.networkBandwidth,
                    value: L10n.ModelManager.Routing.networkBandwidthExcellent,
                    status: .healthy
                )

                Divider()

                statusRow(
                    label: L10n.ModelManager.Routing.localModelReady,
                    value: getActiveModelName(),
                    status: modelManager.isModelLocalReady(for: modelManager.activeModelId) ? .healthy : .warning
                )

                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.appAccent)
                        .frame(width: 20)

                    Text(L10n.ModelManager.Routing.currentDecision)
                        .font(.subheadline)
                        .foregroundStyle(.appText)

                    Spacer()

                    Text(getCurrentRoutingDecision())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, 4)
                        .background(Color.appAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    /// 状态行
    private func statusRow(label: String, value: String, status: HealthStatus) -> some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appText)

            Spacer()

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)
        }
    }

    /// 高级设置
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.advanced)
                .font(.headline)
                .foregroundStyle(.appText)

            VStack(spacing: DesignSystem.small) {
                Toggle(L10n.ModelManager.Routing.wifiOnly, isOn: .constant(false))
                    .font(.subheadline)

                Toggle(L10n.ModelManager.Routing.autoFallback, isOn: .constant(true))
                    .font(.subheadline)

                Toggle(L10n.ModelManager.Routing.preferLocal, isOn: .constant(true))
                    .font(.subheadline)
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
        return L10n.ModelManager.Routing.decisionUnselected
    }

    private func getCurrentRoutingDecision() -> String {
        if modelManager.isCloudEscalationEnabled {
            return L10n.ModelManager.Routing.decisionCloud
        } else if modelManager.isModelLocalReady(for: modelManager.activeModelId) {
            return L10n.ModelManager.Routing.decisionLocal
        } else {
            return L10n.ModelManager.Routing.decisionAutoCloud
        }
    }

    // MARK: - 健康状态枚举

    private enum HealthStatus {
        case healthy
        case warning
        case error

        var color: Color {
            switch self {
            case .healthy:
                return .green
            case .warning:
                return .orange
            case .error:
                return .red
            }
        }
    }
}

// MARK: - 预览

#if DEBUG
#Preview {
    SmartRoutingView()
        .environmentObject(ThemeManager.shared)
}
#endif
