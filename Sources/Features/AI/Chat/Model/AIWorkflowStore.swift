//
//  AIWorkflowStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Observation
import Combine

/// AI 工作流存储，管理 AI 扫描状态、洞察及建议。
@MainActor
@Observable
public final class AIWorkflowStore: AIWorkflowCapabilities {
    // ── 子 Store 聚合 ──
    public var insightStore: AIInsightStore = AIInsightStore()

    // ── 扫描与分析状态 ──
    public var isScanningAI = false
    public var refactorSuggestions: [RefactorSuggestionDTO] = []
    public var potentialLinks: [PotentialLinkSuggestion] = []

    // ── 页面级 AI 状态 ──
    public var activePageAIResult: String?
    public var isProcessingPageAI = false
    public var activeQuiz: QuizModel?

    // ── 健康度状态 ──
    public var lastLintScore: Int = 0
    public var lastLintDate: Date?

    // ── 健康度代理 (由 LintService 实时计算) ──
    public var healthMetrics: (score: Int, level: LintService.HealthLevel) {
        lintService.calculateHealthMetrics(issues: lintIssues)
    }
    public var lintScore: Int { healthMetrics.score }
    public var healthLevel: LintService.HealthLevel { healthMetrics.level }
    
    /// LLM 服务是否已启用
    public var isLLMEnabled: Bool { llmService.isEnabled }

    // ── 健康度问题存储 (Lint Issues) ──
    @ObservationIgnored private var _lintIssues: [LintIssue] = {
        if let data = UserDefaults.standard.data(forKey: AppConstants.Keys.Storage.lastLintIssues),
           let decoded = try? JSONDecoder().decode([LintIssue].self, from: data) {
            return decoded
        }
        return []
    }()

    public var lintIssues: [LintIssue] {
        get { access(keyPath: \.lintIssues); return _lintIssues }
        set {
            withMutation(keyPath: \.lintIssues) {
                _lintIssues = newValue
                if let data = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(data, forKey: AppConstants.Keys.Storage.lastLintIssues)
                }
            }
        }
    }

    @ObservationIgnored @Inject private var insightService: KnowledgeInsightService
    @ObservationIgnored @Inject private var llmService: any LLMServiceProtocol
    /// [L1.5] 知识库领域仓储 — 遵循 DIP，L2 不再直接依赖 L1 SQLiteStore
    @ObservationIgnored @Inject private var knowledgeRepository: any KnowledgeRepository
    /// [L0] 向量检索能力 — 通过 L0 协议注入，避免直接耦合 L1 EmbeddingManager
    @ObservationIgnored @Inject private var vectorStore: any VectorIndexableStore
    @ObservationIgnored @Inject private var lintService: LintService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var linkService: LinkService

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    public init() {
        AppEventBus.shared.subscribe()
            .sink { [weak self] in if case .clearAllDataRequested = $0 { self?.clearAll() } }
            .store(in: &cancellables)
    }

    // ── 扫描与健康检查逻辑 ──

    /// 运行Lint
    public func runLint() async {
        let taskID = TaskCenter.shared.addTask(type: .healthCheck, name: L10n.Common.Sidebar.healthCheck, target: "System")
        let pages = (try? await knowledgeRepository.fetchAll()) ?? []
        let issues = await lintService.runLint(pages: pages, linkService: linkService)
        lintIssues = issues
        lastLintDate = Date()
        TaskCenter.shared.updateTask(taskID, status: .completed)
    }

    /// 运行AI扫描
    public func runAIScan() async {
        guard llmService.isEnabled else {
            logger.addLog(action: .aiscanSkipped, target: "System", details: "LLM service disabled")
            return
        }

        isScanningAI = true
        let taskID = TaskCenter.shared.addTask(type: .ai, name: "Scan_Task", target: "System")

        do {
            let allPages = (try? await knowledgeRepository.fetchAll()) ?? []
            let samplePages = Array(allPages.prefix(10))
            let suggestions = try await llmService.analyzeForRefactoring(pages: samplePages)

            let activePages = allPages.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(5)
            let existingTitles = allPages.map { $0.title }

            var tempLinks: [PotentialLinkSuggestion] = []
            var seenLinks = Set<String>()
            for page in activePages {
                let found = try await llmService.discoverPotentialLinks(content: page.content, existingTitles: existingTitles)
                for title in Set(found) {
                    let linkKey = "\(page.id.uuidString)-\(title)"
                    if !seenLinks.contains(linkKey) && !page.content.contains("[[\(title)]]") {
                        seenLinks.insert(linkKey)
                        tempLinks.append(PotentialLinkSuggestion(sourcePageID: page.id, sourceTitle: page.title, targetTitle: title))
                    }
                }
            }

            refactorSuggestions = suggestions
            potentialLinks = tempLinks
            isScanningAI = false
            TaskCenter.shared.updateTask(taskID, status: .completed)
        } catch {
            logger.addLog(action: .aiscanFailed, target: "System", details: error.localizedDescription)
            isScanningAI = false
            TaskCenter.shared.updateTask(taskID, status: .failed(error: error.localizedDescription))
        }
    }

    /// 拉取FixSuggestion
    /// - Returns: 字符串
    public func fetchFixSuggestion(for issue: LintIssue) async throws -> String {
        HapticFeedback.shared.trigger(.selection)
        let pages = (try? await knowledgeRepository.fetchAll()) ?? []
        return try await AISynthesisService.shared.suggestFix(issue: issue, pages: pages)
    }

    /// 查找与当前页面语义相似的页面（基于向量嵌入）
    public func findSimilarPages(for page: KnowledgePage, limit: Int = 3) async -> [KnowledgePage] {
        let results = await vectorStore.embeddingProvider.search(query: page.title, topK: limit + 1)
        
        var similarPages: [KnowledgePage] = []
        let allPages = (try? await knowledgeRepository.fetchAll()) ?? []
        for res in results {
            if res.id == page.id { continue }
            if let p = allPages.first(where: { $0.id == res.id }) {
                similarPages.append(p)
            }
            if similarPages.count >= limit { break }
        }
        return similarPages
    }

    // ── 页面级 AI 行为 (Async 接口版) ──

    /// 生成页面 AI 摘要
    public func runPageAISummary(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let summary = try await AISynthesisService.shared.summarize(content: content)
        activePageAIResult = summary
        return summary
    }

    /// 提取页面行动项
    public func runPageAIExtractActions(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let actions = try await AISynthesisService.shared.extractActions(content: content)
        activePageAIResult = actions
        return actions
    }

    /// 扩展页面存根内容
    public func runPageAIExpansion(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let expanded = try await AISynthesisService.shared.expandKnowledge(content: content)
        activePageAIResult = expanded
        return expanded
    }

    /// 执行通用页面综合任务（MindMap, Quiz, etc.）
    public func performPageSynthesis(type: SynthesisStore.SynthesisType, title: String, content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let taskID = TaskCenter.shared.addTask(type: .ai, name: type.title, target: title)
        do {
            let result = try await AISynthesisService.shared.synthesize(type: type, content: content)
            TaskCenter.shared.completeTask(id: taskID)
            
            // 针对不同类型处理结果
            if type == .quiz {
                let cleaned = LLMUtils.stripMarkdown(result)
                if let data = cleaned.data(using: .utf8),
                   let quiz = try? JSONDecoder().decode(QuizModel.self, from: data) {
                    activeQuiz = quiz
                } else {
                    activePageAIResult = result
                }
            } else {
                activePageAIResult = result
            }
            return result
        } catch {
            TaskCenter.shared.failTask(id: taskID, error: error.localizedDescription)
            throw error
        }
    }

    /// 清除All
    public func clearAll() {
        refactorSuggestions = []
        potentialLinks = []
        activePageAIResult = nil
        activeQuiz = nil
        lintIssues = []
        lastLintScore = 0
        lastLintDate = nil

        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.lastLintIssues)

        logger.addLog(action: .systemInit, target: "AIWorkflowStore", details: "AI Workflow data cleared.", module: "AIWorkflowStore")
    }

    // ── 建议清理方法 ──
    /// 移除Potential链接
    /// - Parameter id: id
    public func removePotentialLink(id: UUID) {
        potentialLinks.removeAll { $0.id == id }
    }

    /// 移除重构Suggestion
    /// - Parameter id: id
    public func removeRefactorSuggestion(id: String) {
        refactorSuggestions.removeAll { $0.id == id }
    }
}
