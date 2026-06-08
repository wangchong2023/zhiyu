//
//  NotebookThemeConfig.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：笔记本中心：入口页面、笔记本卡片、创建表单。
//
import Foundation

/// 笔记本封面主题配置信息。
/// 决定笔记本封面渲染时采用的色彩集与生成种子。
public struct NotebookThemeConfig: Codable, Equatable, Sendable {
    /// 封面渐变样式类别。
    public enum ThemeType: String, Codable, Sendable {
        /// 线性过渡渐变
        case linear
        /// 径向网格渐变
        case mesh
    }
    
    /// 渐变渲染的类型
    public var type: ThemeType
    /// 渐变所使用的十六进制色彩代码数组
    public var colors: [String]
    /// 随机或拟物物理生成的种子数值
    public var seed: Int
    
    /// 初始化笔记本封面视觉配置
    /// - Parameters:
    ///   - type: 渐变类型，默认为线性渐变
    ///   - colors: 渐变所用颜色代码数组
    ///   - seed: 生成种子，默认为 0
    public init(type: ThemeType = .linear, colors: [String], seed: Int = 0) {
        self.type = type
        self.colors = colors
        self.seed = seed
    }
}