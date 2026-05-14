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
                ToolbarItem(placement: .principal) {
                    VaultBadge()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.medium) {
                        if Trailing.self != EmptyView.self {
                            trailingItems
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    ZStack {
                                        Capsule().fill(Color.appAccent.opacity(0.08))
                                        Capsule().fill(.ultraThinMaterial)
                                    }
                                )
                                .clipShape(Capsule())
                                .compositingGroup() // 消除边缘白边
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
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold)) // 提升字号至标准 17pt
                            .foregroundStyle(.appText)
                        
                        if showVaultBadge {
                            VaultBadge()
                                .scaleEffect(0.85)
                                .padding(.top, -4)
                        }
                    }
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
    func appSubPageToolbar<Trailing: View>(title: String, showVaultBadge: Bool = false, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, showVaultBadge: showVaultBadge, trailing: trailing))
    }
    
    func appSubPageToolbar(title: String, showVaultBadge: Bool = false) -> some View {
        self.modifier(AppSubPageToolbarModifier(title: title, showVaultBadge: showVaultBadge, trailing: { EmptyView() }))
    }
}
