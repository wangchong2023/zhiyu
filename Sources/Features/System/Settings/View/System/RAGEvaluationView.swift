//
//  RAGEvaluationView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：RAG 质量评估详情页 — 按管线阶段排列（检索 → 生成 → 成本） + 段级/指标级信息说明

import SwiftUI

// MARK: - 评分颜色阈值

private enum ScoreThreshold {
    static let excellent: Double = 0.8
    static let fair: Double = 0.6
    /// 反向指标（幻觉率等）优秀上限
    static let invertedExcellent: Double = 0.2
    /// 反向指标一般上限
    static let invertedFair: Double = 0.4
}

// MARK: - 延迟与成本阈值

private enum LatencyThreshold {
    static let low: Int = 500
    static let medium: Int = 2000
}

private enum CostThreshold {
    static let low: Double = 0.50
}

// MARK: - 评估记录显示参数

private enum EvalDisplay {
    static let queryPreviewChars: Int = 50
    static let fetchLimit: Int = 50
    static let displayLimit: Int = 20
    static let hallucinationPenaltyWeight: Double = 0.3
}

// MARK: - 环形图视觉参数

private enum RingStyle {
    static let size: CGFloat = 64
    static let lineWidth: CGFloat = 5
    static let backgroundOpacity: Double = 0.15
    static let rotationDegrees: Double = -90
}

// MARK: - 通用卡片视觉参数

private enum CardVisual {
    static let metricBgOpacity: Double = 0.06
    static let tokenBgOpacity: Double = 0.04
    static let percentAuxOpacity: Double = 0.70
}

// MARK: - 标签（tagLabel）视觉参数

private enum TagVisual {
    static let horizontalPadding: CGFloat = 4
    static let verticalPadding: CGFloat = 1
    static let cornerRadius: CGFloat = 3
    static let fontSize: CGFloat = 10
}

// MARK: - 评估维度标签缩写

private enum MetricTag {
    static let faithfulness = "F"
    static let relevance = "R"
    static let hallucination = "H"
    static let precision = "P"
    static let citation = "C"
    static let answerCorrectness = "A"
}

// MARK: - 统一字号

private enum FontSize {
    static let metricValue: CGFloat = 22
    static let tokenValue: CGFloat = 18
    static let ringPercent: CGFloat = 14
    static let tag: CGFloat = 10
    static let detail: CGFloat = 9
    static let ringPercentSign: CGFloat = 8
}

// MARK: - 数值格式化模板

private enum FormatPattern {
    static let percentInt = "%.0f"
    static let score2 = "%.2f"
    static let score1 = "%.1f"
    static let costUSD = "$%.4f"
    static let tokenAvg = "%.0f"
}

// MARK: - 布局标题工具函数

private enum MetricTitle {
    static func hitRate(_ k: Int) -> String { "Hit@\(k)" }
    static let mrr = String(localized: "dashboard.stats.mrrTitle", defaultValue: "MRR", table: "Insight")
    static func ndcg(_ k: Int) -> String { "NDCG@\(k)" }
}

// MARK: - 主视图

@MainActor
struct RAGEvaluationView: View {
    @Inject private var governance: any RAGGovernanceRepository

    // MARK: 生成质量指标
    @State private var avgScores = AverageRAGScores(
        faithfulness: 0, relevance: 0, precision: 0,
        hallucinationRate: 0, citationAccuracy: 0, answerCorrectness: 0
    )
    // MARK: 检索质量 — 排名类
    @State private var hitRate: Double = 0
    @State private var mrr: Double = 0
    @State private var ndcg: Double = 0
    // MARK: 检索质量 — 覆盖类
    @State private var recall: Double = 0
    @State private var f1Score: Double = 0
    @State private var mapScore: Double = 0
    // MARK: 性能
    @State private var latency = LatencyPercentiles(p50: 0, p95: 0, p99: 0, sampleCount: 0)
    // MARK: 成本
    @State private var tokenEfficiency = TokenEfficiency(totalTokens: 0, queryCount: 0, avgTokensPerQuery: 0, estimatedCostUSD: 0)
    // MARK: 历史与 UI
    @State private var recentEvaluations: [RAGEvaluation] = []
    @State private var selectedDays = 30
    @State private var isLoading = true
    @State private var activeTooltip: String?

    private let dayOptions = [7, 30, 90]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.wide) {
                        timeRangePicker
                        retrievalSection
                        generationSection
                        costSection
                        evaluationHistorySection
                    }
                    .padding(DesignSystem.standardPadding)
                }
            }
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .navigationTitle(L10n.Dashboard.stats.benchmark)
        .task { await loadData() }
        .onChange(of: selectedDays) { _, _ in Task { await loadData() } }
    }

    // MARK: - 时间范围选择

    private var timeRangePicker: some View {
        HStack(spacing: DesignSystem.tightPadding) {
            ForEach(dayOptions, id: \.self) { days in
                Button {
                    selectedDays = days
                } label: {
                    Text("\(days) \(L10n.Dashboard.stats.unitDays)")
                        .font(.subheadline.weight(selectedDays == days ? .semibold : .regular))
                        .padding(.horizontal, DesignSystem.medium).padding(.vertical, DesignSystem.small)
                        .background(selectedDays == days ? Capsule().fill(Color.appAccent) : Capsule().fill(Color.appCard))
                        .foregroundStyle(selectedDays == days ? .white : .appSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 🔍 检索阶段

    private var retrievalSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            infoSectionHeader(
                id: "retrievalPhase",
                title: L10n.Dashboard.stats.retrievalQuality,
                icon: "magnifyingglass.circle.fill",
                color: .teal,
                tip: L10n.Dashboard.stats.tipRetrievalPhase
            )

            // 排名精度
            subSectionLabel(" Ranking Quality", icon: "list.number")
            HStack(spacing: DesignSystem.medium) {
                retrievalMetricCard(
                    id: "hitRate", title: MetricTitle.hitRate(AppConfig.AI.evaluationHitK),
                    score: hitRate, detail: L10n.Dashboard.stats.hitRateDesc, tip: L10n.Dashboard.stats.tipHitRate
                )
                retrievalMetricCard(
                    id: "mrr", title: L10n.Dashboard.stats.mrrTitle,
                    score: mrr, detail: L10n.Dashboard.stats.mrrDesc, tip: L10n.Dashboard.stats.tipMRR
                )
                retrievalMetricCard(
                    id: "ndcg", title: MetricTitle.ndcg(AppConfig.AI.evaluationNDCGK),
                    score: ndcg, detail: L10n.Dashboard.stats.ndcgDesc, tip: L10n.Dashboard.stats.tipNDCG
                )
            }

            // 覆盖完整度
            subSectionLabel(" Coverage", icon: "chart.pie.fill")
            HStack(spacing: DesignSystem.medium) {
                retrievalMetricCard(
                    id: "recall", title: L10n.Dashboard.stats.recallAtK,
                    score: recall, detail: L10n.Dashboard.stats.recallDesc, tip: L10n.Dashboard.stats.tipRecall
                )
                retrievalMetricCard(
                    id: "f1", title: L10n.Dashboard.stats.f1AtK,
                    score: f1Score, detail: L10n.Dashboard.stats.f1Desc, tip: L10n.Dashboard.stats.tipF1
                )
                retrievalMetricCard(
                    id: "map", title: L10n.Dashboard.stats.mapTitle,
                    score: mapScore, detail: L10n.Dashboard.stats.mapDesc, tip: L10n.Dashboard.stats.tipMAP
                )
            }

            // 响应延迟
            subSectionLabel(" Response Latency", icon: "stopwatch")
            latencyGrid
        }
        .appCardStyle()
    }

    private var latencyGrid: some View {
        VStack(spacing: DesignSystem.small) {
            HStack(spacing: DesignSystem.medium) {
                latencyCard(id: "latencyP50", label: L10n.Dashboard.stats.latencyP50, value: latency.p50)
                latencyCard(id: "latencyP95", label: L10n.Dashboard.stats.latencyP95, value: latency.p95)
                latencyCard(id: "latencyP99", label: L10n.Dashboard.stats.latencyP99, value: latency.p99)
            }
            HStack {
                Spacer()
                Text("\(latency.sampleCount) \(L10n.Dashboard.stats.latencySampleCount)")
                    .font(.caption2).foregroundStyle(.tertiary)
                infoIcon(id: "latency", tip: L10n.Dashboard.stats.tipLatency)
            }
        }
    }

    // MARK: - ✍️ 生成阶段

    private var generationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            infoSectionHeader(
                id: "generationPhase",
                title: L10n.Dashboard.stats.generationQuality,
                icon: "text.bubble.fill",
                color: .appAccent,
                tip: L10n.Dashboard.stats.tipGenerationPhase
            )

            VStack(spacing: DesignSystem.small) {
                HStack(spacing: DesignSystem.medium) {
                    scoreCard(id: "faithfulness", title: L10n.Dashboard.stats.faithfulness,
                              score: avgScores.faithfulness, icon: "checkmark.shield",
                              tip: L10n.Dashboard.stats.tipFaithfulness)
                    scoreCard(id: "relevance", title: L10n.Dashboard.stats.relevance,
                              score: avgScores.relevance, icon: "target",
                              tip: L10n.Dashboard.stats.tipRelevance)
                    scoreCard(id: "hallucination", title: L10n.Dashboard.stats.hallucinationRate,
                              score: avgScores.hallucinationRate, icon: "exclamationmark.bubble",
                              inverted: true, tip: L10n.Dashboard.stats.tipHallucination)
                }
                HStack(spacing: DesignSystem.medium) {
                    scoreCard(id: "precision", title: L10n.Dashboard.stats.precision,
                              score: avgScores.precision, icon: "scope",
                              tip: L10n.Dashboard.stats.tipPrecision)
                    scoreCard(id: "citation", title: L10n.Dashboard.stats.citationAccuracy,
                              score: avgScores.citationAccuracy, icon: "quote.bubble",
                              tip: L10n.Dashboard.stats.tipCitation)
                    scoreCard(id: "correctness", title: L10n.Dashboard.stats.answerCorrectness,
                              score: avgScores.answerCorrectness, icon: "checkmark.seal",
                              tip: L10n.Dashboard.stats.tipCorrectness)
                }
            }
        }
        .appCardStyle()
    }

    // MARK: - 💰 资源消耗

    private var costSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            infoSectionHeader(
                id: "costPhase",
                title: L10n.Dashboard.stats.tokenEfficiency,
                icon: "dollarsign.circle",
                color: .green,
                tip: L10n.Dashboard.stats.tipCostPhase
            )

            HStack(spacing: DesignSystem.medium) {
                tokenMetricCard(id: "totalTokens", title: L10n.Dashboard.stats.totalTokens,
                                value: tokenEfficiency.totalTokens.formatted(.number.notation(.compactName)),
                                tip: L10n.Dashboard.stats.tipTokenEfficiency)
                tokenMetricCard(id: "queryCount", title: L10n.Dashboard.stats.queryCount,
                                value: String(tokenEfficiency.queryCount),
                                tip: L10n.Dashboard.stats.tipTokenEfficiency)
                tokenMetricCard(id: "avgTokens", title: L10n.Dashboard.stats.avgTokensPerQuery,
                                value: String(format: FormatPattern.tokenAvg, tokenEfficiency.avgTokensPerQuery),
                                tip: L10n.Dashboard.stats.tipTokenEfficiency)
            }

            HStack {
                Text(L10n.Dashboard.stats.estimatedCost)
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: FormatPattern.costUSD, tokenEfficiency.estimatedCostUSD))
                    .font(.system(size: FontSize.tokenValue, weight: .bold, design: .monospaced))
                    .foregroundStyle(tokenEfficiency.estimatedCostUSD < CostThreshold.low ? .green : .orange)
            }
            .padding(.horizontal, DesignSystem.small)
        }
        .appCardStyle()
    }

    // MARK: - 📋 评估记录

    private var evaluationHistorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(title: L10n.Dashboard.stats.recentEvaluations, icon: "list.bullet.clipboard", color: .orange)
            if recentEvaluations.isEmpty {
                Text(L10n.Dashboard.stats.noEvaluations)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.large).frame(maxWidth: .infinity)
            } else {
                ForEach(recentEvaluations.prefix(EvalDisplay.displayLimit), id: \.id) { eval in
                    evaluationRow(eval)
                    if eval.id != recentEvaluations.prefix(EvalDisplay.displayLimit).last?.id { Divider() }
                }
            }
        }
        .appCardStyle()
    }

    // MARK: - 通用子视图

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
    }

    /// 带信息图标的段标题
    private func infoSectionHeader(id: String, title: String, icon: String, color: Color, tip: String) -> some View {
        HStack(spacing: DesignSystem.small) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
            infoIcon(id: id, tip: tip)
        }
    }

    /// 子区域标签（位于 section 内分组之间）
    private func subSectionLabel(_ text: LocalizedStringKey, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    }

    // MARK: - Tooltip 组件

    /// 信息图标 + 点击/悬停展示的 tooltip overlay
    private func infoIcon(id: String, tip: String) -> some View {
        let isActive = activeTooltip == id
        return Image(systemName: "info.circle")
            .font(.caption)
            .foregroundStyle(isActive ? .appAccent : .appSecondary.opacity(0.5))
            .onTapGesture { activeTooltip = isActive ? nil : id }
            .overlay(alignment: .top) {
                if isActive {
                    Text(tip)
                        .font(.caption2).foregroundStyle(.appSecondary)
                        .padding(.horizontal, DesignSystem.medium)
                        .padding(.vertical, DesignSystem.small)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                        .frame(maxWidth: 260)
                        .offset(y: -DesignSystem.largeIconSize)
                        .onTapGesture { activeTooltip = nil }
                }
            }
    }

    // MARK: - 环形百分比卡片

    private func scoreCard(id: String, title: String, score: Double, icon: String, inverted: Bool = false, tip: String) -> some View {
        let color = inverted ? invertedScoreColor(score) : scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            ZStack {
                Circle()
                    .stroke(color.opacity(RingStyle.backgroundOpacity), lineWidth: RingStyle.lineWidth)
                    .frame(width: RingStyle.size, height: RingStyle.size)
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: RingStyle.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(RingStyle.rotationDegrees))
                    .frame(width: RingStyle.size, height: RingStyle.size)
                    .animation(.easeInOut(duration: 0.8), value: score)
                VStack(spacing: 0) {
                    Text(String(format: FormatPattern.percentInt, score * 100))
                        .font(.system(size: FontSize.ringPercent, weight: .bold, design: .rounded)).foregroundStyle(color)
                    Text("%")
                        .font(.system(size: FontSize.ringPercentSign, weight: .medium))
                        .foregroundStyle(color.opacity(CardVisual.percentAuxOpacity))
                }
            }
            HStack(spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(2)
                infoIcon(id: id, tip: tip)
            }
            Text(String(format: FormatPattern.score2, score)).font(.caption2.monospaced()).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 检索指标迷你卡片

    private func retrievalMetricCard(id: String, title: String, score: Double, detail: String, tip: String) -> some View {
        let color = scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            HStack(spacing: 2) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                infoIcon(id: id, tip: tip)
            }
            Text(String(format: FormatPattern.score2, score))
                .font(.system(size: FontSize.metricValue, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(detail).font(.system(size: FontSize.detail)).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(color.opacity(CardVisual.metricBgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    // MARK: - 延迟卡片

    private func latencyCard(id: String, label: String, value: Int) -> some View {
        let color = latencyColor(value)
        return VStack(spacing: DesignSystem.tightPadding) {
            HStack(spacing: 2) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                infoIcon(id: id, tip: L10n.Dashboard.stats.tipLatency)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: FontSize.metricValue, weight: .bold, design: .rounded)).foregroundStyle(color)
                Text(L10n.Dashboard.stats.latencyUnitMS)
                    .font(.system(size: FontSize.tag, weight: .medium)).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(color.opacity(CardVisual.metricBgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    // MARK: - Token 卡片

    private func tokenMetricCard(id: String, title: String, value: String, tip: String) -> some View {
        VStack(spacing: DesignSystem.tightPadding) {
            Text(value).font(.system(size: FontSize.tokenValue, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            HStack(spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                infoIcon(id: id, tip: tip)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(Color.green.opacity(CardVisual.tokenBgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    // MARK: - 评估记录行

    private func evaluationRow(_ eval: RAGEvaluation) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            HStack {
                Text(eval.query.prefix(EvalDisplay.queryPreviewChars)
                     + (eval.query.count > EvalDisplay.queryPreviewChars ? "…" : ""))
                    .font(.subheadline.bold()).lineLimit(1)
                Spacer()
                scoreBadge(overallScore(eval))
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel(MetricTag.faithfulness, value: eval.faithfulness)
                tagLabel(MetricTag.relevance, value: eval.relevance)
                tagLabel(MetricTag.hallucination, value: eval.hallucinationRate, inverted: true)
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel(MetricTag.precision, value: eval.precision)
                tagLabel(MetricTag.citation, value: eval.citationAccuracy)
                tagLabel(MetricTag.answerCorrectness, value: eval.answerCorrectness)
            }
            Text(eval.evaluatorModel).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.tiny)
    }

    private func scoreBadge(_ score: Double) -> some View {
        Text(String(format: FormatPattern.score1, score * 100))
            .font(.caption.bold()).foregroundStyle(scoreColor(score))
            .padding(.horizontal, DesignSystem.small).padding(.vertical, DesignSystem.atomic)
            .background(scoreColor(score).opacity(0.1)).clipShape(Capsule())
    }

    private func tagLabel(_ prefix: String, value: Double, inverted: Bool = false) -> some View {
        let color = inverted ? invertedScoreColor(value) : scoreColor(value)
        return Text("\(prefix):\(String(format: FormatPattern.score2, value))")
            .font(.system(size: FontSize.tag, weight: .medium, design: .monospaced)).foregroundStyle(color)
            .padding(.horizontal, TagVisual.horizontalPadding).padding(.vertical, TagVisual.verticalPadding)
            .background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: TagVisual.cornerRadius))
    }

    // MARK: - 评分

    private func overallScore(_ eval: RAGEvaluation) -> Double {
        let positiveMean = (eval.faithfulness + eval.relevance + eval.precision
                            + eval.citationAccuracy + eval.answerCorrectness) / 5.0
        let penalty = eval.hallucinationRate * EvalDisplay.hallucinationPenaltyWeight
        return max(0, positiveMean - penalty)
    }

    private func scoreColor(_ s: Double) -> Color {
        if s >= ScoreThreshold.excellent { return .green }
        if s >= ScoreThreshold.fair { return .orange }
        return .red
    }

    private func invertedScoreColor(_ s: Double) -> Color {
        if s <= ScoreThreshold.invertedExcellent { return .green }
        if s <= ScoreThreshold.invertedFair { return .orange }
        return .red
    }

    private func latencyColor(_ ms: Int) -> Color {
        if ms < LatencyThreshold.low { return .green }
        if ms < LatencyThreshold.medium { return .orange }
        return .red
    }

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        let hitK = AppConfig.AI.evaluationHitK
        let ndcgK = AppConfig.AI.evaluationNDCGK
        let recallK = AppConfig.AI.evaluationRecallK

        do {
            async let scores = governance.calculateAverageRAGScores(days: selectedDays)
            async let evals = governance.fetchRAGEvaluations(limit: EvalDisplay.fetchLimit)
            async let hr = governance.calculateHitRate(days: selectedDays, k: hitK)
            async let meanRR = governance.calculateMRR(days: selectedDays)
            async let n = governance.calculateNDCG(days: selectedDays, k: ndcgK)
            async let rec = governance.calculateRecall(days: selectedDays, k: recallK)
            async let f1 = governance.calculateF1Score(days: selectedDays, k: recallK)
            async let map = governance.calculateMAP(days: selectedDays)
            async let lat = governance.calculateRetrievalLatency(days: selectedDays)
            async let tokEff = governance.calculateTokenEfficiency(days: selectedDays)

            avgScores = try await scores
            recentEvaluations = try await evals
            hitRate = (try? await hr) ?? 0
            mrr = (try? await meanRR) ?? 0
            ndcg = (try? await n) ?? 0
            recall = (try? await rec) ?? 0
            f1Score = (try? await f1) ?? 0
            mapScore = (try? await map) ?? 0
            latency = (try? await lat) ?? LatencyPercentiles(p50: 0, p95: 0, p99: 0, sampleCount: 0)
            tokenEfficiency = (try? await tokEff) ?? TokenEfficiency(totalTokens: 0, queryCount: 0, avgTokensPerQuery: 0, estimatedCostUSD: 0)
        } catch {
            Logger.shared.error("[RAG] Evaluation load failed", error: error)
        }
        isLoading = false
    }
}
