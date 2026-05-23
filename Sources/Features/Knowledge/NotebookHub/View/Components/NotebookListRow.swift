//
//  NotebookListRow.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Components 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 笔记本列表单行行组件。
/// 
/// 该组件承载于 [L2] 业务功能层金库工作台。它在列表/表格视图下直观呈现金库元数据（包括图标、名称、简短说明、知识页统计数据），
/// 并且深度挂载了由 Task 2 升级的 `AppCardButtonStyle`，使用户在列表中点击整行时获得拟真阻尼按压物理回弹触感。
@MainActor
struct NotebookListRow: View {
    
    /// 当前列表行绑定的笔记本元数据实体 (Vault)
    let notebook: Vault
    
    /// 获取当前金库工作台的数据和路由视图模型
    @Environment(NotebookHubViewModel.self) var viewModel
    
    /// 当用户点击列表整行时触发的回调行为
    let action: () -> Void
    
    /// 笔记本列表行的渲染视图布局
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.medium) {
                // 1. 图标展示（圆形背景与 Emoji 图标）
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.title2)
                }
                .accessibilityHidden(true) // 屏蔽装饰性圆形底座与 Emoji 噪读，由行容器强合并朗读
                
                // 2. 金库元数据展示 (名称标题及描述，描述过长时智能单行截断)
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    Text(notebook.name)
                        .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                    
                    if let desc = notebook.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: DesignSystem.captionFontSize))
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 3. 统计指标展示（显示该金库中已持久化的知识页面总数）
                VStack(alignment: .trailing, spacing: DesignSystem.tiny) {
                    Text("\(notebook.pageCount)")
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.appAccent)
                    
                    Text(L10n.Vault.pageCountSuffix)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.appSecondary.opacity(0.6))
                }
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .contentShape(Rectangle())
            // 绑定 iOS 原生滑动快捷动作 (SwipeActions)，支持侧滑删除和快速编辑
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
                }
                
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.edit, systemImage: DesignSystem.Icons.edit)
                }
            }
            // 绑定长按上下文菜单 (ContextMenu)
            .contextMenu {
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.edit, systemImage: DesignSystem.Icons.edit)
                }
                
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
                }
            }
        }
        // 绑定 Task 2 微动效交互的核心成果，在点击单行时赋予舒适的欠阻尼物理按压反馈
        .buttonStyle(AppCardButtonStyle())
        // MARK: - A11y 无障碍适配
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notebook.name)，\(L10n.Accessibility.notebookCardLabel)")
        .accessibilityValue(
            "\(notebook.description ?? ""). \(notebook.pageCount) \(L10n.Vault.pageCountSuffix)"
        )
        .accessibilityHint(L10n.Accessibility.notebookListRowHint)
    }
    
    /// 获取根据笔记本 ID 哈希值计算出来的兜底默认 Emoji 图标，收拢至强类型设计令牌
    private var defaultIcon: String {
        let index = abs(notebook.id.hashValue) % IconTokens.options.count
        return IconTokens.options[index]
    }
}
