//
//  IngestViewComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：知识摄入：文档导入、URL 抓取、OCR 扫描、PDF 解析。
//
import SwiftUI


// MARK: - Ingest Hero Section
/// 导入模块顶部宣传区域组件
/// 负责展示导入功能的品牌视觉元素及核心价值主张
struct IngestHeroSection: View {
    var body: some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: DesignSystem.Icons.trayArrowDown)
                .font(.system(size: DesignSystem.iconDisplay))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appSource, .appText],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // 移除重复的标题，因为导航栏已经有了
            Text(L10n.Ingest.hero.subtitle)
                .font(.caption)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.tightPadding)
    }
}
