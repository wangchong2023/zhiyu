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
    
    var body: some View {
        List {
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
            
            // MARK: - 状态与重置 (State & Reset)
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
                Text(L10n.Settings.tr("developer.section.system"))
            }
        }
        .navigationTitle(L10n.Settings.tr("section.developer"))
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
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
        }
    }
}
