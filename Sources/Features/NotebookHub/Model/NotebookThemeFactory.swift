import Foundation
import SwiftUI

/// 笔记本主题工厂
/// 提供根据笔记本名称和 ID 确定性生成主题配置的能力
public struct NotebookThemeFactory {
    /// 预定义的主题配色方案
    private static let palettes: [[String]] = [
        ["#4A90E2", "#50E3C2"], // Blue-Teal (蓝色-青色)
        ["#FF9A9E", "#FECFEF"], // Pink-Soft (粉色-柔和)
        ["#A18CD1", "#FBC2EB"], // Purple-Lavender (紫色-薰衣草)
        ["#84FAB0", "#8FD3F4"], // Green-Blue (绿色-蓝色)
        ["#F6D365", "#FDA085"], // Yellow-Orange (黄色-橙色)
        ["#667EEA", "#764BA2"]  // Indigo-Violet (靛蓝-紫罗兰)
    ]
    
    /// 根据名称和 ID 生成主题配置
    /// - Parameters:
    ///   - name: 笔记本名称
    ///   - id: 笔记本唯一标识符
    /// - Returns: 确定性生成的笔记本主题配置
    public static func generate(from name: String, id: UUID) -> NotebookThemeConfig {
        // 使用名称的哈希值选择配色方案
        let hash = abs(name.hashValue)
        let palette = palettes[hash % palettes.count]
        
        // 使用 ID 的哈希值作为渐变种子
        let seed = abs(id.hashValue)
        
        return NotebookThemeConfig(
            type: .linear, // 默认使用线性渐变
            colors: palette,
            seed: seed
        )
    }
}
