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
            fallback: "Andrej Karpathy's methodology on building AI-native personal wiki systems, emphasizing semantic chunking and RAG pipelines.")
        let workflowURL = resolveFileURL(named: "pkm_workflow.md", in: folder,
            fallback: "Knowledge management workflows: capture, chunk, retrieve, synthesize. Integrate daily tools into a unified knowledge loop.")
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
            fallback: "Luckin Coffee vs Starbucks competitive landscape analysis. Luckin's focus on cashierless grab-and-go outlets vs Starbucks' 'Third Space' business social experience.")
        let surveyURL = resolveFileURL(named: "survey_202606.pdf", in: folder,
            fallback: "200 customer survey forms collected on-site. Target group: 25-35 years old freelancers, self-media creators, and office staff.")
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
        let methodologySnippet = "Andrej Karpathy's methodology on building AI-native personal wiki systems, emphasizing semantic chunking and RAG pipelines, sourced from a local markdown file."
        let workflowSnippet = "Knowledge management workflows: capture, chunk, retrieve, synthesize. Integrate daily tools into a unified knowledge loop."
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
        let luckinSnippet = "Luckin Coffee vs Starbucks competitive landscape analysis. Luckin's focus on cashierless grab-and-go outlets vs Starbucks' 'Third Space' business social experience, retrieved from local market PDF report."
        let surveySnippet = "200 customer survey forms collected on-site. Target group: 25-35 years old freelancers, self-media creators, and office staff who are heavy internet and power outlet users."
        return [
            PageSeed(title: "竞品分析：瑞幸 vs 星巴克", type: .comparison,
                     content: "瑞幸主打极简快取与高性价比，星巴克主打\"第三空间\"的商务社交。我们的独立咖啡店需要避开直接竞争，主打社区融合与[[精品咖啡体验]]。",
                     tags: ["竞品分析", "市场调研"],
                     sourceURL: luckinURL, rawTextSnippet: luckinSnippet, sourceType: "pdf"),
            PageSeed(title: "精品咖啡体验", type: .concept,
                     content: "放弃全自动机器，采用半自动意式机与手冲吧台双轨制。定期举办杯测活动，增强社区黏性，这与我们的[[目标客群分析]]高度吻合。",
                     tags: ["产品设计", "运营"]),
            PageSeed(title: "目标客群分析", type: .source,
                     content: "本月收集了 200 份街头问卷。核心客群锁定为 25-35 岁的自由职业者、自媒体人及周边白领。他们对空间舒适度要求高，且极度依赖[[高品质网络与供电]]。",
                     tags: ["用户调研"],
                     sourceURL: surveyURL, rawTextSnippet: surveySnippet, sourceType: "pdf"),
            PageSeed(title: "高品质网络与供电", type: .concept,
                     content: "部署商用级 Wi-Fi 6 路由器，确保全店无死角覆盖。卡座区必须做到\"一桌一插座\"，这是留住数字游民的核心基建。这部分改造费用已列入[[财务预算模型]]。",
                     tags: ["基础设施", "装修"]),
            PageSeed(title: "财务预算模型", type: .map,
                     content: "- 店面租金与转让费：25万\n- 空间硬装与软装：18万\n- 核心设备（辣妈咖啡机、迈赫迪磨豆机等）：12万\n- 初期流动资金：15万\n首期总预算约 70 万，资金缺口 30 万，需尽快启动[[合伙人招募计划]]。",
                     tags: ["财务", "规划"]),
            PageSeed(title: "合伙人招募计划", type: .entity,
                     content: "理想的合伙人画像：具备成熟的精品咖啡馆店长经验，能独立把控豆子烘焙质量与供应链，与我互补。共同打造极致的[[精品咖啡体验]]。",
                     tags: ["团队", "招聘"]),
            PageSeed(title: "咖啡豆供应链选型", type: .comparison,
                     content: "对比了三家烘焙厂：A厂埃塞豆风味明亮但批次不稳定；B厂云南豆性价比极高且有助农故事；C厂哥伦比亚拼配最均衡。初期决定以 B 厂为主，严格控制[[财务预算模型]]中的物料成本。",
                     tags: ["供应链", "物料"]),
            PageSeed(title: "空间视觉与装修意向", type: .map,
                     content: "采用微水泥侘寂风与温润原木结合。摒弃传统局促的网红打卡墙，大面积留白搭配龟背竹等阔叶绿植。灯光需采用 3000K 暖色温，迎合[[目标客群分析]]中的审美偏好。",
                     tags: ["设计", "装修"]),
            PageSeed(title: "开业营销策划", type: .concept,
                     content: "试营业期间不打折，但买咖啡送定制帆布袋。正式开业首周，邀请本地小红书探店博主进行内容种草。我们将主推具有差异化的[[特调菜单研发]]作为引流爆款。",
                     tags: ["营销", "增长"]),
            PageSeed(title: "特调菜单研发", type: .entity,
                     content: "目前内测评分最高的两款：1. 桂花酒酿拿铁（秋季限定） 2. 澄清番茄气泡美式。这两款特调不仅视觉出片率高，且口味独特，是支持[[开业营销策划]]的核心武器。",
                     tags: ["产品设计", "研发"]),
            PageSeed(title: L10n.InitialNotebook.Coffee.title11, type: .source,
                     content: L10n.InitialNotebook.Coffee.content11,
                     tags: ["市场调研", "竞品分析"],
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
