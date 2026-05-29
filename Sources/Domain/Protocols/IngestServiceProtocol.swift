//
//  IngestServiceProtocol.swift
//  ZhiYu
//
//  系统层级：[L1.5] 领域层
//  核心职责：Protocols。提供跨层依赖倒置的领域协议契约。
//

import Foundation

/// 文件导入服务协议 (L1.5-Domain)
/// 抽象文件导入能力，使 Domain 层无需直接依赖 L2 IngestService
public protocol IngestServiceProtocol: Sendable {

    /// 导入摄取Folder
    /// /// - Parameter type: type
    /// /// - Parameter pageStore: page存储
    func ingestFolder(at url: URL, type: PageType, pageStore: any AnyPageStore) async -> [KnowledgePage]
}
