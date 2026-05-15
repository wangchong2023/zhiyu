// WebViewExportService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：网页导出服务 (L0 基础架构层)
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 修复多任务并发导致的报错与崩溃，引入串行导出锁定机制。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 导出服务门面 (L0 基础架构层)
/// 负责协调底层平台的导出实现（如 WebKit 或 Stub）。
@MainActor
final class WebViewExportService {
    static let shared = WebViewExportService()
    
    @Inject private var exportService: any ExportServiceProtocol
    
    private init() {}
    
    /// 将 Markdown 导出为 PDF
    func exportToPDF(markdown: String, fileName: String) async throws -> URL {
        try await exportService.exportToPDF(markdown: markdown, fileName: fileName)
    }

    /// 将 Mermaid 导出为 PDF
    func exportMindmapToPDF(mermaidCode: String, fileName: String) async throws -> URL {
        try await exportService.exportMindmapToPDF(mermaidCode: mermaidCode, fileName: fileName)
    }
    
    /// 将 Markdown 导出为 PPTX
    func exportToPPTX(markdown: String, fileName: String) async throws -> URL {
        try await exportService.exportToPPTX(markdown: markdown, fileName: fileName)
    }
}

