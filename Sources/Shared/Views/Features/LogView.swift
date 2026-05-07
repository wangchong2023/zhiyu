// LogView.swift
//
// 作者: Wang Chong
// 功能说明: struct LogView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 导航入口
/// 操作日志主视图容器
/// 负责为日志内容提供独立的导航堆栈，支持在设置页或侧边栏中嵌入
struct LogView: View {
    var body: some View {
        LogViewContent()
    }
}

// MARK: - 视图核心
/// 操作日志核心内容列表视图
/// 负责从存储引擎加载日志条目，处理清空逻辑，并管理条目的展开/折叠状态
struct LogViewContent: View {
    @Environment(AppStore.self) var store
    @State private var expandedEntryIDs: Set<UUID> = []
    @State private var showConfirmation = false

    var body: some View {
        List {
            if store.logEntries.isEmpty {
                VStack(spacing: AppUI.medium) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: AppUI.Timeline.emptyIconSize))
                        .foregroundStyle(.appSecondary)
                    Text(Localized.tr("log.noLogs"))
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                    Text(Localized.tr("log.noLogs"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppUI.loosePadding * 1.5)
            } else {
                ForEach(store.logEntries) { entry in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedEntryIDs.contains(entry.id) {
                                expandedEntryIDs.remove(entry.id)
                            } else {
                                expandedEntryIDs.insert(entry.id)
                            }
                        }
                    }) {
                        LogEntryRow(
                            entry: entry,
                            isExpanded: expandedEntryIDs.contains(entry.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#endif
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(L10n.Settings.tr("operationLog"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Label(L10n.Common.tr("clear"), systemImage: "trash.slash.fill")
                }
            }
        }
        .confirmationDialog(
            Localized.tr("log.clearConfirmTitle"),
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Common.tr("clearAll"), role: .destructive) {
                HapticFeedback.shared.trigger(.warning)
                store.clearLogs()
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.Settings.tr("clearAll.message"))
        }
#if os(iOS)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
#endif
    }
}

// MARK: - 日志项渲染
/// 日志条目行渲染组件
/// 负责展示单条日志的动词、目标对象、模块、时间戳，并在展开时显示耗时详情与原始元数据
private struct LogEntryRow: View {
    let entry: LogEntry
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.small - 2) {
            HStack(spacing: AppUI.medium) {
                // 动作图标
                ZStack {
                    Circle()
                        .fill(Color.fromModelColorName(entry.action.colorName).opacity(0.1))
                        .frame(width: AppUI.Timeline.iconCircleSize, height: AppUI.Timeline.iconCircleSize)
                    
                    Image(systemName: entry.action.icon)
                        .foregroundStyle(Color.fromModelColorName(entry.action.colorName))
                        .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.action.localizedName)
                            .font(.headline)
                            .foregroundStyle(Color.fromModelColorName(entry.action.colorName))
                        
                        Text(entry.target)
                            .font(.headline)
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        
                        if let mod = entry.module {
                            Text(mod)
                                .font(.system(size: AppUI.microFontSize - 1, weight: .bold))
                                .padding(.horizontal, AppUI.tiny)
                                .padding(.vertical, 1)
                                .background(Color.appSecondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius - 1))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    
                    HStack(spacing: AppUI.tightPadding) {
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        
                        if let dur = entry.duration {
                            Text("•")
                            Text(String(format: "%.2fs", dur))
                                .foregroundStyle(.appAccent)
                        }
                        
                        if entry.action == .error {
                            Text("•")
                            Text(L10n.Common.tr("failed"))
                                .foregroundStyle(.red)
                        } else if entry.duration != nil {
                            Text("•")
                            Text(L10n.Common.tr("success"))
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: AppUI.medium) {
                    // 时间详情
                    HStack(spacing: AppUI.wide) {
                        if let start = entry.startTime {
                            VStack(alignment: .leading) {
                                Text(Localized.tr("log.startTime"))
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(start.formatted(date: .omitted, time: .standard))
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                        
                        if let end = entry.endTime {
                            VStack(alignment: .leading) {
                                Text(Localized.tr("log.endTime"))
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(end.formatted(date: .omitted, time: .standard))
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                        
                        if let dur = entry.duration {
                            VStack(alignment: .leading) {
                                Text(Localized.tr("log.duration"))
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(String(format: "%.2fs", dur))
                                    .font(.system(.caption2, design: .monospaced).bold())
                                    .foregroundStyle(.appAccent)
                            }
                        }
                    }
                    .padding(.horizontal, AppUI.Timeline.detailHorizontalPadding)
                    .padding(.vertical, AppUI.Timeline.detailVerticalPadding)
                    .background(Color.appCard.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))

                    if !entry.details.isEmpty {
                        Text(entry.details)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.appSecondary)
                            .padding(AppUI.Timeline.detailHorizontalPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
                    }
                }
                .padding(.leading, AppUI.Timeline.indentPadding)
                .padding(.top, AppUI.tiny)
            }
        }
        .padding(.vertical, AppUI.Timeline.rowVerticalPadding)
    }

}
