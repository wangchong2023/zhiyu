//
//  RAGEvaluationView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：RAG 质量评估详情页 — 5 维指标 + 检索质量 + 评估记录

import SwiftUI

@MainActor
struct RAGEvaluationView: View {
    @Inject private var governance: any RAGGovernanceRepository

    @State private var avgScores: (
        faithfulness: Double, relevance: Double, precision: Double,
        hallucinationRate: Double, citationAccuracy: Double
    ) = (0, 0, 0, 0, 0)
    @State private var hitRate: Double = 0
    @State private var mrr: Double = 0
    @State private var ndcg: Double = 0
    @State private var recentEvaluations: [RAGEvaluation] = []
    @State private var selectedDays = 30
    @State private var isLoading = true

    private let dayOptions = [7, 30, 90]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.wide) {
                        timeRangePicker
                        generationQualitySection
                        retrievalQualitySection
                        retrievalFidelitySection
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
                        .padding(.horizontal, DesignSystem.medium)
                        .padding(.vertical, DesignSystem.small)
                        .background(
                            selectedDays == days
                                ? Capsule().fill(Color.appAccent)
                                : Capsule().fill(Color.appCard)
                        )
                        .foregroundStyle(selectedDays == days ? .white : .appSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 生成质量（越高越好）

    private var generationQualitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(
                title: L10n.Dashboard.stats.generationQuality,
                icon: "text.bubble.fill",
                color: .appAccent
            )

            HStack(spacing: DesignSystem.medium) {
                scoreCard(
                    title: L10n.Dashboard.stats.faithfulness,
                    score: avgScores.faithfulness,
                    icon: "checkmark.shield"
                )
                scoreCard(
                    title: L10n.Dashboard.stats.relevance,
                    score: avgScores.relevance,
                    icon: "target"
                )
                scoreCard(
                    title: L10n.Dashboard.stats.hallucinationRate,
                    score: avgScores.hallucinationRate,
                    icon: "exclamationmark.bubble",
                    inverted: true
                )
            }
        }
        .appCardStyle()
    }

    // MARK: - 检索质量（Hit Rate / MRR / NDCG）

    private var retrievalQualitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(
                title: L10n.Dashboard.stats.retrievalQuality,
                icon: "list.number",
                color: .teal
            )

            HStack(spacing: DesignSystem.medium) {
                retrievalMetricCard(
                    title: "Hit@5",
                    score: hitRate,
                    detail: L10n.Dashboard.stats.hitRateDesc
                )
                retrievalMetricCard(
                    title: "MRR",
                    score: mrr,
                    detail: L10n.Dashboard.stats.mrrDesc
                )
                retrievalMetricCard(
                    title: "NDCG@10",
                    score: ndcg,
                    detail: L10n.Dashboard.stats.ndcgDesc
                )
            }
        }
        .appCardStyle()
    }

    // MARK: - 上下文与引用保真

    private var retrievalFidelitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(
                title: L10n.Dashboard.stats.retrievalFidelity,
                icon: "magnifyingglass.circle.fill",
                color: .blue
            )

            HStack(spacing: DesignSystem.medium) {
                scoreCard(
                    title: L10n.Dashboard.stats.precision,
                    score: avgScores.precision,
                    icon: "scope"
                )
                scoreCard(
                    title: L10n.Dashboard.stats.citationAccuracy,
                    score: avgScores.citationAccuracy,
                    icon: "quote.bubble"
                )
                Color.clear.frame(maxWidth: .infinity)
            }
        }
        .appCardStyle()
    }

    // MARK: - 评估记录

    private var evaluationHistorySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(
                title: L10n.Dashboard.stats.recentEvaluations,
                icon: "list.bullet.clipboard",
                color: .orange
            )

            if recentEvaluations.isEmpty {
                Text(L10n.Dashboard.stats.noEvaluations)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.large)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(recentEvaluations.prefix(20), id: \.id) { eval in
                    evaluationRow(eval)
                    if eval.id != recentEvaluations.prefix(20).last?.id {
                        Divider()
                    }
                }
            }
        }
        .appCardStyle()
    }

    // MARK: - 子视图

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(color)
    }

    private func scoreCard(title: String, score: Double, icon: String, inverted: Bool = false) -> some View {
        let color = inverted ? invertedScoreColor(score) : scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                    .animation(.easeInOut(duration: 0.8), value: score)
                VStack(spacing: 0) {
                    Text(String(format: "%.0f", score * 100))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("%")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(color.opacity(0.7))
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(String(format: "%.2f", score))
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    /// 检索质量指标迷你卡片（无环形图，简约数值展示）
    private func retrievalMetricCard(title: String, score: Double, detail: String) -> some View {
        let color = scoreColor(score)
        return VStack(spacing: DesignSystem.tightPadding) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", score))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(detail)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.small)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    private func evaluationRow(_ eval: RAGEvaluation) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            HStack {
                Text(eval.query.prefix(50) + (eval.query.count > 50 ? "..." : ""))
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                scoreBadge(overallScore(eval))
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel("F", value: eval.faithfulness)
                tagLabel("R", value: eval.relevance)
                tagLabel("H", value: eval.hallucinationRate, inverted: true)
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel("P", value: eval.precision)
                tagLabel("C", value: eval.citationAccuracy)
            }
            Text(eval.evaluatorModel)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.tiny)
    }

    private func scoreBadge(_ score: Double) -> some View {
        Text(String(format: "%.1f", score * 100))
            .font(.caption.bold())
            .foregroundStyle(scoreColor(score))
            .padding(.horizontal, DesignSystem.small)
            .padding(.vertical, DesignSystem.atomic)
            .background(scoreColor(score).opacity(0.1))
            .clipShape(Capsule())
    }

    private func tagLabel(_ prefix: String, value: Double, inverted: Bool = false) -> some View {
        let color = inverted ? invertedScoreColor(value) : scoreColor(value)
        return Text("\(prefix):\(String(format: "%.2f", value))")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    // MARK: - 辅助

    private func overallScore(_ eval: RAGEvaluation) -> Double {
        let positiveMean = (eval.faithfulness + eval.relevance + eval.precision + eval.citationAccuracy) / 4.0
        let penalty = eval.hallucinationRate * 0.3
        return max(0, positiveMean - penalty)
    }

    private func scoreColor(_ s: Double) -> Color {
        if s >= 0.8 { return .green }
        if s >= 0.6 { return .orange }
        return .red
    }

    private func invertedScoreColor(_ s: Double) -> Color {
        if s <= 0.2 { return .green }
        if s <= 0.4 { return .orange }
        return .red
    }

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        do {
            async let scores = governance.calculateAverageRAGScores(days: selectedDays)
            async let evals = governance.fetchRAGEvaluations(limit: 50)
            async let hr = governance.calculateHitRate(days: selectedDays, k: 5)
            async let meanRR = governance.calculateMRR(days: selectedDays)
            async let n = governance.calculateNDCG(days: selectedDays, k: 10)

            avgScores = try await scores
            recentEvaluations = try await evals
            hitRate = (try? await hr) ?? 0
            mrr = (try? await meanRR) ?? 0
            ndcg = (try? await n) ?? 0
        } catch {
            print("[RAG] Evaluation load failed: \(error)")
        }
        isLoading = false
    }
}
