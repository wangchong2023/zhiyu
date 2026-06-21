//
//  InitialNotebookGenerator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：提供项目启动时的初始演示/测试笔记本（Initial Notebook）数据生成器。
//           支持为页面填充物理溯源文件（在 sandbox 中的 Imports 文件夹下真实写入文件），
//           以保证详情页能够正确渲染引用源（Provenance）追溯视图，且与用户手工导入文件保持绝对一致。
//

import Foundation
@preconcurrency import GRDB

/// 演示数据生成器
///
/// 职责：用于快速填充知识库，展示图谱、检索、AI 分析及引用物理文件溯源能力。
struct InitialNotebookGenerator {

    // MARK: - 模拟调用日志常量

    /// 演示模型名称，模拟未配置外部大模型时的内置/本地空跑服务
    private static let demoModelName = "ZhiYu-Local-Mock"
    
    /// PKM 模拟调用条数
    private static let pkmLogCount = 50
    /// 调研集模拟调用条数
    private static let researchLogCount = 30
    
    /// PKM 模拟随机小时跨度 (30天 = 720小时)
    private static let pkmMaxHoursAgo = 720
    /// 调研集模拟随机小时跨度 (12天 = 288小时)
    private static let researchMaxHoursAgo = 288
    
    /// 提示 Token 最小值与最大值
    private static let minPromptTokens = 100
    private static let maxPromptTokens = 1000
    /// 补全 Token 最小值与最大值
    private static let minCompletionTokens = 50
    private static let maxCompletionTokens = 2000
    /// 模拟延迟最小值与最大值
    private static let minLatencyMS = 300
    private static let maxLatencyMS = 4500

    /// 统一的演示数据种子结构，支持溯源元数据
    struct PageSeed {
        let title: String
        let type: PageType
        let content: String
        let tags: [String]
        let sourceURL: String?
        let rawTextSnippet: String?
        let sourceType: String?

        init(
            title: String,
            type: PageType,
            content: String,
            tags: [String],
            sourceURL: String? = nil,
            rawTextSnippet: String? = nil,
            sourceType: String? = nil
        ) {
            self.title = title
            self.type = type
            self.content = content
            self.tags = tags
            self.sourceURL = sourceURL
            self.rawTextSnippet = rawTextSnippet
            self.sourceType = sourceType
        }
    }

    // MARK: - 公开生成接口

    /// 执行默认 PKM（个人知识管理）演示数据生成
    /// - Parameter store: 目标存储对象
    /// - Returns: 生成的页面数量
    static func generate(in store: any AnyPageStore) async throws -> Int {
        Logger.shared.info("InitialNotebook_Starting")
        let folder = await resolveImportsFolder()
        // 动态根据当前本地化语言，决定去 Bundle 寻找的物理文件名（中文版使用中文物理文件名，英文版使用英文物理文件名）
        let methodologyURL = resolveFileURL(bundleName: L10n.InitialNotebook.FileNames.methodology, localName: L10n.InitialNotebook.FileNames.methodology, in: folder,
            fallback: L10n.InitialNotebook.Fallback.methodology)
        let workflowURL = resolveFileURL(bundleName: L10n.InitialNotebook.FileNames.workflow, localName: L10n.InitialNotebook.FileNames.workflow, in: folder,
            fallback: L10n.InitialNotebook.Fallback.workflow)
        let ocrFolderURL = resolveFileURL(bundleName: "ocr_folder_scan.png", localName: L10n.InitialNotebook.FileNames.ocrFolderScan, in: folder,
            fallback: "")
        let voiceForgetURL = resolveFileURL(bundleName: "voice_note_forgetting_curve.mp3", localName: L10n.InitialNotebook.FileNames.voiceNoteForget, in: folder,
            fallback: "")
        
        let seeds = buildPKMPageSeeds(
            methodologyURL: methodologyURL,
            workflowURL: workflowURL,
            ocrFolderURL: ocrFolderURL,
            voiceForgetURL: voiceForgetURL
        )
        try await persistPages(seeds, in: store) { db in
            try injectPKMMockLogs(db: db)
        }
        Logger.shared.info("InitialNotebook_Finished")
        return seeds.count
    }

    /// 执行项目调研（Research）演示数据生成
    /// - Parameter store: 目标存储对象
    /// - Returns: 生成的页面数量
    static func generateResearchNotebook(in store: any AnyPageStore) async throws -> Int {
        Logger.shared.info("ResearchInitialNotebook_Starting")
        let folder = await resolveImportsFolder()
        // 动态根据当前本地化语言，决定去 Bundle 寻找的物理文件名（中文版使用中文物理文件名，英文版使用英文物理文件名）
        let luckinURL = resolveFileURL(bundleName: L10n.InitialNotebook.FileNames.luckin, localName: L10n.InitialNotebook.FileNames.luckin, in: folder,
            fallback: L10n.InitialNotebook.Fallback.luckin)
        let surveyURL = resolveFileURL(bundleName: L10n.InitialNotebook.FileNames.survey, localName: L10n.InitialNotebook.FileNames.survey, in: folder,
            fallback: L10n.InitialNotebook.Fallback.survey)
        let ocrStoreURL = resolveFileURL(bundleName: "ocr_store_manual.png", localName: L10n.InitialNotebook.FileNames.ocrStoreManual, in: folder,
            fallback: "")
        let voiceProcureURL = resolveFileURL(bundleName: "voice_note_procurement.mp3", localName: L10n.InitialNotebook.FileNames.voiceNoteProcure, in: folder,
            fallback: "")
        
        let seeds = buildResearchPageSeeds(
            luckinURL: luckinURL,
            surveyURL: surveyURL,
            ocrStoreURL: ocrStoreURL,
            voiceProcureURL: voiceProcureURL
        )
        try await persistPages(seeds, in: store) { db in
            try injectResearchMockLogs(db: db)
        }
        Logger.shared.info("ResearchInitialNotebook_Finished")
        return seeds.count
    }

    /// 执行图谱压力测试数据生成（兼容测试套件调用）
    /// - Parameters:
    ///   - store: 目标存储对象
    ///   - targetCount: 注入的节点数量
    /// - Returns: 实际生成的页面数
    static func generateStressTest(in store: any AnyPageStore, count targetCount: Int = 1000) async throws -> Int {
        try await generateStressTestNotebooks(in: store, count: targetCount)
    }

    /// 执行图谱压力测试数据生成
    /// - Parameters:
    ///   - store: 目标存储对象
    ///   - targetCount: 生成的节点数量，默认为 1000
    /// - Returns: 生成的页面数量
    static func generateStressTestNotebooks(in store: any AnyPageStore, count targetCount: Int = 1000) async throws -> Int {
        Logger.shared.info("StressTestData_Starting")

        try await store.performBatchWrite { db in
            // 按照依赖关系的反向顺序进行物理清理
            try KnowledgePage.deleteAll(db)

            // 预生成标题列表，用于建立随机链接
            let titles = (1...targetCount).map { "StressNode_\($0)" }
            let types: [PageType] = [.concept, .entity, .source, .comparison]

            var localCount = 0
            for i in 0..<targetCount {
                let title = titles[i]
                let type = types[i % types.count]

                // 随机选择 1-3 个其他节点建立链接
                var content = ""
                let linkCount = Int.random(in: 1...3)
                var linkedIndices = Set<Int>()
                while linkedIndices.count < linkCount {
                    let randIdx = Int.random(in: 0..<targetCount)
                    if randIdx != i { linkedIndices.insert(randIdx) }
                }
                for _ in linkedIndices { content += "" }

                let page = KnowledgePage(
                    title: title, pageType: type, content: content,
                    tags: ["StressTest", "Performance"]
                )
                try page.save(db)
                localCount += 1
                if localCount % 100 == 0 { Logger.shared.debug("") }
            }
        }

        Logger.shared.debug("")
        return targetCount
    }

    // MARK: - 私有辅助方法：文件路径解析

    /// 解析当前金库沙盒目录下的 Imports 文件夹路径
    /// 必须在 MainActor 上执行，以安全访问 DatabaseManager
    private static func resolveImportsFolder() async -> URL? {
        await MainActor.run {
            if let dbURL = DatabaseManager.shared.dbURL {
                let folder = dbURL.deletingLastPathComponent().appendingPathComponent("Imports")
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                return folder
            }
            return nil
        }
    }

    /// 将演示 file 路径解析为字符串 URL，若 folder 为 nil 则返回虚拟演示地址
    private static func resolveFileURL(bundleName: String, localName: String, in folder: URL?, fallback: String) -> String {
        guard let folder else { return "file:///demo/\(localName)" }
        return copyOrWriteDemoFile(bundleName: bundleName, localName: localName, to: folder, fallbackText: fallback)
    }

    // MARK: - 私有辅助方法：数据集构建

    /// 构建 PKM 知识管理演示页面的种子数据
    /// - Parameters:
    ///   - methodologyURL: pkm_methodology.md 的本地物理文件路径
    ///   - workflowURL: pkm_workflow.md 的本地物理文件路径
    ///   - ocrFolderURL: ocr_folder_scan.png 的本地物理文件路径
    ///   - voiceForgetURL: voice_note_forgetting_curve.mp3 的本地物理文件路径
    private static func buildPKMPageSeeds(
        methodologyURL: String,
        workflowURL: String,
        ocrFolderURL: String,
        voiceForgetURL: String
    ) -> [PageSeed] {
        let methodologySnippet = L10n.InitialNotebook.Snippet.methodology
        let workflowSnippet = L10n.InitialNotebook.Snippet.workflow
        return [
            PageSeed(title: L10n.InitialNotebook.PKM.title1, type: .concept, content: L10n.InitialNotebook.PKM.content1,
                     tags: [L10n.InitialNotebook.Tags.knowledgeMgmt, L10n.InitialNotebook.Tags.methodology],
                     sourceURL: methodologyURL, rawTextSnippet: methodologySnippet, sourceType: "markdown"),
            PageSeed(title: L10n.InitialNotebook.PKM.title2, type: .entity, content: L10n.InitialNotebook.PKM.content2,
                     tags: [L10n.InitialNotebook.Tags.noteStyles, L10n.InitialNotebook.Tags.efficiency],
                     sourceURL: ocrFolderURL, rawTextSnippet: L10n.InitialNotebook.Snippet.pkmOcrFolder, sourceType: "ocr"),
            PageSeed(title: L10n.InitialNotebook.PKM.title3, type: .concept, content: L10n.InitialNotebook.PKM.content3,
                     tags: [L10n.InitialNotebook.Tags.techPrinciple, L10n.InitialNotebook.Tags.association],
                     sourceURL: "https://github.com/karpathy/llm.c", rawTextSnippet: L10n.InitialNotebook.Snippet.pkmRagLink, sourceType: "link"),
            PageSeed(title: L10n.InitialNotebook.PKM.title4, type: .source, content: L10n.InitialNotebook.PKM.content4,
                     tags: [L10n.InitialNotebook.Tags.cognitivePsych],
                     sourceURL: voiceForgetURL, rawTextSnippet: L10n.InitialNotebook.Snippet.pkmVoiceForget, sourceType: "voice"),
            PageSeed(title: L10n.InitialNotebook.PKM.title5, type: .comparison, content: L10n.InitialNotebook.PKM.content5,
                     tags: [L10n.InitialNotebook.Tags.retrievalTech],
                     sourceURL: workflowURL, rawTextSnippet: workflowSnippet, sourceType: "pdf")
        ]
    }

    /// 构建项目调研（咖啡店研究）演示页面的种子数据
    /// - Parameters:
    ///   - luckinURL: 瑞幸 vs 星巴克分析报告 PDF 的本地物理文件路径
    ///   - surveyURL: 用户调研问卷 PDF 的本地物理文件路径
    ///   - ocrStoreURL: ocr_store_manual.png 的本地物理文件路径
    ///   - voiceProcureURL: voice_note_procurement.mp3 的本地物理文件路径
    private static func buildResearchPageSeeds(
        luckinURL: String,
        surveyURL: String,
        ocrStoreURL: String,
        voiceProcureURL: String
    ) -> [PageSeed] {
        let luckinSnippet = L10n.InitialNotebook.Snippet.luckin
        let surveySnippet = L10n.InitialNotebook.Snippet.survey
        return [
            PageSeed(title: L10n.InitialNotebook.Coffee.title1, type: .comparison,
                     content: L10n.InitialNotebook.Coffee.content1,
                     tags: [L10n.InitialNotebook.Tags.competitorAnalysis, L10n.InitialNotebook.Tags.marketResearch],
                     sourceURL: luckinURL, rawTextSnippet: luckinSnippet, sourceType: "pdf"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title2, type: .entity,
                     content: L10n.InitialNotebook.Coffee.content2,
                     tags: [L10n.InitialNotebook.Tags.productDesign, L10n.InitialNotebook.Tags.operation],
                     sourceURL: ocrStoreURL, rawTextSnippet: L10n.InitialNotebook.Snippet.coffeeOcrManual, sourceType: "ocr"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title3, type: .concept,
                     content: L10n.InitialNotebook.Coffee.content3,
                     tags: [L10n.InitialNotebook.Tags.userResearch],
                     sourceURL: "https://finance.sina.com.cn/coffee-industry", rawTextSnippet: L10n.InitialNotebook.Snippet.coffeeRagLink, sourceType: "link"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title4, type: .source,
                     content: L10n.InitialNotebook.Coffee.content4,
                     tags: [L10n.InitialNotebook.Tags.infrastructure, L10n.InitialNotebook.Tags.decoration],
                     sourceURL: voiceProcureURL, rawTextSnippet: L10n.InitialNotebook.Snippet.coffeeVoiceProcure, sourceType: "voice"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title5, type: .concept,
                     content: L10n.InitialNotebook.Coffee.content5,
                     tags: [L10n.InitialNotebook.Tags.finance, L10n.InitialNotebook.Tags.planning],
                     sourceURL: surveyURL, rawTextSnippet: surveySnippet, sourceType: "markdown")
        ]
    }

    // MARK: - 私有辅助方法：持久化
    
    /// 通用页面批量写入模板：清空旧数据 → 写入页面 → 执行附加日志注入及导入历史写入
    private static func persistPages(
        _ seeds: [PageSeed],
        in store: any AnyPageStore,
        additionalWrites: @escaping @Sendable (Database) throws -> Void
    ) async throws {
        let activeVaultID = await MainActor.run {
            ServiceContainer.shared.resolve((any VaultServiceProtocol).self).selectedVaultID?.uuidString
        }
        
        try await store.performBatchWrite { db in
            try KnowledgePage.deleteAll(db)
            try TokenUsage.deleteAll(db)
            try LLMCallLog.deleteAll(db)
            try ImportRecord.deleteAll(db)
            
            for seed in seeds {
                let pageID = UUID()
                let page = KnowledgePage(
                    id: pageID,
                    title: seed.title, pageType: seed.type, content: seed.content,
                    tags: seed.tags, sourceURL: seed.sourceURL,
                    rawTextSnippet: seed.rawTextSnippet, sourceType: seed.sourceType
                )
                try page.save(db)
                
                // 建立对应的已完成导入记录，对齐导入历史和状态维护。
                // 根据 PageSeed 中声明的 sourceType，将其映射到标准的 6 种 Ingest 导入分类中。
                let category: String
                if let st = seed.sourceType?.lowercased() {
                    if ["ocr", "clipboard", "voice", "link", "manual"].contains(st) {
                        category = st
                    } else if st == "pdf" || st == "markdown" || st == "md" || st == "file" {
                        category = "file"
                    } else {
                        category = "manual"
                    }
                } else if seed.sourceURL != nil {
                    category = "link"
                } else {
                    category = "manual"
                }
                
                let filePath: String?
                if let urlStr = seed.sourceURL, let url = URL(string: urlStr) {
                    filePath = url.path
                } else {
                    filePath = nil
                }
                
                var record = ImportRecord(
                    id: UUID().uuidString,
                    category: category,
                    title: seed.title,
                    status: "done",
                    rawText: seed.rawTextSnippet,
                    sourceURL: seed.sourceURL,
                    filePath: filePath,
                    fileSize: seed.sourceURL != nil ? Int64(seed.content.utf8.count) : nil,
                    pageID: pageID.uuidString,
                    vaultID: activeVaultID,
                    taskID: nil,
                    tags: seed.tags.joined(separator: ", "),
                    createdAt: Date(),
                    completedAt: Date()
                )
                try record.save(db)
            }
            try additionalWrites(db)
        }
    }

    /// 注入 PKM 演示集的模拟 AI 调用日志（50 条，近 30天随机分布）
    private static func injectPKMMockLogs(db: Database) throws {
        let calendar = Calendar.current
        for _ in 0..<pkmLogCount {
            let model = demoModelName
            let prompt = Int.random(in: minPromptTokens...maxPromptTokens)
            let completion = Int.random(in: minCompletionTokens...maxCompletionTokens)
            let latency = Int.random(in: minLatencyMS...maxLatencyMS)
            guard let date = calendar.date(byAdding: .hour, value: -Int.random(in: 1...pkmMaxHoursAgo), to: Date()) else { continue }
            var log = LLMCallLog(model: model, promptTokens: prompt, completionTokens: completion,
                                 latencyMS: latency, status: "success", createdAt: date)
            try log.insert(db)
            var usage = TokenUsage(model: model, promptTokens: prompt, completionTokens: completion, createdAt: date)
            try usage.insert(db)
        }
    }

    /// 注入调研演示集的模拟 AI 调用日志（30 条，近 12 天随机分布）
    private static func injectResearchMockLogs(db: Database) throws {
        let calendar = Calendar.current
        for _ in 0..<researchLogCount {
            let model = demoModelName
            let prompt = Int.random(in: minPromptTokens...maxPromptTokens)
            let completion = Int.random(in: minCompletionTokens...maxCompletionTokens)
            let latency = Int.random(in: minLatencyMS...maxLatencyMS)
            guard let date = calendar.date(byAdding: .hour, value: -Int.random(in: 1...researchMaxHoursAgo), to: Date()) else { continue }
            var log = LLMCallLog(model: model, promptTokens: prompt, completionTokens: completion,
                                 latencyMS: latency, status: "success", createdAt: date)
            try log.insert(db)
            var usage = TokenUsage(model: model, promptTokens: prompt, completionTokens: completion, createdAt: date)
            try usage.insert(db)
        }
    }

    // MARK: - 私有辅助方法：文件拷贝

    /// 从应用 Bundle 中物理拷贝演示 file 至 Imports 沙盒，如果不存在则写入 fallback 文本
    /// - Parameters:
    ///   - bundleName: Bundle 中英文文件名
    ///   - localName: 本地化后的物理文件名
    ///   - folder: 目标沙盒 Imports 路径
    ///   - fallbackText: 降级写入的文本
    private static func copyOrWriteDemoFile(bundleName: String, localName: String, to folder: URL, fallbackText: String) -> String {
        let fileURL = folder.appendingPathComponent(localName)

        // 尝试先物理清理旧文件，防止 copyItem 报 FileExists 错误
        try? FileManager.default.removeItem(at: fileURL)

        let expectedPartsCount = 2
        let extensionSeparator: Character = "."
        let fileParts = bundleName.split(separator: extensionSeparator)
        if fileParts.count == expectedPartsCount,
           let resourceName = fileParts.first.map(String.init),
           let resourceExt = fileParts.last.map(String.init),
           let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) {
            do {
                try FileManager.default.copyItem(at: bundleURL, to: fileURL)
                Logger.shared.info("InitialNotebook_CopiedResource: \(localName)")
                return fileURL.absoluteString
            } catch {
                Logger.shared.error("InitialNotebook_CopyFailed: \(localName), error: \(error)")
            }
        }

        // Fallback: 写入硬编码文本
        do {
            try fallbackText.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.shared.info("InitialNotebook_WroteFallback: \(localName)")
        } catch {
            Logger.shared.error("InitialNotebook_WriteFallbackFailed: \(localName), error: \(error)")
        }
        return fileURL.absoluteString
    }
}
