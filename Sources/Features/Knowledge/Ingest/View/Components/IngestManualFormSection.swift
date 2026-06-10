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

// MARK: - Ingest Manual Form Section
/// 手动录入表单区域组件
/// 负责提供 知识 页面核心元数据（标题、类型、标签、内容）的手动编辑界面，支持智能辅助开关
struct IngestManualFormSection: View {
    @Binding var newTitle: String
    @Binding var newContent: String
    @Binding var newType: PageType
    @Binding var newCustomIcon: String?
    @Binding var newTags: [String]
    @Binding var showIconPicker: Bool
    @Binding var useSmartIngest: Bool
    @Binding var smartResult: SmartIngestResult?
    @Binding var isIngesting: Bool
    @Binding var ingestSuccess: Bool
    @Binding var errorMessage: String?
    @Binding var showError: Bool
    @Binding var useDeepScan: Bool

    let llmService: LLMService
    let store: AppStore
    let ingestStore: IngestStore
    let onPerformIngest: () -> Void
    let onConfirmSmartIngest: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下表单字段标签从 12pt 升到 15pt
    private var fieldLabelFont: Font {
        horizontalSizeClass == .regular ? .subheadline.weight(.medium) : .caption.weight(.medium)
    }

    var body: some View {
        VStack(spacing: DesignSystem.wide) {
            // Title and Type
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                // Title field
                VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) {
                    Text(L10n.Ingest.field.title)
                        .font(fieldLabelFont)
                        .foregroundStyle(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: DesignSystem.medium) {
                        Image(systemName: newCustomIcon ?? newType.icon)
                            .font(.headline)
                            .foregroundStyle(.appAccent)
                            .frame(width: DesignSystem.Action.buttonHeight, height: DesignSystem.Action.buttonHeight)
                            .background(Color.appAccent.opacity(DesignSystem.glassOpacity)) // 0.1
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                            .onTapGesture { showIconPicker = true }
                        
                        TextField(L10n.Ingest.field.titlePlaceholder, text: $newTitle)
                            .font(.headline)
                            .padding()
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                                    .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth)
                            )
                    }
                }
                
                pageTypeSelector
                
                // Tags field
                VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                    Text(L10n.Ingest.field.tags)
                        .font(fieldLabelFont)
                        .foregroundStyle(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    AppTagField(placeholder: L10n.Ingest.field.tagsPlaceholder, tags: $newTags)
                }
            }

            // Content editor
            VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                Text(L10n.Ingest.field.content)
                    .font(fieldLabelFont)
                    .foregroundStyle(.appSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading) // 强制左对齐
                AppMonospacedEditor(text: $newContent, minHeight: DesignSystem.Metrics.heroValueSize * 7) // 180
            }
        }
        .padding(.horizontal)

        // Advanced Options Card
        VStack(spacing: 0) {
            if llmService.isEnabled && !llmService.apiKey.isEmpty {
                Toggle(isOn: $useSmartIngest) {
                    HStack(spacing: DesignSystem.small) { // 8
                        Image(systemName: DesignSystem.Icons.sparkles)
                            .foregroundStyle(.appAccent)
                            .frame(width: DesignSystem.smallIconSize) // 20
                        Text(L10n.Ingest.smartToggle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.appText)
                    }
                }
                .tint(.appAccent)
                .padding(.vertical, DesignSystem.medium) // 12
                .accessibilityIdentifier("ingest.smartToggleAction")
                
                Divider().padding(.leading, DesignSystem.Metrics.iconBoxSize) // 44
            }
            
            Toggle(isOn: $useDeepScan) {
                HStack(spacing: DesignSystem.small) { // 8
                    Image(systemName: DesignSystem.Icons.cpu)
                        .foregroundStyle(.appSource)
                        .frame(width: DesignSystem.smallIconSize) // 20
                    Text(L10n.Ingest.deepScan)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appSource)
            .padding(.vertical, DesignSystem.medium) // 12
            
            if useSmartIngest || useDeepScan {
                VStack(alignment: .leading, spacing: DesignSystem.atomic) { // 4
                    if useSmartIngest {
                        Text(L10n.Ingest.smartToggleHint)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    if useDeepScan {
                        Text(L10n.Ingest.deepScanDesc)
                            .font(.caption)
                            .foregroundStyle(.appSource)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, DesignSystem.medium) // 12
                .transition(.opacity)
            }
        }
        .appContainer(padding: true)
        .padding(.horizontal)

        // Smart preview
        if let result = smartResult {
            SmartIngestPreview(result: result, onConfirm: onConfirmSmartIngest, onDiscard: { smartResult = nil })
                .padding(.horizontal)
        }

        // Submit button
        AppPrimaryButton(
            title: isIngesting ? L10n.Ingest.submitting : L10n.Ingest.submit,
            icon: DesignSystem.Icons.trayArrowDown,
            isLoading: isIngesting
        ) {
            onPerformIngest()
        }
        .disabled(newTitle.isEmpty || newContent.isEmpty || isIngesting)
        .opacity(newTitle.isEmpty || newContent.isEmpty ? DesignSystem.disabledOpacity : DesignSystem.fullOpacity)
        .padding(.horizontal)

    }

    private var smartIngestToggle: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Toggle(isOn: $useSmartIngest) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) {
                    Image(systemName: DesignSystem.Icons.sparkles)
                        .foregroundStyle(.appAccent)
                    Text(L10n.Ingest.smartToggle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appAccent)
            .accessibilityIdentifier("ingest.smartToggleAction")

            if useSmartIngest {
                Text(L10n.Ingest.smartToggleHint)
                    .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.horizontal)
    }

    private var deepScanToggle: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) { // 8
            Toggle(isOn: $useDeepScan) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                    Image(systemName: DesignSystem.Icons.cpuOutline)
                        .foregroundStyle(.appSource)
                    Text(L10n.Ingest.deepScan)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appSource)
            
            if useDeepScan {
                Text(L10n.Ingest.deepScanDesc)
                    .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                    .foregroundStyle(.appSource)
                    .padding(.leading, DesignSystem.Metrics.smallIconBoxSize + DesignSystem.atomic) // 30
            }
        }
        .padding()
        .background(useDeepScan ? Color.appSource.opacity(DesignSystem.glassOpacity) : Color.appCard.opacity(DesignSystem.dimmedOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .padding(.horizontal)
    }

    private var pageTypeSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) {
            Text(L10n.Ingest.field.type)
                .font(fieldLabelFont)
                .foregroundStyle(.appSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.small) {
                    ForEach(PageType.allCases) { type in
                        Button(action: { newType = type }) {
                            AppIconChip(
                                icon: type.icon,
                                text: type.displayName,
                                color: Color.fromModelColorName(type.colorName),
                                isSelected: newType == type
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var iconPickerSection: some View {
        HStack(spacing: DesignSystem.small + DesignSystem.atomic) { // 10
            Text(L10n.Ingest.field.icon)
                .font(fieldLabelFont)
                .foregroundStyle(.appSecondary)

            Button(action: { showIconPicker = true }) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                    Image(systemName: newCustomIcon ?? newType.icon)
                        .font(.caption)
                        .foregroundStyle(newCustomIcon != nil ? .appAccent : .appSecondary)
                        .frame(width: DesignSystem.smallIconSize, height: DesignSystem.smallIconSize) // 20
                        .background((newCustomIcon != nil ? Color.appAccent : Color.fromModelColorName(newType.colorName)).opacity(DesignSystem.glassOpacity * 1.5)) // 0.15
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                    Text(newCustomIcon != nil ? L10n.Ingest.iconCustom : L10n.Ingest.iconDefault)
                        .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                        .foregroundStyle(newCustomIcon != nil ? .appAccent : .appSecondary)
                    Image(systemName: DesignSystem.Icons.chevronUpDown)
                        .font(.system(size: DesignSystem.microFontSize - DesignSystem.atomic / 2)) // 9
                        .foregroundStyle(.appSecondary)
                }
                .padding(.horizontal, DesignSystem.small + DesignSystem.atomic) // 10
                .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic) // 7
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(newCustomIcon != nil ? Color.appAccent.opacity(DesignSystem.dimmedOpacity) : Color.clear, lineWidth: DesignSystem.borderWidth)
                )
            }
            .buttonStyle(.plain)
            .fixedSize()

            if newCustomIcon != nil {
                Button(action: { newCustomIcon = nil }) {
                    Text(L10n.Ingest.iconReset)
                        .font(horizontalSizeClass == .regular ? .caption : .caption2)
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic / 2) // 5
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}
