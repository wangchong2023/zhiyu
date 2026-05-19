// VoiceNoteView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：本文件实现了知识管理系统的语音笔记记录中心（VoiceNoteView），支持高效的语音输入、实时转写及知识提取。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 语音笔记入口
/// 语音笔记功能主视图
/// 负责语音输入的实时采集、波形可视化展示、流式语音转文字（STT）及知识摘要提取
struct VoiceNoteView: View {
    @Inject private var speechService: any SpeechServiceProtocol
    @Environment(AppStore.self) var store
    @State private var noteTitle = ""
    @State private var showSaveSheet = false
    @Environment(\.dismiss) private var dismiss
    var onFinish: ((String, String) -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.standardPadding) {
                headerSection
                languagePicker
                recordingSection
                
                if speechService.isRecording {
                    waveformSection
                }
                
                if !speechService.transcribedText.isEmpty {
                    transcriptionSection
                }
                
                if !speechService.recordings.isEmpty {
                    recordingsSection
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.standardPadding)
            .padding(.top, Spacing.medium)
            .padding(.bottom, Spacing.giant)
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .navigationTitle(L10n.Voice.Speech.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
        .sheet(isPresented: $showSaveSheet) {
            SaveVoiceNoteSheet(speechService: speechService, title: $noteTitle)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: DesignSystem.Icons.waveformCircleFill)
                .font(.system(size: DesignSystem.displayFontSize * 1.5))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appAccent, .appSource],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(L10n.Voice.Speech.subtitle)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.medium)
    }
    
    // MARK: - Language Picker
    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(L10n.Voice.Speech.Language)
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)
            
            Picker(L10n.Voice.Speech.Language, selection: Binding(
                get: { speechService.selectedLanguage },
                set: { speechService.selectedLanguage = $0 }
            )) {
                ForEach(speechService.supportedLanguages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.menu)
            #endif
            .tint(.appAccent)
        }
        .appContainer(cornerRadius: DesignSystem.cardRadius, padding: true)
    }
    
    // MARK: - 录音控制板块
    private var recordingSection: some View {
        VStack(spacing: DesignSystem.Domain.Voice.recordingSectionSpacing) {
            if !speechService.hasPermission {
                permissionSection
            } else {
                recordButton
                recordingStatusText
            }
        }
    }
    
    private var permissionSection: some View {
        VStack(spacing: DesignSystem.Domain.Voice.permissionSectionSpacing) {
            Image(systemName: DesignSystem.Icons.micSlashFill)
                .font(.title)
                .foregroundStyle(.red)
            
            Text(L10n.Voice.Speech.needPermission)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { speechService.checkPermission() }) {
                Text(L10n.Voice.Speech.requestPermission)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.wide)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
            }
        }
        .appContainer(cornerRadius: DesignSystem.cardRadius, padding: true)
    }
    
    private var recordButton: some View {
        Button(action: {
            if speechService.isRecording {
                speechService.stopRecording()
            } else {
                speechService.startRecording()
            }
        }) {
            ZStack {
                Circle()
                    .fill(speechService.isRecording ? Color.appRecording.opacity(DesignSystem.Opacity.glass * 1.5) : Color.appAccent.opacity(DesignSystem.Opacity.glass))
                    .frame(width: DesignSystem.Domain.Voice.recordButtonSize, height: DesignSystem.Domain.Voice.recordButtonSize)
                
                if speechService.isRecording {
                    RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                        .fill(Color.appRecording)
                        .frame(width: DesignSystem.Domain.Voice.recordButtonSize * 0.375, height: DesignSystem.Domain.Voice.recordButtonSize * 0.375)
                } else {
                    Image(systemName: DesignSystem.Icons.micFill)
                        .font(.system(size: DesignSystem.displayFontSize))
                        .foregroundStyle(.appAccent)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var recordingStatusText: some View {
        VStack(spacing: DesignSystem.Domain.Voice.statusTextSpacing) {
            Text(speechService.isRecording ? L10n.Voice.Speech.tapToStop : L10n.Voice.Speech.tapToRecord)
                .font(.caption)
                .foregroundStyle(.appSecondary)
            
            Text(speechService.statusMessage)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
                .padding(.horizontal, DesignSystem.Domain.Voice.statusLabelHorizontalPadding)
                .padding(.vertical, DesignSystem.Domain.Voice.statusLabelVerticalPadding)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
        }
    }
    
    // MARK: - 波形展示
    private var waveformSection: some View {
        VStack(spacing: Spacing.medium) {
            Text(L10n.Voice.Speech.audioLevel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.appSecondary)

            HStack(spacing: DesignSystem.Domain.Voice.waveBarSpacing) {
                ForEach(0..<20, id: \.self) { i in
                    RoundedRectangle(cornerRadius: DesignSystem.tiny)
                        .fill(Color.appAccent)
                        .frame(width: DesignSystem.Domain.Voice.waveBarWidth, height: max(DesignSystem.Domain.Voice.waveBarMinHeight, CGFloat(speechService.audioLevelHistory[i]) * DesignSystem.Domain.Voice.waveScale))
                }
            }
            .frame(height: DesignSystem.Domain.Voice.waveformHeight)
        }
        .appContainer(cornerRadius: DesignSystem.cardRadius, padding: true)
    }
    
    // MARK: - 转写结果
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            HStack {
                Text(L10n.Voice.Speech.result)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                
                Spacer()
                
                Button(action: { AppPasteboard.string = speechService.transcribedText }) {
                    Image(systemName: DesignSystem.Icons.docOnDocFill)
                        .font(.caption)
                        .foregroundStyle(.appAccent)
                }
                
                Button(action: { speechService.clearTranscription() }) {
                    Image(systemName: DesignSystem.Icons.errorCircle)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }
            
            #if !os(watchOS)
            TextEditor(text: Binding(
                get: { speechService.transcribedText },
                set: { speechService.transcribedText = $0 }
            ))
                .font(.body)
                .foregroundStyle(.appText)
                .frame(minHeight: DesignSystem.Domain.Voice.transcriptionEditorMinHeight, maxHeight: DesignSystem.Domain.Voice.transcriptionEditorMaxHeight)
                .padding(Spacing.medium)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                        .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth)
                )
            #else
            TextField("", text: Binding(
                get: { speechService.transcribedText },
                set: { speechService.transcribedText = $0 }
            ))
                .font(.body)
                .foregroundStyle(.appText)
                .padding(Spacing.medium)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            #endif
            
            HStack {
                Text("\(speechService.transcribedText.count) \(L10n.Voice.Speech.characters)")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                
                Spacer()
                
                Button(action: { 
                    onFinish?(L10n.Voice.Speech.defaultTitle, speechService.transcribedText)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: DesignSystem.Icons.squareAndPencil)
                        Text(L10n.Voice.Speech.confirmAndEdit)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.standardPadding)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
                }
            }
        }
        .appContainer(cornerRadius: DesignSystem.cardRadius, padding: true)
    }
    
    // MARK: - Recordings History
    private var recordingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(L10n.Voice.Speech.history)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                
                Text("\(speechService.recordings.count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.small)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.microRadius))
            }
            
            VStack(spacing: Spacing.small) {
                ForEach(Array(speechService.recordings.prefix(5))) { recording in
                    VoiceRecordingRow(recording: recording)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
