import Foundation

public struct NotebookThemeConfig: Codable, Equatable, Sendable {
    public enum ThemeType: String, Codable, Sendable {
        case linear
        case mesh
    }
    
    public var type: ThemeType
    public var colors: [String] // Hex strings
    public var seed: Int
    
    public init(type: ThemeType = .linear, colors: [String], seed: Int = 0) {
        self.type = type
        self.colors = colors
        self.seed = seed
    }
}