// OCRScanComponents.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：OCR 图片选择区域：显示选中图片或占位符 + 相册选择按钮 + 识别按钮
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI
import PhotosUI

// MARK: - OCR Image Picker Area
/// OCR 图片选择区域：显示选中图片或占位符 + 相册选择按钮 + 识别按钮
@MainActor
/// OCR 图片选择与识别触发区域组件
/// 负责图片的选取（从相册）、预览展示及触发后端 OCR 识别流程的交互
struct OCRImagePickerArea: View {
    let selectedImage: AppImage?
    let isProcessing: Bool
    let selectedPhoto: PhotosPickerItem?

    let onPhotoSelected: (PhotosPickerItem?) -> Void
    let onStartRecognition: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.standardPadding) { // 16
            if let image = selectedImage {
                #if os(watchOS)
                Text(Localized.tr("status.simulatorNotSupported"))
                #elseif canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: DesignSystem.Metrics.heroValueSize * 11.5) // 300
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    .shadow(color: .black.opacity(DesignSystem.shadowOpacity), radius: DesignSystem.small) // 0.1, 8
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                            .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth) // 1
                    )
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: DesignSystem.Metrics.heroValueSize * 11.5) // 300
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    .shadow(color: .black.opacity(DesignSystem.shadowOpacity), radius: DesignSystem.small) // 0.1, 8
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                            .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth) // 1
                    )
                #endif
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                    .fill(Color.appCard)
                    .frame(height: DesignSystem.Metrics.heroValueSize * 7.7) // 200
                    .overlay(
                        VStack(spacing: DesignSystem.medium) { // 12
                            Image(systemName: DesignSystem.Icons.ocr)
                                .font(.system(size: DesignSystem.largeIconSize + DesignSystem.small)) // 40
                                .foregroundStyle(.appSecondary)
                            Text(Localized.tr("ocr.selectImage"))
                                .font(.subheadline)
                                .foregroundStyle(.appSecondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.borderWidth * 2, dash: [CGFloat(DesignSystem.small)])) // 2, 8
                            .foregroundStyle(.appBorder)
                    )
            }

            // Photo picker
            HStack(spacing: DesignSystem.standardPadding) { // 16
                PhotosPicker(selection: Binding(
                    get: { selectedPhoto },
                    set: { onPhotoSelected($0) }
                ), matching: .images) {
                    Label(Localized.tr("ocr.fromAlbum"), systemImage: "photo.on.rectangle")
                        .font(.subheadline)
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.standardPadding) // 16
                        .padding(.vertical, DesignSystem.small + DesignSystem.atomic) // 10
                        .background(Color.appAccent.opacity(DesignSystem.glassOpacity), in: RoundedRectangle(cornerRadius: DesignSystem.smallRadius)) // 0.1
                }
                .accessibilityIdentifier("ocr-select-photo")

                if selectedImage != nil {
                    Button(action: onStartRecognition) {
                        HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(DesignSystem.fullOpacity * 0.8) // 0.8
                            }
                            Text(isProcessing ? Localized.tr("ocr.processing") : Localized.tr("ocr.recognize"))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.standardPadding) // 16
                        .padding(.vertical, DesignSystem.small + DesignSystem.atomic) // 10
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    }
                    .accessibilityIdentifier("ocr-start-recognition")
                    .disabled(isProcessing)
                }
            }
        }
    }
}

// MARK: - OCR Result Display
/// OCR 识别结果展示区：显示识别的文本和字符数统计
/// OCR 识别结果实时展示组件
/// 负责显示提取出的文本内容，并提供手动修正输入、字符计数及剪贴板复制功能
struct OCRResultDisplay: View {
    @Binding var recognizedText: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
            HStack {
                Label(Localized.tr("ocr.result"), systemImage: "doc.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)

                Spacer()

                Button(action: onCopy) {
                    Label(Localized.tr("ocr.copy"), systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.appAccent)
                }
                .accessibilityIdentifier("ocr-copy-text")
            }

            Group {
                #if os(watchOS)
                TextField("", text: $recognizedText, axis: .vertical)
                #else
                TextEditor(text: $recognizedText)
                #endif
            }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.appText)
                .frame(minHeight: DesignSystem.Metrics.heroValueSize * 4.6, maxHeight: DesignSystem.Metrics.heroValueSize * 11.5) // 120, 300
                .padding(DesignSystem.small) // 8
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth) // 1
                )

            HStack {
                Text(Localized.trf("ocr.charCountFormat", recognizedText.count))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)

                Spacer()
            }
        }
    }
}

// MARK: - OCR Save Form
/// OCR 保存表单：页面标题/类型选择/图标/标签/保存按钮
/// OCR 资料入库表单组件
/// 负责在保存识别结果前配置页面元数据（标题、类型、标签），并执行最终的入库持久化操作
struct OCRSaveForm: View {
    @Binding var targetTitle: String
    @Binding var targetType: PageType
    @Binding var targetCustomIcon: String?

    let targetTags: [String]
    let showIconPicker: Bool
    let showAddTagInput: Bool
    let newTagText: String

    let onIconPickerToggle: () -> Void
    let onCustomIconClear: () -> Void
    let onRemoveTag: (String) -> Void
    let onAddTag: () -> Void
    let onSave: () -> Void
    let onTagInputChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) { // 12
            Text(Localized.tr("ocr.saveToKnowledge"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)

            TextField(Localized.tr("ocr.pageTitle"), text: $targetTitle)
                .font(.subheadline)
                .foregroundStyle(.appText)
                .padding(DesignSystem.small + DesignSystem.atomic) // 10
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth) // 1
                )
                .accessibilityIdentifier("ocr-page-title")

            Picker(Localized.tr("ocr.pageType"), selection: $targetType) {
                ForEach(PageType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.segmented)
            #endif

            // Icon picker row
            HStack {
                Text(Localized.tr("page.icon"))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)

                Spacer()

                Button(action: onIconPickerToggle) {
                    HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                        Image(systemName: targetCustomIcon ?? targetType.icon)
                            .font(.body)
                            .foregroundStyle(targetCustomIcon != nil ? .appAccent : .appSecondary)
                            .frame(width: DesignSystem.Metrics.smallIconBoxSize, height: DesignSystem.Metrics.smallIconBoxSize) // 28
                            .background((targetCustomIcon != nil ? Color.appAccent : Color.fromModelColorName(targetType.colorName)).opacity(DesignSystem.glassOpacity * 1.5)) // 0.15
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))

                        Text(targetCustomIcon != nil ? Localized.tr("ocr.changeIcon") : Localized.tr("ocr.customIcon"))
                            .font(.caption)
                            .foregroundStyle(.appAccent)

                        if targetCustomIcon != nil {
                            Button(action: onCustomIconClear) {
                                Image(systemName: DesignSystem.Icons.errorCircle)
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, DesignSystem.atomic * 2) // 4

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                    ForEach(targetTags, id: \.self) { tag in
                        TagPill(tag: tag, onRemove: { onRemoveTag(tag) })
                    }

                    Button(action: onAddTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.appAccent)
                    }
                    .accessibilityIdentifier("ocr-add-tag")
                }
            }

            Button(action: onSave) {
                Label(Localized.tr("ocr.saveToKnowledge"), systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.medium) // 12
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
            }
            .accessibilityIdentifier("ocr-save-to-knowledge")
        }
        .padding(DesignSystem.standardPadding) // 16
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
    }
}

// MARK: - Tag Pill
/// 标签胶囊组件
/// 标签胶囊小组件
/// 负责在 OCR 保存表单中以胶囊形态展示已选标签，并提供删除交互
struct TagPill: View {
    let tag: String
    var onRemove: () -> Void = {}

    var body: some View {
        HStack(spacing: DesignSystem.atomic * 2) { // 4
            Text(tag)
                .font(.caption2)
                .foregroundStyle(.appAccent)

            Button(action: onRemove) {
                Image(systemName: DesignSystem.Icons.errorCircle)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.small) // 8
        .padding(.vertical, DesignSystem.atomic * 2) // 4
        .background(Color.appAccent.opacity(DesignSystem.glassOpacity), in: Capsule()) // 0.1
    }
}
