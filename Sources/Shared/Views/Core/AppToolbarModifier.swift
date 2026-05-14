import SwiftUI

// MARK: - Root Tab Toolbar
/// 主标签页工具栏修饰符 (用于根页面)
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
                        if Trailing.self != EmptyView.self {
                            trailingItems
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.appAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        UserProfileMenu()
                    }
                }
            }
    }
}

// MARK: - Sub Page Toolbar
/// 子页面工具栏修饰符 (解决返回按钮重叠)
struct AppSubPageToolbarModifier<Trailing: View>: ViewModifier {
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
                // 子页面下，VaultBadge 与返回按钮并排
                ToolbarItem(placement: .topBarLeading) {
                    VaultBadge()
                        .padding(.leading, -4) // 微调位置以紧贴返回按钮
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    trailingItems
                }
            }
    }
}

extension View {
    /// 应用主标签页统一工具栏 (根页面使用)
    func appTabToolbar<Trailing: View>(title: String, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self.modifier(AppTabToolbarModifier(title: title, trailing: trailing))
    }
    
    func appTabToolbar(title: String) -> some View {
        self.modifier(AppTabToolbarModifier(title: title, trailing: { EmptyView() }))
    }
    
    /// 应用子页面统一工具栏 (解决重叠，保留返回路径)
    func appSubPageToolbar<Trailing: View>(title: String, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, trailing: trailing))
    }
    
    func appSubPageToolbar(title: String) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, trailing: { EmptyView() }))
    }
}
