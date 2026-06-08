//
//  OnDevicePerformanceConfigView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：端侧大模型性能调优页，管理 NPU、运存、上下文等硬件运行参数。
//
import SwiftUI

@MainActor
struct OnDevicePerformanceConfigView: View {
    @Environment(LLMConfigManager.self) private var config
    @EnvironmentObject var themeManager: ThemeManager
    
    @AppStorage("onDevice_npuAcceleration") private var npuAcceleration: Bool = true
    @AppStorage("onDevice_ramAllocation") private var ramAllocation: Double = 5.6
    @AppStorage("onDevice_maxContext") private var maxContext: Double = 4096
    @AppStorage("onDevice_overheatProtection") private var overheatProtection: Bool = true
    
    var body: some View {
        @Bindable var config = config
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            Form {
                Section {
                    Toggle(L10n.Settings.OnDevice.npuAcceleration, isOn: $npuAcceleration)
                        .tint(.appAccent)
                } footer: {
                    Text(L10n.Settings.OnDevice.descNpu)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appListRowBackground()
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.Settings.OnDevice.ramAllocation)
                            Spacer()
                            Text("\(String(format: "%.1f", ramAllocation)) GB")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $ramAllocation, in: 2.0...16.0, step: 0.1)
                            .tint(.appAccent)
                    }
                } footer: {
                    Text(L10n.Settings.OnDevice.descRam)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appListRowBackground()
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.Settings.OnDevice.maxContext)
                            Spacer()
                            Text("\(Int(maxContext)) tokens")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $maxContext, in: 1024...8192, step: 1024)
                            .tint(.appAccent)
                    }
                } footer: {
                    Text(L10n.Settings.OnDevice.descContext)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appListRowBackground()
                
                Section {
                    Toggle(L10n.Settings.OnDevice.overheatProtection, isOn: $overheatProtection)
                        .tint(.appAccent)
                } footer: {
                    Text(L10n.Settings.OnDevice.descOverheat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appListRowBackground()

                Section {
                    Toggle(L10n.AI.OnDevice.enableAutoScan, isOn: $config.autoScan)
                        .tint(.appAccent)
                    
                    Toggle(L10n.AI.OnDevice.autoRefactor, isOn: $config.autoRefactor)
                        .tint(.appAccent)
                } header: {
                    Text(L10n.Settings.advancedMaintenance)
                } footer: {
                    Text(L10n.AI.OnDevice.assistDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .appListRowBackground()
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(L10n.Settings.OnDevice.performanceConfig)
        .navigationBarTitleDisplayMode(.inline)
    }
}
