// AIInsightStore.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：AI 洞察存储，管理周报与每日动态回顾。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 从 AIWorkflowStore 拆分。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import Combine

/// AI 洞察存储，管理周报与每日动态回顾。
@MainActor
@Observable
final class AIInsightStore {
    // ── 洞察与报告 ──
    var weeklyInsight: KnowledgeInsightService.WeeklyInsight?
    var dailyRecap: KnowledgeInsightService.DailyRecap?
    var isGeneratingDailyRecap = false

    @ObservationIgnored @Inject private var insightService: KnowledgeInsightService
    @ObservationIgnored @Inject private var llmService: any LLMServiceProtocol
    @ObservationIgnored @Inject private var sqliteStore: SQLiteStore
    @ObservationIgnored @Inject private var logger: any LoggerProtocol

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

    // ── AI 洞察管理 ──

    func generateWeeklyInsight(forceRefresh: Bool = false) async {
        guard llmService.isEnabled else { return }

        if !forceRefresh, let cached = loadCachedWeeklyInsight() {
            weeklyInsight = cached
            return
        }

        do {
            let insight = try await insightService.generateWeeklyInsight(pages: sqliteStore.pages, llmService: llmService)
            weeklyInsight = insight
            saveCachedWeeklyInsight(insight)
        } catch {
            logger.addLog(action: .error, target: "AIInsightStore", details: "Weekly Insight Error: \(error.localizedDescription)", module: "AIInsightStore")
        }
    }

    private func weeklyCacheKey() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let lang = Localized.currentLanguage
        return "weekly_insight_\(components.yearForWeekOfYear ?? 0)_\(components.weekOfYear ?? 0)_\(lang)"
    }

    private func loadCachedWeeklyInsight() -> KnowledgeInsightService.WeeklyInsight? {
        let key = weeklyCacheKey()
        guard let data = UserDefaults.standard.data(forKey: key),
              let insight = try? JSONDecoder().decode(KnowledgeInsightService.WeeklyInsight.self, from: data) else {
            return nil
        }
        return insight
    }

    private func saveCachedWeeklyInsight(_ insight: KnowledgeInsightService.WeeklyInsight) {
        let key = weeklyCacheKey()
        if let data = try? JSONEncoder().encode(insight) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func generateDailyRecap(forceRefresh: Bool = false) async {
        guard !isGeneratingDailyRecap else { return }
        guard llmService.isEnabled else { return }

        isGeneratingDailyRecap = true
        defer { isGeneratingDailyRecap = false }

        do {
            let result = try await insightService.generateDailyRecap(
                pages: sqliteStore.pages,
                llmService: llmService,
                forceRefresh: forceRefresh
            )
            dailyRecap = result
        } catch {
            logger.addLog(action: .error, target: "AIInsightStore", details: "Generate daily recap failed: \(error.localizedDescription)", module: "AIInsightStore")
        }
    }

    func clearAll() {
        weeklyInsight = nil
        dailyRecap = nil

        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        let lang = Localized.currentLanguage

        let weeklyKey = "weekly_insight_\(year)_\(week)_\(lang)"
        UserDefaults.standard.removeObject(forKey: weeklyKey)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dailyKey = "daily_recap_\(formatter.string(from: Date()))_\(lang)"
        UserDefaults.standard.removeObject(forKey: dailyKey)
    }
}
