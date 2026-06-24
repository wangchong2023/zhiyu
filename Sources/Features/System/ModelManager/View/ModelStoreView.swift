//
//  ModelStoreView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层 / 视图组件
//  核心职责：大模型市场容器视图 — 持有 @State 状态树，编排列表展示与导航。
//
import SwiftUI

/// 动态端侧大模型市场面板视图
@MainActor
public struct ModelStoreView: View {

    // MARK: - 注入环境与中台

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @EnvironmentObject private var themeManager: ThemeManager

    /// 全局大模型市场中台管理器
    @State private var modelManager = GlobalModelManager.shared

    /// 进入测试实验室的回调
    public var onGoToLab: () -> Void

    // MARK: - 局部视图状态

    /// 触发警告弹窗的模型元数据
    @State private var alertManifest: LLMManifest?
    /// 展开详情的模型 ID
    @State private var expandedModelId: String?

    public init(onGoToLab: @escaping () -> Void) {
        self.onGoToLab = onGoToLab
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.medium) {
                        ForEach(modelManager.remoteManifests) { manifest in
                            ModelCardView(
                                manifest: manifest,
                                modelManager: modelManager,
                                alertManifest: $alertManifest,
                                expandedModelId: $expandedModelId,
                                onGoToLab: onGoToLab
                            )
                        }
                    }
                    .padding(DesignSystem.medium)
                }
                .task {
                    await modelManager.reload()
                }
                .refreshable {
                    await modelManager.reload()
                }
            }
        }
        .navigationTitle(L10n.Settings.localModelManager)
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert(item: $alertManifest) { manifest in
            Alert(
                title: Text(" "),
                message: Text("\(manifest.displayName) \(String(format: "%.1f", manifest.minDeviceMemoryInGb)) GB \n\n\(String(format: "%.1f", Double(modelManager.physicalMemory) / (1024 * 1024 * 1024)))_GB_OOM"),
                dismissButton: .default(Text(""))
            )
        }
    }
}
