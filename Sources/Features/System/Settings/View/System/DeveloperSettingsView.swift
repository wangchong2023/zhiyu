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
    @State private var showInjectConfirmation = false
    @State private var showStressTestConfirmation = false
    @State private var stressTestTargetCount = 1000
    
    @State private var isStressTesting = false
    @State private var isInjecting = false
    @State private var stressTestCount: Int? = nil

    var body: some View {
        List {
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

            // MARK: - 性能测试 (Performance Testing)
            Section {
                Picker(selection: $stressTestTargetCount) {
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("5000").tag(5000)
                    Text("10000").tag(10000)
                } label: {
                    Label(L10n.Settings.developer.stressTest.count, systemImage: "number.circle")
                }

                Button(action: { showStressTestConfirmation = true }) {
                    HStack {
                        Label(L10n.Settings.developer.stressTest.run, systemImage: "gauge.with.dots.needle.bottom.100percent")
                        Spacer()
                        Text(L10n.Settings.developer.stressTest.nodes(stressTestTargetCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

            // MARK: - 质量评估
            Section {
                NavigationLink {
                    RAGEvaluationView()
                } label: {
                    Label(L10n.Dashboard.stats.benchmark, systemImage: "checkmark.shield")
                }

                NavigationLink {
                    PerformanceDashboardView(service: store.performanceService)
                } label: {
                    Label(L10n.Common.Perf.title, systemImage: "chart.bar.xaxis")
                }
            } header: {
                Text(L10n.Dashboard.stats.evaluation)
            }
            .appListRowBackground()
        }
            #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .blue))
            .navigationTitle(L10n.Settings.Section.developer)
            .navigationBarTitleDisplayMode(.inline)
            .appToast() // 确保在二级导航页面也能正确渲染 Toast，解决被遮挡问题
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

        // 确保两个默认演示笔记本存在，不存在则创建
        let vaultService = ServiceContainer.shared.resolve(VaultService.self)
        let demoVaultNames = [L10n.Vault.defaultName, L10n.Vault.researchName]
        for name in demoVaultNames {
            if !vaultService.vaults.contains(where: { $0.name == name }) {
                vaultService.createVault(name: name)
            }
        }

        // 对两个默认笔记本注入压力测试数据
        var totalCount = 0
        for vault in vaultService.vaults where demoVaultNames.contains(vault.name) {
            do {
                try await vaultService.selectVaultAndWait(vault)
                let count = (try? await DemoDataGenerator.generateStressTest(in: store.pageStore, count: targetCount)) ?? 0
                totalCount += count
            } catch {
                // 数据库切换失败时跳过该笔记本
            }
        }

        await MainActor.run {
            self.stressTestCount = totalCount
            self.isStressTesting = false
            Task {
                await knowledgeStore.refresh()
                AppEventBus.shared.publish(.pagesCleared)            }
        }
    }
    


}
