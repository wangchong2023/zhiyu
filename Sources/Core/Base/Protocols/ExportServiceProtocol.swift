//
//  ExportServiceProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 ExportService 模块的抽象契约接口。
//
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

/// 导出服务专用的强类型异常定义
public enum ExportError: LocalizedError, Sendable {
    /// 导出引擎正忙，请稍后重试
    case systemBusy
    /// 导出引擎未初始化或不可用
    case engineNotReady
    /// 运行期发生内部脚本或引擎崩溃
    case internalError(String)
    
    public var errorDescription: String? {
        switch self {
        case .systemBusy:
            return L10n.Transfer.Export.errorSystemBusy
        case .engineNotReady:
            return L10n.Transfer.Export.errorEngineNotReady
        case .internalError(let msg):
            return L10n.Transfer.Export.errorInternal(msg)
        }
    }
}
