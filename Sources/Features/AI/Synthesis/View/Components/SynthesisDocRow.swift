//
//  SynthesisDocRow.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Components 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 合成文档条目行组件
/// 负责展示单个生成文档的详情、预览入口及重命名/删除等交互操作
struct SynthesisDocRow: View {
    let doc: SynthesisStore.SynthesisDocument
    let type: SynthesisStore.SynthesisType
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    // MARK: - 编辑模式枚举（跨平台统一定义，不依赖 SwiftUI.EditMode）
    /// 简化编辑模式，避免与 SwiftUI.EditMode 类型混淆
    enum EditMode: Equatable { case active, inactive }
    
    let editMode: EditMode
    
    init(doc: SynthesisStore.SynthesisDocument,
         type: SynthesisStore.SynthesisType,
         editMode: EditMode = .inactive,
         isSelected: Bool,
         onTap: @escaping () -> Void,
         onRename: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.doc = doc
        self.type = type
        self.editMode = editMode
        self.isSelected = isSelected
        self.onTap = onTap
        self.onRename = onRename
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            // ══ 固定宽度的选择指示器插槽 ══
            Group {
                if editMode == .active {
                    Image(systemName: isSelected ? DesignSystem.Icons.checkCircle : DesignSystem.Icons.circle)
                        .font(.system(size: DesignSystem.Graph.nodeSizeReference))
                        .foregroundStyle(isSelected ? .appAccent : .appSecondary.opacity(DesignSystem.disabledOpacity * 1.33)) // 0.4
                        .onTapGesture {
                            HapticFeedback.shared.trigger(.selection)
                            onTap()
                        }
                }
            }
            .frame(width: editMode == .active ? DesignSystem.CompositeRow.indicatorWidth : 0)
            .clipped()
            
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CompositeRow.cornerRadius)
                    .fill(type.formatColor.opacity(DesignSystem.dimmedOpacity * 0.5)) // 0.1
                    .frame(width: DesignSystem.CompositeRow.iconBoxSize, height: DesignSystem.CompositeRow.iconBoxSize)
                Image(systemName: type.formatIcon).foregroundStyle(type.formatColor)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(doc.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.appText)
                
                HStack(spacing: DesignSystem.tightPadding) {
                    Text(formatDate(doc.createdAt))
                    Text(DesignSystem.Icons.dotSeparator)
                    Text(formatByteSize(doc.size))
                }
                .font(.caption2)
                .foregroundStyle(.appSecondary)
            }
            Spacer()
            
            if editMode == .inactive {
                Image(systemName: DesignSystem.Icons.forward)
                    .font(.system(size: DesignSystem.captionFontSize))
                    .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity * 0.6)) // 0.5
            }
        }
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.medium)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onDelete()
            } label: {
                Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
            }
            .tint(.red)
            
            Button {
                onRename()
            } label: {
                Label(L10n.Tag.Action.rename, systemImage: DesignSystem.Icons.edit)
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label(L10n.Tag.Action.rename, systemImage: DesignSystem.Icons.edit)
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
            }
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func formatByteSize(_ bytes: Int) -> String {
        let b = Double(bytes)
        if b < 1024 { return "\(bytes) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", b / 1024) }
        return String(format: "%.1f MB", b / (1024 * 1024))
    }
}
