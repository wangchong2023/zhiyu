//
//  HexSpiralCalculatorTests.swift
//  ZhiYuTests
//
//  Created by Antigravity on 2026/06/21.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层测试
//  核心职责：验证六角蜂窝螺旋排布计算器（HexSpiralCalculator）坐标生成的唯一性、中心对齐与物理坐标转换的正确性。
//

import XCTest
@testable import ZhiYu

final class HexSpiralCalculatorTests: ZhiYuTestCase {
    
    /// 验证螺旋生成的坐标点是否具备唯一性，没有重叠
    func testSpiralCoordinatesUniqueness() {
        let count = 50
        let coords = HexSpiralCalculator.generateSpiralCoordinates(count: count)
        
        // 验证生成的坐标数量与请求数量完全对齐
        XCTAssertEqual(coords.count, count, "生成的螺旋网格坐标数应当等于输入数量")
        
        // 验证去重后的唯一性，保证蜂窝格子之间不重叠
        let uniqueCoords = Set(coords)
        XCTAssertEqual(uniqueCoords.count, count, "所有生成的螺旋网格轴向坐标必须唯一，不能发生重叠")
    }
    
    /// 验证第 0 个标签（词频最高）是否精确锁定在几何中心原点 (0, 0)
    func testCenterAlignment() {
        let count = 10
        let coords = HexSpiralCalculator.generateSpiralCoordinates(count: count)
        
        XCTAssertFalse(coords.isEmpty, "生成坐标列表不应为空")
        XCTAssertEqual(coords[0].axialQ, 0, "首个高频标签 axialQ 轴应置于原点中心")
        XCTAssertEqual(coords[0].axialR, 0, "首个高频标签 axialR 轴应置于原点中心")
    }
    
    /// 验证物理映射坐标转换算法的正确性
    func testPhysicalPointMapping() {
        // 原点映射物理坐标应仍为原点
        let centerCoord = HexCoordinate(axialQ: 0, axialR: 0)
        let centerPoint = HexSpiralCalculator.convertToPhysicalPoint(coord: centerCoord, stepSize: 64.0)
        XCTAssertEqual(centerPoint.x, 0.0, accuracy: 0.0001, "原点轴向坐标转换为物理坐标 x 必须为 0")
        XCTAssertEqual(centerPoint.y, 0.0, accuracy: 0.0001, "原点轴向坐标转换为物理坐标 y 必须为 0")
        
        // 正交或倾斜位移转换校验
        let offsetCoord = HexCoordinate(axialQ: 1, axialR: 0)
        let offsetPoint = HexSpiralCalculator.convertToPhysicalPoint(coord: offsetCoord, stepSize: 64.0)
        let expectedX = 64.0 * sqrt(3.0)
        XCTAssertEqual(offsetPoint.x, expectedX, accuracy: 0.0001, "偏移坐标物理映射 x 坐标不符")
        XCTAssertEqual(offsetPoint.y, 0.0, accuracy: 0.0001, "偏移坐标物理映射 r 轴为 0 时 y 必须为 0")
    }
}
