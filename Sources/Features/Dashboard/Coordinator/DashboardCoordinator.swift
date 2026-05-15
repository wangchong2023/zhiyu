// DashboardCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: 仪表盘功能协调器，负责统计计算、数据聚合及 AI 洞察任务编排。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 初始版本，从 KnowledgeDashboardView 剥离业务逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

@MainActor
@Observable
final class DashboardCoordinator {
    // ── 状态属性 ──
    var tags: [(tag: String, count: Int)] = []
    var totalLinks = 0
    var densityData: [DensityInfo] = []
    var isCalculating = false
    
    // ── AI 洞察状态转发 ──
    var isGeneratingInsights: Bool { aiStore.isGeneratingDailyRecap }
    var dailyRecap: KnowledgeInsightService.DailyRecap? { aiStore.dailyRecap }
    
    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject private var store: AppStore
    @ObservationIgnored @Inject private var aiStore: AIInsightStore
    @ObservationIgnored @Inject private var logger: any LoggerProtocol

    init() {}

    // ── 业务动作 ──

    /// 刷新所有统计数据与 AI 洞察
    func refreshAll() async {
        isCalculating = true
        updateTags()
        await calculateStats()
        await refreshInsights()
        isCalculating = false
    }

    /// 仅触发 AI 洞察刷新
    func refreshInsights() async {
        await aiStore.generateDailyRecap(forceRefresh: false)
    }

    /// 计算知识库核心统计指标（反链、密度等）
    func calculateStats() async {
        let pages = store.pages
        guard !pages.isEmpty else {
            self.totalLinks = 0
            self.densityData = []
            return
        }
        
        // 1. 计算反链地图 (In-memory calculation)
        var backlinkMap: [String: Int] = [:]
        for page in pages {
            for link in page.outgoingLinks {
                backlinkMap[link, default: 0] += 1
            }
        }
        
        // 2. 计算总链接数
        let links = pages.reduce(0) { $0 + $1.outgoingLinks.count }
        
        // 3. 计算重要度 (In + Out) Top 10 密度数据
        let density = pages.map { page in
            let inbound = backlinkMap[page.title, default: 0]
            let outbound = page.outgoingLinks.count
            return DensityInfo(name: page.title, inbound: Double(inbound), outbound: Double(outbound))
        }
        .sorted { ($0.inbound + $0.outbound) > ($1.inbound + $1.outbound) }
        .prefix(10)
        .map { $0 }
        
        // 更新状态
        self.totalLinks = links
        self.densityData = density
        
        logger.debug("📊 [Dashboard] 统计计算完成: \(links) 链接, \(density.count) 密度节点")
    }

    /// 聚合标签分布
    func updateTags() {
        var dict: [String: Int] = [:]
        for page in store.pages {
            for tag in page.getAllTags() {
                dict[tag, default: 0] += 1
            }
        }
        self.tags = dict.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }
}
