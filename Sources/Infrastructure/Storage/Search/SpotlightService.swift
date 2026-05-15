// SpotlightService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：Spotlight 索引服务 (Expert Design Item #3)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// Spotlight 索引服务 (Expert Design Item #3)
/// 负责协调底层平台的系统搜索索引实现。
@MainActor
final class SpotlightService {
    static let shared = SpotlightService()
    
    @Inject private var indexer: any SearchIndexerProtocol
    
    private init() {}
    
    /// 索引单张页面
    func indexPage(_ page: KnowledgePage) {
        indexer.indexPage(page)
    }
    
    /// 批量索引页面
    func indexPages(_ pages: [KnowledgePage]) {
        indexer.indexPages(pages)
    }
    
    /// 移除页面索引
    func removeIndex(for pageID: UUID) {
        indexer.removeIndex(for: pageID)
    }
    
    /// 移除所有页面索引
    func deindexAll() {
        indexer.deindexAll()
    }
    
    /// 全量重新索引
    func reindexAll(pages: [KnowledgePage]) {
        indexer.reindexAll(pages: pages)
    }
}

