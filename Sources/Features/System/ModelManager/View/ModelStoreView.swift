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
    
    /// 分段器当前选中的 Tab (0: 我的模型, 1: 模型商店)
    @State private var selectedTab = 0
    
    /// 触发警告弹窗的模型元数据
    @State private var alertManifest: LLMManifest?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 物理设备运存信息看板
                deviceHardwareHeader
                
                // 2. 「我的模型」与「模型商店」中枢分段器
                segmentedPicker
                
                // 3. 模型列表展示区
                ScrollView {
                    LazyVStack(spacing: DesignSystem.medium) {
                        if selectedTab == 0 {
                            // 我的模型：仅展示已下载并就绪的模型
                            let localModels = modelManager.remoteManifests.filter { modelManager.isModelLocalReady(for: $0.modelId) }
                            if localModels.isEmpty {
                                emptyStateView(
                                    title: "",
                                    subtitle: " Gemma-2B",
                                    icon: "arrow.down.circle.dotted"
                                )
                            } else {
                                ForEach(localModels) { manifest in
                                    modelCard(for: manifest)
                                }
                            }
                        } else {
                            // 模型商店：展示所有白名单模型
                            ForEach(modelManager.remoteManifests) { manifest in
                                modelCard(for: manifest)
                            }
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
        .navigationTitle("AI ")
        #if !os(watchOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // 右上角齿轮跳转云端 API 密匙高级配置
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.appAccent)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .alert(item: $alertManifest) { manifest in
            Alert(
                title: Text(" "),
                message: Text("\(manifest.displayName) \(String(format: "%.1f", manifest.minDeviceMemoryInGb)) GB \n\n\(String(format: "%.1f", Double(modelManager.physicalMemory) / (1024 * 1024 * 1024)))_GB_OOM"),
                dismissButton: .default(Text(""))
            )
        }
    }
    
    // MARK: - 子视图组件
    
    /// 顶部物理设备运存信息看板
    private var deviceHardwareHeader: some View {
        let memInGb = Double(modelManager.physicalMemory) / (1024 * 1024 * 1024)
        return HStack(spacing: DesignSystem.small) {
            Image(systemName: "cpu")
                .foregroundStyle(.appAccent)
                .font(.system(size: 18, weight: .bold))
                .shadow(color: .appAccent.opacity(0.4), radius: 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(": \(String(format: "%.1f", memInGb)) GB")
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                
                Text(" ")
                    .font(.system(size: 10))
                    .foregroundStyle(.appSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.appCard.opacity(0.6))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.appBorder.opacity(0.6)),
            alignment: .bottom
        )
    }
    
    /// 中枢分段器
    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { selectedTab = 0 } }) {
                VStack(spacing: 6) {
                    Text("")
                        .font(.subheadline.bold())
                        .foregroundStyle(selectedTab == 0 ? .appAccent : .appSecondary)
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(selectedTab == 0 ? .appAccent : .clear)
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { withAnimation { selectedTab = 1 } }) {
                VStack(spacing: 6) {
                    Text("")
                        .font(.subheadline.bold())
                        .foregroundStyle(selectedTab == 1 ? .appAccent : .appSecondary)
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(selectedTab == 1 ? .appAccent : .clear)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 12)
        .background(Color.appCard.opacity(0.4))
    }
    
    /// 空状态占位视图
    private func emptyStateView(title: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: DesignSystem.medium) {
            Spacer().frame(height: 40)
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.appSecondary.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.appText)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding(.vertical, 40)
    }
    
    /// 大模型卡片渲染逻辑
    private func modelCard(for manifest: LLMManifest) -> some View {
        let isSelected = modelManager.activeModelId == manifest.modelId
        let eligibility = modelManager.evaluateEligibility(for: manifest)
        let downloadState = modelManager.downloadStates[manifest.modelId] ?? .failed(error: String(data: Data(base64Encoded: "Tm90IERvd25sb2FkZWQ=")!, encoding: .utf8)!)
        let isLocalReady = modelManager.isModelLocalReady(for: manifest.modelId)
        
        let cardBackground = Color.appCard.opacity(eligibility == .restricted ? 0.4 : 0.8)
        let borderColor = isSelected ? Color.appAccent : (eligibility == .restricted ? Color.red.opacity(0.4) : Color.appBorder.opacity(0.8))
        let shadowColor = isSelected ? Color.appAccent.opacity(0.2) : Color.black.opacity(0.05)
        
        return VStack(alignment: .leading, spacing: DesignSystem.small) {
            // 头部：标题与状态标签
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DesignSystem.small) {
                        Text(manifest.displayName)
                            .font(.headline)
                            .foregroundStyle(eligibility == .restricted ? .appSecondary : .appText)
                        
                        Text(manifest.parameterCount)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccent.opacity(0.15))
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
            
            // 场景能力标签 (Chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // 支持的任务展示
                    ForEach(manifest.displayName == "Gemma-2B" ? [" ", " ", ""] : [""], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.appBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .foregroundStyle(.appSecondary)
                    }
                }
            }
            .padding(.vertical, 2)
            
            // 硬件防爆护栏层
            if eligibility == .restricted {
                restrictedBanner(for: manifest)
            } else if eligibility == .warning {
                warningBanner
            }
            
            Divider()
                .foregroundStyle(Color.appBorder.opacity(0.5))
            
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
                    .frame(width: 80)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
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
            if error != String(data: Data(base64Encoded: "Tm90IERvd25sb2FkZWQ=")!, encoding: .utf8)! && error != "Cancelled" {
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
            // 物理限制，禁止下载
            Button(action: { alertManifest = manifest }) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.octagon.fill")
                    Text("")
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(Capsule())
            }
        } else if isLocalReady {
            // 已下载，可激活
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
        } else {
            // 未下载或正在下载
            switch state {
            case .pending, .downloading:
                Button(action: { modelManager.pauseDownload(for: manifest.modelId) }) {
                    Image(systemName: "pause.fill")
                        .font(.caption)
                        .padding(8)
                        .background(Color.appBackground)
                        .foregroundStyle(.orange)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.orange, lineWidth: 1))
                }
            case .paused:
                HStack(spacing: DesignSystem.small) {
                    Button(action: { modelManager.cancelDownload(for: manifest.modelId) }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .padding(8)
                            .background(Color.appBackground)
                            .foregroundStyle(.appSecondary)
                            .clipShape(Circle())
                    }
                    Button(action: { modelManager.resumeDownload(for: manifest.modelId) }) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .padding(8)
                            .background(Color.appAccent)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                }
            default:
                Button(action: { modelManager.startDownload(for: manifest) }) {
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
            }
        }
    }
    
    // MARK: - Banner 信息条
    
    /// 强物理内存拦截红条
    private func restrictedBanner(for manifest: LLMManifest) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(" \(String(format: "%.1f", manifest.minDeviceMemoryInGb)) GB  OOM")
                .font(.system(size: 10))
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    /// 临界运存警告黄条
    private var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text("")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - 辅助计算
    
    /// 格式化大小
    private func formattedSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1.0 {
            return String(format: String(data: Data(base64Encoded: "JS4yZiBHQg==")!, encoding: .utf8)!, gb)
        } else {
            return String(format: String(data: Data(base64Encoded: "JS4xZiBNQg==")!, encoding: .utf8)!, mb)
        }
    }
}
