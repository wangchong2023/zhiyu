// PDFServiceProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：PDF 处理器抽象协议，定义跨平台 PDF 文本提取能力。
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，旨在剥离 PDFKit。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// PDF 处理服务协议
@MainActor
public protocol PDFServiceProtocol: Sendable {
    /// 保存 PDF 数据
    func savePDF(data: Data, fileName: String) async -> URL?
    
    /// 删除 PDF 文件
    func deletePDF(fileName: String) async -> Bool
    
    /// 获取所有 PDF 文件名
    func allPDFFilenames() async -> [String]
    
    /// 获取指定 PDF 文件的物理路径
    func getPDFURL(fileName: String) -> URL?
    
    /// 提取全量文本内容
    func extractText(from url: URL) async -> String?
    
    /// 提取指定页码范围的文本内容
    func extractText(from url: URL, pageRange: Range<Int>) async -> String?
    
    /// 保存元数据
    func saveDocumentsInfo(_ docs: [PDFDocumentInfo]) async
    
    /// 加载元数据
    func loadDocumentsInfo() async -> [PDFDocumentInfo]
}
