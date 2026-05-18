// IngestService.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：本文件实现了知识管理系统的自动化入库引擎，负责将多源异构数据转化为结构化的知识页面。
// MARK: [SR-02] 混合检索 (RAG) 摄入管道编排与知识提取
// MARK: [PR-02] 混合检索 (RAG) 链路耗时优化
// 版本: 1.2
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

// MARK: - Ingest Service (Knowledge Ingestion)
actor IngestService {
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

        // 1. 安全脱敏：拦截恶意指令注入 (@P0: Security)
        let sanitizedRawContent = PromptSanitizer.sanitize(content)

        // --- RAG 摄入管道集成 ---
        let processedContent: String
        if forceDeepScan || llmService != nil {
            // 核心重构：利用协议能力，避免显式类型转换
            if let vectorStore = pageStore as? any VectorIndexableStore {
                let manager = await MainActor.run { vectorStore.embeddingManager }
                processedContent = await KnowledgeIngestPipeline.shared.process(
                    content: sanitizedRawContent,
                    pageID: pageID,
                    llm: llmService,
                    embeddingManager: manager
                )
            } else {
                // fallback: 如果 Store 不支持向量，则仅保留内容
                processedContent = sanitizedRawContent
            }
        } else {
            processedContent = sanitizedRawContent
        }

        // Create raw source page with provenance
        let rawPage = await pageStore.anyCreatePage(
            title: title,
            pageType: type,
            customIcon: nil,
            content: processedContent,
            tags: ["ingested"],
            sourceURL: sourceURL,
            rawSnippet: rawSnippet ?? String(processedContent.prefix(500)),
            fileSize: fileSize,
            sourceType: sourceType,
            forceDeepScan: forceDeepScan
        )

        // Auto-extract potential concept links from content
        let allPages = await pageStore.pages
        let concepts = extractConcepts(from: processedContent, pages: allPages)
        var updatedContent = rawPage.content

        for concept in concepts {
            updatedContent = updatedContent.replacingOccurrences(
                of: concept,
                with: "[[\(concept)]]"
            )
        }

        var page = rawPage
        page.content = updatedContent
        await pageStore.anyUpdatePage(page, forceDeepScan: forceDeepScan)

        let duration = Date().timeIntervalSince(startTime)
        await pageStore.addLog(
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
        let content = result.markdown

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
    func ingestDocument(
        at url: URL,
        title: String? = nil,
        type: PageType = .source,
        pageStore: any AnyPageStore
    ) async -> KnowledgePage? {
        let format = DocumentFormat.detectFormat(from: url)
        let extractedTitle = title ?? url.deletingPathExtension().lastPathComponent

        guard let processor = DocumentProcessorFactory.processor(for: format) else {
            print("Unsupported or unknown document format: \(url.pathExtension)")
            return nil
        }

        do {
            let text = try await processor.extractText(from: url)
            if text.isEmpty { return nil }
            return await ingestRawContent(title: extractedTitle, content: text, type: type, forceDeepScan: true, pageStore: pageStore)
        } catch {
            print("Failed to extract text from document \(url.path): \(error)")
            return nil
        }
    }

    /// Batch import all supported documents from a folder. (Enhanced: Eco-Indexing)
    func ingestFolder(
        at url: URL,
        type: PageType = .source,
        pageStore: any AnyPageStore
    ) async -> [KnowledgePage] {

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("Failed to enumerate folder: \(url.path)")
            return []
        }

        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if isLowPowerMode {
            print(L10n.Ingest.ecoIndexingLowPower)
        }

        let enumeratorArray = enumerator.compactMap { $0 as? URL }
        let totalCount = enumeratorArray.count
        
        // 接入 TaskCenter (由 TaskCenter 统一触发灵动岛)
        let taskID = await TaskCenter.shared.addTask(
            type: .ingest, 
            name: L10n.AI.Task.tr("type.ingest"), 
            target: url.lastPathComponent
        )

        return await withTaskGroup(of: (KnowledgePage?, String).self) { group in
            for fileURL in enumeratorArray {
                group.addTask { [self, pageStore, type] in
                    // 智适应节流：低功耗模式下每个文件处理后强制休息，释放 CPU
                    if isLowPowerMode {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }

                    let page = await self.ingestDocument(at: fileURL, type: type, pageStore: pageStore)
                    if page != nil {
                        await MainActor.run {
                            LocalAnalyticsService.shared.trackEvent("document_ingested", properties: ["format": fileURL.pathExtension])
                        }
                    }
                    return (page, fileURL.lastPathComponent)
                }
            }

            var results: [KnowledgePage] = []
            var currentIndex = 0
            for await (page, filename) in group {
                currentIndex += 1
                if let p = page { results.append(p) }
                
                // 更新任务中心与灵动岛
                let progress = Double(currentIndex) / Double(totalCount)
                let status = L10n.AI.Status.indexing(currentIndex, totalCount, filename)
                await TaskCenter.shared.updateTask(taskID, status: .running(progress: progress, stage: .general))
                await TaskCenter.shared.updateLatestStatus(status)
            }
            
            // 完成任务
            await TaskCenter.shared.completeTask(id: taskID)
            
            return results
        }
    }
}
