// AppInputs.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 的标准输入控件体系，包括文本框、标签/令牌输入框及等宽编辑器。
// 核心职责：
// 1. 提供统一样式的输入组件，封装背景、圆角及交互反馈。
// 2. 支持自动分词的标签输入逻辑及针对代码/Markdown 优化的等宽编辑器。
// MARK: [PR-03] 统一输入控件规范，提升数据录入的流畅度与视觉一致性
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Text Field

/// 统一样式的文本输入框
/// 提供标准的卡片背景与内边距。
public struct AppTextField: View {
    public let placeholder: String
    @Binding public var text: String

    public init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
            .foregroundStyle(.appText)
    }
}

// MARK: - App Tag Field

/// 标签/令牌输入框
/// 支持芯片式展示、自动分词及删除交互。
public struct AppTagField: View {
    public let placeholder: String
    @Binding public var tags: [String]
    @State private var newTag: String = ""

    public init(placeholder: String, tags: Binding<[String]>) {
        self.placeholder = placeholder
        self._tags = tags
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // 使用 FlowLayout 自动换行排列标签
            FlowLayout(spacing: Spacing.tiny + Spacing.atomic) { // 6
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: Spacing.atomic * 1.5) { // 3
                        Text(tag)
                            .font(.system(size: Typography.microFontSize + 1))
                        
                        Button(action: { 
                            withAnimation(.spring(response: Animations.Interaction.standardDuration)) {
                                tags.removeAll { $0 == tag }
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: Typography.microFontSize - 1))
                                .foregroundStyle(.appSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.tiny)
                    .background(Color.appAccent.opacity(Colors.glassOpacity))
                    .clipShape(Capsule())
                    .foregroundStyle(.appAccent)
                }
                
                // 标签输入框
                TextField(placeholder, text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onChange(of: newTag) { _, newValue in
                        // 自动检测空格、逗号或中文逗号进行分词
                        if newValue.hasSuffix(" ") || newValue.hasSuffix(",") || newValue.hasSuffix("，") {
                            addCurrentTag()
                        }
                    }
                    .onSubmit {
                        addCurrentTag()
                    }
                    .frame(minWidth: Spacing.largeIconSize * 2.5) // 100
                    .foregroundStyle(.appText)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.standardRadius)
                    .stroke(Color.appBorder.opacity(Colors.disabledOpacity), lineWidth: Spacing.borderWidth)
            )
        }
    }
    
    /// 将当前输入的内容添加为标签并清空输入框
    private func addCurrentTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: ",，")))
            .replacingOccurrences(of: "#", with: "")
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            withAnimation(.appStandard) {
                tags.append(trimmed)
            }
        }
        newTag = ""
    }
}

// MARK: - App Monospaced Editor

/// 等宽文本编辑器
/// 适用于 Markdown、代码或需要精确排版的文本录入。
public struct AppMonospacedEditor: View {
    @Binding public var text: String
    public var minHeight: CGFloat = 200

    public init(text: Binding<String>, minHeight: CGFloat = 200) {
        self._text = text
        self.minHeight = minHeight
    }

    public var body: some View {
        #if os(watchOS)
        TextField("", text: $text, axis: .vertical)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.appText)
            .padding(Spacing.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
        #else
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .foregroundStyle(.appText)
            .frame(minHeight: minHeight)
            .padding(Spacing.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
        #endif
    }
}
