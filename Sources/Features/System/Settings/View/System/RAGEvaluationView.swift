//
//  RAGEvaluationView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：RAG 质量评估详情页 — 展示检索增强生成全链路指标与评估记录

import SwiftUI

@MainActor
struct RAGEvaluationView: View {
    @Inject private var governance: any GovernanceRepository

    @State private var avgScores: (faithfulness: Double, relevance: Double, precision: Double) = (0, 0, 0)
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
                        scoreOverviewSection
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

    // MARK: - 综合评分

    private var scoreOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            sectionHeader(title: L10n.Dashboard.stats.overview, icon: "chart.bar.fill", color: .appAccent)

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
                    title: L10n.Dashboard.stats.precision,
                    score: avgScores.precision,
                    icon: "scope"
                )
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

    private func scoreCard(title: String, score: Double, icon: String) -> some View {
        let color = scoreColor(score)
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
            Text(String(format: "%.2f", score))
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func evaluationRow(_ eval: RAGEvaluation) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            HStack {
                Text(eval.query.prefix(50) + (eval.query.count > 50 ? "..." : ""))
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                scoreBadge((eval.faithfulness + eval.relevance + eval.precision) / 3.0)
            }
            HStack(spacing: DesignSystem.small) {
                tagLabel("F", value: eval.faithfulness)
                tagLabel("R", value: eval.relevance)
                tagLabel("P", value: eval.precision)
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

    private func tagLabel(_ prefix: String, value: Double) -> some View {
        Text("\(prefix):\(String(format: "%.2f", value))")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(scoreColor(value))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(scoreColor(value).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    // MARK: - 辅助

    private func scoreColor(_ s: Double) -> Color {
        if s >= 0.8 { return .green }
        if s >= 0.6 { return .orange }
        return .red
    }

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        do {
            async let scores = governance.calculateAverageRAGScores(days: selectedDays)
            async let evals = governance.fetchRAGEvaluations(limit: 50)

            avgScores = try await scores
            recentEvaluations = try await evals
        } catch {
            print("[RAG] Evaluation load failed: \(error)")
        }
        isLoading = false
    }
}
