// AIWorkflowStore.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：AI 工作流存储，管理 AI 扫描状态、洞察及建议。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import Combine

/// AI 工作流存储，管理 AI 扫描状态、洞察及建议。
@MainActor
@Observable
final class AIWorkflowStore {
    // ── 扫描与分析状态 ──
    var isScanningAI = false
    var refactorSuggestions: [RefactorSuggestion] = []
    var potentialLinks: [PotentialLinkSuggestion] = []

    // ── 页面级 AI 状态 ──
    var activePageAIResult: String?
    var isProcessingPageAI = false
    var activeQuiz: QuizModel?

    // ── 健康度状态 ──
    var lastLintScore: Int = 0
    var lastLintDate: Date?

    // ── 健康度代理 (由 LintService 实时计算) ──
    var healthMetrics: (score: Int, level: LintService.HealthLevel) {
        lintService.calculateHealthMetrics(issues: lintIssues)
    }
    var lintScore: Int { healthMetrics.score }
    var healthLevel: LintService.HealthLevel { healthMetrics.level }
    
    /// LLM 服务是否已启用
    var isLLMEnabled: Bool { llmService.isEnabled }

    // ── 健康度问题存储 (Lint Issues) ──
    @ObservationIgnored private var _lintIssues: [LintIssue] = {
        if let data = UserDefaults.standard.data(forKey: "lastLintIssues"),
           let decoded = try? JSONDecoder().decode([LintIssue].self, from: data) {
            return decoded
        }
        return []
    }()

    var lintIssues: [LintIssue] {
        get { access(keyPath: \.lintIssues); return _lintIssues }
        set {
            withMutation(keyPath: \.lintIssues) {
                _lintIssues = newValue
                if let data = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(data, forKey: "lastLintIssues")
                }
            }
        }
    }

    @ObservationIgnored @Inject private var insightService: KnowledgeInsightService
    @ObservationIgnored @Inject private var llmService: any LLMServiceProtocol
    @ObservationIgnored @Inject private var sqliteStore: SQLiteStore
    @ObservationIgnored @Inject private var lintService: LintService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var linkService: LinkService

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                if case .clearAllDataRequested = event {
                    self?.clearAll()
                }
            }
            .store(in: &cancellables)
    }

    // ── 扫描与健康检查逻辑 ──

    func runLint() async {
        let taskID = TaskCenter.shared.addTask(type: .healthCheck, name: Localized.tr("sidebar.healthCheck"), target: "System")
        let issues = await lintService.runLint(pages: sqliteStore.pages, linkService: linkService)
        lintIssues = issues
        lastLintDate = Date()
        TaskCenter.shared.updateTask(taskID, status: .completed)
    }

    func runAIScan() async {
        guard llmService.isEnabled else {
            logger.addLog(action: .aiscanSkipped, target: "System", details: "LLM service disabled")
            return
        }

        isScanningAI = true
        let taskID = TaskCenter.shared.addTask(type: .ai, name: L10n.AI.Task.tr("scanTaskName"), target: "System")

        do {
            let samplePages = Array(sqliteStore.pages.prefix(10))
            let suggestions = try await llmService.analyzeForRefactoring(pages: samplePages)

            let activePages = sqliteStore.pages.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(5)
            let existingTitles = sqliteStore.pages.map { $0.title }

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

    func fetchFixSuggestion(for issue: LintIssue) async throws -> String {
        HapticFeedback.shared.trigger(.selection)
        return try await AISynthesisService.shared.suggestFix(issue: issue, pages: sqliteStore.pages)
    }

    /// 查找与当前页面语义相似的页面（基于向量嵌入）
    func findSimilarPages(for page: KnowledgePage, limit: Int = 3) async -> [KnowledgePage] {
        let results = await sqliteStore.embeddingManager.search(query: page.title, topK: limit + 1)
        return results
            .filter { $0.id != page.id }
            .prefix(limit)
            .compactMap { res in sqliteStore.pages.first { $0.id == res.id } }
    }

    // ── 页面级 AI 行为 (Async 接口版) ──

    /// 生成页面 AI 摘要
    func runPageAISummary(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let summary = try await AISynthesisService.shared.summarize(content: content)
        activePageAIResult = summary
        return summary
    }

    /// 提取页面行动项
    func runPageAIExtractActions(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let actions = try await AISynthesisService.shared.extractActions(content: content)
        activePageAIResult = actions
        return actions
    }

    /// 扩展页面存根内容
    func runPageAIExpansion(content: String) async throws -> String {
        isProcessingPageAI = true
        defer { isProcessingPageAI = false }
        
        let expanded = try await AISynthesisService.shared.expandKnowledge(content: content)
        activePageAIResult = expanded
        return expanded
    }

    /// 执行通用页面综合任务（MindMap, Quiz, etc.）
    func performPageSynthesis(type: SynthesisStore.SynthesisType, title: String, content: String) async throws -> String {
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

    func clearAll() {
        refactorSuggestions = []
        potentialLinks = []
        activePageAIResult = nil
        activeQuiz = nil
        lintIssues = []
        lastLintScore = 0
        lastLintDate = nil

        UserDefaults.standard.removeObject(forKey: "lastLintIssues")

        logger.addLog(action: .systemInit, target: "AIWorkflowStore", details: "AI Workflow data cleared.", module: "AIWorkflowStore")
    }

    // ── 建议清理方法 ──
    func removePotentialLink(id: UUID) {
        potentialLinks.removeAll { $0.id == id }
    }

    func removeRefactorSuggestion(id: String) {
        refactorSuggestions.removeAll { $0.id == id }
    }

}
