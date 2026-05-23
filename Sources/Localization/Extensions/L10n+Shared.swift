//
//  L10n+Shared.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Shared 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    /// 共享组件与通用视觉风格本地化词条
    public struct Shared {
        /// 笔记本页数本地化格式化模板，接收页数参数
        public static var pageCountFormat: String { "%d 篇知识" }
        
        /// 默认错误提示标题
        public static var errorTitle: String { "出错了" }
        
        /// 重新尝试按钮文本
        public static var retryButton: String { "重新尝试" }
        
        /// 文本编辑器默认占位符
        public static var editorPlaceholder: String { "请输入内容..." }
        
        /// 标准极地主题名称
        public static var themeStandard: String { "标准极地" }
        
        /// 落日余晖主题名称
        public static var themeSunset: String { "落日余晖" }
        
        /// 霓虹深空主题名称
        public static var themeNeonPurple: String { "霓虹深空" }
    }
}
