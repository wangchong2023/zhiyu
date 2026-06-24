//
//  AppStore+AI.swift
//  ZhiYu
//
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：AppStore 的 AI 标签管理扩展 — 标签 CRUD 操作转发至 TagStore。
//
import SwiftUI

// MARK: - 标签管理 (转发至 TagStore)

extension AppStore {

    /// 获取AllTags
    public func getAllTags() -> [String: Int] {
        tagStore.getAllTags(from: pages)
    }

    /// 重命名Tag
    public func renameTag(_ oldTag: String, to newTag: String) async {
        await tagStore.renameTag(old: oldTag, to: newTag)
        await knowledgeStore.refresh()
    }

    /// 删除Tag
    public func deleteTag(_ tag: String) async {
        await tagStore.deleteTag(tag)
        await knowledgeStore.refresh()
    }

    /// bulk删除Tags
    public func bulkDeleteTags(_ tags: [String]) async {
        await tagStore.bulkDeleteTags(tags)
        await knowledgeStore.refresh()
    }

    /// 添加NewTag
    public func addNewTag(_ tag: String) {
        tagStore.addNewTag(tag)
    }
}
