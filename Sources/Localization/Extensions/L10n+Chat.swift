// 功能说明: [Shared]
//
// L10n+Chat.swift
// 智宇 (ZhiYu) 多语言 Chat 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Chat {
        public static let t = "AI"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 获取活跃会话个数文案
        /// - Parameter count: 会话个数
        /// - Returns: 本地化格式化文案
        public static func activeSessionCount(_ count: Int) -> String { Localized.trf("chat.activeSessionCount", table: t, count) }

        /// 获取消息条数文案
        /// - Parameter count: 消息条数
        /// - Returns: 本地化格式化文案
        public static func messageCount(_ count: Int) -> String { Localized.trf("chat.messageCount", table: t, count) }

        /// 获取消耗 Token 数文案
        /// - Parameter count: Token数
        /// - Returns: 本地化格式化文案
        public static func tokenUsage(_ count: Int) -> String { Localized.trf("chat.tokenUsage", table: t, count) }

        /// 获取引用文献个数文案
        /// - Parameter count: 引用文献个数
        /// - Returns: 本地化格式化文案
        public static func referenceCount(_ count: Int) -> String { Localized.trf("chat.referenceCount", table: t, count) }

        /// 获取上下文超限警告文案
        /// - Parameter limit: 限制数
        /// - Returns: 本地化格式化文案
        public static func contextLimitWarning(_ limit: Int) -> String { Localized.trf("chat.contextLimitWarning", table: t, limit) }

        public static var title: String { tr("chat.title") }
        public static var welcomeDesc: String { tr("chat.welcomeDesc") }

        public struct group {
            public static var ai: String { Chat.tr("chat.group.ai") }
            public static var base: String { Chat.tr("chat.group.base") }
            public static var user: String { Chat.tr("chat.group.user") }
        }

        public static var aiAssistantName: String { tr("chat.aiAssistantName") }
        public static var referencesExpanded: String { tr("chat.referencesExpanded") }
        public static var referencesCollapsed: String { tr("chat.referencesCollapsed") }
        public static var clearHistoryConfirmTitle: String { tr("chat.clearHistory.confirm.title") }
        public static var clearHistoryConfirmMessage: String { tr("chat.clearHistory.confirm.message") }
        public static var configureFirst: String { tr("chat.configureFirst") }
        public static var aiRunning: String { tr("chat.aiRunning") }
        public static var inputPlaceholder: String { tr("chat.inputPlaceholder") }
        public static var explorationAndPrompts: String { tr("chat.explorationAndPrompts") }
        public static var exportConversation: String { tr("chat.exportConversation") }
        public static var llmSettings: String { tr("chat.llmSettings") }
        public static var selectToExport: String { tr("chat.selectToExport") }
        public static var exportSelectedPDF: String { tr("chat.exportSelectedPDF") }
        public static var exportPDF: String { tr("chat.exportPDF") }

        /// 获取深度探索/总体探索的提示词文案
        /// - Parameter topic: 探索主题
        /// - Returns: 本地化格式化文案
        public static func deepExplorePrompt(_ topic: String) -> String { Localized.trf("chat.deepExplorePrompt", table: t, topic) }

        public struct ai {
            public static var thinking: String { Chat.tr("chat.ai.thinking") }
        }
    }
}
