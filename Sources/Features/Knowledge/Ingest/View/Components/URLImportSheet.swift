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


// MARK: - URL Import Sheet
/// 网页链接导入面板组件
/// 负责提供 URL 地址录入界面，并触发基于网页抓取的自动化导入流程
struct URLImportSheet: View {
    @Binding var urlText: String
    let onImport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
                    Text(L10n.Ingest.urlImportPlaceholder)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                    
                    Group {
                        #if os(watchOS)
                        TextField("", text: $urlText)
                        #else
                        TextEditor(text: $urlText)
                        #endif
                    }
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.small) // 8
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                                .stroke(Color.appAccent.opacity(DesignSystem.Opacity.glass * 2), lineWidth: DesignSystem.borderWidth) // 0.2, 1
                        )
                }
                .padding()
                
                VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
                    Label(L10n.Ingest.webDesc, systemImage: DesignSystem.Icons.info)
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                    
                    AppPrimaryButton(
                        title: L10n.Common.import,
                        icon: DesignSystem.Icons.trayArrowDown,
                        isLoading: false
                    ) {
                        onImport()
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.appCard)
            }
            .navigationTitle(L10n.Ingest.urlImport)
.appNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
            }
            .background(PageBackgroundView(accentColor: .appAccent))
        }
    }
}

