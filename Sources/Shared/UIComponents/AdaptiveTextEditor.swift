//
//  AdaptiveTextEditor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/04.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：跨平台自适应文本编辑器 —— watchOS 使用可垂直扩展的 TextField，其他平台使用 TextEditor。
//

import SwiftUI

/// 跨平台自适应文本编辑器
///
/// watchOS 上 `TextEditor` 不可用，降级为带垂直轴的 `TextField`；
/// iOS / macOS 上使用原生 `TextEditor`。
public struct AdaptiveTextEditor: View {
    @Binding private var text: String

    /// 创建自适应文本编辑器
    /// - Parameter text: 绑定的文本内容
    public init(text: Binding<String>) {
        self._text = text
    }

    public var body: some View {
        #if os(watchOS)
        TextField("", text: $text, axis: .vertical)
        #else
        TextEditor(text: $text)
        #endif
    }
}
