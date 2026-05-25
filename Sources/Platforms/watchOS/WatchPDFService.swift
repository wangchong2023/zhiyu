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

    /// 保存PDF
    /// /// - Parameter data: data
    /// /// - Parameter fileName: fileName
    /// /// - Returns: 可选值
    func savePDF(data: Data, fileName: String) async -> URL? { return nil }

    /// 删除PDF
    /// /// - Parameter fileName: fileName
    /// /// - Returns: 是否成功
    func deletePDF(fileName: String) async -> Bool { return false }

    /// allPDFFilenames
    /// /// - Returns: 列表
    func allPDFFilenames() async -> [String] { return [] }

    /// 获取PDFURL
    /// /// - Parameter fileName: fileName
    /// /// - Returns: 可选值
    func getPDFURL(fileName: String) -> URL? { return nil }

    /// 提取Text
    /// /// - Returns: 可选值
    func extractText(from url: URL) async -> String? { return nil }

    /// 提取Text
    /// /// - Parameter pageRange: pageRange
    /// /// - Returns: 可选值
    func extractText(from url: URL, pageRange: Range<Int>) async -> String? { return nil }

    /// 保存DocumentsInfo
    /// /// - Parameter docs: docs
    func saveDocumentsInfo(_ docs: [PDFDocumentInfo]) async {}

    /// 加载DocumentsInfo
    /// /// - Returns: 列表
    func loadDocumentsInfo() async -> [PDFDocumentInfo] { return [] }
}
#endif
