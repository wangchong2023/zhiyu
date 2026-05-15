import Foundation
import SwiftUI

public struct NotebookThemeFactory {
    private static let palettes: [[String]] = [
        ["#4A90E2", "#50E3C2"], // Blue-Teal
        ["#FF9A9E", "#FECFEF"], // Pink-Soft
        ["#A18CD1", "#FBC2EB"], // Purple-Lavender
        ["#84FAB0", "#8FD3F4"], // Green-Blue
        ["#F6D365", "#FDA085"], // Yellow-Orange
        ["#667EEA", "#764BA2"]  // Indigo-Violet
    ]
    
    public static func generate(from name: String, id: UUID) -> NotebookThemeConfig {
        let hash = abs(name.hashValue)
        let palette = palettes[hash % palettes.count]
        let seed = abs(id.hashValue)
        
        return NotebookThemeConfig(
            type: .linear, // Default type
            colors: palette,
            seed: seed
        )
    }
}