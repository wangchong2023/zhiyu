//
//  UnsupportedExportService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：实现 UnsupportedExport 模块的核心业务逻辑服务。
//
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
