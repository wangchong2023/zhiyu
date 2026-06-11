//
//  AppLottieView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/03.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Feedback 模块，封装 Airbnb Lottie 动效播放器，支持多端适配。
//
import SwiftUI
import Lottie

/// 跨平台 Lottie 动效播放组件
/// 支持原生 fallback 退化策略：若找不到指定的 Lottie json/dotLottie 文件，
/// 将自动降级为原生 SwiftUI 的骨架屏动画或 ProgressView。
public struct AppLottieView: View {
    public let animationName: String
    public let loopMode: LottieLoopMode
    public let contentMode: UIView.ContentMode
    
    public init(name: String, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.animationName = name
        self.loopMode = loopMode
        self.contentMode = contentMode
    }
    
    public var body: some View {
        if Bundle.main.url(forResource: animationName, withExtension: "json") != nil {
            // 使用 LottieView 原生 SwiftUI 支持 (lottie-ios 4.x)
            LottieView(animation: .named(animationName))
                .configure({ view in
                    view.contentMode = contentMode
                })
                .looping()
        } else {
            // 如果找不到 Lottie 资源文件，优雅降级为纯 SwiftUI 的呼吸灯
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(DesignSystem.Opacity.medium))
                Circle()
                    .stroke(Color.appAccent, lineWidth: 2)
                    .modifier(PulsingDot(delay: 0))
            }
        }
    }
}
