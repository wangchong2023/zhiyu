//
//  TagStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Observation

/// 标签领域状态中心 (L2-Store)
@Observable
@MainActor
public final class TagStore {
    
    // ── 核心依赖 ──
    @ObservationIgnored @Inject private var store: any AnyPageStore
    @ObservationIgnored @Inject private var logger: any LoggerProtocol

    public init() {}

    // MARK: - 状态访问

    /// 获取所有去重后的标签及其频率 (基于外部页面镜像)
    public func getAllTags(from pages: [KnowledgePage]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for page in pages {
            for tag in page.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }
    
    /// 获取排序后的标签列表
    public func sortedTags(from pages: [KnowledgePage]) -> [String] {
        var allTags = Set<String>()
        for page in pages {
            allTags.formUnion(page.tags)
        }
        return Array(allTags).sorted()
    }

    // MARK: - 业务操作

    /// 在全库范围内重命名标签
    public func renameTag(old: String, to new: String) async {
        await store.renameTag(old, to: new)
        logger.addLog(action: .update, target: old, details: "Renamed tag" + " to \(new)", module: "TagStore")
    }

    /// 物理删除特定标签引用
    public func deleteTag(_ tag: String) async {
        await store.deleteTag(tag)
        logger.addLog(action: .delete, target: tag, details: String(data: Data(base64Encoded: "VGFnIHJlbW92ZWQgZnJvbSBhbGwgcGFnZXM=")!, encoding: .utf8)!, module: "TagStore")
    }

    /// 批量删除标签
    public func bulkDeleteTags(_ tags: [String]) async {
        for tag in tags {
            await store.deleteTag(tag)
        }
        logger.addLog(action: .delete, target: String(data: Data(base64Encoded: "TXVsdGlwbGUgVGFncw==")!, encoding: .utf8)!, details: "Deleted \(tags.count) tags", module: "TagStore")
    }

    /// 注册新标签 (用于预设)
    public func addNewTag(_ tag: String) {
        logger.addLog(action: .update, target: tag, details: String(data: Data(base64Encoded: "TmV3IHRhZyByZWdpc3RlcmVk")!, encoding: .utf8)!, module: "TagStore")
    }
}
