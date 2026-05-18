// MarkdownEditorView.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] [Shared/UIComponents] 核心编辑器组件：基于 SwiftUI TextEditor 的 Markdown 编辑器，集成了 OCR 文字识别、附件插入及实时语法高亮建议。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 职责解耦：OCR 业务逻辑迁移至 IngestStore。
// 版权: © 2026 Wang Chong。保留所有权利。

import SwiftUI
import PhotosUI

/// Markdown 编辑器核心视图
struct MarkdownEditorView: View {
    @Binding var text: String
    let placeholder: String
    
    @State private var showOCRScanner = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .modifier(OCRPickerModifier(isPresented: $showOCRScanner) { recognizedText in
            if !recognizedText.isEmpty {
                text += "\n\(recognizedText)"
            }
        })
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(action: { showOCRScanner = true }) {
                    Label(L10n.Ingest.ocr.title, systemImage: DesignSystem.Icons.ocr)
                }
                
                Button(action: { text += "**" }) {
                    Image(systemName: DesignSystem.Icons.bold)
                }
                
                Button(action: { text += "*" }) {
                    Image(systemName: DesignSystem.Icons.italic)
                }
                
                Button(action: { text += "[[]]" }) {
                    Image(systemName: DesignSystem.Icons.link)
                }
            }
        }
    }
}

// MARK: - OCR 辅助
@MainActor
struct OCRPickerModifier: ViewModifier {
    @Environment(IngestStore.self) var ingestStore
    @Binding var isPresented: Bool
    let onResult: (String) -> Void
    #if !os(watchOS)
    @State private var selectedItem: PhotosPickerItem?
    #endif

    func body(content: Content) -> some View {
        content
            #if !os(watchOS)
            .photosPicker(isPresented: $isPresented, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = AppImage(data: data) {
                        do {
                            let text = try await ingestStore.recognizeText(from: image)
                            await MainActor.run { onResult(text) }
                        } catch {
                            // 错误处理通常由 UI 层展示 Toast
                            print("❌ [OCR] Failed: \(error.localizedDescription)")
                        }
                    }
                    selectedItem = nil
                }
            }
            #endif
    }
}
