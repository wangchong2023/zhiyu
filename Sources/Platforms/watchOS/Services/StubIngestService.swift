//
//  StubIngestService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 watchOS 模块，提供 IngestServiceProtocol 契约接口的轻量级空实现的桩 (Stub) 服务，
//           彻底断绝 watchOS 因为裁剪 Features 层代码导致的 Ingest 依赖链断裂与运行时闪退。
//

import Foundation

/// watchOS 特有的 IngestService 空实现服务
public final class StubIngestService: IngestServiceProtocol {
    
    /// 构造初始化
    public init() {}
    
    /// watchOS 上模拟导入文件夹，仅作空日志输出并返回空列表
    /// - Parameters:
    ///   - url: 文件夹路径 URL
    ///   - type: 生成页面的实体类型
    ///   - pageStore: 数据持久层
    /// - Returns: 空页面列表
    public func ingestFolder(at url: URL, type: PageType, pageStore: any AnyPageStore) async -> [KnowledgePage] {
        Logger.shared.info("watchOS_Stub")
        return []
    }
}
