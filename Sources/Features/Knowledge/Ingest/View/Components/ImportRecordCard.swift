//
//  ImportRecordCard.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：导入原始内容卡片组件

import SwiftUI

struct ImportRecordCard: View {
    let record: ImportRecord

    private var categoryValue: ImportCategory? { ImportCategory(rawValue: record.category) }

    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(record.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                detailLine
                timeLine
            }
            Spacer()
            statusBadge
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
    }

    // MARK: - 信息行

    @ViewBuilder
    private var detailLine: some View {
        HStack(spacing: DesignSystem.tightPadding) {
            switch categoryValue {
            case .file:
                if let size = record.fileSize {
                    Label(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), systemImage: "doc")
                }
            case .link:
                if let url = record.sourceURL, let host = URL(string: url)?.host {
                    Label(host, systemImage: "link")
                }
            case .voice:
                Label(L10n.Ingest.voiceNote, systemImage: "waveform")
            default:
                EmptyView()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var timeLine: some View {
        HStack(spacing: DesignSystem.small) {
            Label(record.createdAt.formatted(date: .numeric, time: .shortened), systemImage: "clock")
                .font(.caption2)
            if record.status == ImportRecordStatus.done, let done = record.completedAt {
                Label(done.formatted(date: .numeric, time: .shortened), systemImage: "flag.checkered")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.tertiary)
    }

    // MARK: - 状态

    @ViewBuilder
    private var statusBadge: some View {
        switch record.status {
        case "done":
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case ImportRecordStatus.failed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        default:
            ProgressView().scaleEffect(0.8)
        }
    }

    // MARK: - 分类样式

    private var categoryIcon: String {
        switch categoryValue {
        case .link: return "link"
        case .file: return "doc.fill"
        case .manual: return "pencil.line"
        case .ocr: return "camera.fill"
        case .clipboard: return "list.clipboard"
        case .voice: return "waveform"
        case nil: return "questionmark"
        }
    }

    private var categoryColor: Color {
        switch categoryValue {
        case .link: return .blue
        case .file: return .orange
        case .manual: return .green
        case .ocr: return .purple
        case .clipboard: return .gray
        case .voice: return .pink
        case nil: return .secondary
        }
    }
}
