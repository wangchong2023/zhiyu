// IngestViewComponents.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识导入模块（IngestView）所需的 UI 原子组件与业务行视图，旨在提供直观且高效的资料采集体验。
// 该组件包通过以下核心功能点保障了外部资料向本地知识库转化的丝滑感：
// 1. 多态导入行渲染：支持网页链接、PDF 预览及剪贴板内容的不同视觉呈现，并集成了基于 AppUI 的动态进度反馈。
// 2. 智能标签预览：实现了资料预处理后的建议标签展示，利用微型圆角（Tiny Radius）与语义化色彩标识资料的类别与置信度。
// 3. 队列交互增强：提供了滑动手势支持与状态实时同步逻辑，确保用户在处理大规模导入任务时具备清晰的操纵感。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，修复 AppUI 成员引用错误，统一间距常量
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let importFromClipboard = Notification.Name("importFromClipboard")
}

// MARK: - Ingest Hero Section
/// 导入模块顶部宣传区域组件
/// 负责展示导入功能的品牌视觉元素及核心价值主张
struct IngestHeroSection: View {
    var body: some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: DesignSystem.iconDisplay))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appSource, .appText],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // 移除重复的标题，因为导航栏已经有了
            Text(L10n.Ingest.tr("hero.subtitle"))
                .font(.caption)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.tightPadding)
    }
}

// MARK: - Ingest Entry Cards Section
/// 导入入口卡片组组件
/// 负责展示文件导入、手动录入、网页导入、OCR 扫描等多种导入方式的启动网格
struct IngestEntryCardsSection: View {
    @Binding var showManualForm: Bool
    @Binding var showOCRScan: Bool
    @Binding var newType: PageType
    @Binding var showFileImporter: Bool
    @Binding var showVoiceNote: Bool
    @Binding var showURLImport: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下副标题从 10pt 升到 12pt
    private var subtitleFont: Font {
        horizontalSizeClass == .regular ? .caption : .caption2
    }

    /// 响应式列配置：iPhone 2列，iPad 自适应多列
    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            Array(repeating: GridItem(.flexible(minimum: DesignSystem.Metrics.heroValueSize * 3, maximum: DesignSystem.Metrics.heroValueSize * 7), spacing: DesignSystem.medium), count: 5) // 80, 180, 12
        } else {
            [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.medium) {
            // 1. File import card
            Button(action: {
                showFileImporter = true
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("fileImport"),
                    icon: "doc.badge.plus",
                    color: .blue
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.file")

            // 2. Manual entry card
            Button(action: {
                showManualForm = true
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("manualEntry"),
                    icon: "pencil.and.list.clipboard",
                    color: .orange
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.manual")

            // 3. URL import card
            Button(action: {
                showURLImport = true
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("urlImport"),
                    icon: "link",
                    color: .teal
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.url")

            // 4. OCR entry card
            Button(action: {
                showOCRScan = true
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("ocrScan"),
                    icon: "text.viewfinder",
                    color: .purple
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.ocr")

            // 5. Clipboard import card
            Button(action: {
                NotificationCenter.default.post(name: .importFromClipboard, object: nil)
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("clipboardImport"),
                    icon: "doc.on.clipboard",
                    color: .green
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.clipboard")

            // 6. Voice note card
            Button(action: {
                showVoiceNote = true
            }) {
                entryCardContent(
                    title: L10n.Ingest.tr("voiceNote"),
                    icon: "waveform",
                    color: .red
                )
            }
            .buttonStyle(AppCardButtonStyle())
            .accessibilityIdentifier("ingest.voice")
        }
    }

    private func entryCardContent(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.tiny) {
            ZStack {
                Circle()
                    .fill(color.opacity(DesignSystem.glassOpacity * 1.2)) // 0.12
                    .frame(width: DesignSystem.Metrics.largeIconBoxSize, height: DesignSystem.Metrics.largeIconBoxSize)
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.iconMedium, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: DesignSystem.Metrics.dashboardLabelSize, weight: .bold))
                .foregroundStyle(.appText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.standardPadding)
        .appMetricCardStyle(color: color, cornerRadius: DesignSystem.standardRadius)
    }
}

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
                    Text(L10n.Ingest.tr("field.title"))
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
                        
                        TextField(L10n.Ingest.tr("field.titlePlaceholder"), text: $newTitle)
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
                    Text(L10n.Ingest.tr("field.tags"))
                        .font(fieldLabelFont)
                        .foregroundStyle(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    AppTagField(placeholder: L10n.Ingest.tr("field.tagsPlaceholder"), tags: $newTags)
                }
            }

            // Content editor
            VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                Text(L10n.Ingest.tr("field.content"))
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
                        Image(systemName: "sparkles")
                            .foregroundStyle(.appAccent)
                            .frame(width: DesignSystem.smallIconSize) // 20
                        Text(L10n.Ingest.tr("smartToggle"))
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
                    Image(systemName: "cpu")
                        .foregroundStyle(.appSource)
                        .frame(width: DesignSystem.smallIconSize) // 20
                    Text(L10n.Ingest.tr("deepScan"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appSource)
            .padding(.vertical, DesignSystem.medium) // 12
            
            if useSmartIngest || useDeepScan {
                VStack(alignment: .leading, spacing: DesignSystem.atomic) { // 4
                    if useSmartIngest {
                        Text(L10n.Ingest.tr("smartToggleHint"))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    if useDeepScan {
                        Text(L10n.Ingest.tr("deepScanDesc"))
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
            title: isIngesting ? L10n.Ingest.tr("submitting") : L10n.Ingest.tr("submit"),
            icon: "tray.and.arrow.down.fill",
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
                    Image(systemName: "sparkles")
                        .foregroundStyle(.appAccent)
                    Text(L10n.Ingest.tr("smartToggle"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appAccent)
            .accessibilityIdentifier("ingest.smartToggleAction")

            if useSmartIngest {
                Text(L10n.Ingest.tr("smartToggleHint"))
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
                    Image(systemName: "cpu")
                        .foregroundStyle(.appSource)
                    Text(L10n.Ingest.tr("deepScan"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.appText)
                }
            }
            .tint(.appSource)
            
            if useDeepScan {
                Text(L10n.Ingest.tr("deepScanDesc"))
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
            Text(L10n.Ingest.tr("field.type"))
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
            Text(L10n.Ingest.tr("field.icon"))
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
                    Text(newCustomIcon != nil ? L10n.Ingest.tr("iconCustom") : L10n.Ingest.tr("iconDefault"))
                        .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                        .foregroundStyle(newCustomIcon != nil ? .appAccent : .appSecondary)
                    Image(systemName: "chevron.up.chevron.down")
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
                    Text(L10n.Ingest.tr("iconReset"))
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

// MARK: - Smart Ingest Preview
/// 智能导入预览卡片组件
/// 负责展示 LLM 预处理后的建议结果（标题、摘要、自动标签等），供用户确认或修正
struct SmartIngestPreview: View {
    let result: SmartIngestResult
    let onConfirm: () -> Void
    let onDiscard: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下从 12pt 升到 15pt
    private var previewFont: Font {
        horizontalSizeClass == .regular ? .subheadline : .caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(
                title: L10n.Ingest.tr("preview"),
                icon: "sparkles",
                iconColor: .appAccent,
                trailing: AnyView(
                    HStack {
                        Button(action: onConfirm) {
                            AppCapsuleButton(title: L10n.Ingest.tr("previewConfirm"), icon: "checkmark", isPrimary: true, color: .appAccent)
                        }
                        .buttonStyle(.plain)
                        Button(action: onDiscard) {
                            AppCapsuleButton(title: L10n.Ingest.tr("previewDiscard"), icon: nil, isPrimary: false)
                        }
                        .buttonStyle(.plain)
                    }
                )
            )
            .padding(.horizontal, DesignSystem.tiny)

            VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
                // Type + Tags chips
                HStack(spacing: DesignSystem.small) { // 8
                    if let type = PageType(rawValue: result.suggestedType) {
                        AppChip(text: type.displayName, color: Color.fromModelColorName(type.colorName))
                    }
                    ForEach(result.suggestedTags.prefix(DesignSystem.Metrics.maxRecentItems), id: \.self) { tag in // 5
                        AppChip(text: "#\(tag)", color: .appAccent, backgroundOpacity: DesignSystem.glassOpacity) // 0.1
                    }
                }

                if !result.summary.isEmpty {
                    Text(result.summary)
                        .font(previewFont)
                        .foregroundStyle(.appSecondary)
                        .italic()
                }

                // Compiled content preview
                ScrollView {
                    Text(result.compiledContent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.appText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: DesignSystem.Metrics.heroValueSize * 7.7) // 200
                .padding(DesignSystem.small) // 8
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))

                // Related titles
                if !result.relatedTitles.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.atomic) { // 4
                        Text(L10n.Ingest.tr("suggestLinks"))
                            .font(previewFont.weight(.medium))
                            .foregroundStyle(.appSecondary)

                        ForEach(result.relatedTitles, id: \.self) { title in
                            HStack(spacing: DesignSystem.atomic) { // 4
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("[[\(title)]]")
                                    .font(previewFont)
                            }
                            .foregroundStyle(.appAccent)
                        }
                    }
                }
            }
            .appContainer(padding: true)
        }
    }
}

// MARK: - Ingest Tips Section
/// 导入操作提示区域组件
/// 负责提供各导入方式的功能说明及操作建议，提升用户初次使用体验
struct IngestTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("tips"), icon: "lightbulb.fill", iconColor: .orange)
                .padding(.horizontal, DesignSystem.tiny)

            // Three import method cards
            HStack(spacing: DesignSystem.small + DesignSystem.atomic) { // 10
                importMethodCard(
                    icon: "doc.badge.plus",
                    title: L10n.Ingest.tr("method.file"),
                    desc: L10n.Ingest.tr("method.fileDesc")
                )
                importMethodCard(
                    icon: "text.viewfinder",
                    title: L10n.Ingest.tr("method.ocr"),
                    desc: L10n.Ingest.tr("method.ocrDesc")
                )
                importMethodCard(
                    icon: "pencil.and.list.clipboard",
                    title: L10n.Ingest.tr("method.manual"),
                    desc: L10n.Ingest.tr("method.manualDesc")
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
                    Text(L10n.Ingest.tr("urlImportPlaceholder"))
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
                                .stroke(Color.appAccent.opacity(DesignSystem.glassOpacity * 2), lineWidth: DesignSystem.borderWidth) // 0.2, 1
                        )
                }
                .padding()
                
                VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
                    Label(L10n.Ingest.tr("webDesc"), systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                    
                    AppPrimaryButton(
                        title: L10n.Common.tr("import"),
                        icon: "arrow.down.doc.fill",
                        isLoading: false
                    ) {
                        onImport()
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.appCard)
            }
            .navigationTitle(L10n.Ingest.tr("urlImport"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.tr("cancel")) {
                        dismiss()
                    }
                }
            }
            .background(PageBackgroundView(accentColor: .appAccent))
        }
    }
}
