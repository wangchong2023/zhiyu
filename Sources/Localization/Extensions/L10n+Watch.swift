//
//  L10n+Watch.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Watch 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Watch {
        public static let t = "Platform"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var capture: String { tr("watch.capture") }
        public static var recents: String { Localized.tr("watch.recents", table: t) }
        public static var dictateHint: String { Localized.tr("watch.dictate.hint", table: t) }
        public static var widgetDisplayName: String { Localized.tr("watch.widget.displayName", table: t) }
        public static var widgetDisplayDesc: String { Localized.tr("watch.widget.displayDesc", table: t) }
        
        // ─── 新增 watchOS 专用本地化翻译 ───────────────────────────────────────────
        
        private static let watchTable = "Watch"
        
        /// 从 Watch.xcstrings 获取翻译
        private static func watchTr(_ key: String) -> String { Localized.tr(key, table: watchTable) }
        
        public static var briefingSynthesizing: String { watchTr("watch.briefing.synthesizing") }
        public static var briefingGetToday: String { watchTr("watch.briefing.getToday") }
        public static var briefingGenerateNow: String { watchTr("watch.briefing.generateNow") }
        public static var briefingAudioBriefing: String { watchTr("watch.briefing.audioBriefing") }
        public static var widgetCapture: String { watchTr("watch.widget.title") }
        public static var widgetDescription: String { watchTr("watch.widget.desc") }
        
        public static var briefingNoNewContent: String { watchTr("watch.briefing.noNewContent") }

        /// briefingPromptTemplate
        /// /// - Parameter content: content
        /// /// - Returns: 字符串
        public static func briefingPromptTemplate(_ content: String) -> String {
            Localized.trf("watch.briefing.promptTemplate", table: watchTable, content)
        }
        public static var briefingSystemPrompt: String { watchTr("watch.briefing.systemPrompt") }
        public static var briefingFailed: String { watchTr("watch.briefing.failed") }
    }
}
