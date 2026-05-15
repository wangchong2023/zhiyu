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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if !os(watchOS)
                ToolbarItem(placement: .topBarLeading) {
                    // 纯空间占位符：用于平衡右侧头像菜单，确保中间 principal 元素物理居中
                    Spacer()
                        .frame(width: 40)
                }
                #endif
                
                #if os(watchOS)
                ToolbarItem(placement: .topBarTrailing) {
                    VaultBadge()
                }
                #else
                ToolbarItem(placement: .principal) {
                    VaultBadge()
                }
                #endif
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DesignSystem.small) {
                        if Trailing.self != EmptyView.self {
                            trailingItems
                        }
                        UserProfileMenu()
                    }
                    .fixedSize()
                }
            }
    }
}

// MARK: - Sub Page Toolbar
/// 子页面工具栏修饰符 (解决返回按钮重叠)
struct AppSubPageToolbarModifier<Trailing: View>: ViewModifier {
    let title: String
    let trailingItems: Trailing
    let showVaultBadge: Bool
    
    init(title: String, showVaultBadge: Bool = false, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.showVaultBadge = showVaultBadge
        self.trailingItems = trailing()
    }
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(watchOS)
                ToolbarItem(placement: .topBarLeading) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.appText)
                }
                #else
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.appText)
                        
                        if showVaultBadge {
                            VaultBadge()
                                .scaleEffect(0.85)
                                .padding(.top, -4)
                        }
                    }
                }
                #endif
                
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
    func appSubPageToolbar<Trailing: View>(title: String, showVaultBadge: Bool = false, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, showVaultBadge: showVaultBadge, trailing: trailing))
    }
    
    func appSubPageToolbar(title: String, showVaultBadge: Bool = false) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, showVaultBadge: showVaultBadge, trailing: { EmptyView() }))
    }
}
