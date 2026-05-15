// TagCloudCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：标签云功能协调器，负责标签管理（增删改查）与 UI 状态编排。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 初始版本，从 TagCloudView 剥离业务逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

@MainActor
@Observable
final class TagCloudCoordinator {
    // ── 状态属性 ──
    var tags: [(tag: String, count: Int)] = []
    var selectedTag: String?
    var searchText = ""
    var isEditMode = false
    var selectedTagsForBulk: Set<String> = []
    
    // 弹窗控制
    var showAddTagDialog = false
    var addTagName = ""
    var tagToRename: String?
    var newTagName = ""
    var showDeleteConfirm = false
    var tagToDelete: String?
    
    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject private var store: AppStore
    @ObservationIgnored @Inject private var haptic: any HapticFeedbackProtocol

    init(initialTag: String? = nil) {
        self.selectedTag = initialTag
    }

    // ── 计算属性 ──

    /// 经过搜索过滤后的标签列表
    var filteredTags: [(tag: String, count: Int)] {
        if searchText.isEmpty { return tags }
        return tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }
    }

    /// 基于选中标签筛选的页面列表
    var filteredPages: [KnowledgePage] {
        guard let tag = selectedTag else { return store.pages }
        return store.pages.filter { $0.tags.contains(tag) }
    }

    // ── 业务动作 ──

    /// 执行数据抓取
    func fetchData() async {
        let allTags = await store.getAllTags()
        self.tags = allTags
    }

    /// 执行标签重命名逻辑
    func performRename() {
        guard let old = tagToRename, !newTagName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        Task {
            await store.renameTag(old, to: trimmed)
            if selectedTag == old { selectedTag = trimmed }
            await fetchData()
        }
        tagToRename = nil
        haptic.trigger(.success)
    }

    /// 执行标签删除逻辑
    func performDelete() {
        if let tag = tagToDelete {
            Task {
                await store.deleteTag(tag)
                if selectedTag == tag { selectedTag = nil }
                await fetchData()
            }
        }
        tagToDelete = nil
        haptic.trigger(.success)
    }

    /// 创建新标签并自动设为选中状态
    func performAddTag() {
        let trimmed = addTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        Task {
            await store.addNewTag(trimmed)
            await fetchData()
            self.selectedTag = trimmed
        }
        
        addTagName = ""
        showAddTagDialog = false
        haptic.trigger(.success)
    }
    
    /// 批量删除
    func performBulkDelete() {
        guard !selectedTagsForBulk.isEmpty else { return }
        Task {
            await store.bulkDeleteTags(selectedTagsForBulk)
            selectedTagsForBulk.removeAll()
            await fetchData()
        }
        isEditMode = false
        haptic.trigger(.success)
    }
    
    func toggleSelection(_ tag: String) {
        if selectedTagsForBulk.contains(tag) {
            selectedTagsForBulk.remove(tag)
        } else {
            selectedTagsForBulk.insert(tag)
        }
        haptic.trigger(.selection)
    }
}
