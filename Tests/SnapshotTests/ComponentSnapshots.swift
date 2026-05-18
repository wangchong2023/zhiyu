// ComponentSnapshots.swift
//
// 作者: Wang Chong
// 功能说明: 测试 AI 脉搏指示器的视觉一致性
// 版本: 1.1
// 修改记录:
//   - 2026-05-07: 适配 DI 重构与 Swift 6 并发模型。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
import SwiftUI
import SnapshotTesting
import Combine
import GRDB
@testable import ZhiYu

@MainActor
final class ComponentSnapshots: XCTestCase {
    
    /// 测试 AI 脉搏指示器的视觉一致性
    func testAIPulseIndicator() {
        // 配置 Mock 环境
        setupMockEnvironment()
        
        let store = AppStore()
        let view = AIPulseIndicator()
            .environment(store)
            .frame(width: 150, height: 60)
            .background(Color.appBackground)
        
        // 记录/验证 iOS 布局
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    private func setupMockEnvironment() {
        setupFullMockEnvironment()
    }
    
    /// 测试图谱节点的视觉一致性
    func testGraphNodeView() {
        let node = GraphNode(
            id: UUID(),
            title: "测试节点",
            pageType: .concept,
            position: .zero
        )
        
        // 使用包装器提供 Namespace
        let view = SnapshotContainer { namespace in
            GraphNodeView(
                node: node,
                isSelected: false,
                isAnimating: false,
                linkCount: 5,
                clusters: [],
                useClustering: false,
                onSelect: {},
                heroNamespace: namespace,
                viewportRect: CGRect(x: 0, y: 0, width: 200, height: 200),
                scale: 1.0
            )
        }
        .frame(width: 100, height: 100)
        .background(Color.appBackground)
        
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)))
    }
}

// MARK: - Snapshot Helpers

/// 用于快照测试的容器，提供 Namespace 和必要的环境注入
struct SnapshotContainer<Content: View>: View {
    @Namespace var namespace
    let content: (Namespace.ID) -> Content
    
    var body: some View {
        content(namespace)
    }
}
