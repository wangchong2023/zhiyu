//
//  MarkdownEditorView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：构建 MarkdownEditor 界面的 UI 视图层组件。
//
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
                    .padding(.horizontal, DesignSystem.tiny)
                    .padding(.vertical, DesignSystem.small)
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

    /// 视图主体
    /// /// - Parameter content: content
    /// /// - Returns: 返回值
    func body(content: Content) -> some View {
        content
            #if !os(watchOS)
            .photosPicker(isPresented: $isPresented, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { oldValue, newValue in
                guard let newItem = newValue else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = AppImage(data: data) {
                        do {
                            let text = try await ingestStore.recognizeText(from: image)
                            onResult(text)
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
