// ExportServiceProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：导出服务抽象协议，支持 Markdown/Mermaid 导出为 PDF/PPTX。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 导出服务协议
public protocol ExportServiceProtocol: Sendable {
    /// 将 Markdown 导出为 PDF
    func exportToPDF(markdown: String, fileName: String) async throws -> URL
    
    /// 将 Mermaid 导出为 PDF
    func exportMindmapToPDF(mermaidCode: String, fileName: String) async throws -> URL
    
    /// 将 Markdown 导出为 PPTX
    func exportToPPTX(markdown: String, fileName: String) async throws -> URL
}
