//
//  NotebookCard.swift
//  ZhiYu
//
//  Created by Wang Chong on 2026-05-18.
//  Copyright © 2026 Wang Chong. All rights reserved.
//

import SwiftUI

/// 笔记本网格卡片组件。
/// 
/// 该组件承载于 [L2] 业务功能层金库工作台。它直观展示金库卡片元数据（包含图标、名、更新时间及相对描述），
/// 并且深度挂载了由 Task 2 升级的 `AppCardButtonStyle`，使用户在点击、长按或执行 ContextMenu 时获得拟真阻尼按压物理回跃触感。
struct NotebookCard: View {
    
    /// 获取当前金库工作台的数据和路由视图模型
    @Environment(NotebookHubViewModel.self) var viewModel
    
    /// 当前卡片所绑定的笔记本元数据实体 (Vault)
    let notebook: Vault
    
    /// 当用户点击该笔记本卡片时触发的回调行为
    let action: () -> Void
    
    /// 笔记本卡片的渲染视图布局
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                // 1. 图标展示 (根据卡片哈希色计算出来的彩色发光底座，赋予视觉独特性)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorForVault.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.system(size: 22))
                }
                .padding(.top, DesignSystem.tiny)
                .accessibilityHidden(true) // 屏蔽装饰性发光底座及 Emoji 的无谓直译，由外壳统合播报
                
                // 2. 金库名称标题
                Text(notebook.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 3. 摘要描述文案，字数过多时优雅截断
                Text(notebook.description ?? L10n.Vault.defaultDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: DesignSystem.small)
                
                // 4. 元数据底部说明（采用强类型相对时间表达，保持跨语言的国际化适配）
                Text("\(L10n.Vault.lastEdited) \(notebook.updatedAt.formatted(.relative(presentation: .numeric)))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.04), lineWidth: 0.5)
            )
            .premiumAmbientShadow(color: .black, radius: 10)
            .scaleOnHover()
            // 绑定长按上下文菜单 (ContextMenu)，支持重命名与沙盒物理彻底擦除
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
        // 绑定 Task 2 微动效交互的核心成果，使用户物理压下卡片时得到即时的 Spring 回弹与下沉反馈
        .buttonStyle(AppCardButtonStyle())
        // MARK: - A11y 无障碍适配
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notebook.name)，\(L10n.Accessibility.notebookCardLabel)")
        .accessibilityValue(notebook.description ?? L10n.Vault.defaultDescription)
        .accessibilityHint("\(L10n.Vault.lastEdited) \(notebook.updatedAt.formatted(.relative(presentation: .numeric)))。\(L10n.Accessibility.notebookCardHint)")
    }
    
    /// 根据笔记本名称的哈希值自动计算底座主色调，确保不同笔记本具有差异化的视觉令牌颜色
    private var colorForVault: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        let index = abs(notebook.name.hashValue) % colors.count
        return colors[index]
    }
    
    /// 获取根据笔记本 ID 哈希值计算出来的兜底默认 Emoji 图标，收拢至强类型设计令牌
    private var defaultIcon: String {
        let index = abs(notebook.id.hashValue) % IconTokens.options.count
        return IconTokens.options[index]
    }
}
