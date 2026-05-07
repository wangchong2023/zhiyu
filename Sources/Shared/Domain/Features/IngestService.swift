// IngestService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的自动化入库引擎（IngestService），负责将多源异构数据（网页、文档、剪贴板）转化为结构化的 知识库 页面。
// 该服务整合了格式解析、语义增强与生态节能机制，核心功能点如下：
// 1. 多格式深度解析：支持对 DOCX、XLSX、PDF 及 Markdown 等主流文档格式的流式解析与文本提取，内置 ZIP 解压与 XML 处理逻辑。
// 2. 网页智能摄入：集成 WebScraperProcessor（原 LinkProcessor），支持通过 Jina Reader 等引擎实现网页内容的去噪提取与自动标题识别。
// 3. 语义增强与链接发现：在入库过程中利用 LLM 对图表进行文本化解释，并自动匹配已有知识库标题以建立 知识库-link 关联。
// 4. 智适应节能模式：实现了针对 iOS 低功耗模式的“生态索引”机制，通过动态节流与 CPU 释放保障在大规模导入时的设备响应速度。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，修复重命名导致的 LinkProcessor 引用错误，完善 RAG 入库逻辑说明
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Compression

// MARK: - Document Format

enum DocumentFormat {
    case markdown
    case plainText
    case docx
    case xlsx
    case pdf
    case unknown

    static func detectFormat(from url: URL) -> DocumentFormat {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "md", "markdown":
            return .markdown
        case "txt", "text":
            return .plainText
        case "docx":
            return .docx
        case "xlsx":
            return .xlsx
        case "pdf":
            return .pdf
        default:
            return .unknown
        }
    }
}

// MARK: - Page Store Protocol

/// Abstraction layer allowing different store implementations to serve as data sources.
/// SQLiteStore is the sole implementation; PageStore was removed (JSON-based, unused).
@MainActor
protocol AnyPageStore {
    var pages: [KnowledgePage] { get }
    @discardableResult
    func createPage(title: String, type: PageType, content: String, tags: [String], sourceURL: String?, rawSnippet: String?, fileSize: Int64?, sourceType: String?, forceDeepScan: Bool) -> KnowledgePage
    func updatePage(_ page: KnowledgePage, forceDeepScan: Bool)
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?)
}
// Note: SQLiteStore conformance is declared in SQLiteStore.swift to avoid circular dependency

// MARK: - Ingest Service (Knowledge Ingestion)
@MainActor
final class IngestService {
    let scraper = WebScraperProcessor()

    /// 将原始内容摄入知识库：创建新页面并自动链接已知概念。
    /// - Returns: The created page (with auto-linked content).
    /// 将原始内容摄入知识库：创建新页面并自动链接已知概念。
    /// - Returns: The created page (with auto-linked content).
    func ingestRawContent(
        title: String,
        content: String,
        type: PageType = .source,
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        forceDeepScan: Bool = false,
        llmService: (any LLMServiceProtocol)? = nil,
        pageStore: any AnyPageStore,
        fileSize: Int64? = nil,
        sourceType: String? = nil
    ) async -> KnowledgePage {
        let startTime = Date()
        let pageID = UUID()
        
        // --- RAG 摄入管道集成 ---
        let processedContent: String
        if forceDeepScan || llmService != nil {
            let embeddingManager: EmbeddingManager
            if let sqlite = pageStore as? SQLiteStore {
                embeddingManager = sqlite.embeddingManager
            } else if let km = pageStore as? AppStore {
                embeddingManager = km.sqliteStore.embeddingManager
            } else {
                // fallback: 使用全局 DatabaseManager 获取 dbWriter 并创建临时的 EmbeddingManager
                guard let writer = DatabaseManager.shared.dbWriter else {
                    fatalError("Database not initialized")
                }
                embeddingManager = EmbeddingManager(repository: KnowledgePageStore(dbWriter: writer))
            }

            processedContent = await KnowledgeIngestPipeline.shared.process(
                content: content,
                pageID: pageID,
                llm: llmService,
                embeddingManager: embeddingManager
            )
        } else {
            processedContent = content
        }

        // Create raw source page with provenance
        let rawPage = pageStore.createPage(
            title: title,
            type: type,
            content: processedContent,
            tags: ["ingested"],
            sourceURL: sourceURL,
            rawSnippet: rawSnippet ?? String(processedContent.prefix(500)),
            fileSize: fileSize,
            sourceType: sourceType,
            forceDeepScan: forceDeepScan
        )

        // Auto-extract potential concept links from content
        let concepts = extractConcepts(from: processedContent, pages: pageStore.pages)
        var updatedContent = rawPage.content

        for concept in concepts {
            updatedContent = updatedContent.replacingOccurrences(
                of: concept,
                with: "[[\(concept)]]"
            )
        }

        var page = rawPage
        page.content = updatedContent
        pageStore.updatePage(page, forceDeepScan: forceDeepScan)

        let duration = Date().timeIntervalSince(startTime)
        pageStore.addLog(
            action: .create,
            target: title,
            details: "Ingested \(processedContent.count) chars. DeepScan: \(forceDeepScan)",
            duration: duration,
            startTime: startTime,
            endTime: Date(),
            module: "IngestService"
        )

        return page
    }

    /// 从 URL 摄入内容
    func ingestURL(
        urlString: String,
        forceDeepScan: Bool = true,
        llmService: (any LLMServiceProtocol)? = nil,
        pageStore: any AnyPageStore
    ) async throws -> KnowledgePage {
        let result = try await scraper.fetchMarkdown(from: urlString)
        var content = result.markdown
        
        // 使用统一的 RAG 摄入管道
        // 注意：ingestRawContent 内部现在已经包含了 pipeline 调用
        
        return await ingestRawContent(
            title: result.title,
            content: content,
            type: .source,
            sourceURL: urlString,
            rawSnippet: String(content.prefix(1000)),
            forceDeepScan: forceDeepScan,
            llmService: llmService,
            pageStore: pageStore
        )
    }

    /// Extract existing page titles mentioned in the given content.
    func extractConcepts(from content: String, pages: [KnowledgePage]) -> [String] {
        var found: [String] = []
        for page in pages {
            if content.lowercased().contains(page.title.lowercased()) {
                found.append(page.title)
            }
        }
        return found
    }
    

    // MARK: - Document Ingestion

    /// Ingest a document file, automatically detecting format and extracting text content.
    /// - Returns: The created KnowledgePage, or nil if extraction failed.
    /// Ingest a document file, automatically detecting format and extracting text content.
    /// - Returns: The created KnowledgePage, or nil if extraction failed.
    func ingestDocument(
        at url: URL,
        title: String? = nil,
        type: PageType = .source,
        pageStore: any AnyPageStore
    ) async -> KnowledgePage? {
        let format = DocumentFormat.detectFormat(from: url)

        let extractedTitle = title ?? url.deletingPathExtension().lastPathComponent
        var content: String?

        switch format {
        case .docx:
            content = extractTextFromDocx(at: url)
        case .xlsx:
            content = extractTextFromXlsx(at: url)
        case .markdown, .plainText:
            content = try? String(contentsOf: url, encoding: .utf8)
        case .pdf:
            content = PDFProcessor.extractText(from: url)
        case .unknown:
            print("Unknown document format: \(url.pathExtension)")
            return nil
        }

        guard let text = content, !text.isEmpty else {
            print("Failed to extract text from document: \(url.path)")
            return nil
        }

        return await ingestRawContent(title: extractedTitle, content: text, type: type, forceDeepScan: true, pageStore: pageStore)
    }

    /// Batch import all supported documents from a folder. (Enhanced: Eco-Indexing)
    /// Batch import all supported documents from a folder. (Enhanced: Parallel processing)
    func ingestFolder(
        at url: URL,
        type: PageType = .source,
        pageStore: any AnyPageStore
    ) async -> [KnowledgePage] {
        var pages: [KnowledgePage] = []

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("Failed to enumerate folder: \(url.path)")
            return pages
        }
        
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if isLowPowerMode {
            print(L10n.Ingest.tr("ecoIndexingLowPower"))
        }

        return await withTaskGroup(of: KnowledgePage?.self) { group in
            for case let fileURL as URL in enumerator {
                group.addTask {
                    // 智适应节流：低功耗模式下每个文件处理后强制休息，释放 CPU
                    if isLowPowerMode {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                    
                    if let page = await self.ingestDocument(at: fileURL, type: type, pageStore: pageStore) {
                        await MainActor.run {
                            LocalAnalyticsService.shared.trackEvent("document_ingested", properties: ["format": fileURL.pathExtension])
                        }
                        return page
                    }
                    return nil
                }
            }
            
            var results: [KnowledgePage] = []
            for await page in group {
                if let p = page { results.append(p) }
            }
            return results
        }
    }

    // MARK: - DOCX Text Extraction

    /// Extract text content from a DOCX file.
    /// DOCX is a ZIP archive containing document.xml with XML-formatted text.
    func extractTextFromDocx(at url: URL) -> String? {
        guard let archive = readZipArchive(at: url) else { return nil }

        guard let documentXML = archive["word/document.xml"] else {
            print("DOCX missing word/document.xml")
            return nil
        }

        let parser = DocxProcessor(xmlData: documentXML)
        if parser.parse() {
            return parser.extractedText
        } else {
            print("DOCX XML parsing failed")
            return nil
        }
    }

    // MARK: - XLSX Text Extraction

    /// Extract text content from an XLSX file.
    /// XLSX is a ZIP archive containing xl/sharedStrings.xml and sheet files.
    func extractTextFromXlsx(at url: URL) -> String? {
        guard let archive = readZipArchive(at: url) else { return nil }

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

        return allText.isEmpty ? nil : allText.joined(separator: "\n")
    }

    // MARK: - ZIP Archive Helper

    /// Read a ZIP archive and return a dictionary of file paths to their uncompressed data.
    private func readZipArchive(at url: URL) -> [String: Data]? {
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to read file data: \(url.path)")
            return nil
        }

        var archive: [String: Data] = [:]

        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            guard let baseAddress = buffer.baseAddress else { return }

            var offset = 0
            let count = buffer.count

            while offset + 30 < count {
                let bytes = baseAddress.advanced(by: offset)

                // Local file header signature
                guard bytes.load(as: UInt32.self) == 0x04034b50 else {
                    // Try to find next file header
                    if let nextOffset = findNextLocalFileHeader(in: buffer, start: offset) {
                        offset = nextOffset
                        continue
                    }
                    break
                }

                let fileNameLength = Int(bytes.load(fromByteOffset: 28, as: UInt16.self))
                let extraFieldLength = Int(bytes.load(fromByteOffset: 30, as: UInt16.self))
                let compressedSize = Int(bytes.load(fromByteOffset: 18, as: UInt32.self))

                let headerSize = 30 + fileNameLength + extraFieldLength
                let dataOffset = offset + headerSize

                guard dataOffset + compressedSize <= count else { break }

                let nameBytes = UnsafeRawPointer(baseAddress).advanced(by: offset + 30)
                let fileNameData = Data(bytes: nameBytes, count: fileNameLength)
                guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                    offset += 4
                    continue
                }

                // Decompress if needed (method 0 = stored, 8 = deflate)
                let compressionMethod = UInt16(bytes.load(fromByteOffset: 8, as: UInt16.self))
                let compressedData = Data(bytes: baseAddress.advanced(by: dataOffset), count: compressedSize)

                if compressionMethod == 0 {
                    archive[fileName] = compressedData
                } else if compressionMethod == 8 {
                    if let decompressed = decompressDeflate(data: compressedData) {
                        archive[fileName] = decompressed
                    }
                }

                offset = dataOffset + compressedSize
            }
        }

        return archive.isEmpty ? nil : archive
    }

    private func findNextLocalFileHeader(in buffer: UnsafeRawBufferPointer, start: Int) -> Int? {
        let count = buffer.count
        var i = start + 4
        while i + 4 <= count {
            let sig = buffer.load(fromByteOffset: i, as: UInt32.self)
            if sig == 0x04034b50 {
                return i
            }
            i += 1
        }
        return nil
    }

    private func decompressDeflate(data: Data) -> Data? {
        let destinationBufferSize = data.count * 10
        var destinationBuffer = [UInt8](repeating: 0, count: destinationBufferSize)

        let result = data.withUnsafeBytes { (sourceBuffer: UnsafeRawBufferPointer) -> Int? in
            guard let sourcePointer = sourceBuffer.baseAddress else { return nil }

            return sourcePointer.withMemoryRebound(to: UInt8.self, capacity: data.count) { sourcePtr in
                compression_decode_buffer(
                    &destinationBuffer,
                    destinationBufferSize,
                    sourcePtr,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        guard let size = result, size > 0 else { return nil }
        return Data(destinationBuffer.prefix(size))
    }
}