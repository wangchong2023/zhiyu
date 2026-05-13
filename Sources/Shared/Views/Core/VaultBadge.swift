// VaultBadge.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了通用的笔记本标识组件（VaultBadge）。
// 1. 身份标识：在各个功能页面顶部清晰展示当前所处的笔记本名称。
// 2. 快捷切换：点击该组件可快速返回笔记本选择界面。
// 3. 视觉规范：遵循 Platinum 设计规范，采用微光渐变与柔和投影。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct VaultBadge: View {
    @Environment(VaultService.self) var vaultService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        if let currentVault = vaultService.currentVault {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    vaultService.exitVault()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text(currentVault.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.appAccent.opacity(0.1))
                )
                .foregroundStyle(.appAccent)
            }
            .buttonStyle(.plain)
        } else {
            EmptyView()
        }
    }
}
