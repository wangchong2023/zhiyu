// SourceRow.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：信源展示行，支持点击跳转至原文
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct SourceRow: View {
    let source: KnowledgeSource
    var onSelect: (UUID) -> Void
    
    var body: some View {
        Button(action: { onSelect(source.pageID) }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: DesignSystem.Icons.documentFill)
                        .font(.caption)
                        .foregroundStyle(.appAccent)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(source.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        
                        if let path = source.anchorPath, !path.isEmpty {
                            Text(path)
                                .font(.system(size: 9))
                                .foregroundStyle(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(Int(source.score * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Text(source.snippet)
                    .font(.system(size: 11))
                    .foregroundStyle(.appSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignSystem.small)
            .background(Color.appCard.opacity(DesignSystem.softOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                    .stroke(Color.appBorder.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
