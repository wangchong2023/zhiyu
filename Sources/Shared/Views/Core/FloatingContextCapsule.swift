import SwiftUI

/// 方案 D 核心组件：悬浮上下文胶囊
/// 集成了侧边栏开关、当前笔记本标识及数据洞察入口
struct FloatingContextCapsule: View {
    @Environment(VaultService.self) var vaultService
    @EnvironmentObject var themeManager: ThemeManager
    
    var onToggleSidebar: (() -> Void)?
    var onShowInsights: (() -> Void)?
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            // 1. 图 1 风格集成按钮：视图模式切换
            Button {
                HapticFeedback.shared.trigger(.selection)
                NotificationCenter.default.post(name: NSNotification.Name("toggleDisplayMode"), object: nil)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
            }
            
            Divider()
                .frame(height: 20)
                .background(.white.opacity(0.3))
            
            // 2. 语境标识 (Avenir Next 风格文字)
            if let currentVault = vaultService.currentVault {
                vaultMenu(currentVault)
            } else {
                hubIndicator
            }
        }
        .padding(.horizontal, DesignSystem.small)
        .background(
            ZStack {
                // 方案 D：极高透明度的深色玻璃
                Capsule().fill(.black.opacity(0.4))
                Capsule().fill(.ultraThinMaterial)
            }
        )
        .overlay(
            // 方案 D 核心：绚丽的外发光描边
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .appAccent.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(color: .appAccent.opacity(0.5), radius: 8, x: 0, y: 0)
        )
        .clipShape(Capsule())
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    @ViewBuilder
    private func vaultMenu(_ vault: VaultService.Vault) -> some View {
        #if os(watchOS)
        HStack(spacing: DesignSystem.small) {
            Text(vault.name)
                .font(.custom("Avenir Next", size: 18).weight(.bold))
                .lineLimit(1)
        }
        .padding(.trailing, DesignSystem.medium)
        .frame(minHeight: 44)
        #else
        Menu {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                onShowInsights?()
            }) {
                Label(L10n.Dashboard.tr("index.overview"), systemImage: DesignSystem.Icons.comparison)
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                    vaultService.exitVault()
                }
            }) {
                Label(L10n.Vault.tr("backToHub"), systemImage: "arrow.left.circle")
            }
        } label: {
            HStack(spacing: DesignSystem.small) {
                Text(vault.name)
                    .font(.custom("Avenir Next", size: 18).weight(.bold))
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.trailing, DesignSystem.medium)
            .frame(minHeight: 44)
        }
        #endif
    }
    
    private var hubIndicator: some View {
        HStack(spacing: DesignSystem.small) {
            Text("My Knowledge") // 完美对齐图 1
                .font(.custom("Avenir Next", size: 18).weight(.bold))
            
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.trailing, DesignSystem.medium)
        .frame(minHeight: 44)
    }
}
