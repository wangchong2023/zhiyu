//
//  DeveloperSettingsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 DeveloperSettings 界面的 UI 视图层组件。
//
import SwiftUI

struct DeveloperSettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(KnowledgeStore.self) var knowledgeStore
    @Environment(SettingsStore.self) var settingsStore
    @ObservedObject var onboardingService: OnboardingService
    
    @State private var showInjectConfirmation = false
    @State private var showResetOnboardingConfirmation = false
    @State private var showStressTestConfirmation = false
    @State private var stressTestTargetCount = 1000
    
    @State private var isStressTesting = false
    @State private var isInjecting = false
    @State private var stressTestCount: Int? = nil
    
    // ── 标签定义 ──
    enum DeveloperTab: String, CaseIterable {
        case data
        case quality
        
        var title: String {
            switch self {
            case .data: return L10n.Settings.Section.tabData
            case .quality: return L10n.Settings.Section.tabQuality
            }
        }
    }
    
    @State private var selectedTab: DeveloperTab = .data
    
    // RAG 评估数据
    @State private var evalStats: [String: Double] = [:]
    @State private var isLoadingStats = true
    
    var body: some View {
        List {
            // MARK: - Tab 切换
            Section {
                Picker("", selection: $selectedTab) {
                    ForEach(DeveloperTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, DesignSystem.small)
            }
            
            if selectedTab == .data {
                // MARK: - 数据注入 (Data Injection)
                Section {
                    Button(action: { showInjectConfirmation = true }) {
                        HStack {
                            Label(L10n.Settings.injectDemoData, systemImage: "testtube.2")
                            Spacer()
                            if isInjecting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isInjecting)
                    .alert(L10n.Settings.injectConfirm.title, isPresented: $showInjectConfirmation) {
                        Button(L10n.Common.confirm) {
                            Task {
                                isInjecting = true
                                let count = await store.generateDemoData()
                                isInjecting = false
                                
                                // 避开动画冲突
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                
                                HapticFeedback.shared.trigger(count > 0 ? .success : .error)
                                if count > 0 {
                                    ToastManager.shared.show(type: .success, message: L10n.Settings.InjectDemo.successMessage(count))
                                } else {
                                    ToastManager.shared.show(type: .error, message: L10n.Settings.InjectDemo.errorMessage)
                                }
                            }
                        }
                        Button(L10n.Common.cancel, role: .cancel) { }
                    } message: {
                        Text(L10n.Settings.injectConfirm.message)
                    }
                    
                } header: {
                    Text(L10n.Settings.developer.section.data)
                }
                .appListRowBackground()
                
                // MARK: - 数据重置 (Data Reset)
                Section {
                    Button(action: { showResetOnboardingConfirmation = true }) {
                        Label(L10n.Settings.resetOnboarding.label, systemImage: "arrow.triangle.2.circlepath")
                    }
                    .alert(L10n.Settings.resetOnboarding.title, isPresented: $showResetOnboardingConfirmation) {
                        Button(L10n.Common.confirm, role: .destructive) {
                            onboardingService.reset()
                            HapticFeedback.shared.trigger(.success)
                        }
                        Button(L10n.Common.cancel, role: .cancel) { }
                    } message: {
                        Text(L10n.Settings.resetOnboarding.message)
                    }
                } header: {
                    Text(L10n.Settings.developer.section.dataReset)
                }
                .appListRowBackground()

                // MARK: - 操作信息 (Operation Info)
                Section {
                    SettingsNavigationRow(icon: "clock.arrow.circlepath", title: L10n.Settings.operationLog, identifier: "settings.log") {
                        LogView()
                    }
                } header: {
                    Text(L10n.Settings.developer.section.operationInfo)
                }
                .appListRowBackground()
            } else {
                // MARK: - 性能测试 (Performance Testing)
                Section {
                    HStack {
                        Label(L10n.Settings.developer.stressTest.count, systemImage: "number.circle")
                        Spacer()
                        Picker("", selection: $stressTestTargetCount) {
                            Text("100").tag(100)
                            Text("500").tag(500)
                            Text("1000").tag(1000)
                            Text("5000").tag(5000)
                            Text("10000").tag(10000)
                        }
                        #if !os(watchOS)
                        .pickerStyle(.menu)
                        #endif
                    }
                    
                    Button(action: { showStressTestConfirmation = true }) {
                        HStack {
                            Label(L10n.Settings.developer.stressTest.run, systemImage: "gauge.with.dots.needle.bottom.100percent")
                            Spacer()
                            if isStressTesting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isStressTesting)
                } header: {
                    Text(L10n.Settings.developer.section.performance_test)
                } footer: {
                    if let count = stressTestCount {
                        Text(L10n.Settings.developer.stressTest.success(count))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .appListRowBackground()

                // MARK: - 性能监控面板入口
                Section {
                    Button {
                        store.showPerfDashboard = true
                    } label: {
                        HStack {
                            Label(L10n.Common.Perf.title, systemImage: "chart.bar.xaxis")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(L10n.Common.Perf.title)
                }
                .appListRowBackground()

                // MARK: - RAG 质量评估 (RAG Quality Evaluation)
                Section {
                    qualityGrid
                } header: {
                    Text(L10n.Dashboard.stats.benchmark)
                } footer: {
                    Text(L10n.Dashboard.benchmarkDescription)
                        .font(.caption)
                }
                .appListRowBackground()
            }
            }
            #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .blue))
            .navigationTitle(L10n.Settings.Section.developer)
            .navigationBarTitleDisplayMode(.inline)
            .appToast() // 确保在二级导航页面也能正确渲染 Toast，解决被遮挡问题
            .task {
                await loadStats()
            }
            .confirmationDialog(L10n.Settings.developer.stressTest.confirmTitle, isPresented: $showStressTestConfirmation, titleVisibility: .visible) {
                Button(L10n.Settings.developer.stressTest.confirmAction(stressTestTargetCount), role: .destructive) {
                    Task { await runStressTest(count: stressTestTargetCount) }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Settings.developer.stressTest.confirmMessage)
            }
        }

    private func runStressTest(count targetCount: Int) async {
        await MainActor.run { 
            self.stressTestTargetCount = targetCount
            self.isStressTesting = true 
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let count = (try? await DemoDataGenerator.generateStressTest(in: store.pageStore, count: targetCount)) ?? 0
        
        await MainActor.run {
            self.stressTestCount = count
            self.isStressTesting = false
            Task {
                await knowledgeStore.refresh()
                AppEventBus.shared.publish(.pagesCleared)
                await loadStats() // 压力测试后重新加载统计
            }
        }
    }
    
    private func loadStats() async {
        let governance = ServiceContainer.shared.resolve((any GovernanceRepository).self)
        do {
            let stats = try await governance.calculateAverageRAGScores(days: 30)
            await MainActor.run {
                self.evalStats = [
                    EvaluationMetric.faithfulness.rawValue: stats.faithfulness,
                    EvaluationMetric.relevance.rawValue: stats.relevance,
                    EvaluationMetric.precision.rawValue: stats.precision
                ]
                self.isLoadingStats = false
            }
        } catch {
            print("Failed to" + " load developer" + " stats: \(error)")
            await MainActor.run { self.isLoadingStats = false }
        }
    }
    
    // MARK: - UI Components
    
    private var qualityGrid: some View {
        HStack(spacing: DesignSystem.standardPadding) {
            metricCard(title: L10n.Dashboard.stats.faithfulness, value: evalStats[EvaluationMetric.faithfulness.rawValue] ?? 0, icon: "checkmark.shield", color: .appAccent)
            metricCard(title: L10n.Dashboard.stats.relevance, value: evalStats[EvaluationMetric.relevance.rawValue] ?? 0, icon: "target", color: .appAccent)
            metricCard(title: L10n.Dashboard.stats.precision, value: evalStats[EvaluationMetric.precision.rawValue] ?? 0, icon: "scope", color: .appAccent)
        }
        .padding(.vertical, DesignSystem.small)
    }

    private func metricCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(DesignSystem.Opacity.glass))
                        .frame(width: DesignSystem.smallIconSize + 12, height: DesignSystem.smallIconSize + 12)
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.captionFontSize, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
            }
        }
        .padding(DesignSystem.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appMetricCardStyle(color: color)
        .appStandardShadow()
    }
}
