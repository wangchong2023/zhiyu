// UnsupportedSearchIndexer.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：SearchIndexerProtocol 的不支持平台占位实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 不支持搜索索引的平台实现
final class UnsupportedSearchIndexer: SearchIndexerProtocol, Sendable {
    func indexPage(_ page: KnowledgePage) {}
    func indexPages(_ pages: [KnowledgePage]) {}
    func removeIndex(for pageID: UUID) {}
    func deindexAll() {}
    func reindexAll(pages: [KnowledgePage]) {}
}
