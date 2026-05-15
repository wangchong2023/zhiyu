// AboutView.swift
//
// 作者: Wang Chong
// 功能说明: 关于页面：展示应用版本信息、版权声明及核心理念
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
                            .frame(width: 100, height: 100)
                            .shadow(color: .appAccent.opacity(0.3), radius: 15, y: 8)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text(Localized.tr("app.name"))
                            .font(.title2.bold())
                        
                        Text("Version 1.0.0 (Build 20260512)")
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
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
                    infoRow(title: "Developer", value: "Wang Chong")
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: "Website", value: "https://zhiyu.ai")
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: "Open Source", value: "MIT License")
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Common.tr("close")) {
                    dismiss()
                }
                .fontWeight(.medium)
            }
        }
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
