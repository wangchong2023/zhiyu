// AboutView.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：关于页面：展示应用版本信息、版权声明及核心理念
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-12
// 日期: 2026-05-12
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 关于页面
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.huge) {
                // App Icon & Name
                VStack(spacing: Spacing.medium) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: DesignSystem.Domain.About.logoSize, height: DesignSystem.Domain.About.logoSize)
                            .shadow(color: .appAccent.opacity(0.3), radius: 15, y: 8)
                        
                        Image(systemName: DesignSystem.Icons.sparkles)
                            .font(.system(size: DesignSystem.Domain.About.logoSize / 2))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text(Localized.tr("app.name"))
                            .font(.title2.bold())
                    }
                }
                .padding(.top, 40)
                
                // Description
                Text(L10n.Vault.tr("subtitle"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.huge)
                
                // Info List
                VStack(spacing: 1) {
                    infoRow(title: L10n.Settings.tr("about.developer"), value: L10n.Settings.tr("about.developerName"))
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.tr("about.website"), value: "https://zhiyu.ai")
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.tr("about.version"), value: "1.0.0 (20260512)")
                }
                .background(Color.appCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
                .padding(.horizontal, Spacing.standardPadding)
                
                Spacer()
                
                // Copyright
                Text("Copyright © 2026 Wang Chong.\nAll rights reserved.")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .navigationTitle(L10n.Settings.tr("section.about"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.appSecondary)
        }
        .padding(Spacing.standardPadding)
    }
}
