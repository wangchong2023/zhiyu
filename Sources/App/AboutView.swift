//
//  AboutView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：构建 About 界面的 UI 视图层组件。
//
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
                    
                    VStack(spacing: DesignSystem.tiny) {
                        Text(L10n.Common.appName)
                            .font(.title2.bold())
                    }
                }
                .padding(.top, 40)
                
                // Description
                Text(L10n.Vault.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.huge)
                
                // Info List
                VStack(spacing: 1) {
                    infoRow(title: L10n.Settings.About.developer, value: L10n.Settings.About.developerName)
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.About.website, value: "https://zhiyu.ai")
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.About.version, value: "1.0.0 (20260512)")
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
        .navigationTitle(L10n.Settings.Section.about)
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
