// iOSPDFService.swift
//
// 作者: Wang Chong
// 功能说明: PDFServiceProtocol 的 iOS/macOS 实现，基于 PDFKit。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if !os(watchOS)
import Foundation
import PDFKit

/// iOS/macOS PDF 处理实现
final class iOSPDFService: PDFServiceProtocol {
    private let documentsDirectory: URL

    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppPDFs", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - File Management

    func savePDF(data: Data, fileName: String) async -> URL? {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    func deletePDF(fileName: String) async -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }

    func allPDFFilenames() async -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "pdf" }
                .map { $0.lastPathComponent }
                .sorted()
        } catch {
            return []
        }
    }

    // MARK: - Text Extraction

    func extractText(from url: URL) async -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
                text += String(format: Localized.tr("pdf.pageSeparator"), i + 1)
            }
        }
        return text
    }

    // MARK: - Metadata Persistence

    func saveDocumentsInfo(_ docs: [PDFDocumentInfo]) async {
        let url = documentsDirectory.appendingPathComponent("pdf_metadata.json")
        if let data = try? JSONEncoder().encode(docs) {
            try? data.write(to: url)
        }
    }

    func loadDocumentsInfo() async -> [PDFDocumentInfo] {
        let url = documentsDirectory.appendingPathComponent("pdf_metadata.json")
        guard let data = try? Data(contentsOf: url),
              let docs = try? JSONDecoder().decode([PDFDocumentInfo].self, from: data) else {
            return []
        }
        return docs
    }
}
#endif
