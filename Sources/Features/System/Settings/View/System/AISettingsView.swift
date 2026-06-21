//
//  AISettingsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/21.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建统一的 AI 大模型设置面板（AISettingsView），聚合在线模型、本地模型、智能路由和提示词设置。
//

import SwiftUI

/// 统一的 AI 大模型配置面板视图
@MainActor
struct AISettingsView: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text(L10n.Settings.smartRouting).tag(0)
                    Text(L10n.Settings.llmSettings).tag(1)
                    Text(L10n.Settings.localModelManager).tag(2)
                    Text(L10n.Settings.promptSettings).tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    switch selectedTab {
                    case 0: SmartRoutingView()
                    case 1: LLMSettingsView()
                    case 2: LocalModelManagerView()
                    case 3: PromptWorkshopView()
                    default: EmptyView()
                    }
                }
                .id(selectedTab)
            }
        }
        .navigationTitle(L10n.Settings.Section.ai)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) {
                    dismiss()
                }
                .bold()
            }
        }
    }
}
