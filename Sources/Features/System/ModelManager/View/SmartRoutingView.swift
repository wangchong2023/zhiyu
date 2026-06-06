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

/// 大模型策略配置视图
@MainActor
public struct SmartRoutingView: View {

    @StateObject private var themeManager = ThemeManager.shared
    @State private var modelManager = GlobalModelManager()

    public init() {}

    public var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.large) {
                    modelStrategySection
                    taskRoutingSection
                    runtimeStatusSection
                }
                .padding(DesignSystem.medium)
            }
        }
        .navigationTitle(L10n.Settings.smartRouting)
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - 大模型策略

    private var modelStrategySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.modelStrategy)
                .font(.headline).foregroundStyle(.appText)

            // 端云混合开关
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(L10n.ModelManager.Routing.cloudEscalationToggle)
                        .font(.subheadline).foregroundStyle(.appText)
                    Text(L10n.ModelManager.Routing.cloudEscalationDesc)
                        .font(.caption2).foregroundStyle(.appSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { modelManager.isCloudEscalationEnabled },
                    set: { modelManager.isCloudEscalationEnabled = $0 })).labelsHidden()
            }

            Divider()

            // 高级选项
            Toggle(L10n.ModelManager.Routing.wifiOnly, isOn: .constant(false)).font(.subheadline)
            Toggle(L10n.ModelManager.Routing.autoFallback, isOn: .constant(true)).font(.subheadline)
            Toggle(L10n.ModelManager.Routing.preferLocal, isOn: .constant(true)).font(.subheadline)
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    // MARK: - 任务路由

    private var taskRoutingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.taskRules)
                .font(.headline).foregroundStyle(.appText)
            VStack(spacing: DesignSystem.small) {
                routingRuleRow(icon: "lock.fill", iconColor: .red, task: L10n.ModelManager.Routing.taskSemanticChunking, rule: L10n.ModelManager.Routing.strategyForceLocal)
                routingRuleRow(icon: "lock.fill", iconColor: .red, task: L10n.ModelManager.Routing.taskLinkDiscovery, rule: L10n.ModelManager.Routing.strategyForceLocal)
                routingRuleRow(icon: "arrow.triangle.branch", iconColor: .blue, task: L10n.ModelManager.Routing.taskSynthesis, rule: L10n.ModelManager.Routing.strategySmartRouting)
                routingRuleRow(icon: "arrow.triangle.branch", iconColor: .blue, task: L10n.ModelManager.Routing.taskChat, rule: L10n.ModelManager.Routing.strategySmartRouting)
                routingRuleRow(icon: "arrow.triangle.branch", iconColor: .blue, task: L10n.ModelManager.Routing.taskTagGeneration, rule: L10n.ModelManager.Routing.strategySmartRouting)
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    // MARK: - 运行状态

    private var runtimeStatusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.ModelManager.Routing.runtimeStatus)
                .font(.headline).foregroundStyle(.appText)

            VStack(spacing: DesignSystem.small) {
                // 本地模型
                statusRow(label: L10n.ModelManager.Routing.localModelReady,
                    value: getActiveModelName(),
                    status: modelManager.isModelLocalReady(for: modelManager.activeModelId) ? .healthy : .warning)
                // 当前决策
                HStack {
                    Image(systemName: "cpu").foregroundStyle(.appAccent).frame(width: DesignSystem.titleIconSize)
                    Text(L10n.ModelManager.Routing.currentDecision).font(.subheadline).foregroundStyle(.appText)
                    Spacer()
                    Text(getCurrentRoutingDecision()).font(.caption.weight(.bold)).foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.small).padding(.vertical, DesignSystem.atomic)
                        .background(Color.appAccent.opacity(0.15)).clipShape(Capsule())
                }
                Divider()
                // 网络
                statusRow(label: L10n.ModelManager.Routing.networkCurrent, value: "WiFi", status: .healthy)
                statusRow(label: L10n.ModelManager.Routing.networkLatency, value: "23ms", status: .healthy)
                statusRow(label: L10n.ModelManager.Routing.networkBandwidth, value: L10n.ModelManager.Routing.networkBandwidthExcellent, status: .healthy)
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
    }

    // MARK: - 子视图组件

    private func routingRuleRow(icon: String, iconColor: Color, task: String, rule: String) -> some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon).font(.caption).foregroundStyle(iconColor).frame(width: DesignSystem.titleIconSize)
            Text(task).font(.subheadline).foregroundStyle(.appText)
            Spacer()
            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.appSecondary)
            Text(rule).font(.caption.weight(.medium)).foregroundStyle(.appAccent)
        }
        .padding(.vertical, DesignSystem.small).padding(.horizontal, DesignSystem.medium)
        .background(Color.appBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    private func statusRow(label: String, value: String, status: HealthStatus) -> some View {
        HStack {
            Circle().fill(status.color).frame(width: DesignSystem.iconSmall, height: DesignSystem.iconSmall)
            Text(label).font(.subheadline).foregroundStyle(.appText)
            Spacer()
            Text(value).font(.caption.weight(.medium)).foregroundStyle(.appSecondary)
        }
    }

    private func getActiveModelName() -> String {
        if let m = modelManager.remoteManifests.first(where: { $0.modelId == modelManager.activeModelId }) {
            return m.displayName
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
