//
//  SplashComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

// MARK: - Splash Background View
/// 程序化启动画面背景：深空 + 神经网络节点 + 书本光芒
struct SplashBackgroundView: View {
    let starTwinkle: Bool
    let nodeGlow: Bool

    // 预生成的随机数据
    private struct StarConfig { let x: CGFloat; let y: CGFloat; let size: CGFloat; let delay: Double }
    private let stars: [StarConfig] = [
        (0.12, 0.08, 1.5, 0.0), (0.85, 0.05, 1.0, 0.3), (0.45, 0.12, 2.0, 0.6),
        (0.72, 0.18, 1.2, 0.2), (0.28, 0.22, 1.8, 0.8), (0.93, 0.25, 1.0, 0.1),
        (0.08, 0.30, 1.5, 0.5), (0.55, 0.08, 1.3, 0.7), (0.38, 0.28, 1.0, 0.4),
        (0.65, 0.32, 2.0, 0.9), (0.18, 0.42, 1.2, 0.15), (0.78, 0.38, 1.5, 0.55),
        (0.50, 0.45, 1.0, 0.35), (0.90, 0.48, 1.8, 0.75), (0.32, 0.52, 1.3, 0.25),
        (0.05, 0.55, 1.0, 0.65), (0.62, 0.58, 2.0, 0.45), (0.42, 0.35, 1.5, 0.85),
        (0.75, 0.55, 1.2, 0.05), (0.22, 0.62, 1.0, 0.95), (0.88, 0.62, 1.8, 0.38),
        (0.15, 0.68, 1.5, 0.58), (0.58, 0.42, 1.0, 0.18), (0.35, 0.72, 2.0, 0.78),
        (0.82, 0.72, 1.3, 0.28), (0.48, 0.68, 1.0, 0.48), (0.68, 0.48, 1.5, 0.68),
        (0.10, 0.78, 1.2, 0.88), (0.92, 0.82, 1.0, 0.08), (0.40, 0.82, 1.8, 0.42)
    ]

    // 神经网络节点位置
    private struct NetworkNodeConfig { let x: CGFloat; let y: CGFloat; let size: CGFloat; let isAccent: Bool }
    private let networkNodes: [NetworkNodeConfig] = [
        (0.20, 0.15, 5, false), (0.40, 0.10, 6, true), (0.60, 0.18, 5, false),
        (0.80, 0.12, 4, false), (0.15, 0.30, 4, false), (0.35, 0.28, 7, true),
        (0.55, 0.25, 5, false), (0.75, 0.30, 6, true), (0.90, 0.22, 4, false),
        (0.25, 0.45, 5, false), (0.50, 0.40, 8, true), (0.70, 0.42, 5, false),
        (0.10, 0.50, 4, false), (0.85, 0.48, 5, false), (0.30, 0.55, 6, true),
        (0.60, 0.52, 4, false), (0.80, 0.55, 5, false), (0.45, 0.60, 7, true)
    ]

    // 网络连接线
    private let connections: [(from: Int, to: Int)] = [
        (0, 1), (1, 2), (2, 3), (0, 4), (1, 5), (2, 6), (3, 7), (8, 7),
        (4, 5), (5, 6), (6, 7), (5, 10), (6, 10), (9, 10), (10, 11),
        (4, 9), (9, 14), (10, 15), (11, 16), (14, 17), (15, 17),
        (12, 9), (13, 16), (8, 5), (1, 6), (5, 10), (10, 17)
    ]

    var body: some View {
        ZStack {
            // 基底渐变：深靛蓝 → 深海军蓝 → 底部暖琥珀光
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.12), location: 0.0),
                    .init(color: Color(red: 0.06, green: 0.08, blue: 0.22), location: 0.3),
                    .init(color: Color(red: 0.08, green: 0.10, blue: 0.28), location: 0.55),
                    .init(color: Color(red: 0.10, green: 0.12, blue: 0.30), location: 0.7),
                    .init(color: Color(red: 0.12, green: 0.10, blue: 0.22), location: 0.85),
                    .init(color: Color(red: 0.18, green: 0.12, blue: 0.15), location: 0.95),
                    .init(color: Color(red: 0.25, green: 0.15, blue: 0.10), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 星星层
            GeometryReader { geo in
                if geo.size.width > 1 && geo.size.height > 1 {
                    ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                        Circle()
                            .fill(.appGloss)
                            .frame(width: star.size, height: star.size)
                            .position(x: geo.size.width * star.x, y: geo.size.height * star.y)
                            .opacity(starTwinkle ? DesignSystem.fullOpacity * 0.7 : DesignSystem.disabledOpacity)
                            .animation(
                                .easeInOut(duration: DesignSystem.Animation.looseDuration + star.delay)
                                .repeatForever(autoreverses: true)
                                .delay(star.delay),
                                value: starTwinkle
                            )
                    }
                }
            }

            // 神经网络连接线
            GeometryReader { geo in
                if geo.size.width > 1 && geo.size.height > 1 {
                    ForEach(Array(connections.enumerated()), id: \.offset) { _, conn in
                        let fromNode = networkNodes[conn.from]
                        let toNode = networkNodes[conn.to]
                        let lineColor1 = fromNode.isAccent ? Color.appAccent.opacity(DesignSystem.disabledOpacity) : Color.appGloss.opacity(DesignSystem.glassOpacity * 1.2)
                        let lineColor2 = toNode.isAccent ? Color.appAccent.opacity(DesignSystem.disabledOpacity) : Color.appGloss.opacity(DesignSystem.glassOpacity * 1.2)
                        
                        Path { path in
                            path.move(to: CGPoint(
                                x: geo.size.width * fromNode.x,
                                y: geo.size.height * fromNode.y
                            ))
                            path.addLine(to: CGPoint(
                                x: geo.size.width * toNode.x,
                                y: geo.size.height * toNode.y
                            ))
                        }
                        .stroke(
                            LinearGradient(
                                colors: [lineColor1, lineColor2],
                                startPoint: .init(x: fromNode.x, y: fromNode.y),
                                endPoint: .init(x: toNode.x, y: toNode.y)
                            ),
                            lineWidth: DesignSystem.borderWidth * 0.8
                        )
                    }
                }
            }

            // 神经网络节点
            GeometryReader { geo in
                if geo.size.width > 1 && geo.size.height > 1 {
                    ForEach(Array(networkNodes.enumerated()), id: \.offset) { index, node in
                        let nodeColor1 = node.isAccent ? Color.appAccent.opacity(DesignSystem.fullOpacity * 0.9) : Color.appGloss.opacity(DesignSystem.fullOpacity * 0.8)
                        let nodeColor2 = node.isAccent ? Color.appAccent.opacity(DesignSystem.disabledOpacity) : Color.appGloss.opacity(DesignSystem.glassOpacity * 2)
                        
                        let nodeScale = nodeGlow ? DesignSystem.fullOpacity : DesignSystem.fullOpacity * 0.5
                        let nodeOpacity = nodeGlow ? DesignSystem.fullOpacity : DesignSystem.disabledOpacity
                        let animDuration = DesignSystem.Animation.slowDuration + Double(index) * 0.1
                        let nodeAnim = SwiftUI.Animation.easeInOut(duration: animDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [nodeColor1, nodeColor2, .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: node.size * 2
                                )
                            )
                            .frame(width: node.size * 4, height: node.size * 4)
                            .position(x: geo.size.width * node.x, y: geo.size.height * node.y)
                            .scaleEffect(nodeScale)
                            .opacity(nodeOpacity)
                            .animation(nodeAnim, value: nodeGlow)
                    }
                }
            }

            // 书本光芒 — 底部中央的暖光
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.5).opacity(DesignSystem.glassOpacity * 2.5), // 0.25
                        Color(red: 0.9, green: 0.65, blue: 0.3).opacity(DesignSystem.glassOpacity * 1.2), // 0.12
                        Color(red: 0.7, green: 0.4, blue: 0.2).opacity(DesignSystem.shadowOpacity / 2), // 0.05
                        .clear
                    ],
                    center: .center,
                    startRadius: DesignSystem.loosePadding, // 20
                    endRadius: DesignSystem.Metrics.heroValueSize * 9.6 // 250
                )
                .frame(height: DesignSystem.Metrics.heroValueSize * 11.5) // 300
                .offset(y: DesignSystem.Metrics.heroValueSize * 3) // 80
            }

            // 书本轮廓 — 极简线条
            VStack {
                Spacer()
                ZStack {
                    // 书本主体
                    RoundedRectangle(cornerRadius: DesignSystem.tiny)
                        .stroke(Color.appAccent.opacity(DesignSystem.disabledOpacity * 1.15), lineWidth: DesignSystem.borderWidth * 1.2) // 0.35, 1.2
                        .frame(width: DesignSystem.Metrics.iconBoxSize + DesignSystem.medium, height: DesignSystem.iconDisplay) // 60, 44
                        .rotationEffect(.degrees(-8))
                        .offset(x: -DesignSystem.atomic) // -2

                    RoundedRectangle(cornerRadius: DesignSystem.tiny)
                        .stroke(Color.appAccent.opacity(DesignSystem.disabledOpacity * 1.15), lineWidth: DesignSystem.borderWidth * 1.2) // 0.35, 1.2
                        .frame(width: DesignSystem.Metrics.iconBoxSize + DesignSystem.medium, height: DesignSystem.iconDisplay) // 60, 44
                        .rotationEffect(.degrees(8))
                        .offset(x: DesignSystem.atomic) // 2

                    // 书脊
                    Capsule()
                        .fill(Color.appAccent.opacity(DesignSystem.glassOpacity * 2)) // 0.2
                        .frame(width: DesignSystem.atomic + 1, height: DesignSystem.iconDisplay) // 3, 44

                    // 从书中升起的光粒子
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.appAccent.opacity(DesignSystem.glassOpacity * 4)) // 0.4
                            .frame(width: DesignSystem.atomic + 1, height: DesignSystem.atomic + 1) // 3, 3
                            .offset(
                                x: CGFloat(i - 2) * (DesignSystem.small + DesignSystem.tiny), // 14
                                y: nodeGlow ? -DesignSystem.Metrics.iconBoxSize * 1.35 - CGFloat(i) * 15 : -DesignSystem.loosePadding // -60, -20
                            )
                            .opacity(nodeGlow ? DesignSystem.fullOpacity * 0.6 : DesignSystem.glassOpacity) // 0.6, 0.1
                            .animation(
                                .easeOut(duration: 3.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: nodeGlow
                            )
                    }
                }
                .padding(.bottom, DesignSystem.Metrics.heroValueSize * 7) // 180
            }
        }
    }
}
