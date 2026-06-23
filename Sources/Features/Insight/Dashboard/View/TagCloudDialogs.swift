//
//  TagCloudDialogs.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：标签管理的弹窗与确认对话框集合视图（重命名、删除、新增、批量删除），
//  提取至独立视图以缩短编译器类型推演耗时。
//

import SwiftUI

// MARK: - 弹窗与对话框

extension TagCloudViewContent {

    /// 弹窗与确认对话框集合视图
    /// 提取该视图可以极大缩短编译时间，提升类型检查效率
    @ViewBuilder
    var dialogsView: some View {
        @Bindable var coordinator = coordinator

        let isRenamePresented = Binding<Bool>(
            get: { coordinator.tagToRename != nil },
            set: { if !$0 { coordinator.tagToRename = nil } }
        )

        let renameMessage = L10n.Tag.Action.renameMessage(coordinator.tagToRename ?? "")
        let deleteMessage = coordinator.tagToDelete.map { L10n.Tag.Action.deleteMessage($0) } ?? L10n.Tag.Action.deleteTag
        let bulkDeleteMessage = L10n.Tag.Management.bulkDeleteWarning(coordinator.selectedTagsForBulk.count)

        Color.clear
            // 重命名对话框
            .alert(L10n.Tag.Action.renameTag, isPresented: isRenamePresented) {
                TextField(L10n.Tag.Action.newName, text: $coordinator.newTagName)
                Button(L10n.Common.cancel, role: .cancel) { coordinator.tagToRename = nil }
                Button(L10n.Common.ok) {
                    coordinator.performRename()
                }
            } message: {
                Text(renameMessage)
            }
            // 删除确认对话框
            .confirmationDialog(
                deleteMessage,
                isPresented: $coordinator.showDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.delete, role: .destructive) {
                    coordinator.performDelete()
                }
                Button(L10n.Common.cancel, role: .cancel) { coordinator.tagToDelete = nil }
            } message: {
                Text(L10n.Settings.clearAll.message)
            }
            // 新增标签对话框
            .alert(L10n.Tag.Management.addNew, isPresented: $coordinator.showAddTagDialog) {
                TextField(L10n.Tag.Management.inputName, text: $coordinator.addTagName)
                Button(L10n.Common.cancel, role: .cancel) { coordinator.addTagName = "" }
                Button(L10n.Common.Misc.create) {
                    coordinator.performAddTag()
                }
            } message: {
                Text(L10n.Tag.Management.createHint)
            }
            // 批量删除确认
            .confirmationDialog(
                bulkDeleteMessage,
                isPresented: $showBulkDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.Misc.deleteAll, role: .destructive) {
                    coordinator.performBulkDelete()
                }
                Button(L10n.Common.cancel, role: .cancel) { }
            } message: {
                Text(L10n.Settings.clearAll.message)
            }
    }
}
