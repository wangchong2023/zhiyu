//
//  RAGEvaluationView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：RAG 质量评估详情页 — 检索 → 生成 → 满意度 → 成本 → 记录

import SwiftUI

// MARK: - 评分颜色阈值

private enum ScoreThreshold {
    static let excellent: Double = 0.8
    static let fair: Double = 0.6
    static let invertedExcellent: Double = 0.2
    static let invertedFair: Double = 0.4
}

private enum LatencyThreshold {
    static let low: Int = 500
    static let medium: Int = 2000
}

private enum CostThreshold {
    static let low: Double = 0.50
}

// MARK: - 显示参数

private enum EvalDisplay {
    static let queryPreviewChars: Int = 50
    static let fetchLimit: Int = 50
    static let displayLimit: Int = 20
    static let hallucinationPenaltyWeight: Double = 0.3
    /// 综合评分中正向指标的数量（faithfulness + relevance + precision + citation + correctness + contextSufficiency）
    static let positiveMetricCount: Double = 6.0
}

// MARK: - 用户评分常量

private enum UserRating {
    static let thumbsDown = 1
    static let thumbsUp = 2
}

private enum EvalTab: Int, CaseIterable, Identifiable {
    case retrieval
    case generation
    case satisfaction
    case history

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .retrieval: return L10n.Dashboard.stats.tabRetrieval
        case .generation: return L10n.Dashboard.stats.tabGeneration
        case .satisfaction: return L10n.Dashboard.stats.tabSatisfaction
        case .history: return L10n.Dashboard.stats.tabHistory
        }
    }
}

// MARK: - SF Symbol 图标名

private enum RatingIcon {
    static let thumbsUp = "hand.thumbsup.fill"
    static let thumbsDown = "hand.thumbsdown.fill"
}

private enum RingStyle {
    static let size: CGFloat = 64
    static let lineWidth: CGFloat = 5
    static let backgroundOpacity: Double = 0.15
    static let rotationDegrees: Double = -90
}

private enum CardVisual {
    static let metricBgOpacity: Double = 0.06
    static let tokenBgOpacity: Double = 0.04
    static let percentAuxOpacity: Double = 0.70
}

private enum TagVisual {
    static let horizontalPadding: CGFloat = 4
    static let verticalPadding: CGFloat = 1
    static let cornerRadius: CGFloat = 3
    static let fontSize: CGFloat = 10
}

private enum TooltipVisual {
    static let iconHitTarget: CGFloat = 24
    static let animationDuration: TimeInterval = 0.2
    static let shadowOpacity: Double = 0.1
    static let shadowRadius: CGFloat = 5
    static let shadowOffsetY: CGFloat = 2
    static let popupOffsetY: CGFloat = -30
    static let maxZIndex: Double = 100
}

// MARK: - 标签缩写

private enum MetricTag {
    static let faithfulness = "F"
    static let relevance = "R"
    static let hallucination = "H"
    static let precision = "P"
    static let citation = "C"
    static let correctness = "A"
    static let contextSufficiency = "S"
}

private enum FontSize {
    static let metricValue: CGFloat = 22
    static let tokenValue: CGFloat = 18
    static let ringPercent: CGFloat = 14
    static let tag: CGFloat = 10
    static let detail: CGFloat = 9
    static let ringPercentSign: CGFloat = 8
}

private enum FormatPattern {
    static let percentInt = "%.0f"
    static let score2 = "%.2f"
    static let score1 = "%.1f"
    static let costUSD = "$%.4f"
    static let tokenAvg = "%.0f"
}

private enum MetricTitle {
    static func hitRate(_ k: Int) -> String { "Hit@\(k)" }
    static let mrr = String(localized: "dashboard.stats.mrrTitle", defaultValue: "MRR", table: "Insight")
    static func ndcg(_ k: Int) -> String { "NDCG@\(k)" }
}

// MARK: - 主视图

@MainActor
struct RAGEvaluationView: View {
    @Inject private var governance: any RAGGovernanceRepository

    // 生成质量（七维）
    @State private var avgScores = AverageRAGScores(
        faithfulness: 0, relevance: 0, precision: 0, hallucinationRate: 0,
        citationAccuracy: 0, answerCorrectness: 0, contextSufficiency: 0
    )
    // 检索 — 排名
    @State private var hitRate: Double = 0
    @State private var mrr: Double = 0
    @State private var ndcg: Double = 0
    // 检索 — 覆盖
    @State private var recall: Double = 0
    @State private var f1Score: Double = 0
    @State private var mapScore: Double = 0
    // 性能
    @State private var latency = LatencyPercentiles(p50: 0, p95: 0, p99: 0, sampleCount: 0)
    // 成本
    @State private var tokenEfficiency = TokenEfficiency(totalTokens: 0, queryCount: 0, avgTokensPerQuery: 0, estimatedCostUSD: 0)
    // 满意度
    @State private var satisfactionRate: Double = 0
    @State private var satisfactionThumbsUp: Int = 0
    @State private var satisfactionThumbsDown: Int = 0
    // 历史
    @State private var recentEvaluations: [RAGEvaluation] = []
    @State private var selectedDays = 30
    @State private var isLoading = true
    @State private var activeTooltip: String?
    @State private var selectedTab: EvalTab = .retrieval

    private let dayOptions = [7, 30, 90]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.wide) {
                        timeRangePicker
                        
                        Picker("", selection: $selectedTab) {
                            ForEach(EvalTab.allCases) { tab in
                                Text(tab.title).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, DesignSystem.small)

                        switch selectedTab {
                        case .retrieval:
                            retrievalSection
                        case .generation:
                            generationSection
                        case .satisfaction:
                            satisfactionSection
                            costSection
                        case .history:
                            evaluationHistorySection
                        }
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

    // MARK: - 时间范围

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
            infoSectionHeader(id: "retrievalPhase", title: L10n.Dashboard.stats.retrievalQuality,
                              icon: "magnifyingglass.circle.fill", color: .teal, tip: L10n.Dashboard.stats.tipRetrievalPhase)

            subSectionLabel(L10n.Dashboard.stats.rankingQuality, icon: "list.number")
            HStack(spacing: DesignSystem.medium) {
                retrievalMetricCard(id: "hitRate", title: MetricTitle.hitRate(AppConfig.AI.evaluationHitK),
                                    score: hitRate, detail: L10n.Dashboard.stats.hitRateDesc, tip: L10n.Dashboard.stats.tipHitRate)
                retrievalMetricCard(id: "mrr", title: L10n.Dashboard.stats.mrrTitle,
                                    score: mrr, detail: L10n.Dashboard.stats.mrrDesc, tip: L10n.Dashboard.stats.tipMRR)
                retrievalMetricCard(id: "ndcg", title: MetricTitle.ndcg(AppConfig.AI.evaluationNDCGK),
                                    score: ndcg, detail: L10n.Dashboard.stats.ndcgDesc, tip: L10n.Dashboard.stats.tipNDCG)
            }

            subSectionLabel(L10n.Dashboard.stats.coverage, icon: "chart.pie.fill")
            HStack(spacing: DesignSystem.medium) {
                retrievalMetricCard(id: "recall", title: L10n.Dashboard.stats.recallAtK,
                                    score: recall, detail: L10n.Dashboard.stats.recallDesc, tip: L10n.Dashboard.stats.tipRecall)
                retrievalMetricCard(id: "f1", title: L10n.Dashboard.stats.f1AtK,
                                    score: f1Score, detail: L10n.Dashboard.stats.f1Desc, tip: L10n.Dashboard.stats.tipF1)
                retrievalMetricCard(id: "map", title: L10n.Dashboard.stats.mapTitle,
                                    score: mapScore, detail: L10n.Dashboard.stats.mapDesc, tip: L10n.Dashboard.stats.tipMAP)
            }

            subSectionLabel(L10n.Dashboard.stats.contextFidelity, icon: "scope")
            HStack(spacing: DesignSystem.medium) {
                scoreCardMedium(id: "precision", title: L10n.Dashboard.stats.precision,
                                score: avgScores.precision, tip: L10n.Dashboard.stats.tipPrecision)
                scoreCardMedium(id: "citation", title: L10n.Dashboard.stats.citationAccuracy,
                                score: avgScores.citationAccuracy, tip: L10n.Dashboard.stats.tipCitation)
                Color.clear.frame(maxWidth: .infinity)
            }

            subSectionLabel(L10n.Dashboard.stats.responseLatency, icon: "stopwatch")
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
            infoSectionHeader(id: "generationPhase", title: L10n.Dashboard.stats.generationQuality,
                              icon: "text.bubble.fill", color: .appAccent, tip: L10n.Dashboard.stats.tipGenerationPhase)
            VStack(spacing: DesignSystem.small) {
                HStack(spacing: DesignSystem.medium) {
                    scoreCard(id: "faithfulness", title: L10n.Dashboard.stats.faithfulness,
                              score: avgScores.faithfulness, icon: "checkmark.shield", tip: L10n.Dashboard.stats.tipFaithfulness)
                    scoreCard(id: "relevance", title: L10n.Dashboard.stats.relevance,
                              score: avgScores.relevance, icon: "target", tip: L10n.Dashboard.stats.tipRelevance)
                    scoreCard(id: "hallucination", title: L10n.Dashboard.stats.hallucinationRate,
                              score: avgScores.hallucinationRate, icon: "exclamationmark.bubble",
                              inverted: true, tip: L10n.Dashboard.stats.tipHallucination)
                }
                HStack(spacing: DesignSystem.medium) {
                    scoreCard(id: "correctness", title: L10n.Dashboard.stats.answerCorrectness,
                              score: avgScores.answerCorrectness, icon: "checkmark.seal", tip: L10n.Dashboard.stats.tipCorrectness)
                    scoreCard(id: "contextSufficiency", title: L10n.Dashboard.stats.contextSufficiency,
                              score: avgScores.contextSufficiency, icon: "books.vertical.fill", tip: L10n.Dashboard.stats.tipContextSufficiency)
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
        .appCardStyle()
    }

    // MARK: - 👍 用户满意度

    private var satisfactionSection: some View {
        let barHeight: CGFloat = 12
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            infoSectionHeader(id: "satisfactionPhase", title: L10n.Dashboard.stats.userSatisfaction,
                              icon: "hand.thumbsup.fill", color: .blue, tip: L10n.Dashboard.stats.tipUserSatisfaction)

            let total = satisfactionThumbsUp + satisfactionThumbsDown
            if total > 0 {
                HStack(spacing: DesignSystem.medium) {
                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: DesignSystem.atomic)
                                .fill(Color.appCard).frame(height: barHeight)
                            RoundedRectangle(cornerRadius: DesignSystem.atomic)
                                .fill(satisfactionColor)
                                .frame(width: geo.size.width * satisfactionRate, height: barHeight)
                        }
                    }
                    .frame(height: barHeight)

                    Text(String(format: FormatPattern.percentInt, satisfactionRate * 100) + "%")
                        .font(.title3.bold()).foregroundStyle(satisfactionColor)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(satisfactionThumbsUp) 👍  \(satisfactionThumbsDown) 👎")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(total) \(L10n.Dashboard.stats.ratingTotal)")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text(L10n.Dashboard.stats.noRatings)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.small).frame(maxWidth: .infinity)
            }
        }
        .appCardStyle()
    }

    private var satisfactionColor: Color {
        if satisfactionRate >= ScoreThreshold.excellent { return .green }
        if satisfactionRate >= ScoreThreshold.fair { return .orange }
        return .red
    }

    // MARK: - 💰 资源消耗

    private var costSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            infoSectionHeader(id: "costPhase", title: L10n.Dashboard.stats.tokenEfficiency,
                              icon: "dollarsign.circle", color: .green, tip: L10n.Dashboard.stats.tipCostPhase)
            HStack(spacing: DesignSystem.medium) {
                tokenMetricCard(id: "totalTokens", title: L10n.Dashboard.stats.totalTokens,
                                value: tokenEfficiency.totalTokens.formatted(.number.notation(.compactName)),
                                tip: L10n.Dashboard.stats.tipTokenEfficiency)
                tokenMetricCard(id: "queryCount", title: L10n.Dashboard.stats.queryCount,
                                value: String(tokenEfficiency.queryCount), tip: L10n.Dashboard.stats.tipTokenEfficiency)
                tokenMetricCard(id: "avgTokens", title: L10n.Dashboard.stats.avgTokensPerQuery,
                                value: String(format: FormatPattern.tokenAvg, tokenEfficiency.avgTokensPerQuery),
                                tip: L10n.Dashboard.stats.tipTokenEfficiency)
            }
            HStack {
                Text(L10n.Dashboard.stats.estimatedCost).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
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

    private func infoSectionHeader(id: String, title: String, icon: String, color: Color, tip: String) -> some View {
        HStack(spacing: DesignSystem.small) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
            infoIcon(id: id, tip: tip)
        }
    }

    private func subSectionLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    }

    // MARK: - Tooltip

    private func infoIcon(id: String, tip: String) -> some View {
        let binding = Binding(
            get: { activeTooltip == id },
            set: { activeTooltip = $0 ? id : nil }
        )
        return Button(action: {
            HapticFeedback.shared.trigger(.selection)
            activeTooltip = (activeTooltip == id) ? nil : id
        }) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle((activeTooltip == id) ? .appAccent : .appSecondary.opacity(DesignSystem.Opacity.soft))
                .frame(width: TooltipVisual.iconHitTarget, height: TooltipVisual.iconHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: binding, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
            Text(tip)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.small)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - 环形百分比卡片

    private func scoreCard(id: String, title: String, score: Double, icon: String,
                           inverted: Bool = false, tip: String) -> some View {
        let color = inverted ? invertedScoreColor(score) : scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            ZStack {
                Circle().stroke(color.opacity(RingStyle.backgroundOpacity), lineWidth: RingStyle.lineWidth)
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
                    Text("%").font(.system(size: FontSize.ringPercentSign, weight: .medium))
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

    /// 无环形图的中型评分卡片（用于检索保真区）
    private func scoreCardMedium(id: String, title: String, score: Double, tip: String) -> some View {
        let color = scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            HStack(spacing: 2) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                infoIcon(id: id, tip: tip)
            }
            Text(String(format: FormatPattern.score2, score))
                .font(.system(size: FontSize.metricValue, weight: .bold, design: .rounded)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(color.opacity(CardVisual.metricBgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    // MARK: - 检索指标卡片

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

    private func latencyCard(id: String, label: String, value: Int) -> some View {
        let color = latencyColor(value)
        return VStack(spacing: DesignSystem.tightPadding) {
            HStack(spacing: 2) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                infoIcon(id: id, tip: L10n.Dashboard.stats.tipLatency)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(value)").font(.system(size: FontSize.metricValue, weight: .bold, design: .rounded)).foregroundStyle(color)
                Text(L10n.Dashboard.stats.latencyUnitMS).font(.system(size: FontSize.tag, weight: .medium)).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(color.opacity(CardVisual.metricBgOpacity)).clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    private func tokenMetricCard(id: String, title: String, value: String, tip: String) -> some View {
        VStack(spacing: DesignSystem.tightPadding) {
            Text(value).font(.system(size: FontSize.tokenValue, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            HStack(spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                infoIcon(id: id, tip: tip)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.small)
        .background(Color.green.opacity(CardVisual.tokenBgOpacity)).clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    // MARK: - 评估记录行（含 👍👎）

    private func evaluationRow(_ eval: RAGEvaluation) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            HStack {
                Text(eval.query.prefix(EvalDisplay.queryPreviewChars)
                     + (eval.query.count > EvalDisplay.queryPreviewChars ? "…" : ""))
                    .font(.subheadline.bold()).lineLimit(1)
                Spacer()
                scoreBadge(overallScore(eval))
                // 👍👎 按钮
                ratingButton(eval: eval, rating: UserRating.thumbsUp, icon: RatingIcon.thumbsUp, isActive: eval.userRating == UserRating.thumbsUp)
                ratingButton(eval: eval, rating: UserRating.thumbsDown, icon: RatingIcon.thumbsDown, isActive: eval.userRating == UserRating.thumbsDown)
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel(MetricTag.faithfulness, value: eval.faithfulness)
                tagLabel(MetricTag.relevance, value: eval.relevance)
                tagLabel(MetricTag.hallucination, value: eval.hallucinationRate, inverted: true)
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel(MetricTag.correctness, value: eval.answerCorrectness)
                tagLabel(MetricTag.citation, value: eval.citationAccuracy)
                tagLabel(MetricTag.contextSufficiency, value: eval.contextSufficiency)
            }
            Text(eval.evaluatorModel).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.tiny)
    }

    private func ratingButton(eval: RAGEvaluation, rating: Int, icon: String, isActive: Bool) -> some View {
        Button {
            guard let evalID = eval.id else { return }
            Task {
                try? await governance.updateUserRating(evaluationID: evalID, rating: rating)
                await loadData()
            }
        } label: {
            Image(systemName: icon)
                .font(.caption).foregroundStyle(isActive ? .blue : .appSecondary.opacity(DesignSystem.Opacity.disabled))
        }
        .buttonStyle(.plain)
    }

    private func scoreBadge(_ score: Double) -> some View {
        Text(String(format: FormatPattern.score1, score * 100))
            .font(.caption.bold()).foregroundStyle(scoreColor(score))
            .padding(.horizontal, DesignSystem.small).padding(.vertical, DesignSystem.atomic)
            .background(scoreColor(score).opacity(DesignSystem.Opacity.subtle)).clipShape(Capsule())
    }

    private func tagLabel(_ prefix: String, value: Double, inverted: Bool = false) -> some View {
        let color = inverted ? invertedScoreColor(value) : scoreColor(value)
        return Text("\(prefix):\(String(format: FormatPattern.score2, value))")
            .font(.system(size: FontSize.tag, weight: .medium, design: .monospaced)).foregroundStyle(color)
            .padding(.horizontal, TagVisual.horizontalPadding).padding(.vertical, TagVisual.verticalPadding)
            .background(color.opacity(DesignSystem.Opacity.light)).clipShape(RoundedRectangle(cornerRadius: TagVisual.cornerRadius))
    }

    // MARK: - 评分与颜色

    private func overallScore(_ eval: RAGEvaluation) -> Double {
        let positiveMean = (eval.faithfulness + eval.relevance + eval.precision
                            + eval.citationAccuracy + eval.answerCorrectness
                            + eval.contextSufficiency) / EvalDisplay.positiveMetricCount
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
            let evaluationList = try await evals
            recentEvaluations = evaluationList
            hitRate = (try? await hr) ?? 0
            mrr = (try? await meanRR) ?? 0
            ndcg = (try? await n) ?? 0
            recall = (try? await rec) ?? 0
            f1Score = (try? await f1) ?? 0
            mapScore = (try? await map) ?? 0
            latency = (try? await lat) ?? LatencyPercentiles(p50: 0, p95: 0, p99: 0, sampleCount: 0)
            tokenEfficiency = (try? await tokEff) ?? TokenEfficiency(totalTokens: 0, queryCount: 0, avgTokensPerQuery: 0, estimatedCostUSD: 0)

            // 满意度统计
            let rated = evaluationList.filter { $0.userRating != nil }
            satisfactionThumbsUp = rated.filter { $0.userRating == UserRating.thumbsUp }.count
            satisfactionThumbsDown = rated.filter { $0.userRating == UserRating.thumbsDown }.count
            let total = satisfactionThumbsUp + satisfactionThumbsDown
            satisfactionRate = total > 0 ? Double(satisfactionThumbsUp) / Double(total) : 0
        } catch {
            Logger.shared.error("[RAG] Evaluation load failed", error: error)
        }
        isLoading = false
    }
}
