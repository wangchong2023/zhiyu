// SynthesisDocRow.swift
//
// 作者: Wang Chong
// 功能说明: 合成文档条目行组件，负责展示单个生成文档的详情、预览入口及重命名/删除等交互操作。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 合成文档条目行组件
/// 负责展示单个生成文档的详情、预览入口及重命名/删除等交互操作
struct SynthesisDocRow: View {
    let doc: SynthesisStore.SynthesisDocument
    let type: SynthesisStore.SynthesisType
    let editMode: EditMode
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @Environment(SynthesisStore.self) var synthesisStore

    init(doc: SynthesisStore.SynthesisDocument, 
         type: SynthesisStore.SynthesisType, 
         editMode: EditMode, 
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
        HStack(spacing: AppUI.medium) {
            // ══ 固定宽度的选择指示器插槽 ══
            Group {
                if editMode == .active {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: AppUI.Graph.nodeSizeReference))
                        .foregroundStyle(isSelected ? .appAccent : .appSecondary.opacity(AppUI.disabledOpacity * 1.33)) // 0.4
                        .onTapGesture {
                            HapticFeedback.shared.trigger(.selection)
                            onTap()
                        }
                }
            }
            .frame(width: editMode == .active ? AppUI.CompositeRow.indicatorWidth : 0)
            .clipped()
            
            ZStack {
                RoundedRectangle(cornerRadius: AppUI.CompositeRow.cornerRadius)
                    .fill(type.formatColor.opacity(AppUI.dimmedOpacity * 0.5)) // 0.1
                    .frame(width: AppUI.CompositeRow.iconBoxSize, height: AppUI.CompositeRow.iconBoxSize)
                Image(systemName: type.formatIcon).foregroundStyle(type.formatColor)
            }
            
            VStack(alignment: .leading, spacing: AppUI.tiny) {
                Text(doc.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.appText)
                
                HStack(spacing: AppUI.tightPadding) {
                    Text(formatDate(doc.createdAt))
                    Text("·")
                    Text(formatByteSize(doc.size))
                }
                .font(.caption2)
                .foregroundStyle(.appSecondary)
            }
            Spacer()
            
            if editMode == .inactive {
                Image(systemName: "chevron.right")
                    .font(.system(size: AppUI.captionFontSize))
                    .foregroundStyle(.appSecondary.opacity(AppUI.secondaryOpacity * 0.6)) // 0.5
            }
        }
        .padding(.horizontal, AppUI.standardPadding)
        .padding(.vertical, AppUI.medium)
        .appCardStyle(cornerRadius: AppUI.CompositeRow.cornerRadius)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label(Localized.tr("tag.rename"), systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.Common.tr("delete"), systemImage: "trash")
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
