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
                        RoundedRectangle(cornerRadius: Spacing.giant)
                            .fill(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: DesignSystem.Domain.About.logoSize, height: DesignSystem.Domain.About.logoSize)
                            .shadow(color: .appAccent.opacity(DesignSystem.Opacity.shadow), radius: 15, y: 8)
                        
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
                    infoRow(title: L10n.Settings.About.website, value: AppConstants.URLs.officialWebsite)
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.About.version, value: versionDisplayString)
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.About.build, value: buildDetailString)
                    Divider().padding(.leading, Spacing.standardPadding)
                    infoRow(title: L10n.Settings.About.buildTime, value: buildTimestampString)
                }
                .background(Color.appCard.opacity(DesignSystem.Opacity.soft))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
                .padding(.horizontal, Spacing.standardPadding)
                
                Spacer()
                
                // Copyright
                Text(L10n.Settings.About.copyright)
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) {
                    dismiss()
                }
            }
        }
    }
    
    /// 版本号（SemVer），从 Info.plist 的 CFBundleShortVersionString 读取
    private var versionDisplayString: String {
        VersionInfoFormatter.semVerString(from: Bundle.main.infoDictionary)
    }

    /// 构建详情：构建号 + 短哈希
    private var buildDetailString: String {
        VersionInfoFormatter.buildDetailString(from: Bundle.main.infoDictionary)
    }

    /// 构建时间，从 Info.plist 的 BUILD_TIMESTAMP 读取
    private var buildTimestampString: String {
        VersionInfoFormatter.buildTimestampString(from: Bundle.main.infoDictionary)
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
