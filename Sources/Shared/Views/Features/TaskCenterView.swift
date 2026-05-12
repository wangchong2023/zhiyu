// TaskCenterView.swift
//
// 作者: Wang Chong
// 功能说明: 任务中心视图
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 任务中心入口
/// 任务中心主视图
/// 负责全局异步任务（如 AI 扫描、文档导入、知识合成）的队列监控、状态管理与历史追溯
struct TaskCenterView: View {
    @ObservedObject var taskCenter = TaskCenter.shared
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(AppRouter.self) var router
    @State private var showClearConfirm = false
    
    var body: some View {
        Group {
            if taskCenter.tasks.isEmpty {
                ScrollView {
                    VStack(spacing: AppUI.loosePadding) {
                        statusDashboard
                            .padding(.horizontal, AppUI.Task.dashboardPadding)
                        emptyState
                            .padding(.top, AppUI.loosePadding)
                    }
                }
            } else {
                List {
                    Section {
                        statusDashboard
                            .padding(.vertical, AppUI.tightPadding)
                    } header: {
                        Text(L10n.AI.Task.tr("categories"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                    }
                    
                    Section {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            let metrics = taskCenter.metrics(for: type)
                            let tasks = taskCenter.tasks.filter { $0.type == type }
                            
                            #if os(watchOS)
                            Section {
                                if tasks.isEmpty {
                                    Text(L10n.AI.Task.tr("noHistory"))
                                        .font(.caption)
                                        .foregroundStyle(.appSecondary)
                                        .padding(.vertical, AppUI.tightPadding)
                                } else {
                                    ForEach(tasks.sorted(by: { $0.startTime > $1.startTime })) { task in
                                        TaskRow(task: task)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                taskCenter.markAsRead(task.id)
                                                if let pageID = task.associatedPageID {
                                                    router.navigateToPage(id: pageID)
                                                }
                                            }
                                    }
                                    .onDelete { indices in
                                        let sortedTasks = tasks.sorted(by: { $0.startTime > $1.startTime })
                                        indices.forEach { index in
                                            taskCenter.removeTask(sortedTasks[index].id)
                                        }
                                    }
                                }
                            } header: {
                                HStack(spacing: AppUI.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(taskColor(for: type).opacity(AppUI.glassOpacity / 3))
                                            .frame(width: AppUI.Task.badgeSize, height: AppUI.Task.badgeSize)
                                        Image(systemName: type.icon)
                                            .font(.system(size: AppUI.Action.smallIconSize, weight: .bold))
                                            .foregroundStyle(taskColor(for: type))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AppUI.atomic) {
                                        Text(L10n.AI.Task.tr("type.\(type.rawValue)"))
                                            .font(.subheadline.bold())
                                        Text(L10n.AI.Task.trf("history.count", metrics.total))
                                            .font(.caption2)
                                            .foregroundStyle(.appSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if metrics.running > 0 {
                                        HStack(spacing: AppUI.tiny) {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("\(metrics.running)")
                                                .font(.system(size: AppUI.Metrics.dashboardLabelSize, weight: .bold, design: .rounded))
                                                .foregroundStyle(taskColor(for: type))
                                        }
                                        .padding(.horizontal, AppUI.tightPadding)
                                        .padding(.vertical, AppUI.tiny)
                                        .background(taskColor(for: type).opacity(AppUI.glassOpacity / 3))
                                        .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
                                    }
                                }
                                .padding(.vertical, AppUI.tiny)
                            }
                            #else
                            DisclosureGroup {
                                if tasks.isEmpty {
                                    Text(L10n.AI.Task.tr("noHistory"))
                                        .font(.caption)
                                        .foregroundStyle(.appSecondary)
                                        .padding(.vertical, AppUI.tightPadding)
                                } else {
                                    ForEach(tasks.sorted(by: { $0.startTime > $1.startTime })) { task in
                                        TaskRow(task: task)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                taskCenter.markAsRead(task.id)
                                                if let pageID = task.associatedPageID {
                                                    router.navigateToPage(id: pageID)
                                                }
                                            }
                                    }
                                    .onDelete { indices in
                                        let sortedTasks = tasks.sorted(by: { $0.startTime > $1.startTime })
                                        indices.forEach { index in
                                            taskCenter.removeTask(sortedTasks[index].id)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: AppUI.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(taskColor(for: type).opacity(AppUI.glassOpacity / 3))
                                            .frame(width: AppUI.Task.badgeSize, height: AppUI.Task.badgeSize)
                                        Image(systemName: type.icon)
                                            .font(.system(size: AppUI.Action.smallIconSize, weight: .bold))
                                            .foregroundStyle(taskColor(for: type))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AppUI.atomic) {
                                        Text(L10n.AI.Task.tr("type.\(type.rawValue)"))
                                            .font(.subheadline.bold())
                                        Text(L10n.AI.Task.trf("history.count", metrics.total))
                                            .font(.caption2)
                                            .foregroundStyle(.appSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if metrics.running > 0 {
                                        HStack(spacing: AppUI.tiny) {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("\(metrics.running)")
                                                .font(.system(size: AppUI.Metrics.dashboardLabelSize, weight: .bold, design: .rounded))
                                                .foregroundStyle(taskColor(for: type))
                                        }
                                        .padding(.horizontal, AppUI.tightPadding)
                                        .padding(.vertical, AppUI.tiny)
                                        .background(taskColor(for: type).opacity(AppUI.glassOpacity / 3))
                                        .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
                                    }
                                }
                                .padding(.vertical, AppUI.tiny)
                            }
                            #endif
                        }
                    } header: {
                        Text(L10n.AI.Task.tr("list.title"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                            .textCase(nil)
                    }
                }
                #if !os(watchOS)
                .listStyle(.insetGrouped)
                #endif
            }
        }
        .navigationTitle(L10n.AI.Task.centerTitle)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .background(themeManager.pageBackground())
        .onAppear {
            taskCenter.markAllAsRead()
        }
        .confirmationDialog(
            L10n.AI.Task.tr("clearConfirmTitle"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.Common.tr("clearAll"), role: .destructive) {
                taskCenter.reset()
                HapticFeedback.shared.trigger(.success)
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.AI.Task.tr("clearConfirmMessage"))
        }
    }
    
    // MARK: - Status Dashboard
    private var statusDashboard: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: AppUI.Task.dashboardSpacing), GridItem(.flexible(), spacing: AppUI.Task.dashboardSpacing)], spacing: AppUI.Task.dashboardSpacing) {
            summaryCard(type: .ingest, color: .blue)
            summaryCard(type: .healthCheck, color: .red)
            summaryCard(type: .aiScan, color: .orange)
            summaryCard(type: .synthesis, color: .purple)
        }
    }
    
    private func taskColor(for type: TaskType) -> Color {
        type.uiColor
    }
    
    private func summaryCard(type: TaskType, color: Color) -> some View {
        let metrics = taskCenter.metrics(for: type)
        let runningCount = metrics.running
        
        return VStack(alignment: .center, spacing: AppUI.tiny) {
            ZStack {
                Circle()
                    .fill(color.opacity(AppUI.glassOpacity / 2))
                    .frame(width: AppUI.Timeline.indicatorSize - AppUI.tiny, height: AppUI.Timeline.indicatorSize - AppUI.tiny) // 32
                Image(systemName: type.icon)
                    .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                    .foregroundStyle(color)
                
                if runningCount > 0 {
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(color, lineWidth: AppUI.borderWidth * 2)
                        .frame(width: AppUI.Timeline.indicatorSize, height: AppUI.Timeline.indicatorSize)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(spacing: AppUI.atomic) {
                Text(L10n.AI.Task.tr("type.\(type.rawValue)"))
                    .font(.system(size: AppUI.microFontSize + AppUI.atomic, weight: .bold)) // 11
                    .foregroundStyle(.appSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: AppUI.atomic) {
                    Text("\(metrics.completed)")
                        .font(.system(size: AppUI.standardFontSize + AppUI.small, weight: .bold, design: .rounded)) // 20
                        .foregroundStyle(.appText)
                    Text("/ \(metrics.total)")
                        .font(.system(size: AppUI.microFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(.appSecondary.opacity(AppUI.secondaryOpacity * 0.75)) // 0.6
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.standardPadding)
        .appMetricCardStyle(color: color, cornerRadius: AppUI.standardRadius)
        .padding(.vertical, AppUI.tiny)
        .shadow(color: Color.black.opacity(AppUI.shadowOpacity / 5), radius: AppUI.small, x: 0, y: AppUI.tiny)
    }
    
    private var emptyState: some View {
        VStack(spacing: AppUI.loosePadding) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(AppUI.glassOpacity / 2))
                    .frame(width: AppUI.Gallery.displayIconSize, height: AppUI.Gallery.displayIconSize)
                
                Image(systemName: "tray.fill")
                    .font(.system(size: AppUI.Gallery.splashIconSize - AppUI.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appAccent.opacity(AppUI.fullOpacity), .appAccent.opacity(AppUI.glassOpacity * 2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: AppUI.tiny)
                
                Image(systemName: "sparkles")
                    .font(.system(size: AppUI.Action.largeIconSize))
                    .foregroundStyle(.purple)
                    .offset(x: AppUI.standardPadding + AppUI.medium, y: -(AppUI.standardPadding + AppUI.medium))
            }
            
            VStack(spacing: AppUI.medium) {
                Text(L10n.AI.Task.emptyTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.appText)
                
                Text(L10n.AI.Task.emptyDesc)
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(AppUI.atomic * 2)
            }
            
            VStack(alignment: .leading, spacing: AppUI.standardPadding) {
                Text(L10n.AI.Task.tr("howToTrigger"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.appSecondary)
                    .padding(.bottom, AppUI.tiny)
                
                guideRow(icon: "stethoscope", color: .red, title: L10n.AI.Task.tr("guide.health"), desc: L10n.AI.Task.tr("guide.health.desc"))
                guideRow(icon: "bolt.shield.fill", color: .orange, title: L10n.AI.Task.tr("guide.aiscan"), desc: L10n.AI.Task.tr("guide.aiscan.desc"))
                guideRow(icon: "tray.and.arrow.down.fill", color: .blue, title: L10n.AI.Task.tr("guide.ingest"), desc: L10n.AI.Task.tr("guide.ingest.desc"))
                guideRow(icon: "wand.and.stars", color: .purple, title: L10n.AI.Task.tr("guide.synthesis"), desc: L10n.AI.Task.tr("guide.synthesis.desc"))
            }
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
            .padding(.horizontal, AppUI.loosePadding + AppUI.tiny)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
    
    private func guideRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: AppUI.standardPadding) {
            Image(systemName: icon)
                .font(.system(size: AppUI.Action.iconSize))
                .foregroundStyle(color)
                .frame(width: AppUI.Task.badgeSize, height: AppUI.Task.badgeSize)
                .background(color.opacity(AppUI.glassOpacity / 2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: AppUI.atomic) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            Spacer()
        }
    }
}

/// 任务条目行组件
/// 负责单个异步任务的进度条展示、状态文本反馈及关联页面的快捷跳转交互
private struct TaskRow: View {
    let task: GlobalTask
    
    var body: some View {
        HStack(spacing: AppUI.Task.rowSpacing) {
            // 类型图标与状态
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(task.type == .ai ? Color.purple.opacity(AppUI.glassOpacity / 2) : Color.appAccent.opacity(AppUI.glassOpacity / 2))
                    .frame(width: AppUI.Task.iconBoxSize, height: AppUI.Task.iconBoxSize)
                
                Image(systemName: task.type.icon)
                    .font(.system(size: AppUI.Action.iconSize + AppUI.atomic))
                    .foregroundStyle(task.type == .ai ? .purple : .appAccent)
                    .frame(width: AppUI.Task.iconBoxSize, height: AppUI.Task.iconBoxSize)
                
                if !task.isRead && (task.status == .completed || isFailed) {
                    Circle()
                        .fill(.red)
                        .frame(width: AppUI.Task.statusIndicatorSize, height: AppUI.Task.statusIndicatorSize)
                        .overlay(Circle().stroke(Color.appCard, lineWidth: AppUI.borderWidth * 2))
                }
            }
            
            VStack(alignment: .leading, spacing: AppUI.atomic * 2) {
                HStack {
                    Text(task.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    if task.associatedPageID != nil {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption2)
                            .foregroundStyle(.appAccent)
                    }
                }
                
                Text(task.target)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(1)
                
                if case .failed(let error) = task.status {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .padding(.top, AppUI.atomic)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppUI.Metrics.progressHeight) {
                statusText
                Text(task.startTime.formatted(.dateTime.hour().minute().second().locale(Localized.currentLocale)))
                    .font(.system(size: AppUI.microFontSize - AppUI.atomic * 2, design: .monospaced)) // 8
                    .foregroundStyle(.appSecondary.opacity(AppUI.glassOpacity * 2))
                    .fixedSize()
            }
        }
        .padding(.vertical, AppUI.Task.rowVerticalPadding)
        .opacity(task.isRead ? AppUI.disabledOpacity : AppUI.fullOpacity)
    }
    
    private var isFailed: Bool {
        if case .failed = task.status { return true }
        return false
    }
    
    @ViewBuilder
    private var statusText: some View {
        switch task.status {
        case .pending:
            Text(L10n.AI.Task.tr("status.pending"))
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        case .running(let progress):
            HStack(spacing: AppUI.tiny) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: AppUI.Task.progressWidth)
                Text(L10n.AI.Task.tr("status.running"))
                    .font(.caption2)
                    .foregroundStyle(.appAccent)
            }
        case .completed:
            Text(L10n.AI.Task.tr("status.completed"))
                .font(.caption2)
                .foregroundStyle(.green)
        case .failed:
            Text(L10n.AI.Task.tr("status.failed"))
                .font(.caption2.bold())
                .foregroundStyle(.red)
        }
    }
}
// MARK: - UI Extensions
extension TaskType {
    var uiColor: Color {
        switch self.defaultColor {
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        default: return .appAccent
        }
    }
}
