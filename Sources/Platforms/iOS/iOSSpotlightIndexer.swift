//
//  iOSSpotlightIndexer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 iOS 模块，提供相关的结构体或工具支撑。
//
#if canImport(CoreSpotlight)
import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

/// iOS/macOS Spotlight 索引实现
final class iOSSpotlightIndexer: SearchIndexerProtocol, @unchecked Sendable {
    func indexPage(_ page: KnowledgePage) {
        indexPages([page])
    }
    
    func indexPages(_ pages: [KnowledgePage]) {
        var searchableItems: [CSSearchableItem] = []
        
        for page in pages {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .plainText)
            attributeSet.title = page.title
            attributeSet.contentDescription = String(page.content.prefix(200))
            attributeSet.keywords = page.tags + page.aliases
            attributeSet.relatedUniqueIdentifier = page.id.uuidString
            
            let item = CSSearchableItem(
                uniqueIdentifier: page.id.uuidString,
                domainIdentifier: "com.zhiyu.app.pages",
                attributeSet: attributeSet
            )
            item.expirationDate = nil
            searchableItems.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Logger.shared.error("🔍 [Spotlight] Batch indexing failed: \(error.localizedDescription)")
            }
        }
    }
    
    func removeIndex(for pageID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [pageID.uuidString]) { _ in }
    }
    
    func deindexAll() {
        CSSearchableIndex.default().deleteAllSearchableItems() { _ in }
    }
    
    func reindexAll(pages: [KnowledgePage]) {
        CSSearchableIndex.default().deleteAllSearchableItems { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.indexPages(pages)
            }
        }
    }
}
#endif
