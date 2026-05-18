// 功能说明: [Shared]
import SwiftUI

/// 笔记本标识与快速切换组件
/// 采用平台感知的交互模式：
/// - 指针/触控设备：显示下拉菜单 (Menu)
/// - 旋钮/紧凑设备：显示纯展示标签 (Label)
struct VaultBadge: View {
    @Environment(VaultService.self) var vaultService
    @Inject var platformEnv: any AppEnvironmentProtocol // 使用 DI 注入平台环境能力集
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        if let currentVault = vaultService.currentVault {
            adaptiveContainer(currentVault: currentVault)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func adaptiveContainer(currentVault: Vault) -> some View {
        #if os(watchOS)
        // watchOS 降级处理：仅显示标签，不支持下拉菜单
        badgeLabel(currentVault: currentVault)
        #else
        // 具有指针/触控能力的设备使用 Menu
        Menu {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    vaultService.exitVault()
                }
            }) {
                Label(L10n.Vault.backToHub, systemImage: DesignSystem.Icons.backToHub)
            }
        } label: {
            badgeLabel(currentVault: currentVault)
        }
        .buttonStyle(.plain)
        .tint(.primary)
        #endif
    }
    
    @ViewBuilder
    private func badgeLabel(currentVault: any VaultProtocol) -> some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: DesignSystem.Icons.booksVerticalFill)
                .imageScale(.small)
                .foregroundStyle(.primary)
            
            Text(L10n.Vault.label + "：")
                .font(.system(size: DesignSystem.bodyFontSize, weight: .medium))
                .foregroundStyle(.primary)
            
            Text(vaultService.currentVault?.name ?? L10n.Vault.defaultName)
                .font(.system(size: DesignSystem.bodyFontSize, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: 160)
            
            if platformEnv.interactionStyle != InteractionStyle.crown {
                Image(systemName: DesignSystem.Icons.chevronUpDown)
                    .imageScale(.small)
                    .foregroundStyle(.primary.opacity(0.4))
            }
        }
        .padding(.vertical, 6)
        .foregroundStyle(.primary)
    }
}
