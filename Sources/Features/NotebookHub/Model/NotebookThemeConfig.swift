import Foundation

/// 笔记本主题配置模型
/// 用于定义笔记本卡片的背景主题，支持线性渐变和网格渐变
public struct NotebookThemeConfig: Codable, Equatable, Sendable {
    /// 主题类型
    public enum ThemeType: String, Codable, Sendable {
        /// 线性渐变
        case linear
        /// 网格渐变
        case mesh
    }
    
    /// 主题类型
    public var type: ThemeType
    /// 颜色列表（十六进制字符串）
    public var colors: [String]
    /// 随机种子，用于生成不同的渐变效果
    public var seed: Int
    
    /// 初始化笔记本主题配置
    /// - Parameters:
    ///   - type: 主题类型，默认为线性渐变
    ///   - colors: 颜色列表
    ///   - seed: 随机种子，默认为 0
    public init(type: ThemeType = .linear, colors: [String], seed: Int = 0) {
        self.type = type
        self.colors = colors
        self.seed = seed
    }
}
