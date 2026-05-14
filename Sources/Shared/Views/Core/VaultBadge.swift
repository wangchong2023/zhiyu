import SwiftUI

/// 笔记本标识与快速切换组件
/// 采用下拉菜单 (Menu) 模式，解决导航重叠并提供快捷操作
struct VaultBadge: View {
    @Environment(VaultService.self) var vaultService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        if let currentVault = vaultService.currentVault {
            Menu {
                // 1. 切换笔记本操作
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vaultService.exitVault()
                    }
                }) {
                    Label(L10n.Vault.tr("backToHub"), systemImage: "arrow.left.circle")
                }
                
                Divider()
                
                // 2. 笔记本详情/设置 (预留)
                Button(action: {}) {
                    Label(currentVault.name, systemImage: "info.circle")
                }
                .disabled(true)
                
            } label: {
                HStack(spacing: DesignSystem.Chip.spacing) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: DesignSystem.captionIconSize + DesignSystem.atomic)) // 14pt
                    
                    if !currentVault.name.isEmpty {
                        Text(currentVault.name)
                            .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold, design: .rounded)) // 14pt
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: DesignSystem.captionIconSize - DesignSystem.atomic, weight: .bold)) // 10pt
                        .foregroundStyle(.appAccent.opacity(DesignSystem.secondaryOpacity))
                }
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.Chip.verticalPadding * 2)
                .background(
                    ZStack {
                        Capsule().fill(Color.appAccent.opacity(DesignSystem.glassOpacity))
                        Capsule().fill(.ultraThinMaterial)
                    }
                )
                .compositingGroup()
                .foregroundStyle(.appAccent)
            }
            .buttonStyle(.plain)
        } else {
            EmptyView()
        }
    }
}
