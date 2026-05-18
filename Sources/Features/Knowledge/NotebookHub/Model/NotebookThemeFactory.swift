import Foundation
import SwiftUI

/// [L2] 笔记本主题工厂：负责基于 AI 语义启发生成动态背景配置
public struct NotebookThemeFactory {
    /// 语义配色字典：将标题关键字映射到特定的色系
    private static let semanticPalettes: [String: [String]] = [
        "科学": ["#4A90E2", "#50E3C2", "#B8E986", "#1F3B4D"], // 科技蓝绿
        "物理": ["#4A90E2", "#50E3C2", "#B8E986", "#1F3B4D"],
        "数学": ["#4A90E2", "#50E3C2", "#B8E986", "#1F3B4D"],
        "艺术": ["#FF9A9E", "#FECFEF", "#A18CD1", "#FBC2EB"], // 艺术粉紫
        "文学": ["#FF9A9E", "#FECFEF", "#A18CD1", "#FBC2EB"],
        "历史": ["#F6D365", "#FDA085", "#D4A373", "#7F4F24"], // 复古暖色
        "自然": ["#84FAB0", "#8FD3F4", "#2D6A4F", "#00B4D8"], // 自然苍翠
        "代码": ["#000000", "#333333", "#00FF41", "#008F11"], // 极客黑绿
        "编程": ["#000000", "#333333", "#00FF41", "#008F11"]
    ]
    
    private static let defaultPalettes: [[String]] = [
        ["#4A90E2", "#50E3C2", "#764BA2", "#FF9A9E"],
        ["#A18CD1", "#FBC2EB", "#8FD3F4", "#84FAB0"],
        ["#F6D365", "#FDA085", "#764BA2", "#4A90E2"]
    ]
    
    /// 根据笔记本名称生成主题配置
    /// - Parameters:
    ///   - name: 笔记本名称
    ///   - id: 笔记本唯一标识
    /// - Returns: 符合语义或随机启发的主题配置
    public static func generate(from name: String, id: UUID) -> NotebookThemeConfig {
        // 1. 语义启发匹配
        var palette: [String] = []
        for (keyword, colors) in semanticPalettes {
            if name.localizedCaseInsensitiveContains(keyword) {
                palette = colors
                break
            }
        }
        
        // 2. 如果未匹配，使用哈希分发默认配色
        if palette.isEmpty {
            let hash = abs(name.hashValue)
            palette = defaultPalettes[hash % defaultPalettes.count]
        }
        
        let seed = abs(id.hashValue)
        
        // 默认返回 mesh 类型，打造 AI 驱动的流体感
        return NotebookThemeConfig(
            type: .mesh,
            colors: palette,
            seed: seed
        )
    }
}