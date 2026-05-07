// VoiceNoteComponents.swift
//
// 作者: Wang Chong
// 功能说明: struct SaveVoiceNoteSheet
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Save Voice Note Sheet
/// 语音笔记保存配置面板组件
/// 负责在保存语音识别结果前配置页面标题、类型，并展示转录文本预览供最终确认
struct SaveVoiceNoteSheet: View {
    @ObservedObject var speechService: SpeechProcessor
    @Binding var title: String
    @Environment(AppStore.self) var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: PageType = .source
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    titleField
                    typePicker
                    previewSection
                    saveButton
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle(Localized.tr("speech.saveTitle"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Localized.tr("speech.noteTitle"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)
            
            TextField(Localized.tr("speech.noteTitlePlaceholder"), text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Localized.tr("ocr.pageType"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)
            
            Picker("", selection: $selectedType) {
                ForEach(PageType.allCases) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Localized.tr("pdf.contentPreview"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)
            
            TextEditor(text: $speechService.transcribedText)
                .font(.body)
                .foregroundStyle(.appText)
                .frame(minHeight: 120, maxHeight: 300)
                .padding(8)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.standardRadius)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }
    
    private var saveButton: some View {
        Button(action: saveNote) {
            Text(Localized.tr("speech.saveToKnowledge"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
        }
    }
    
    private func saveNote() {
        let noteTitle = title.isEmpty
            ? "\(Localized.tr("speech.voiceNote")) \(Date().formatted(.dateTime.month().day().hour().minute()))"
            : title
        _ = store.createPage(
            title: noteTitle,
            type: selectedType,
            content: speechService.transcribedText,
            tags: [Localized.tr("speech.voiceTag")]
        )
        
        let _ = speechService.saveRecording(title: noteTitle)
        speechService.clearTranscription()
        title = ""
        dismiss()
    }
}

// MARK: - Voice Recording Row
/// 语音录音列表行组件
/// 负责展示语音笔记的摘要信息（标题、部分文本、创建日期）及波形图标
struct VoiceRecordingRow: View {
    let recording: VoiceRecording
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .foregroundStyle(.appSource)
                .frame(width: 32, height: 32)
                .background(Color.appSource.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recording.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                Text(String(recording.text.prefix(50)))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(recording.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
        .frame(maxWidth: .infinity)
    }
}