// WatchPDFService.swift
//
// 作者: Wang Chong
// 功能说明: PDFServiceProtocol 的 watchOS 实现 (存根)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import Foundation

/// watchOS PDF 处理实现 (手表暂不支持 PDF 解析)
final class WatchPDFService: PDFServiceProtocol {
    func savePDF(data: Data, fileName: String) async -> URL? { return nil }
    func deletePDF(fileName: String) async -> Bool { return false }
    func allPDFFilenames() async -> [String] { return [] }
    func extractText(from url: URL) async -> String? { return nil }
    func saveDocumentsInfo(_ docs: [PDFDocumentInfo]) async {}
    func loadDocumentsInfo() async -> [PDFDocumentInfo] { return [] }
}
#endif
