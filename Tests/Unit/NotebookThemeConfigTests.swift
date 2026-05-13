// NotebookThemeConfigTests.swift
//
// 功能说明: 笔记本主题配置模型测试
//

import XCTest
@testable import ZhiYu

final class NotebookThemeConfigTests: XCTestCase {
    
    func testNotebookThemeConfigInitialization() {
        let colors = ["#FFFFFF", "#000000"]
        let config = NotebookThemeConfig(type: .linear, colors: colors, seed: 42)
        
        XCTAssertEqual(config.type, .linear)
        XCTAssertEqual(config.colors, colors)
        XCTAssertEqual(config.seed, 42)
    }
    
    func testNotebookThemeConfigCodable() throws {
        let colors = ["#FF5733", "#C70039"]
        let config = NotebookThemeConfig(type: .mesh, colors: colors, seed: 123)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(NotebookThemeConfig.self, from: data)
        
        XCTAssertEqual(config, decodedConfig)
    }
}
