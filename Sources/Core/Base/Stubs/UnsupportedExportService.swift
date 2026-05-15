// UnsupportedExportService.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：ExportServiceProtocol 的不支持平台占位实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 不支持导出的平台实现
final class UnsupportedExportService: ExportServiceProtocol, Sendable {
    func exportToPDF(markdown: String, fileName: String) async throws -> URL {
        throw NSError(domain: "Export", code: 501, userInfo: [NSLocalizedDescriptionKey: "Export is not supported on this platform."])
    }
    
    func exportMindmapToPDF(mermaidCode: String, fileName: String) async throws -> URL {
        throw NSError(domain: "Export", code: 501, userInfo: [NSLocalizedDescriptionKey: "Export is not supported on this platform."])
    }
    
    func exportToPPTX(markdown: String, fileName: String) async throws -> URL {
        throw NSError(domain: "Export", code: 501, userInfo: [NSLocalizedDescriptionKey: "Export is not supported on this platform."])
    }
}
