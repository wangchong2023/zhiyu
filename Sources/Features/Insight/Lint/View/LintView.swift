//
//  LintView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Lint 界面的 UI 视图层组件。
//
import SwiftUI

// MARK: - 治理中心入口
/// 知识治理中心主视图容器
/// 负责为健康检查与 AI 建议提供独立的导航上下文，管理顶层治理生命周期
struct LintView: View {
    @Binding var selection: SidebarSelection?
    var body: some View {
        LintViewContent(selection: $selection)
    }
}

// MARK: - 治理中心核心
/// 知识治理核心内容视图
/// 负责健康得分看板（Dashboard）渲染、结构化问题分析、AI 治理建议展示及自动化修复逻辑
struct LintViewContent: View {
    @Binding var selection: SidebarSelection?
    @Environment(AppStore.self) var store
    @Environment(AIWorkflowStore.self) var aiStore
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss // 新增：用于强制退出层级
    @State private var isRunning = false
    @State private var selectedTab = 0 // 0: 健康检查, 1: AI 建议

    // MARK: - UI Helpers
    private var healthColor: Color {
        switch aiStore.healthLevel {
        case .excellent: return .green
        case .good: return .appAccent
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var buttonGradient: Color {
        selectedTab == 0 ? .blue : .purple
    }

    var body: some View {
        ZStack {
            PageBackgroundView(accentColor: themeManager.accentColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 选项卡切换
                Picker("", selection: $selectedTab) {
                    Text(L10n.Lint.title).tag(0)
                    Text(L10n.Lint.aiSuggestions).tag(1)
                }
                #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
                .padding(.horizontal, DesignSystem.huge)
                .padding(.vertical, DesignSystem.tiny)
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .padding(.horizontal, DesignSystem.standardPadding)

                // 内容区
                Group {
                    if selectedTab == 0 {
                        healthCheckSection
                    } else {
                        aiSuggestionsSection
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .appSubPageToolbar(title: selectedTab == 0 ? L10n.Lint.title : L10n.Lint.aiSuggestions) {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                if selectedTab == 0 { runLint() } else { runAIScan() }
            }) {
                HStack(spacing: DesignSystem.tightPadding) { // 减小间距，使视觉更紧凑
                    ZStack {
                        ProgressView()
                            .controlSize(.small)
                            .opacity(isRunning || aiStore.isScanningAI ? 1 : 0)
                        
                        Image(systemName: selectedTab == 0 ? DesignSystem.Icons.healthCheck : DesignSystem.Icons.sparkles)
                            .font(.system(size: DesignSystem.subheadlineFontSize)) // 工具栏图标与文字对齐
                            .opacity(isRunning || aiStore.isScanningAI ? 0 : 1)
                    }
                    
                    Text(isRunning || aiStore.isScanningAI ? L10n.Lint.scanning : (selectedTab == 0 ? L10n.Lint.runCheck : L10n.Lint.runAIScan))
                }
                .font(.footnote.bold())
                .foregroundStyle(buttonGradient)
                .padding(.horizontal, DesignSystem.small) // 补偿 iOS 胶囊背景缺少内边距的问题
            }
            .buttonStyle(.plain)
            .disabled(isRunning || aiStore.isScanningAI)
        }
    }

    // MARK: - 健康检查板块 (重构为 Dashboard模式)
    private var healthCheckSection: some View {
        ScrollView {
            VStack(spacing: DesignSystem.giant) {
                // 1. Dashboard Header
                healthDashboardHeader
                    .padding(.top)

                // 2. Metrics Grid
                metricsGrid
                
                // 3. Issue List (如果存在问题)
                if !aiStore.lintIssues.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Text(L10n.Lint.detailIssues)
                            .font(.headline)
                            .padding(.horizontal, DesignSystem.huge)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            issueSection(title: L10n.Lint.errors(aiStore.lintIssues.filter { $0.severity == .error }.count), 
                                         issues: aiStore.lintIssues.filter { $0.severity == .error }, 
                                         icon: DesignSystem.Icons.errorCircle, color: .red)
                            
                            issueSection(title: L10n.Lint.warnings(aiStore.lintIssues.filter { $0.severity == .warning }.count), 
                                         issues: aiStore.lintIssues.filter { $0.severity == .warning }, 
                                         icon: DesignSystem.Icons.warning, color: .orange)
                            
                            issueSection(title: L10n.Lint.tips(aiStore.lintIssues.filter { $0.severity == .info }.count), 
                                         issues: aiStore.lintIssues.filter { $0.severity == .info }, 
                                         icon: DesignSystem.Icons.info, color: .blue)
                        }
                        .appContainer(padding: true)
                        .padding(.horizontal, DesignSystem.huge)
                    }
                }
            }
            .padding(.bottom, DesignSystem.wide)
        }
    }
    
    private var healthDashboardHeader: some View {
        VStack(spacing: DesignSystem.wide) {
            ZStack {
                // 上次检查时间展示在左上角
                VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                    Text(L10n.Lint.lastCheckTitle)
                        .font(.system(size: DesignSystem.microFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                        .padding(.leading, DesignSystem.tiny)

                    VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                        if let date = aiStore.lastLintDate {
                            Text(formatDate(date))
                                .font(.system(size: DesignSystem.microFontSize, design: .monospaced))
                                .foregroundStyle(.appText)
                        } else {
                            Text(L10n.Lint.lastCheckNever)
                                .font(.system(size: DesignSystem.microFontSize))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    .appContainer(padding: false) // 使用统一容器，padding 设置为 false 以便内部精确控制
                    .padding(DesignSystem.small)
                }
                .padding(.leading, DesignSystem.huge)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(healthColor.opacity(0.08), lineWidth: 10)
                            .frame(width: DesignSystem.Domain.Lint.chartSize, height: DesignSystem.Domain.Lint.chartSize) // 略微缩小，确保不重叠
                        
                        // 进度环
                        Circle()
                            .trim(from: 0, to: CGFloat(aiStore.lintScore) / 100.0)
                            .stroke(
                                LinearGradient(colors: [healthColor.opacity(0.6), healthColor], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: DesignSystem.Domain.Lint.chartSize, height: DesignSystem.Domain.Lint.chartSize)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(aiStore.lintScore)")
                                .font(.system(size: DesignSystem.Domain.Lint.scoreFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(.appText)
                            
                            Text(aiStore.healthLevel.title)
                                .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                                .foregroundStyle(healthColor)
                        }
                    }
                    Spacer()
                }
                
                // 评分标准展示在右下角
                VStack(alignment: .trailing, spacing: DesignSystem.tiny) {
                    let ranges = [
                        (L10n.Lint.healthExcellent, "90-100"),
                        (L10n.Lint.healthGood, "70-89"),
                        (L10n.Lint.healthFair, "50-69"),
                        (L10n.Lint.healthPoor, "< 50")
                    ]
                    
                    ForEach(ranges, id: \.1) { label, range in
                        HStack(spacing: DesignSystem.small) {
                            Text(label)
                                .font(.system(size: DesignSystem.microFontSize, weight: .bold))
                                .frame(width: 32, alignment: .trailing)
                            Text(range)
                                .font(.system(size: DesignSystem.microFontSize, design: .monospaced))
                                .foregroundStyle(.appSecondary.opacity(0.8))
                                .frame(width: 46, alignment: .leading)
                        }
                    }
                }
                .appContainer(padding: false)
                .padding(DesignSystem.small)
                .padding(.trailing, DesignSystem.standardPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .frame(height: DesignSystem.Metrics.chartHeight - 60)
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: DesignSystem.standardPadding), GridItem(.flexible(), spacing: DesignSystem.standardPadding)], spacing: DesignSystem.standardPadding) {
            metricCard(title: L10n.Lint.metricPages, 
                       value: "\(store.pages.count)", 
                       icon: DesignSystem.Icons.documentFill, 
                       color: .blue)
            
            metricCard(title: L10n.Lint.metricBroken, 
                       value: "\(store.brokenLinkCount)", 
                       icon: DesignSystem.Icons.link, 
                       color: .red)
            
            metricCard(title: L10n.Lint.metricOrphans, 
                       value: "\(store.orphanPageCount)", 
                       icon: DesignSystem.Icons.orphanPage, 
                       color: .orange)
            
            metricCard(title: L10n.Lint.metricLinks, 
                       value: "\(store.totalConnectionCount)", 
                       icon: DesignSystem.Icons.network, 
                       color: .appAccent)
        }
        .padding(.horizontal, DesignSystem.huge)
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(DesignSystem.Opacity.glass))
                        .frame(width: DesignSystem.Metrics.iconBoxSize - 8, height: DesignSystem.Metrics.iconBoxSize - 8)
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(title)
                    .font(.system(size: DesignSystem.captionFontSize, weight: .medium))
                    .foregroundColor(.appSecondary)
                
                Text(value)
                    .font(.system(size: DesignSystem.displayFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
            }
        }
        .padding(DesignSystem.standardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appContainer(background: Color.appCard, cornerRadius: DesignSystem.Metrics.dashboardRadius, padding: false)
        .shadow(color: .primary.opacity(0.04), radius: DesignSystem.small + DesignSystem.tiny, x: 0, y: DesignSystem.tiny + DesignSystem.atomic)
    }

    // MARK: - AI 建议板块
    private var aiSuggestionsSection: some View {
        VStack {
            if aiStore.refactorSuggestions.isEmpty && aiStore.potentialLinks.isEmpty {
                emptyAIView
            } else {
                List {
                    if !aiStore.refactorSuggestions.isEmpty {
                        Section(L10n.Lint.refactorSection) {
                            ForEach(aiStore.refactorSuggestions) { suggestion in
                                RefactorSuggestionRow(suggestion: suggestion)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                aiStore.removeRefactorSuggestion(id: suggestion.id)
                                            }
                                        } label: {
                                            Label(L10n.Common.ignore, systemImage: DesignSystem.Icons.privacyMode)
                                        }
                                    }
                            }
                        }
                    }
                    
                    if !aiStore.potentialLinks.isEmpty {
                        Section(L10n.Lint.linkDiscoverySection) {
                            ForEach(aiStore.potentialLinks) { link in
                                PotentialLinkRow(link: link)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                aiStore.removePotentialLink(id: link.id)
                                            }
                                        } label: {
                                            Label(L10n.Common.ignore, systemImage: DesignSystem.Icons.privacyMode)
                                        }
                                    }
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var emptyHealthView: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            Spacer()
            Image(systemName: DesignSystem.Icons.seal)
                .font(.system(size: DesignSystem.Domain.Lint.emptyIconSize))
                .foregroundStyle(.green)
            Text(L10n.Lint.noIssues)
                .font(.title3.weight(.semibold))
            Text(L10n.Lint.noIssuesHint)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Spacer()
        }
    }

    private var emptyAIView: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            Spacer()
            Image(systemName: DesignSystem.Icons.sparkles)
                .font(.system(size: DesignSystem.Domain.Lint.emptyIconSize))
                .foregroundStyle(.appAccent)
            Text(L10n.Lint.noAISuggestions)
                .font(.title3.weight(.semibold))
            Text(L10n.Lint.noAISuggestionsHint)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }

    private func issueSection(title: String, issues: [LintIssue], icon: String, color: Color) -> some View {
        Group {
            if !issues.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    HStack {
                        Label(title, systemImage: icon)
                            .font(.subheadline.bold())
                            .foregroundStyle(color)
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.tiny)
                    
                    VStack(spacing: 0) {
                        ForEach(issues) { issue in
                            LintIssueRow(issue: issue)
                                .padding(.horizontal)
                                .padding(.vertical, DesignSystem.small)
                            
                            if issue.id != issues.last?.id {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                    .appContainer(padding: true)
                }
                .padding(.bottom, DesignSystem.small)
            }
        }
    }

    private func runLint() {
        isRunning = true
        Task {
            // 模拟扫描耗时，增加视觉反馈
            try? await Task.sleep(nanoseconds: 800_000_000)
            await aiStore.runLint()
            await MainActor.run {
                isRunning = false
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.show(type: .success, message: L10n.Lint.scanComplete)
            }
        }
    }

    private func runAIScan() {
        guard aiStore.isLLMEnabled else {
            HapticFeedback.shared.trigger(.error)
            ToastManager.shared.show(type: .error, message: L10n.Lint.aiDisabledHint)
            return
        }
        
        Task {
            await aiStore.runAIScan()
            await MainActor.run {
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.show(type: .success, message: L10n.Lint.aiScanComplete)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(as: Date.AppFormat.slashDetailed)
    }
}

// MARK: - AI 建议行组件

struct RefactorSuggestionRow: View {
    let suggestion: RefactorSuggestion
    @Environment(AppStore.self) var store
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack {
                Label(suggestion.type.uppercased(), systemImage: iconName)
                    .font(.caption2.bold())
                    .padding(.horizontal, DesignSystem.tightPadding)
                    .padding(.vertical, DesignSystem.atomic)
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
                
                Text(suggestion.target)
                    .font(.subheadline.bold())
                
                Spacer()
                
                AppBorderedButton(title: L10n.Lint.apply, color: .appAccent, maxWidth: 80) {
                    Task { await store.applyRefactorSuggestion(suggestion) }
                }
            }
            
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.appSecondary)
            
            Text(L10n.Lint.aiFixSuggestion(suggestion.suggestion))
                .font(.caption2)
                .padding(DesignSystem.tightPadding)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
        }
        .padding(.vertical, DesignSystem.tiny)
    }
    
    private var iconName: String {
        switch suggestion.type {
        case "merge": return DesignSystem.Icons.merge
        case "split": return DesignSystem.Icons.branch
        case "rename": return DesignSystem.Icons.cursorIbeam
        default: return DesignSystem.Icons.sparkles
        }
    }
    
    private var color: Color {
        switch suggestion.type {
        case "merge": return .orange
        case "split": return .purple
        case "rename": return .blue
        default: return .appAccent
        }
    }
}

struct PotentialLinkRow: View {
    let link: PotentialLinkSuggestion
    @Environment(AppStore.self) var store
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(link.sourceTitle)
                    .font(.subheadline.bold())
                HStack(spacing: DesignSystem.tiny) {
                    Image(systemName: DesignSystem.Icons.forward)
                        .font(.caption2)
                    Text("[[\(link.targetTitle)]]")
                        .font(.caption)
                        .foregroundStyle(.appAccent)
                }
            }
            
            Spacer()
            
            AppBorderedButton(title: L10n.Lint.apply, color: .appAccent, maxWidth: 80) {
                Task { await store.applyPotentialLink(link) }
            }
        }
        .padding(.vertical, DesignSystem.tiny)
    }
}


// MARK: - 质量问题行渲染
/// 单个知识质量问题的展示行组件
/// 负责展示特定质量问题的详情、修复建议，并提供 AI 深度分析入口及页面快捷跳转能力
struct LintIssueRow: View {
    let issue: LintIssue
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @State private var aiSuggestion: String?
    @State private var isAnalyzing = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack(spacing: DesignSystem.small) {
                Image(systemName: issue.type.icon)
                    .foregroundStyle(Color.fromModelColorName(issue.severity.colorName))
                    .frame(width: 16, height: 16)

                Text(issue.message)
                    .font(.subheadline)
                    .foregroundStyle(.appText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !issue.suggestion.isEmpty {
                HStack(spacing: DesignSystem.tiny) {
                    Image(systemName: DesignSystem.Icons.concept)
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(issue.suggestion)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.leading, DesignSystem.giant)
            }

            if let pageID = issue.pageID,
               store.pages.contains(where: { $0.id == pageID }) {
                HStack(spacing: DesignSystem.medium) {
                    Button(action: { router.navigateToPage(id: pageID) }) {
                        Text(L10n.Lint.goToPage)
                            .font(.caption2)
                            .foregroundStyle(.appAccent)
                    }
                    
                    if store.llmService.isEnabled {
                        Button(action: fetchAISuggestion) {
                            HStack(spacing: DesignSystem.tiny) {
                                if isAnalyzing {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Image(systemName: DesignSystem.Icons.sparkles)
                                        .font(.caption2)
                                }
                                Text(L10n.Lint.aiFixSuggestionShort)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.purple)
                        }
                        .disabled(isAnalyzing)
                    }
                }
                .padding(.leading, DesignSystem.giant)
            }
            
            if let suggestion = aiSuggestion {
                Text(suggestion)
                    .font(.caption)
                    .padding(DesignSystem.small)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.leading, DesignSystem.giant)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, DesignSystem.tiny)
    }
    
    private func fetchAISuggestion() {
        #if !os(watchOS)
        guard !isAnalyzing else { return }
        isAnalyzing = true
        
        Task {
            do {
                let suggestion = try await store.aiWorkflowStore.fetchFixSuggestion(for: issue)
                await MainActor.run {
                    withAnimation {
                        self.aiSuggestion = suggestion
                        self.isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.aiSuggestion = L10n.Lint.aiSuggestionError(error.localizedDescription)
                    self.isAnalyzing = false
                }
            }
        }
        #endif
    }
}
