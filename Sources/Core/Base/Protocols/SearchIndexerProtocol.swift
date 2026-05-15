// SearchIndexerProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：系统搜索索引服务抽象协议，用于解耦 CoreSpotlight。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 搜索索引服务协议
public protocol SearchIndexerProtocol: Sendable {
    /// 索引单张页面
    func indexPage(_ page: KnowledgePage)
    
    /// 批量索引页面
    func indexPages(_ pages: [KnowledgePage])
    
    /// 移除页面索引
    func removeIndex(for pageID: UUID)
    
    /// 移除所有页面索引
    func deindexAll()
    
    /// 全量重新索引
    func reindexAll(pages: [KnowledgePage])
}
