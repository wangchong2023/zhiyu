//
//  ModelStoreView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层 / 视图组件
//  核心职责：构建大模型商店（ModelStoreView）的 UI 视图。支持「我的模型」与「模型商店」分段切换、物理运存护栏视觉拦截与动态下载进度交互。
//

import SwiftUI

/// 动态端侧大模型商店面板视图
@MainActor
public struct ModelStoreView: View {
    
    // MARK: - 注入环境与中台
    
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @EnvironmentObject private var themeManager: ThemeManager
    
    /// 全局大模型商店中台管理器
    @State private var modelManager = GlobalModelManager()
    
    // MARK: - 局部视图状态

    /// 触发警告弹窗的模型元数据
    @State private var alertManifest: LLMManifest?
    /// 展开详情的模型 ID（参照 Gallery Model Spec Sheet）
    @State private var expandedModelId: String?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 物理设备运存信息看板
                deviceHardwareHeader

                // 2. 模型列表展示区
                ScrollView {
                    LazyVStack(spacing: DesignSystem.medium) {
                        ForEach(modelManager.remoteManifests) { manifest in
                            modelCard(for: manifest)
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
    
    // MARK: - 子视图组件
    
    /// 顶部设备摘要卡片（内存 + 模型数量）
    private var deviceHardwareHeader: some View {
        let memInGb = Double(modelManager.physicalMemory) / (1024 * 1024 * 1024)
        let modelCount = modelManager.remoteManifests.count

        return HStack(spacing: DesignSystem.standardPadding) {
            // 设备内存
            summaryItem(
                icon: "memorychip", iconColor: .blue,
                value: String(format: "%.0f GB", memInGb),
                label: L10n.ModelManager.Spec.memory
            )
            // 分隔
            Rectangle().frame(width: DesignSystem.borderWidth, height: DesignSystem.huge).foregroundStyle(Color.appBorder.opacity(DesignSystem.glassOpacity))
            // 可用模型数
            summaryItem(
                icon: "square.stack.3d.up", iconColor: .appAccent,
                value: "\(modelCount)",
                label: L10n.ModelManager.Header.availableModels
            )
        }
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.medium)
        .frame(maxWidth: .infinity)
        .background(Color.appCard.opacity(DesignSystem.Opacity.disabled))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .padding(.horizontal, DesignSystem.medium)
        .padding(.top, DesignSystem.small)
    }

    /// 摘要条目
    private func summaryItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: DesignSystem.small) {
            Image(systemName: icon)
                .font(.title3).foregroundStyle(iconColor)
                .frame(width: DesignSystem.titleIconSize)
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(.appText)
                Text(label).font(.caption2).foregroundStyle(.appSecondary)
            }
            Spacer()
        }
    }
    
    /// 大模型卡片渲染逻辑
    /// 大模型卡片渲染逻辑
    private func modelCard(for manifest: LLMManifest) -> some View {
        ModelCardView(
            manifest: manifest,
            modelManager: modelManager,
            alertManifest: $alertManifest,
            expandedModelId: $expandedModelId
        )
    }
}

// MARK: - 大模型卡片组件

/// 动态大模型卡片视图组件，承载模型的展示与下载/激活逻辑
private struct ModelCardView: View {
    /// 模型元数据清单
    let manifest: LLMManifest
    
    /// 全局大模型中台管理器
    let modelManager: GlobalModelManager
    
    /// 警告弹窗的绑定值
    @Binding var alertManifest: LLMManifest?
    
    /// 展开状态下的模型 ID
    @Binding var expandedModelId: String?
    
    var body: some View {
        let isSelected = modelManager.activeModelId == manifest.modelId
        let eligibility = modelManager.evaluateEligibility(for: manifest)
        let downloadState = modelManager.downloadStates[manifest.modelId] ?? .failed(error: "Not Downloaded")
        let isLocalReady = modelManager.isModelLocalReady(for: manifest.modelId)
        
        // 卡片背景：复用项目设计令牌，浅色/深色自动适配
        let cardBackground = Color.appCard.opacity(eligibility == .restricted ? 0.4 : 0.8)
        let borderColor = isSelected ? Color.appAccent : (eligibility == .restricted ? Color.theme.red.opacity(DesignSystem.Opacity.disabled) : Color.appBorder.opacity(DesignSystem.Opacity.prominent))
        let shadowColor = isSelected ? Color.appAccent.opacity(DesignSystem.Opacity.medium) : Color.theme.black.opacity(DesignSystem.Opacity.ghost)
        
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DesignSystem.small) {
                // 头部：标题与状态标签
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DesignSystem.small) {
                            Text(manifest.displayName)
                                .font(.headline)
                                .foregroundStyle(eligibility == .restricted ? .appSecondary : .appText)
                            
                            Text(manifest.parameterCount)
                                .font(.system(size: 10, weight: .bold, design: .monospaced)) // Dynamic Type
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appAccent.opacity(DesignSystem.Opacity.glass))
                                .clipShape(Capsule())
                                .foregroundStyle(.appAccent)
                        }
                        
                        Text("\(manifest.vendor)    \(formattedSize(manifest.fileSizeInBytes))")
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    Spacer()
                    
                    // 绿盾/就绪标签
                    if isLocalReady {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("")
                        }
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                    }
                }
                
                // 说明文案
                Text(manifest.description)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(2)
                
                // 场景能力标签 (Chips) — 从 Mock/API 数据动态生成
                if !manifest.supportedTasks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.tiny) {
                            ForEach(manifest.supportedTasks, id: \.self) { task in
                                Text(taskLabel(for: task))
                                    .font(.system(size: DesignSystem.microFontSize, weight: .medium))
                                    .padding(.horizontal, DesignSystem.small)
                                    .padding(.vertical, DesignSystem.atomic)
                                    .background(taskColor(for: task).opacity(DesignSystem.Opacity.subtle))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.chipRadius))
                                    .foregroundStyle(taskColor(for: task))
                            }
                        }
                    }
                    .padding(.vertical, DesignSystem.atomic)
                }
                
                // 硬件防爆护栏层
                if eligibility == .restricted {
                    restrictedBanner(for: manifest)
                } else if eligibility == .warning {
                    warningBanner
                }
                
                Divider()
                    .foregroundStyle(Color.appBorder.opacity(DesignSystem.Opacity.soft))
                
                // 底部下载/激活状态交互组
                HStack {
                    downloadStatusBar(for: manifest, state: downloadState)
                    
                    Spacer()
                    
                    actionButton(for: manifest, eligibility: eligibility, isSelected: isSelected, isLocalReady: isLocalReady, state: downloadState)
                }
            }
            .padding()
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedModelId = (expandedModelId == manifest.modelId) ? nil : manifest.modelId
                }
            }

            // 展开的 Model Spec Sheet（参照 Gallery Model Management）
            if expandedModelId == manifest.modelId {
                modelSpecSheet(for: manifest)
            }
        }
    }
    
    // MARK: - Model Spec Sheet（参照 Gallery）

    @ViewBuilder
    private func modelSpecSheet(for manifest: LLMManifest) -> some View {
        let specBg = Color.appCard.opacity(DesignSystem.Opacity.dim)
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Divider().foregroundStyle(Color.appBorder.opacity(DesignSystem.Opacity.soft))

            // 完整描述
            Text(manifest.description)
                .font(.subheadline).foregroundStyle(.appText).fixedSize(horizontal: false, vertical: true)

            // 规格网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.small) {
                specItem(icon: "cpu", label: L10n.ModelManager.Spec.memory, value: String(format: "%.0f GB", manifest.minDeviceMemoryInGb))
                specItem(icon: "arrow.down.doc", label: L10n.ModelManager.Spec.downloadSize, value: formattedSize(manifest.fileSizeInBytes))
                specItem(icon: "square.3.layers.3d", label: L10n.ModelManager.Spec.parameters, value: manifest.parameterCount)
                specItem(icon: "number", label: L10n.ModelManager.Spec.checksum, value: String(manifest.sha256Checksum.prefix(12)) + "...")
            }

            // 支持的任务
            if !manifest.supportedTasks.isEmpty {
                HStack(spacing: DesignSystem.tiny) {
                    Text(L10n.ModelManager.Spec.tasks).font(.caption).foregroundStyle(.appSecondary)
                    ForEach(manifest.supportedTasks, id: \.self) { t in
                        Text(taskLabel(for: t)).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(taskColor(for: t).opacity(DesignSystem.Opacity.subtle)).clipShape(Capsule())
                            .foregroundStyle(taskColor(for: t))
                    }
                }
            }
        }
        .padding(DesignSystem.medium)
        .background(specBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func specItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.appAccent).frame(width: DesignSystem.IconSize.micro)
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(.appText)
                Text(label).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
            }
        }
        .padding(DesignSystem.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground.opacity(DesignSystem.Opacity.shadow))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }
    
    // MARK: - 状态子栏与操作按钮
    
    /// 下载进度与状态文案提示
    @ViewBuilder
    private func downloadStatusBar(for manifest: LLMManifest, state: DownloadState) -> some View {
        switch state {
        case .pending:
            Text("...")
                .font(.caption.italic())
                .foregroundStyle(.appSecondary)
        case .downloading(let progress):
            HStack(spacing: DesignSystem.small) {
                ProgressView(value: progress, total: 1.0)
                    .tint(.appAccent)
                    .frame(width: DesignSystem.Metrics.indicatorSize)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced)) // Dynamic Type
                    .foregroundStyle(.appAccent)
            }
        case .paused:
            Text("")
                .font(.caption)
                .foregroundStyle(.orange)
        case .verifying:
            HStack(spacing: DesignSystem.small) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("...")
                    .font(.caption.bold())
                    .foregroundStyle(.appAccent)
            }
        case .completed:
            EmptyView()
        case .failed(let error):
            if error != "Not Downloaded" && error != "Cancelled" {
                Text(": \(error)")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                EmptyView()
            }
        }
    }
    
    /// 操作按钮（激活、下载、暂停、恢复）
    @ViewBuilder
    private func actionButton(for manifest: LLMManifest, eligibility: DeviceEligibility, isSelected: Bool, isLocalReady: Bool, state: DownloadState) -> some View {
        if eligibility == .restricted {
            restrictedActionButton(for: manifest)
        } else if isLocalReady {
            activeActionButton(for: manifest, isSelected: isSelected)
        } else {
            downloadActionButton(for: manifest, state: state)
        }
    }

    /// 渲染因硬件限制而被拦截的下载按钮
    /// - Parameter manifest: 模型元数据
    /// - Returns: 物理内存限制时的警告警告按钮视图
    private func restrictedActionButton(for manifest: LLMManifest) -> some View {
        Button(action: { alertManifest = manifest }) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.octagon.fill")
                Text("")
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.theme.red.opacity(DesignSystem.Opacity.glass))
            .foregroundStyle(.red)
            .clipShape(Capsule())
        }
    }

    /// 渲染已就绪模型的激活与选中切换按钮
    /// - Parameters:
    ///   - manifest: 模型元数据
    ///   - isSelected: 是否为当前处于活跃状态的模型
    /// - Returns: 激活切换按钮视图
    private func activeActionButton(for manifest: LLMManifest, isSelected: Bool) -> some View {
        Button(action: {
            withAnimation {
                modelManager.activeModelId = manifest.modelId
            }
        }) {
            Text(isSelected ? "" : "")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appAccent : Color.appBackground)
                .foregroundStyle(isSelected ? .white : .appAccent)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.appAccent, lineWidth: isSelected ? 0 : 1)
                )
        }
    }

    /// 渲染处于未下载、下载中或已暂停等各状态下的功能按钮组合
    /// - Parameters:
    ///   - manifest: 模型元数据
    ///   - state: 当前模型文件的下载状态
    /// - Returns: 下载及控制按钮组视图
    private func downloadActionButton(for manifest: LLMManifest, state: DownloadState) -> some View {
        switch state {
        case .pending, .downloading:
            return AnyView(
                Button(action: { modelManager.pauseDownload(for: manifest.modelId) }) {
                    Image(systemName: "pause.fill")
                        .font(.caption)
                        .padding(DesignSystem.small)
                        .background(Color.appBackground)
                        .foregroundStyle(.orange)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.orange, lineWidth: 1))
                }
            )
        case .paused:
            return AnyView(
                HStack(spacing: DesignSystem.small) {
                    Button(action: { modelManager.cancelDownload(for: manifest.modelId) }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .padding(DesignSystem.small)
                            .background(Color.appBackground)
                            .foregroundStyle(.appSecondary)
                            .clipShape(Circle())
                    }
                    Button(action: { modelManager.resumeDownload(for: manifest.modelId) }) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .padding(DesignSystem.small)
                            .background(Color.appAccent)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                }
            )
        default:
            return AnyView(
                Button(action: {
                    Logger.shared.info(" [ModelStore] Download tapped for \(manifest.modelId)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "icloud.and.arrow.down")
                        Text("")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.appAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            )
        }
    }
    
    // MARK: - Banner 信息条
    
    /// 强物理内存拦截红条
    private func restrictedBanner(for manifest: LLMManifest) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(" \(String(format: "%.1f", manifest.minDeviceMemoryInGb)) GB  OOM")
                .font(.system(size: 10)) // Dynamic Type
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(DesignSystem.tightPadding)
        .background(Color.theme.red.opacity(DesignSystem.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.Chip.cornerRadius))
    }
    
    /// 临界运存警告黄条
    private var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("")
                .font(.system(size: 10)) // Dynamic Type
                .foregroundStyle(.orange)
            Spacer()
        }
        .padding(DesignSystem.tightPadding)
        .background(Color.theme.orange.opacity(DesignSystem.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.Chip.cornerRadius))
    }
    
    // MARK: - 辅助计算
    
    /// 格式化大小
    private func formattedSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    // MARK: - 任务标签（参照 Gallery taskTypes）

    private func taskLabel(for task: String) -> String {
        switch task {
        case "chat": return L10n.ModelManager.Task.chat
        case "completion": return L10n.ModelManager.Task.completion
        case "reasoning": return L10n.ModelManager.Task.reasoning
        case "code": return L10n.ModelManager.Task.code
        case "rag": return L10n.ModelManager.Task.rag
        case "translation": return L10n.ModelManager.Task.translation
        default: return task
        }
    }

    private func taskColor(for task: String) -> Color {
        switch task {
        case "chat": return .blue
        case "completion": return .green
        case "reasoning": return .purple
        case "code": return .orange
        case "rag": return .pink
        case "translation": return .teal
        default: return .appSecondary
        }
    }
}
