// DeveloperSettingsView.swift
//
// 作者: Wang Chong
// 功能说明: 开发者设置页面，提供演示数据注入、压力测试、状态重置及性能调试工具。
// 核心原则：
// 1. 分门别类：将开发者工具按功能（数据、系统、性能）进行逻辑分组。
// 2. 安全性：该页面仅在 DEBUG 模式下可见，涉及破坏性操作时需二次确认。
// 修改记录:
//   - 2026-05-08: 从 SettingsView 与 SystemStatsView 整合开发者工具，创建分级菜单。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct DeveloperSettingsView: View {
    @Environment(AppStore.self) var store
    @Environment(SettingsStore.self) var settingsStore
    @ObservedObject var onboardingService: OnboardingService
    
    @State private var showInjectConfirmation = false
    @State private var showClearAllConfirmation = false
    @State private var showResetOnboardingConfirmation = false
    @State private var showStressTestConfirmation = false
    @State private var stressTestTargetCount = 1000
    
    @State private var isStressTesting = false
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
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, AppUI.small)
            }
            
            if selectedTab == .data {
                // MARK: - 数据注入 (Data Injection)
                Section {
                    Button(action: { showInjectConfirmation = true }) {
                        Label(L10n.Settings.tr("injectDemoData"), systemImage: "testtube.2")
                    }
                    .alert(L10n.Settings.tr("injectConfirm.title"), isPresented: $showInjectConfirmation) {
                        Button(L10n.Common.tr("confirm")) {
                            let count = store.generateDemoData()
                            HapticFeedback.shared.trigger(count > 0 ? .success : .error)
                            if count > 0 {
                                ToastManager.shared.show(type: .success, message: L10n.Settings.trf("injectDemo.successMessage", count))
                            }
                        }
                        Button(L10n.Common.tr("cancel"), role: .cancel) { }
                    } message: {
                        Text(L10n.Settings.tr("injectConfirm.message"))
                    }
                    
                } header: {
                    Text(L10n.Settings.tr("developer.section.data"))
                }
                
                // MARK: - 数据重置 (Data Reset)
                Section {
                    Button(action: { showResetOnboardingConfirmation = true }) {
                        Label(L10n.Settings.tr("resetOnboarding"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .alert(L10n.Settings.tr("resetOnboarding.title"), isPresented: $showResetOnboardingConfirmation) {
                        Button(L10n.Common.tr("confirm"), role: .destructive) {
                            onboardingService.reset()
                            HapticFeedback.shared.trigger(.success)
                        }
                        Button(L10n.Common.tr("cancel"), role: .cancel) { }
                    } message: {
                        Text(L10n.Settings.tr("resetOnboarding.message"))
                    }
                    
                    Button(role: .destructive, action: { showClearAllConfirmation = true }) {
                        Label(L10n.Settings.tr("clearAll"), systemImage: "trash.slash.fill")
                    }
                    .confirmationDialog(L10n.Settings.tr("clearAll.confirmTitle"), isPresented: $showClearAllConfirmation, titleVisibility: .visible) {
                        Button(L10n.Settings.tr("clearAll.action"), role: .destructive) {
                            store.clearAllDeveloperData()
                            HapticFeedback.shared.trigger(.success)
                        }
                        Button(L10n.Common.tr("cancel"), role: .cancel) { }
                    } message: {
                        Text(L10n.Settings.tr("clearAll.message"))
                    }
                } header: {
                    Text(L10n.Settings.tr("developer.section.dataReset"))
                }

                // MARK: - 操作信息 (Operation Info)
                Section {
                    SettingsNavigationRow(icon: "clock.arrow.circlepath", title: L10n.Settings.operationLog, identifier: "settings.log") {
                        LogView()
                    }
                } header: {
                    Text(L10n.Settings.tr("developer.section.operationInfo"))
                }
            } else {
                // MARK: - 性能测试 (Performance Testing)
                Section {
                    HStack {
                        Label(L10n.Settings.tr("developer.stressTest.count"), systemImage: "number.circle")
                        Spacer()
                        Picker("", selection: $stressTestTargetCount) {
                            Text("100").tag(100)
                            Text("500").tag(500)
                            Text("1000").tag(1000)
                            Text("5000").tag(5000)
                            Text("10000").tag(10000)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: { showStressTestConfirmation = true }) {
                        HStack {
                            Label(L10n.Settings.tr("developer.stressTest.run"), systemImage: "gauge.with.dots.needle.bottom.100percent")
                            Spacer()
                            if isStressTesting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isStressTesting)
                } header: {
                    Text(L10n.Settings.tr("developer.section.performance_test"))
                } footer: {
                    if let count = stressTestCount {
                        Text(L10n.Settings.trf("developer.stressTest.success", count))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // MARK: - RAG 质量评估 (RAG Quality Evaluation)
                Section {
                    qualityGrid
                } header: {
                    Text(L10n.Dashboard.tr("stats.benchmark"))
                } footer: {
                    Text(L10n.Dashboard.benchmarkDescription)
                        .font(.caption)
                }
            }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .listRowBackground(Color.appCard.opacity(0.8))
            .scrollContentBackground(.hidden)
            .background(AppUI.Background.pageBackground(accentColor: .blue))
            .navigationTitle(L10n.Settings.tr("section.developer"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadStats()
            }
            .confirmationDialog(L10n.Settings.tr("developer.stressTest.confirmTitle"), isPresented: $showStressTestConfirmation, titleVisibility: .visible) {
                Button(L10n.Settings.trf("developer.stressTest.confirmAction", stressTestTargetCount), role: .destructive) {
                    Task { await runStressTest(count: stressTestTargetCount) }
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) {}
            } message: {
                Text(L10n.Settings.tr("developer.stressTest.confirmMessage"))
            }
        }

    private func runStressTest(count targetCount: Int) async {
        await MainActor.run { 
            self.stressTestTargetCount = targetCount
            self.isStressTesting = true 
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 假设 store 有 generateStressTest 方法，或者直接调用 DemoDataGenerator
        // 根据之前的 SystemStatsView.swift，它是调用 DemoDataGenerator
        let count = DemoDataGenerator.generateStressTest(in: store.sqliteStore, count: targetCount)
        
        await MainActor.run {
            self.stressTestCount = count
            self.isStressTesting = false
            store.refresh()
            AppEventBus.shared.publish(.pagesCleared)
            Task { await loadStats() } // 压力测试后重新加载统计
        }
    }
    
    private func loadStats() async {
        let pageStore = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        do {
            let stats = try pageStore.fetchEvaluationStats()
            await MainActor.run {
                self.evalStats = stats
                self.isLoadingStats = false
            }
        } catch {
            print("Failed to load developer stats: \(error)")
            await MainActor.run { self.isLoadingStats = false }
        }
    }
    
    // MARK: - UI Components
    
    private var qualityGrid: some View {
        HStack(spacing: AppUI.standardPadding) {
            metricCard(title: L10n.Dashboard.tr("stats.faithfulness"), value: evalStats[EvaluationMetric.faithfulness.rawValue] ?? 0, icon: "checkmark.shield", color: .appAccent)
            metricCard(title: L10n.Dashboard.tr("stats.relevance"), value: evalStats[EvaluationMetric.relevance.rawValue] ?? 0, icon: "target", color: .appAccent)
            metricCard(title: L10n.Dashboard.tr("stats.precision"), value: evalStats[EvaluationMetric.precision.rawValue] ?? 0, icon: "scope", color: .appAccent)
        }
        .padding(.vertical, AppUI.small)
    }

    private func metricCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appMetricCardStyle(color: color)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
