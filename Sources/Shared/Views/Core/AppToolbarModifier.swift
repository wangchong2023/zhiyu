// AppToolbarModifier.swift
//
// 作者: Wang Chong
// 功能说明: 统一主标签页的工具栏样式，包含知识库标识与用户头像。支持自定义额外的工具栏项。
// 版本: 1.1
// 修改记录:
//   - 2026-05-12: 增加对自定义尾部工具栏项的支持，优化 Hstack 布局
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 主标签页工具栏修饰符
struct AppTabToolbarModifier<Trailing: View>: ViewModifier {
    let title: String
    let trailingItems: Trailing
    
    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailingItems = trailing()
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VaultBadge()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.medium) {
                        trailingItems
                        UserProfileMenu()
                    }
                }
            }
    }
}

extension View {
    /// 应用主标签页统一工具栏 (带头像)
    /// - Parameters:
    ///   - title: 页面标题
    ///   - trailing: 额外的尾部工具栏项
    func appTabToolbar<Trailing: View>(title: String, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self.modifier(AppTabToolbarModifier(title: title, trailing: trailing))
    }
    
    /// 应用主标签页统一工具栏 (带头像，无额外项)
    /// - Parameter title: 页面标题
    func appTabToolbar(title: String) -> some View {
        self.modifier(AppTabToolbarModifier(title: title, trailing: { EmptyView() }))
    }
}
