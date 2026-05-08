// OCRScanComponents.swift
//
// 作者: Wang Chong
// 功能说明: OCR 图片选择区域：显示选中图片或占位符 + 相册选择按钮 + 识别按钮
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
        VStack(spacing: AppUI.standardPadding) { // 16
            if let image = selectedImage {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: AppUI.Metrics.heroValueSize * 11.5) // 300
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
                    .shadow(color: .black.opacity(AppUI.shadowOpacity), radius: AppUI.small) // 0.1, 8
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.cardRadius)
                            .stroke(Color.appBorder, lineWidth: AppUI.borderWidth) // 1
                    )
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: AppUI.Metrics.heroValueSize * 11.5) // 300
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
                    .shadow(color: .black.opacity(AppUI.shadowOpacity), radius: AppUI.small) // 0.1, 8
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.cardRadius)
                            .stroke(Color.appBorder, lineWidth: AppUI.borderWidth) // 1
                    )
                #endif
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: AppUI.cardRadius)
                    .fill(Color.appCard)
                    .frame(height: AppUI.Metrics.heroValueSize * 7.7) // 200
                    .overlay(
                        VStack(spacing: AppUI.medium) { // 12
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: AppUI.Metrics.largeIconSize + AppUI.small)) // 40
                                .foregroundStyle(.appSecondary)
                            Text(Localized.tr("ocr.selectImage"))
                                .font(.subheadline)
                                .foregroundStyle(.appSecondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.cardRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: AppUI.borderWidth * 2, dash: [CGFloat(AppUI.small)])) // 2, 8
                            .foregroundStyle(.appBorder)
                    )
            }

            // Photo picker
            HStack(spacing: AppUI.standardPadding) { // 16
                PhotosPicker(selection: Binding(
                    get: { selectedPhoto },
                    set: { onPhotoSelected($0) }
                ), matching: .images) {
                    Label(Localized.tr("ocr.fromAlbum"), systemImage: "photo.on.rectangle")
                        .font(.subheadline)
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, AppUI.standardPadding) // 16
                        .padding(.vertical, AppUI.small + AppUI.atomic) // 10
                        .background(Color.appAccent.opacity(AppUI.glassOpacity), in: RoundedRectangle(cornerRadius: AppUI.smallRadius)) // 0.1
                }
                .accessibilityIdentifier("ocr-select-photo")

                if selectedImage != nil {
                    Button(action: onStartRecognition) {
                        HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(AppUI.fullOpacity * 0.8) // 0.8
                            }
                            Text(isProcessing ? Localized.tr("ocr.processing") : Localized.tr("ocr.recognize"))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppUI.standardPadding) // 16
                        .padding(.vertical, AppUI.small + AppUI.atomic) // 10
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppUI.smallRadius))
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
        VStack(alignment: .leading, spacing: AppUI.medium) { // 12
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

            TextEditor(text: $recognizedText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.appText)
                .frame(minHeight: AppUI.Metrics.heroValueSize * 4.6, maxHeight: AppUI.Metrics.heroValueSize * 11.5) // 120, 300
                .padding(AppUI.small) // 8
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.smallRadius)
                        .stroke(Color.appBorder, lineWidth: AppUI.borderWidth) // 1
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
        VStack(alignment: .leading, spacing: AppUI.medium) { // 12
            Text(Localized.tr("ocr.saveToKnowledge"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)

            TextField(Localized.tr("ocr.pageTitle"), text: $targetTitle)
                .font(.subheadline)
                .foregroundStyle(.appText)
                .padding(AppUI.small + AppUI.atomic) // 10
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: AppUI.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.smallRadius)
                        .stroke(Color.appBorder, lineWidth: AppUI.borderWidth) // 1
                )
                .accessibilityIdentifier("ocr-page-title")

            Picker(Localized.tr("ocr.pageType"), selection: $targetType) {
                ForEach(PageType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Icon picker row
            HStack {
                Text(Localized.tr("page.icon"))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)

                Spacer()

                Button(action: onIconPickerToggle) {
                    HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
                        Image(systemName: targetCustomIcon ?? targetType.icon)
                            .font(.body)
                            .foregroundStyle(targetCustomIcon != nil ? .appAccent : .appSecondary)
                            .frame(width: AppUI.Metrics.smallIconBoxSize, height: AppUI.Metrics.smallIconBoxSize) // 28
                            .background((targetCustomIcon != nil ? Color.appAccent : Color.fromModelColorName(targetType.colorName)).opacity(AppUI.glassOpacity * 1.5)) // 0.15
                            .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius))

                        Text(targetCustomIcon != nil ? Localized.tr("ocr.changeIcon") : Localized.tr("ocr.customIcon"))
                            .font(.caption)
                            .foregroundStyle(.appAccent)

                        if targetCustomIcon != nil {
                            Button(action: onCustomIconClear) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, AppUI.atomic * 2) // 4

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
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
                    .padding(.vertical, AppUI.medium) // 12
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppUI.standardRadius))
            }
            .accessibilityIdentifier("ocr-save-to-knowledge")
        }
        .padding(AppUI.standardPadding) // 16
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: AppUI.cardRadius))
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
    var body: some View {
        HStack(spacing: AppUI.atomic * 2) { // 4
            Text(tag)
                .font(.caption2)
                .foregroundStyle(.appAccent)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.horizontal, AppUI.small) // 8
        .padding(.vertical, AppUI.atomic * 2) // 4
        .background(Color.appAccent.opacity(AppUI.glassOpacity), in: Capsule()) // 0.1
    }
    }
}
