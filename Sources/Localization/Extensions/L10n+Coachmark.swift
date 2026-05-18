// 功能说明: [Shared]
//
// L10n+Coachmark.swift
// 智宇 (ZhiYu) 多语言 Coachmark 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Coachmark {
        public static let t = "System"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 引导对话框：发现隐藏关联标题
        public static var graphDiscoveryTitle: String { tr("coachmark.graphDiscovery.title") }

        /// 引导对话框：发现隐藏关联描述信息
        public static var graphDiscoveryDesc: String { tr("coachmark.graphDiscovery.desc") }

        /// 引导对话框：发现隐藏关联动作按钮文字
        public static var graphDiscoveryAction: String { tr("coachmark.graphDiscovery.action") }
    }
}
