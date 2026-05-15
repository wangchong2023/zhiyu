// PDFReaderView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：struct PDFLibraryView
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
import UniformTypeIdentifiers

// MARK: - PDF Library View
#if os(watchOS)
@MainActor
struct PDFLibraryView: View {
    var body: some View {
        Text(Localized.tr("status.simulatorNotSupported"))
    }
}

struct PDFReaderView: View {
    let documentInfo: PDFDocumentInfo
    var body: some View {
        Text(Localized.tr("status.simulatorNotSupported"))
    }
}
#else
@MainActor
struct PDFLibraryView: View {
    @Environment(AppStore.self) var store
    @State private var documents: [PDFDocumentInfo] = []
    @State private var showFilePicker = false
    @State private var selectedDoc: PDFDocumentInfo?

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    PDFLibraryEmptyView(onAdd: { showFilePicker = true })
                } else {
                    PDFDocumentListView(
                        documents: documents,
                        onSelect: { selectedDoc = $0 },
                        onDelete: deleteDocument,
                        onIngest: ingestPDF
                    )
                }
            }
            .navigationTitle(Localized.tr("pdf.title"))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showFilePicker = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(item: $selectedDoc) { doc in
                PDFReaderView(documentInfo: doc)
            }
            .onAppear {
                Task {
                    documents = await store.loadPDFDocuments()
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }

            guard let data = try? Data(contentsOf: url) else { return }
            let fileName = "\(UUID().uuidString).pdf"

            Task {
                if let _ = await store.savePDFDocument(data: data, fileName: fileName) {
                    let pdfDoc = PDFKit.PDFDocument(data: data)
                    let docInfo = PDFDocumentInfo(
                        title: url.deletingPathExtension().lastPathComponent,
                        fileName: fileName,
                        pageCount: pdfDoc?.pageCount ?? 0
                    )
                    documents.append(docInfo)
                    await store.savePDFDocuments(documents)
                    store.addLog(action: .importPDF, target: docInfo.title, details: Localized.trf("pdf.pageCountFormat", docInfo.pageCount))
                }
            }

        case .failure(let error):
            store.addLog(action: .importPDFFailed, target: "", details: error.localizedDescription)
        }
    }

    private func deleteDocument(_ doc: PDFDocumentInfo) {
        Task {
            _ = await store.deletePDFDocument(fileName: doc.fileName)
            documents.removeAll { $0.id == doc.id }
            await store.savePDFDocuments(documents)
            store.addLog(action: .deletePDF, target: doc.title, details: "")
        }
    }

    private func ingestPDF(_ doc: PDFDocumentInfo) {
        Task {
            guard let pdfDoc = await store.loadPDFDocument(fileName: doc.fileName) else { return }
            let text = await store.extractPDFText(from: pdfDoc)

            if !text.isEmpty {
                let page = await store.createPage(
                    title: doc.title,
                    type: .source,
                    content: text,
                    tags: ["PDF", Localized.tr("logAction.ingest")]
                )
                store.addLog(action: .importPDF, target: doc.title, details: Localized.trf("pdf.createdPage", page.title))
                store.saveToDisk()
            }
        }
    }
}

// MARK: - PDF Library Empty View
private struct PDFLibraryEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(Localized.tr("pdf.library"), systemImage: "doc.richtext")
        } description: {
            Text(Localized.tr("pdf.libraryHint"))
        } actions: {
            AppPrimaryButton(title: Localized.tr("pdf.add"), action: onAdd)
                .frame(maxWidth: 200)
        }
    }
}

// MARK: - PDF Document List View
private struct PDFDocumentListView: View {
    let documents: [PDFDocumentInfo]
    let onSelect: (PDFDocumentInfo) -> Void
    let onDelete: (PDFDocumentInfo) -> Void
    let onIngest: (PDFDocumentInfo) -> Void

    var body: some View {
        List {
            ForEach(documents) { doc in
                Button(action: { onSelect(doc) }) {
                    PDFDocumentRow(doc: doc)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDelete(doc)
                    } label: {
                        Label(Localized.tr("pdf.delete"), systemImage: "trash")
                    }

                    Button(action: { onIngest(doc) }) {
                        Label(Localized.tr("pdf.ingest"), systemImage: "arrow.down.doc")
                    }
                    .tint(.appAccent)
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#endif
        .scrollContentBackground(.hidden)
        .background(PageBackgroundView(accentColor: .appAccent))
    }
}

// MARK: - PDF Reader View (Full Screen)
struct PDFReaderView: View {
    let documentInfo: PDFDocumentInfo
    @Environment(AppStore.self) var store

    @State private var currentPage = 0
    @State private var highlights: [PDFHighlight] = []
    @State private var showHighlightPanel = false
    @State private var showIngestSheet = false
    @State private var selectedText = ""
    @State private var highlightColor = "yellow"
    @State private var highlightNote = ""
    @State private var pdfDocument: PDFKit.PDFDocument?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackgroundView(accentColor: .appAccent)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    pdfContent
                    bottomBar
                }
            }
            .navigationTitle(documentInfo.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: { showHighlightPanel.toggle() }) {
                        Image(systemName: showHighlightPanel ? "highlighter.fill" : "highlighter")
                    }

                    Button(action: { showIngestSheet = true }) {
                        Image(systemName: "arrow.down.doc")
                    }
                }
            }
            .sheet(isPresented: $showIngestSheet) {
                PDFIngestSheet(documentInfo: documentInfo, store: store, pdfDocument: pdfDocument)
            }
        }
        .onAppear {
            Task {
                if let url = await store.loadPDFDocument(fileName: documentInfo.fileName) {
                    #if canImport(PDFKit)
                    pdfDocument = PDFDocument(url: url)
                    #endif
                }
                highlights = documentInfo.highlights
                currentPage = documentInfo.lastReadPage
            }
        }
    }

    // MARK: - PDF Content
    @ViewBuilder
    private var pdfContent: some View {
        #if canImport(PDFKit)
        if let pdfDoc = pdfDocument {
            PDFKitRepresentedView(
                document: pdfDoc,
                currentPage: $currentPage,
                onTextSelected: { selectedText = $0 }
            )
            .ignoresSafeArea()
        } else {
            ContentUnavailableView(Localized.tr("pdf.cannotLoadPDF"), systemImage: "exclamationmark.triangle")
        }
        #else
        ContentUnavailableView(Localized.tr("pdf.notSupported"), systemImage: DesignSystem.Icons.warning, description: Text(Localized.tr("pdf.notSupportedDesc")))
        #endif
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            if showHighlightPanel && !selectedText.isEmpty {
                highlightEditor
            }

            HStack {
                #if canImport(PDFKit)
                Text("\(currentPage + 1) / \(pdfDocument?.pageCount ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                #else
                Text("0 / 0")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                #endif

                Spacer()

                if !highlights.isEmpty {
                    Button(action: { showHighlightPanel.toggle() }) {
                        Label("\(highlights.count)", systemImage: "highlighter")
                            .font(.caption)
                            .foregroundStyle(.appAccent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appCard)
        }
    }

    // MARK: - Highlight Editor
    private var highlightEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localized.tr("pdf.annotateSelected"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.appText)

            Text(selectedText)
                .font(.caption)
                .foregroundStyle(.appSecondary)
                .lineLimit(3)

            HStack(spacing: 8) {
                ForEach(["yellow", "green", "blue", "pink", "purple"], id: \.self) { color in
                    Button(action: { highlightColor = color }) {
                        Circle()
                            .fill(Color.pdfHighlight(color))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.appText, lineWidth: highlightColor == color ? 2 : 0)
                            )
                    }
                }
                Spacer()
            }

            TextField(Localized.tr("pdf.addNote"), text: $highlightNote)
                .font(.caption)
#if os(iOS) || os(macOS)
                .textFieldStyle(.roundedBorder)
#endif

            Button(action: saveHighlight) {
                Text(Localized.tr("pdf.saveAnnotation"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
            }
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard)
    }

    // MARK: - Actions
    private func saveHighlight() {
        let highlight = PDFHighlight(
            pageIndex: currentPage,
            text: selectedText,
            color: highlightColor,
            note: highlightNote
        )
        highlights.append(highlight)

        Task {
            var docs = await store.loadPDFDocuments()
            if let index = docs.firstIndex(where: { $0.id == documentInfo.id }) {
                docs[index].highlights = highlights
                await store.savePDFDocuments(docs)
            }
        }

        selectedText = ""
        highlightNote = ""
        showHighlightPanel = false

        store.addLog(action: .highlight, target: documentInfo.title, details: Localized.trf("pdf.pageNumber", currentPage + 1))
    }
}

#endif
