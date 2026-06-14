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
        let methodologyURL = resolveFileURL(named: "pkm_methodology.md", in: folder,
            fallback: L10n.InitialNotebook.Fallback.methodology)
        let workflowURL = resolveFileURL(named: "pkm_workflow.md", in: folder,
            fallback: L10n.InitialNotebook.Fallback.workflow)
        let seeds = buildPKMPageSeeds(methodologyURL: methodologyURL, workflowURL: workflowURL)
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
        let luckinURL = resolveFileURL(named: "luckin_vs_starbucks_report.pdf", in: folder,
            fallback: L10n.InitialNotebook.Fallback.luckin)
        let surveyURL = resolveFileURL(named: "survey_202606.pdf", in: folder,
            fallback: L10n.InitialNotebook.Fallback.survey)
        let seeds = buildResearchPageSeeds(luckinURL: luckinURL, surveyURL: surveyURL)
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
            let types: [PageType] = [.concept, .entity, .source, .comparison, .map]

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
    private static func resolveFileURL(named name: String, in folder: URL?, fallback: String) -> String {
        guard let folder else { return "file:///demo/\(name)" }
        return copyOrWriteDemoFile(named: name, to: folder, fallbackText: fallback)
    }

    // MARK: - 私有辅助方法：数据集构建

    /// 构建 PKM 知识管理演示页面的种子数据
    /// - Parameters:
    ///   - methodologyURL: pkm_methodology.md 的本地物理文件路径
    ///   - workflowURL: pkm_workflow.md 的本地物理文件路径
    private static func buildPKMPageSeeds(methodologyURL: String, workflowURL: String) -> [PageSeed] {
        let methodologySnippet = L10n.InitialNotebook.Snippet.methodology
        let workflowSnippet = L10n.InitialNotebook.Snippet.workflow
        return [
            PageSeed(title: L10n.InitialNotebook.PKM.title1, type: .concept, content: L10n.InitialNotebook.PKM.content1,
                     tags: [L10n.InitialNotebook.Tags.knowledgeMgmt, L10n.InitialNotebook.Tags.methodology],
                     sourceURL: methodologyURL, rawTextSnippet: methodologySnippet, sourceType: "markdown"),
            PageSeed(title: L10n.InitialNotebook.PKM.title2, type: .concept, content: L10n.InitialNotebook.PKM.content2,
                     tags: [L10n.InitialNotebook.Tags.noteStyles, L10n.InitialNotebook.Tags.efficiency]),
            PageSeed(title: L10n.InitialNotebook.PKM.title3, type: .concept, content: L10n.InitialNotebook.PKM.content3,
                     tags: [L10n.InitialNotebook.Tags.techPrinciple, L10n.InitialNotebook.Tags.association]),
            PageSeed(title: L10n.InitialNotebook.PKM.title4, type: .concept, content: L10n.InitialNotebook.PKM.content4,
                     tags: [L10n.InitialNotebook.Tags.cognitivePsych]),
            PageSeed(title: L10n.InitialNotebook.PKM.title5, type: .concept, content: L10n.InitialNotebook.PKM.content5,
                     tags: [L10n.InitialNotebook.Tags.retrievalTech]),
            PageSeed(title: L10n.InitialNotebook.PKM.title6, type: .concept, content: L10n.InitialNotebook.PKM.content6,
                     tags: [L10n.InitialNotebook.Tags.brainSci, "心理学"]),
            PageSeed(title: L10n.InitialNotebook.PKM.title7, type: .concept, content: L10n.InitialNotebook.PKM.content7,
                     tags: [L10n.InitialNotebook.Tags.learningMethod]),
            PageSeed(title: L10n.InitialNotebook.PKM.title8, type: .concept, content: L10n.InitialNotebook.PKM.content8,
                     tags: [L10n.InitialNotebook.Tags.fileMgmt]),
            PageSeed(title: L10n.InitialNotebook.PKM.title9, type: .concept, content: L10n.InitialNotebook.PKM.content9,
                     tags: [L10n.InitialNotebook.Tags.knowledgeMgmt, L10n.InitialNotebook.Tags.productivity]),
            PageSeed(title: L10n.InitialNotebook.PKM.title10, type: .source, content: L10n.InitialNotebook.PKM.content10,
                     tags: [L10n.InitialNotebook.Tags.workflow],
                     sourceURL: workflowURL, rawTextSnippet: workflowSnippet, sourceType: "markdown"),
            PageSeed(title: L10n.InitialNotebook.PKM.title11, type: .map, content: L10n.InitialNotebook.PKM.content11,
                     tags: [L10n.InitialNotebook.Tags.architectureOrg]),
            PageSeed(title: L10n.InitialNotebook.PKM.title12, type: .concept, content: L10n.InitialNotebook.PKM.content12,
                     tags: [L10n.InitialNotebook.Tags.readingMethod, L10n.InitialNotebook.Tags.summary]),
            PageSeed(title: L10n.InitialNotebook.PKM.title13, type: .concept, content: L10n.InitialNotebook.PKM.content13,
                     tags: [L10n.InitialNotebook.Tags.creation, L10n.InitialNotebook.Tags.output]),
            PageSeed(title: L10n.InitialNotebook.PKM.title14, type: .entity, content: L10n.InitialNotebook.PKM.content14,
                     tags: [L10n.InitialNotebook.Tags.biography]),
            PageSeed(title: L10n.InitialNotebook.PKM.title15, type: .concept, content: L10n.InitialNotebook.PKM.content15,
                     tags: ["学习法"]),
            PageSeed(title: L10n.InitialNotebook.PKM.title16, type: .concept, content: L10n.InitialNotebook.PKM.content16,
                     tags: [L10n.InitialNotebook.Tags.metaphor]),
            PageSeed(title: L10n.InitialNotebook.PKM.title17, type: .concept, content: L10n.InitialNotebook.PKM.content17,
                     tags: [L10n.InitialNotebook.Tags.innovation, L10n.InitialNotebook.Tags.summary]),
            PageSeed(title: L10n.InitialNotebook.PKM.title18, type: .source, content: L10n.InitialNotebook.PKM.content18,
                     tags: [L10n.InitialNotebook.Tags.workflow],
                     sourceURL: methodologyURL, rawTextSnippet: methodologySnippet, sourceType: "markdown")
        ]
    }

    /// 构建项目调研（咖啡店研究）演示页面的种子数据
    /// - Parameters:
    ///   - luckinURL: 瑞幸 vs 星巴克分析报告 PDF 的本地物理文件路径
    ///   - surveyURL: 用户调研问卷 PDF 的本地物理文件路径
    private static func buildResearchPageSeeds(luckinURL: String, surveyURL: String) -> [PageSeed] {
        let luckinSnippet = L10n.InitialNotebook.Snippet.luckin
        let surveySnippet = L10n.InitialNotebook.Snippet.survey
        return [
            PageSeed(title: L10n.InitialNotebook.Coffee.title1, type: .comparison,
                     content: L10n.InitialNotebook.Coffee.content1,
                     tags: [L10n.InitialNotebook.Tags.competitorAnalysis, L10n.InitialNotebook.Tags.marketResearch],
                     sourceURL: luckinURL, rawTextSnippet: luckinSnippet, sourceType: "pdf"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title2, type: .concept,
                     content: L10n.InitialNotebook.Coffee.content2,
                     tags: [L10n.InitialNotebook.Tags.productDesign, L10n.InitialNotebook.Tags.operation]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title3, type: .source,
                     content: L10n.InitialNotebook.Coffee.content3,
                     tags: [L10n.InitialNotebook.Tags.userResearch],
                     sourceURL: surveyURL, rawTextSnippet: surveySnippet, sourceType: "pdf"),
            PageSeed(title: L10n.InitialNotebook.Coffee.title4, type: .concept,
                     content: L10n.InitialNotebook.Coffee.content4,
                     tags: [L10n.InitialNotebook.Tags.infrastructure, L10n.InitialNotebook.Tags.decoration]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title5, type: .map,
                     content: L10n.InitialNotebook.Coffee.content5,
                     tags: [L10n.InitialNotebook.Tags.finance, L10n.InitialNotebook.Tags.planning]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title6, type: .entity,
                     content: L10n.InitialNotebook.Coffee.content6,
                     tags: [L10n.InitialNotebook.Tags.team, L10n.InitialNotebook.Tags.recruitment]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title7, type: .comparison,
                     content: L10n.InitialNotebook.Coffee.content7,
                     tags: [L10n.InitialNotebook.Tags.supplyChain, L10n.InitialNotebook.Tags.materials]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title8, type: .map,
                     content: L10n.InitialNotebook.Coffee.content8,
                     tags: [L10n.InitialNotebook.Tags.design, L10n.InitialNotebook.Tags.decoration]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title9, type: .concept,
                     content: L10n.InitialNotebook.Coffee.content9,
                     tags: [L10n.InitialNotebook.Tags.marketing, L10n.InitialNotebook.Tags.growth]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title10, type: .entity,
                     content: L10n.InitialNotebook.Coffee.content10,
                     tags: [L10n.InitialNotebook.Tags.productDesign, L10n.InitialNotebook.Tags.rd]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title11, type: .source,
                     content: L10n.InitialNotebook.Coffee.content11,
                     tags: [L10n.InitialNotebook.Tags.marketResearch, L10n.InitialNotebook.Tags.competitorAnalysis],
                     sourceURL: luckinURL, rawTextSnippet: luckinSnippet, sourceType: "pdf")
        ]
    }

    // MARK: - 私有辅助方法：持久化

    /// 通用页面批量写入模板：清空旧数据 → 写入页面 → 执行附加日志注入
    /// - Parameters:
    ///   - seeds: 需要写入的页面种子数据
    ///   - store: 目标存储仓储
    ///   - additionalWrites: 额外写入操作（如注入模拟 AI 日志）
    private static func persistPages(
        _ seeds: [PageSeed],
        in store: any AnyPageStore,
        additionalWrites: @escaping @Sendable (Database) throws -> Void
    ) async throws {
        try await store.performBatchWrite { db in
            try KnowledgePage.deleteAll(db)
            try TokenUsage.deleteAll(db)
            try LLMCallLog.deleteAll(db)
            for seed in seeds {
                let page = KnowledgePage(
                    title: seed.title, pageType: seed.type, content: seed.content,
                    tags: seed.tags, sourceURL: seed.sourceURL,
                    rawTextSnippet: seed.rawTextSnippet, sourceType: seed.sourceType
                )
                try page.save(db)
            }
            try additionalWrites(db)
        }
    }

    /// 注入 PKM 演示集的模拟 AI 调用日志（50 条，近 30天随机分布）
    private static func injectPKMMockLogs(db: Database) throws {
        let models = ["GPT-4o", "Claude-3.5-Sonnet", "DeepSeek-V3"]
        let calendar = Calendar.current
        for _ in 0..<50 {
            let model = models.randomElement() ?? "GPT-4o"
            let prompt = Int.random(in: 200...1000)
            let completion = Int.random(in: 100...2000)
            let latency = Int.random(in: 400...4500)
            guard let date = calendar.date(byAdding: .hour, value: -Int.random(in: 1...720), to: Date()) else { continue }
            var log = LLMCallLog(model: model, promptTokens: prompt, completionTokens: completion,
                                 latencyMS: latency, status: "success", createdAt: date)
            try log.insert(db)
            var usage = TokenUsage(model: model, promptTokens: prompt, completionTokens: completion, createdAt: date)
            try usage.insert(db)
        }
    }

    /// 注入调研演示集的模拟 AI 调用日志（30 条，近 12 天随机分布）
    private static func injectResearchMockLogs(db: Database) throws {
        let models = ["GPT-4o", "Claude-3.5-Sonnet"]
        let calendar = Calendar.current
        for _ in 0..<30 {
            let model = models.randomElement() ?? "GPT-4o"
            let prompt = Int.random(in: 100...800)
            let completion = Int.random(in: 50...1000)
            let latency = Int.random(in: 300...3500)
            guard let date = calendar.date(byAdding: .hour, value: -Int.random(in: 1...300), to: Date()) else { continue }
            var log = LLMCallLog(model: model, promptTokens: prompt, completionTokens: completion,
                                 latencyMS: latency, status: "success", createdAt: date)
            try log.insert(db)
            var usage = TokenUsage(model: model, promptTokens: prompt, completionTokens: completion, createdAt: date)
            try usage.insert(db)
        }
    }

    // MARK: - 私有辅助方法：文件拷贝

    /// 从应用 Bundle 中物理拷贝演示文件至 Imports 沙盒，如果不存在则写入 fallback 文本
    /// - Parameters:
    ///   - fileName: 文件名（含后缀）
    ///   - folder: 目标沙盒 Imports 路径
    ///   - fallbackText: 降级写入的文本
    private static func copyOrWriteDemoFile(named fileName: String, to folder: URL, fallbackText: String) -> String {
        let fileURL = folder.appendingPathComponent(fileName)

        // 尝试先物理清理旧文件，防止 copyItem 报 FileExists 错误
        try? FileManager.default.removeItem(at: fileURL)

        let fileParts = fileName.split(separator: ".")
        if fileParts.count == 2,
           let resourceName = fileParts.first.map(String.init),
           let resourceExt = fileParts.last.map(String.init),
           let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: resourceExt) {
            do {
                try FileManager.default.copyItem(at: bundleURL, to: fileURL)
                Logger.shared.info("InitialNotebook_CopiedResource: \(fileName)")
                return fileURL.absoluteString
            } catch {
                Logger.shared.error("InitialNotebook_CopyFailed: \(fileName), error: \(error)")
            }
        }

        // Fallback: 写入硬编码文本
        do {
            try fallbackText.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.shared.info("InitialNotebook_WroteFallback: \(fileName)")
        } catch {
            Logger.shared.error("InitialNotebook_WriteFallbackFailed: \(fileName), error: \(error)")
        }
        return fileURL.absoluteString
    }
}
