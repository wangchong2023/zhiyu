//
//  ShortcutManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：属于 Shortcuts 模块，提供相关的结构体或工具支撑。
//
#if os(iOS) || os(macOS)
// ShortcutManager.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：Siri 快捷指令管理器 (Expert Design Item #3)
// 版本: 1.1
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-23: 实现 Siri 快捷指令与后台数据库的真实业务交互
// 日期: 2026-05-23
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import AppIntents

/// Siri 快捷指令管理器 (Expert Design Item #3)
/// 负责封装和定义与 Apple Siri 快捷指令集成的各项 AppIntent 动作，支持系统级的智能化调用。
@available(iOS 16.0, macOS 13.0, *)
struct ShortcutManager {
    
    // MARK: - 快速记录 Intent
    /// 快速记录意图
    /// 允许用户在不打开 App 的情况下通过 Siri 或快捷指令直接向智宇知识库中添加便签或闪念。
    struct CaptureIntent: AppIntent {
        // 重要提示 (L0.5 架构约束)：由于 Apple 的 Siri 快捷指令元数据编译器 (appintentsmetadataprocessor)
        // 采用的是纯静态语法树 (AST) 扫描分析，在 static var title / description 和 @Parameter 的元数据属性上
        // 强行要求必须直接使用 LocalizedStringResource 的原生构造器字面量或 String 字面量进行初始化赋值。
        // 任何跨文件、间接计算属性（如 L10n.Shortcuts.*）在此处都会导致编译终止（Error 65）。
        // 因此，元数据属性必须直接构造，而非元数据的 perform 业务返回逻辑中已完美采用 L10n 安全管理。
        
        nonisolated(unsafe) static var title: LocalizedStringResource = LocalizedStringResource("shortcuts.capture.title", table: "System")
        nonisolated(unsafe) static var description: IntentDescription = .init(LocalizedStringResource("shortcuts.capture.description", table: "System"))
        
        /// Siri 接收的记录文本内容
        @Parameter(title: LocalizedStringResource("shortcuts.capture.contentTitle", table: "System"), default: "")
        var content: String
        
        /// 执行快捷指令核心方法
        /// - Returns: 返回指示记录成功的动作结果
        func perform() async throws -> some IntentResult & ReturnsValue<String> {
            Logger.shared.debug("🎙️ [Siri] Recording content: \(content)")
            
            // 在主线程解析并获取知识库存储能力
            let store = await MainActor.run { ServiceContainer.shared.resolve(KnowledgeStore.self) }
            let summary = content.count > 15 ? String(content.prefix(15)) + "..." : content
            
            // 自动将记录保存至知识库中，并标记 Siri 数据源，此业务逻辑非 AST 静态提取，已安全采用 L10n
            let _ = await store.createPage(
                title: L10n.Shortcuts.Capture.pageTitle(summary),
                pageType: .raw,
                content: content,
                tags: ["Siri", "QuickCapture"]
            )
            
            return .result(value: L10n.Shortcuts.Capture.success)
        }
    }
    
    // MARK: - 搜索知识库 Intent
    /// 搜索知识库意图
    /// 允许用户通过 Siri 或快捷指令以指定的关键词对本地知识库和 RAG 库进行检索，并自动唤起主 App。
    struct SearchKnowledgeIntent: AppIntent {
        // 重要提示 (L0.5 架构约束)：同上，AppIntent 核心元数据（title / description / @Parameter）
        // 必须直接使用 LocalizedStringResource 构造字面量赋值，无法使用间接 L10n 桥接。
        
        nonisolated(unsafe) static var title: LocalizedStringResource = LocalizedStringResource("shortcuts.search.title", table: "System")
        nonisolated(unsafe) static var description: IntentDescription = .init(LocalizedStringResource("shortcuts.search.description", table: "System"))
        nonisolated(unsafe) static var openAppWhenRun: Bool = true
        
        /// 搜索的关键词
        @Parameter(title: LocalizedStringResource("shortcuts.search.queryTitle", table: "System"), default: "")
        var query: String
        
        /// 执行搜索指令核心方法
        /// - Returns: 返回完成搜索的动作结果，并将搜索参数注入主 App 交互层
        func perform() async throws -> some IntentResult & ReturnsValue<String> {
            Logger.shared.debug("🎙️ [Siri] Searching for: \(query)")
            
            // 在主线程驱动全局 UI 路由器，自动切换到知识分类并传入搜索文本
            await MainActor.run {
                let appStore = ServiceContainer.shared.resolve(AppStore.self)
                let router = ServiceContainer.shared.resolve(Router.self)
                
                router.selectedTab = .knowledge
                router.sidebarSelection = .tool(.pageList)
                appStore.searchStore.searchText = query
            }
            
            return .result(value: L10n.Shortcuts.Search.success(query))
        }
    }
    
    // MARK: - 获取统计 Intent
    /// 获取知识库统计意图
    /// 允许用户快速查询当前知识库的页面总数与基本概览。
    struct GetKnowledgeStatsIntent: AppIntent {
        // 重要提示 (L0.5 架构约束)：元数据属性必须直接使用 LocalizedStringResource 构造。
        
        nonisolated(unsafe) static var title: LocalizedStringResource = LocalizedStringResource("shortcuts.stats.title", table: "System")
        nonisolated(unsafe) static var description: IntentDescription = .init(LocalizedStringResource("shortcuts.stats.description", table: "System"))
        
        /// 执行统计查询方法
        /// - Returns: 返回包含知识库总页面数的文案结果
        func perform() async throws -> some IntentResult & ReturnsValue<String> {
            let store = await MainActor.run { ServiceContainer.shared.resolve(KnowledgeStore.self) }
            let pageCount = await MainActor.run { store.pages.count }
            
            return .result(value: L10n.Shortcuts.Stats.success(pageCount))
        }
    }
}

// MARK: - App 快捷指令提供者
/// 智宇快捷指令注册器
/// 向 iOS/macOS 系统注册应用程序的快捷短语，帮助用户直接通过呼叫 Siri 触发定义好的 AppIntents
@available(iOS 16.0, macOS 13.0, *)
struct ZhiYuShortcuts: AppShortcutsProvider {
    /// 导出注册到系统的 AppShortcut 集合
    static var appShortcuts: [AppShortcut] {
        // 重要提示：AppShortcutsProvider 的元数据注册逻辑也是由元数据编译器静态扫描提取的，
        // 因此 shortTitle 参数必须使用直接的 LocalizedStringResource 构造字面量赋值。
        
        AppShortcut(
            intent: ShortcutManager.CaptureIntent(),
            phrases: [
                AppShortcutPhrase("Record with \(.applicationName)"),
                AppShortcutPhrase("Jot down in \(.applicationName)")
            ],
            shortTitle: LocalizedStringResource("shortcuts.provider.captureShortTitle", table: "System"),
            systemImageName: "sparkles"
        )
        
        AppShortcut(
            intent: ShortcutManager.SearchKnowledgeIntent(),
            phrases: [
                AppShortcutPhrase("Search in \(.applicationName)"),
                AppShortcutPhrase("Search \(.applicationName)")
            ],
            shortTitle: LocalizedStringResource("shortcuts.provider.searchShortTitle", table: "System"),
            systemImageName: "magnifyingglass"
        )
        
        AppShortcut(
            intent: ShortcutManager.GetKnowledgeStatsIntent(),
            phrases: [
                AppShortcutPhrase("\(.applicationName) Stats"),
                AppShortcutPhrase("\(.applicationName) Overview")
            ],
            shortTitle: LocalizedStringResource("shortcuts.provider.statsShortTitle", table: "System"),
            systemImageName: "chart.bar"
        )
    }
}
#endif

