//
//  QuizPresentationModifier.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 View 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 测验展示修饰符
/// 针对 iPad 提供 Sheet 展示，针对 iPhone 提供全屏覆盖展示。
struct QuizPresentationModifier: ViewModifier {
    @Binding var activeQuiz: QuizModel?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(activeQuiz: Binding<QuizModel?>) {
        self._activeQuiz = activeQuiz
    }

    public func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .sheet(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                        .frame(minWidth: Spacing.Decorator.desktopSheetMinWidth, minHeight: Spacing.Decorator.desktopSheetMinHeight)
                }
        } else {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            content
                .fullScreenCover(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                }
            #else
            content
                .sheet(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                }
            #endif
        }
    }
}

extension View {
    /// 应用测验展示模态
    func quizPresentation(activeQuiz: Binding<QuizModel?>) -> some View {
        modifier(QuizPresentationModifier(activeQuiz: activeQuiz))
    }
}
