//
//  iOSPDFService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 iOSPDF 模块的核心业务逻辑服务。
//
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

    func getPDFURL(fileName: String) -> URL? {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    // MARK: - Text Extraction

    func extractText(from url: URL) async -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        return await extractText(from: url, pageRange: 0..<document.pageCount)
    }

    func extractText(from url: URL, pageRange: Range<Int>) async -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var text = ""
        let start = max(0, pageRange.lowerBound)
        let end = min(document.pageCount, pageRange.upperBound)
        
        for i in start..<end {
            if let page = document.page(at: i) {
                text += page.string ?? ""
                text += String(format: L10n.Ingest.PDF.pageSeparator, i + 1)
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
