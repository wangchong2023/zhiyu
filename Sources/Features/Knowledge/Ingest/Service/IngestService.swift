//
//  IngestService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 Ingest 模块的核心业务逻辑服务。
//
import Foundation
import Compression

// MARK: - Ingest Service (Knowledge Ingestion)
actor IngestService {
    @Inject private var docExtractor: any DocumentExtractionServiceProtocol
    let scraper = WebScraperProcessor()

    /// 将原始内容摄入知识库：执行安全脱敏、进行 RAG 分块与向量索引、自动抽取并链接已知页面概念。
    /// - Parameters:
    ///   - title: 知识页面的标题
    ///   - content: 待处理的原始文档内容
    ///   - type: 创建的知识页面类型，默认为来源页面
    ///   - sourceURL: 文档外链或网页地址 (可选)
    ///   - rawSnippet: 原始文本的快照片段 (可选)
    ///   - forceDeepScan: 是否强制拉起 AI 执行深度语义索引
    ///   - llmService: 用于解析的 AI 大模型服务 (可选)
    ///   - pageStore: 底层数据存储仓储
    ///   - fileSize: 原始文件大小 (字节，可选)
    ///   - sourceType: 文件物理类型后缀 (可选)
    /// - Returns: 封装、链接完成并安全持久化后的知识页面对象
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
        await MainActor.run {
            DatabaseManager.shared.incrementActiveTransactions()
        }
        let pageID = UUID()

        // 1. 安全脱敏：拦截恶意指令注入 (@P0: Security)
        let sanitizedRawContent = PromptSanitizer.shared.sanitize(content)

        // --- RAG 摄入管道集成 ---
        let processedContent: String
        if forceDeepScan || llmService != nil {
            // 核心重构：利用协议能力，避免显式类型转换
            if let vectorStore = pageStore as? any VectorIndexableStore {
                let provider = await MainActor.run { vectorStore.embeddingProvider }
                processedContent = await KnowledgeIngestPipeline.shared.process(
                    content: sanitizedRawContent,
                    pageID: pageID,
                    llm: llmService,
                    embeddingProvider: provider
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
        pageStore.addLog(
            action: .create,
            target: title,
            details: "Ingested \(processedContent.count) chars. DeepScan: \(forceDeepScan)",
            duration: duration,
            startTime: startTime,
            endTime: Date(),
            module: "IngestService"
        )

        await MainActor.run {
            DatabaseManager.shared.decrementActiveTransactions()
        }
        return page
    }

    /// 从给定的网络 URL 地址中抓取并摄入网页内容
    /// - Parameters:
    ///   - urlString: 目标网页的 URL 地址字符串
    ///   - forceDeepScan: 是否对网页内容执行强制 AI 深度分析，默认为真
    ///   - llmService: 用于摄入的大语言模型服务 (可选)
    ///   - pageStore: 数据持久化容器仓储
    /// - Returns: 处理完毕后的 `KnowledgePage` 知识页面对象
    /// - Throws: 网页爬取、解析失败或网络异常
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

    /// 从给定的文本内容中智能识别并匹配已有的页面标题，用以自动构建双链关联
    /// - Parameters:
    ///   - content: 待扫描匹配的文本内容
    ///   - pages: 知识库中已存在的所有备选知识页面集合
    /// - Returns: 识别到的现有知识标题字符串列表
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

        guard docExtractor.canExtract(format: format) else {
            print("Unsupported or unknown document format: \(url.pathExtension)")
            return nil
        }

        do {
            let text = try await docExtractor.extractText(from: url)
            if text.isEmpty { return nil }
            return await ingestRawContent(title: extractedTitle, content: text, type: type, forceDeepScan: true, pageStore: pageStore)
        } catch {
            print("Failed to extract text from document \(url.path): \(error)")
            return nil
        }
    }

    /// 批量从指定文件夹目录中导入所有支持的文档实体（带低功耗绿色索引控制）
    /// - Parameters:
    ///   - url: 待扫描的文件夹本地物理路径
    ///   - type: 导入后创建的页面类型，默认来源数据类型
    ///   - pageStore: 数据持久化容器仓储
    /// - Returns: 成功被批量摄入并创建出来的知识页面集合
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
            name: L10n.AI.Task.typeIngest, 
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
