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
    var onTap: (() -> Void)?
    var onViewPage: (() -> Void)?
    var onOpenWith: (() -> Void)?
    var onAITag: (() -> Void)?

    private var categoryValue: ImportCategory? { ImportCategory(rawValue: record.category) }
    private var canViewPage: Bool { record.pageID != nil && record.status == ImportRecordStatus.done }
    private var canOpenFile: Bool { record.filePath != nil }
    private var tagList: [String] {
        record.tags?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? []
    }

    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: DesignSystem.Metrics.customSize36, height: DesignSystem.Metrics.customSize36)
                .background(categoryColor.opacity(DesignSystem.Opacity.subtle))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))

            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(record.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                // 来源类型与 AI 标签行
                HStack(spacing: DesignSystem.atomic) {
                    // 来源类型胶囊标签 (使用高对比度的实色背景，明确标明文件来源)
                    Text(categoryValue?.displayName ?? L10n.Common.unknown)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, DesignSystem.tightPadding)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(categoryColor))
                        .foregroundStyle(.white)
                    
                    if !tagList.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.atomic) {
                                ForEach(tagList, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, DesignSystem.tightPadding)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(categoryColor.opacity(DesignSystem.Opacity.subtle)))
                                        .foregroundStyle(categoryColor)
                                }
                            }
                        }
                    }
                }
                detailLine
                timeLine
            }
            Spacer()
            HStack(spacing: DesignSystem.small) {
                statusBadge
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .swipeActions(edge: .trailing) {
            if canViewPage {
                Button(action: { onViewPage?() }) {
                    Label(L10n.Ingest.viewPage, systemImage: "doc.text")
                }
                .tint(.appAccent)
            }
            if canOpenFile {
                Button(action: { onOpenWith?() }) {
                    Label(L10n.Ingest.openWith, systemImage: "square.and.arrow.up")
                }
                .tint(.green)
            }
        }
        .contextMenu {
            if record.rawText != nil {
                Button(action: { onAITag?() }) {
                    Label(L10n.Ingest.aiTag, systemImage: "sparkles")
                }
            }
        }
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

    private var fileIcon: String {
        guard let path = record.filePath else { return "doc.fill" }
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "png", "jpg", "jpeg", "heic", "gif": return "doc.image.fill"
        case "mp3", "m4a", "wav", "caf": return "doc.sound.fill"
        case "txt", "md": return "doc.text.fill"
        case "zip", "tar", "gz": return "doc.zipper.fill"
        default: return "doc.fill"
        }
    }

    private var categoryIcon: String {
        switch categoryValue {
        case .link: return "link"
        case .file: return fileIcon
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
