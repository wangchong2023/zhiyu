//
//  DeepLinkService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：实现 DeepLink 模块的核心业务逻辑服务。
//
import Foundation

// MARK: - Deep Link Service
/// Handles deep links, universal links, and Spotlight indexing for Knowledge Base pages.
final class DeepLinkService: ObservableObject {
    @Published var pendingDeepLink: DeepLink?
    
    enum DeepLink {
        case openPage(id: UUID)
        case openPageByTitle(String)
        case search(String)
        case create // 桌面小组件快捷新建卡片动作
        case ingest
        case graph
        case chat
    }
    
    // MARK: - URL Scheme Handling
    // 处理应用特有的 URL Scheme 深度路由分发
    /// - Parameter url: 传入的原始 URL 实例
    /// - Returns: 是否为系统可识别且处理成功的路由动作
    // swiftlint:disable:next cyclomatic_complexity
    func handleURL(_ url: URL) -> Bool {
        // 限流保护：防止外部意图总线过载，超过 10Hz 直接拒绝 (TC-DEE-06)
        guard IntentRateLimiter.shared.request() else {
            print(" [DeepLinkService]" + " Rate limit" + " exceeded! Dropping" + " request: \(url.absoluteString)")
            return false
        }
        
        // 关键过程：验证前置协议头是否符合 zhiyu 专属定义
        guard url.scheme == "zhiyu" else { return false }
        
        switch url.host {
        case "page":
            // 物理页面 ID 快速跳转解析
            if let idString = url.queryParameters["id"],
               let id = UUID(uuidString: idString) {
                pendingDeepLink = .openPage(id: id)
                return true
            }
            // 页面标题快速跳转解析
            if let title = url.queryParameters["title"] {
                pendingDeepLink = .openPageByTitle(title)
                return true
            }
            
        case "create":
            // 🟢 补全桌面小组件的新建笔记路由：直达新建卡片弹窗
            pendingDeepLink = .create
            return true
            
        case "search":
            // 🟢 容错与防灾降级策略：若缺失 q 参数（例如从小组件点击 Search 按钮），
            // 则将其安全降级解析为空搜索 q=""，拉起搜索面板而不丢弃路由。
            let query = url.queryParameters["q"] ?? ""
            pendingDeepLink = .search(query)
            return true
            
        case "ingest":
            pendingDeepLink = .ingest
            return true
            
        case "graph":
            pendingDeepLink = .graph
            return true
            
        case "chat":
            pendingDeepLink = .chat
            return true
            
        default:
            break
        }
        
        return false
    }
    
    // MARK: - Spotlight Query Handling
    /// 处理SpotlightActivity
    /// - Parameter userActivity: userActivity
    /// - Returns: 是否成功
    func handleSpotlightActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == "com.zhiyu.app.openPage",
              let userInfo = userActivity.userInfo,
              let idString = userInfo["pageID"] as? String,
              let id = UUID(uuidString: idString) else {
            return false
        }
        pendingDeepLink = .openPage(id: id)
        return true
    }
    
    /// consumeDeep链接
    /// - Returns: 可选值
    func consumeDeepLink() -> DeepLink? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }
}

// MARK: - URL Query Parameters Extension
extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return [:] }
        return Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
    }
}
