// DocumentProcessor.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：定义文档处理通用协议与工厂，实现 IngestService 与具体格式解析器的解耦。
// 版本: 1.1
// 修改记录:
//   - 2026-05-07: 初始版本，引入工厂模式。
//   - 2026-05-07: 完善 DOCX/XLSX 解析逻辑，对接 ZipUtility。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 文档处理器协议
protocol DocumentProcessor: Sendable {
    /// 提取文档中的文本内容
    func extractText(from url: URL) async throws -> String
}

/// 文档处理器工厂
struct DocumentProcessorFactory {
    /// 根据文档格式获取对应的处理器
    static func processor(for format: DocumentFormat) -> (any DocumentProcessor)? {
        switch format {
        case .pdf:
            return PDFProcessorProxy()
        case .docx:
            return DocxProcessorProxy()
        case .xlsx:
            return XlsxProcessorProxy()
        case .markdown, .plainText:
            return TextProcessorProxy()
        default:
            return nil
        }
    }
}

// MARK: - 具体处理器代理 (适配现有实现)

struct PDFProcessorProxy: DocumentProcessor {
    @Inject private var pdfService: any PDFServiceProtocol

    func extractText(from url: URL) async throws -> String {
        guard let text = await pdfService.extractText(from: url) else {
            throw ProcessorError.extractionFailed
        }
        return text
    }
}

struct DocxProcessorProxy: DocumentProcessor {
    func extractText(from url: URL) async throws -> String {
        guard let archive = ZipUtility.readZipArchive(at: url) else {
            throw ProcessorError.extractionFailed
        }

        guard let documentXML = archive["word/document.xml"] else {
            throw ProcessorError.extractionFailed
        }

        let parser = DocxProcessor(xmlData: documentXML)
        if parser.parse() {
            return parser.extractedText
        } else {
            throw ProcessorError.extractionFailed
        }
    }
}

struct XlsxProcessorProxy: DocumentProcessor {
    func extractText(from url: URL) async throws -> String {
        guard let archive = ZipUtility.readZipArchive(at: url) else {
            throw ProcessorError.extractionFailed
        }

        var sharedStrings: [String] = []

        // Extract shared strings (common string values)
        if let sharedStringsXML = archive["xl/sharedStrings.xml"] {
            let parser = XlsxSharedStringsParser(xmlData: sharedStringsXML)
            if parser.parse() {
                sharedStrings = parser.strings
            }
        }

        var allText: [String] = []

        // Extract from each sheet
        for (path, data) in archive {
            if path.hasPrefix("xl/worksheets/sheet") && path.hasSuffix(".xml") {
                let parser = ExcelProcessor(xmlData: data)
                if parser.parse() {
                    // Resolve shared string references
                    for value in parser.values {
                        if value.hasPrefix("[") && value.hasSuffix("]"),
                           let index = Int(value.dropFirst().dropLast()),
                           index < sharedStrings.count {
                            allText.append(sharedStrings[index])
                        } else if !value.isEmpty && !value.hasPrefix("[") {
                            allText.append(value)
                        }
                    }
                }
            }
        }

        if allText.isEmpty {
            throw ProcessorError.extractionFailed
        }
        return allText.joined(separator: "\n")
    }
}

struct TextProcessorProxy: DocumentProcessor {
    func extractText(from url: URL) async throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }
}

enum ProcessorError: Error {
    case extractionFailed
    case notImplemented
}
