//
//  WatchPDFService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 WatchPDF 模块的核心业务逻辑服务。
//
#if os(watchOS)
import Foundation

/// watchOS PDF 处理实现 (手表暂不支持 PDF 解析)
final class WatchPDFService: PDFServiceProtocol {
    func savePDF(data: Data, fileName: String) async -> URL? { return nil }
    func deletePDF(fileName: String) async -> Bool { return false }
    func allPDFFilenames() async -> [String] { return [] }
    func getPDFURL(fileName: String) -> URL? { return nil }
    func extractText(from url: URL) async -> String? { return nil }
    func extractText(from url: URL, pageRange: Range<Int>) async -> String? { return nil }
    func saveDocumentsInfo(_ docs: [PDFDocumentInfo]) async {}
    func loadDocumentsInfo() async -> [PDFDocumentInfo] { return [] }
}
#endif
