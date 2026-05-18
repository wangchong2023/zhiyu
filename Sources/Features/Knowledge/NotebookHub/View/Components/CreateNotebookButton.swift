// CreateNotebookButton.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：新建笔记本按钮组件。
// 支持网格 (Card) 和列表 (ListRow) 两种展示模式。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
struct CreateNotebookButton: View {
    // MARK: - 状态与环境
    
    @Bindable var viewModel: NotebookHubViewModel
    let displayMode: NotebookHubViewModel.DisplayMode
    
    // MARK: - 视图主体
    
    var body: some View {
        if displayMode == .grid {
            createNotebookCard
        } else {
            createNotebookListRow
        }
    }
    
    // MARK: - 子视图组件
    
    private var createNotebookListRow: some View {
        Button(action: { 
            HapticFeedback.shared.trigger(.selection)
            viewModel.isShowingCreateSheet = true 
        }) {
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: DesignSystem.Icons.plusCircle)
                    .font(.system(size: DesignSystem.titleFontSize))
                    .foregroundStyle(.appAccent)
                
                Text(L10n.Vault.new)
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                    .foregroundStyle(.appText)
                
                Spacer()
            }
            .padding(DesignSystem.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.borderWidth, dash: [4]))
                    .foregroundStyle(.appAccent.opacity(DesignSystem.secondaryOpacity))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var createNotebookCard: some View {
        Button(action: { 
            HapticFeedback.shared.trigger(.selection)
            viewModel.isShowingCreateSheet = true 
        }) {
            VStack(spacing: DesignSystem.medium) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: DesignSystem.Icons.plus)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.appAccent)
                }
                
                Text(L10n.Vault.new)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.appText)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color.appCard.opacity(DesignSystem.subtleFillOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.appAccent.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
}
