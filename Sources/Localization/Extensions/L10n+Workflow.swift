// 功能说明: [Shared]
//
// L10n+Workflow.swift
// 智宇 (ZhiYu) 多语言 Workflow 垂直切片强类型扩展定义
//
// 作者: Wang Chong
// 功能说明: 提供工作流服务的强类型多语言接口，映射至 "System" 表。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

extension L10n {
    /// 工作流服务多语言强类型扩展
    public enum Workflow {
        public static let t = "System"
        
        /// 获取带表名映射的翻译
        /// - Parameter key: 多语言键值
        /// - Returns: 翻译文案
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        
        /// 获取带参数的格式化翻译
        /// - Parameters:
        ///   - key: 多语言键值
        ///   - args: 参数列表
        /// - Returns: 格式化后的翻译文案
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        /// 无法访问提醒事项时的错误信息
        public static var accessDeniedMessage: String { tr("workflow.accessDeniedMessage") }
        
        /// 未发现可同步事项时的提示信息
        public static var noTasksFoundMessage: String { tr("workflow.noTasksFoundMessage") }
        
        /// 正在同步中提示
        /// - Parameter count: 同步条数
        /// - Returns: 格式化文案
        public static func syncingMessage(_ count: Int) -> String { trf("workflow.syncingMessage", count) }
        
        /// 同步来源前缀
        /// - Parameter title: 知识页面标题
        /// - Returns: 格式化文案
        public static func sourceNotes(_ title: String) -> String { trf("workflow.sourceNotes", title) }
        
        /// 同步成功提示
        /// - Parameter count: 同步条数
        /// - Returns: 格式化文案
        public static func syncSuccessMessage(_ count: Int) -> String { trf("workflow.syncSuccessMessage", count) }
        
        /// 同步失败错误提示
        /// - Parameter details: 错误详情
        /// - Returns: 格式化文案
        public static func syncErrorMessage(_ details: String) -> String { trf("workflow.syncErrorMessage", details) }
    }
}
