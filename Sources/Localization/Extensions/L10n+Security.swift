// L10n+Security.swift
// 智宇 (ZhiYu) 多语言 Security 强类型扩展定义
//
// 作者: Wang Chong
// 功能说明: [Shared] 全局安全模块 L10n 国际化键映射（物理挂载于 System.xcstrings 字典中）
// 版本: 1.0
// 日期: 2026-05-19
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation

extension L10n {
    public enum Security {
        public static let t = "System"
        
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }
        
        // MARK: - Prompt 防御与消毒词条
        
        /// 日志：拦截到高风险注入
        public static func promptInjectionLog(_ pattern: String) -> String {
            trf("security.prompt.injection_log", pattern)
        }
        
        /// 拦截到非法指令注入过滤时的无害替代占位文本
        public static var promptInjectionPlaceholder: String {
            tr("security.prompt.injection_placeholder")
        }
        
        /// DLP 拦截：移除网络动态图像时的无害替代占位文本
        public static var dlpImagePlaceholder: String {
            tr("security.dlp.image_placeholder")
        }
        
        /// XML 沙箱包裹参考上下文时的引导词模板（支持 %1$@ 包裹的参考资料）
        public static func sandboxInstructions(with content: String) -> String {
            trf("security.sandbox.instructions", content)
        }
    }
}
