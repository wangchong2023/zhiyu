// PDFComponents.swift
//
// 作者: Wang Chong
// 功能说明: struct PDFIngestSheet
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
#if canImport(PDFKit)
import PDFKit
#endif

// MARK: - PDF Ingest Sheet
/// PDF 资料入库配置面板组件
/// 负责配置 PDF 内容的提取方式（全文、范围或仅高亮），并设定目标 知识库 页面的元数据
struct PDFIngestSheet: View {
    let documentInfo: PDFDocumentInfo
    @Bindable var store: AppStore
    #if canImport(PDFKit)
    let pdfDocument: PDFKit.PDFDocument?
    #endif
    
    @State private var ingestMode = "fullText"
    @State private var pageStart = 1
    @State private var pageEnd = 1
    @State private var targetType = PageType.source
    @State private var targetTitle = ""
    @State private var previewText = ""
    @State private var isLoadingPreview = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                targetSection
                rangeSection
                highlightsSection
                previewSection
            }
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(Localized.tr("pdf.ingestToKnowledge"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(Localized.tr("pdf.ingest")) {
                        Task {
                            await ingestContent()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(targetTitle.isEmpty || isLoadingPreview)
                }
            }
            .onAppear {
                targetTitle = documentInfo.title
                pageEnd = documentInfo.pageCount
                updatePreview()
            }
            .onChange(of: ingestMode) { updatePreview() }
            .onChange(of: pageStart) { updatePreview() }
            .onChange(of: pageEnd) { updatePreview() }
        }
    }
    
    // MARK: - Target Section
    private var targetSection: some View {
        Section {
            TextField(Localized.tr("pdf.pageTitle"), text: $targetTitle)
                .foregroundStyle(.appText)
            
            Picker(Localized.tr("pdf.pageType"), selection: $targetType) {
                ForEach(PageType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
        } header: {
            Text(Localized.tr("pdf.targetPage"))
        }
    }
    
    // MARK: - Range Section
    private var rangeSection: some View {
        Section {
            Picker(Localized.tr("pdf.extractionMethod"), selection: $ingestMode) {
                Text(Localized.tr("pdf.fullText")).tag("fullText")
                Text(Localized.tr("pdf.pageRange")).tag("pageRange")
                Text(Localized.tr("pdf.highlightsOnly")).tag("highlights")
            }
            #if !os(watchOS)
            .pickerStyle(.segmented)
            #endif
            
            if ingestMode == "pageRange" {
                HStack {
                    Text(Localized.tr("pdf.fromPage"))
                    TextField("1", value: $pageStart, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .frame(width: Spacing.Metrics.heroValueSize * 1.9) // 50
                    Text(Localized.tr("pdf.toPage"))
                    TextField("\(documentInfo.pageCount)", value: $pageEnd, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .frame(width: Spacing.Metrics.heroValueSize * 1.9) // 50
                    Text(Localized.tr("pdf.page"))
                }
                .foregroundStyle(.appText)
            }
        } header: {
            Text(Localized.tr("pdf.extractionRange"))
        }
    }
    
    // MARK: - Highlights Section
    @ViewBuilder
    private var highlightsSection: some View {
        if ingestMode == "highlights" && documentInfo.highlights.isEmpty {
            Section {
                Text(Localized.tr("pdf.noHighlights"))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        Section {
            ScrollView {
                if isLoadingPreview {
                    ProgressView()
                        .padding()
                } else {
                    Text(previewText)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                        .lineLimit(10)
                }
            }
            .frame(maxHeight: Spacing.Metrics.heroValueSize * 5.75) // 150
        } header: {
            Text(Localized.tr("pdf.contentPreview"))
        }
    }
    
    // MARK: - Update Preview
    private func updatePreview() {
        Task {
            isLoadingPreview = true
            defer { isLoadingPreview = false }
            
            switch ingestMode {
            case "fullText":
                #if canImport(PDFKit)
                guard let pdfDoc = pdfDocument, let url = pdfDoc.documentURL else {
                    previewText = Localized.tr("pdf.cannotLoadPDF")
                    return
                }
                let text = await store.extractPDFText(from: url, pageRange: 0..<min(2, pdfDoc.pageCount))
                previewText = String(text.prefix(500))
                #else
                previewText = "PDF extraction is not supported on this platform."
                #endif
            case "pageRange":
                #if canImport(PDFKit)
                guard let pdfDoc = pdfDocument, let url = pdfDoc.documentURL else {
                    previewText = ""
                    return
                }
                let start = max(0, pageStart - 1)
                let end = min(pdfDoc.pageCount, pageEnd)
                let text = await store.extractPDFText(from: url, pageRange: start..<end)
                previewText = String(text.prefix(500))
                #else
                previewText = ""
                #endif
            case "highlights":
                let texts = documentInfo.highlights.map { $0.text }
                previewText = String(texts.joined(separator: "\n\n").prefix(500))
            default:
                previewText = ""
            }
        }
    }
    
    // MARK: - Ingest Content
    private func ingestContent() async {
        var content = ""
        
        switch ingestMode {
        case "fullText":
            #if canImport(PDFKit)
            if let pdfDoc = pdfDocument, let url = pdfDoc.documentURL {
                content = await store.extractPDFText(from: url)
            }
            #endif
        case "pageRange":
            #if canImport(PDFKit)
            if let pdfDoc = pdfDocument, let url = pdfDoc.documentURL {
                let start = max(0, pageStart - 1)
                let end = min(pdfDoc.pageCount, pageEnd)
                content = await store.extractPDFText(from: url, pageRange: start..<end)
            }
            #endif
        case "highlights":
            content = documentInfo.highlights.map { h in
                var text = "> \(h.text)"
                if !h.note.isEmpty {
                    text += "\n\n\(Localized.tr("pdf.noteLabel")) \(h.note)"
                }
                return text
            }.joined(separator: "\n\n---\n\n")
        default:
            break
        }
        
        let _ = store.createPage(
            title: targetTitle,
            type: targetType,
            content: content,
            tags: ["PDF", Localized.tr("logAction.ingest")]
        )
        store.addLog(action: .importPDF, target: targetTitle, details: Localized.trf("pdf.ingestModeFormat", ingestMode))
        store.saveToDisk()
        dismiss()
    }
}

// MARK: - PDF Document Row
/// PDF 文档列表行组件
/// 负责展示 PDF 文件的基本元数据（标题、页数、高亮统计）及预览图标
struct PDFDocumentRow: View {
    let doc: PDFDocumentInfo
    
    var body: some View {
        HStack(spacing: Spacing.medium) { // 12
            pdfIcon
            docInfo
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .padding(.vertical, Spacing.atomic * 2) // 4
    }
    
    private var pdfIcon: some View {
        RoundedRectangle(cornerRadius: Spacing.microRadius)
            .fill(Color.appAccent.opacity(Colors.Opacity.glassOpacity * 1.5)) // 0.15
            .frame(width: Spacing.Metrics.heroValueSize * 1.85, height: Spacing.Metrics.heroValueSize * 2.45) // 48, 64
            .overlay(
                VStack(spacing: Spacing.atomic * 2) { // 4
                    Image(systemName: "doc.richtext.fill")
                        .font(.title3)
                        .foregroundStyle(.appAccent)
                    Text("\(doc.pageCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.appAccent)
                }
            )
    }
    
    private var docInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.atomic * 2) { // 4
            Text(doc.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appText)
                .lineLimit(1)
            
            HStack(spacing: Spacing.small) { // 8
                Label(Localized.trf("pdf.pageCountFormat", doc.pageCount), systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                
                Label(Localized.trf("pdf.highlightCountFormat", doc.highlights.count), systemImage: "highlighter")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            
            Text(doc.addedDate.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Localized.currentLocale)))
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
    }
}

#if canImport(PDFKit)
// MARK: - PDF Preview Wrapper
/// PDF 预览包装器组件
/// 负责在 SwiftUI 中嵌入原生 PDFView 渲染引擎，支持文档加载与自动缩放
struct PDFPreviewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFKit.PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFKit.PDFDocument(url: url)
        }
    }
}
#endif

// MARK: - Highlight Color Extension
extension Color {
    static func pdfHighlight(_ name: String) -> Color {
        switch name {
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "pink": return .pink
        case "purple": return .purple
        default: return .yellow
        }
    }
}