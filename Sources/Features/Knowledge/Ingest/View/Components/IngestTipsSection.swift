//
//  IngestViewComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：知识摄入：文档导入、URL 抓取、OCR 扫描、PDF 解析。
//
import SwiftUI

// MARK: - Ingest Tips Section
/// 导入操作提示区域组件
/// 负责提供各导入方式的功能说明及操作建议，提升用户初次使用体验
struct IngestTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.tips, icon: DesignSystem.Icons.concept, iconColor: .orange)
                .padding(.horizontal, DesignSystem.tiny)

            // Three import method cards
            HStack(spacing: DesignSystem.small + DesignSystem.atomic) { // 10
                importMethodCard(
                    icon: DesignSystem.Icons.docBadgePlus,
                    title: L10n.Ingest.method.file,
                    desc: L10n.Ingest.method.fileDesc
                )
                importMethodCard(
                    icon: DesignSystem.Icons.ocr,
                    title: L10n.Ingest.method.ocr,
                    desc: L10n.Ingest.method.ocrDesc
                )
                importMethodCard(
                    icon: DesignSystem.Icons.pencilClipboard,
                    title: L10n.Ingest.method.manual,
                    desc: L10n.Ingest.method.manualDesc
                )
            }
            .appContainer(padding: true)
        }
        .padding(.horizontal)
    }

    private func importMethodCard(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.appAccent)
                .frame(maxWidth: .infinity)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.appText)
            Text(desc)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.small + DesignSystem.atomic) // 10
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }
}
