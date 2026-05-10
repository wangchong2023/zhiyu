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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var expandedEntryIDs: Set<UUID> = []
    @State private var showConfirmation = false

    var body: some View {
        List {
            if store.logEntries.isEmpty {
                VStack(spacing: AppUI.medium) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: AppUI.Timeline.emptyIconSize))
                        .foregroundStyle(.appSecondary)
                    Text(L10n.Log.noLogs)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                    Text(L10n.Log.noLogs)
                        .font(.caption)
                        .foregroundStyle(.appSecondary.opacity(AppUI.secondaryOpacity))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppUI.loosePadding * 1.5)
            } else {
                ForEach(store.logEntries) { entry in
                    Button(action: {
                        withAnimation(.easeInOut(duration: AppUI.Animation.standardDuration)) {
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
        .background(themeManager.pageBackground())
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
            L10n.Log.clearConfirmTitle,
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
        .scrollContentBackground(.hidden)
        .background(AppUI.Background.pageBackground(accentColor: .appAccent))
#if os(iOS)
        .toolbarBackground(.visible, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) { // 6
            HStack(spacing: AppUI.medium) {
                // 动作图标
                ZStack {
                    Circle()
                        .fill(Color.fromModelColorName(entry.action.colorName).opacity(AppUI.dimmedOpacity * 0.5)) // 0.1
                        .frame(width: AppUI.Timeline.iconCircleSize, height: AppUI.Timeline.iconCircleSize)
                    
                    Image(systemName: entry.action.icon)
                        .foregroundStyle(Color.fromModelColorName(entry.action.colorName))
                        .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: AppUI.atomic) {
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
                                .font(.system(size: AppUI.microFontSize - AppUI.atomic / 2, weight: .bold)) // 9
                                .padding(.horizontal, AppUI.tiny)
                                .padding(.vertical, AppUI.atomic / 2) // 1
                                .background(Color.appSecondary.opacity(AppUI.glassOpacity))
                                .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius - AppUI.atomic / 2)) // 3
                                .foregroundStyle(.appSecondary)
                        }
                        
                        Spacer()
                        
                        // 状态标签
                        if let status = entry.status {
                            Text(status.localizedName)
                                .font(.system(size: AppUI.caption2FontSize - AppUI.atomic / 2, weight: .bold)) // 10
                                .padding(.horizontal, AppUI.small - AppUI.atomic) // 6
                                .padding(.vertical, AppUI.atomic)
                                .background(status == .success ? Color.green.opacity(AppUI.glassOpacity) : Color.red.opacity(AppUI.glassOpacity))
                                .foregroundStyle(status == .success ? .green : .red)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: AppUI.tightPadding) {
                        if let start = entry.startTime, let end = entry.endTime {
                            Text("\(start.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: Localized.currentLocale))) - \(end.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: Localized.currentLocale)))")
                        } else {
                            Text(entry.timestamp.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Localized.currentLocale)))
                        }
                        
                        if let dur = entry.duration {
                            Text("•")
                            Text(dur.formattedAdaptive)
                                .foregroundStyle(.appAccent)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                }

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
                                Text(L10n.Log.startTime)
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(start.formatted(Date.FormatStyle(date: .omitted, time: .standard, locale: Localized.currentLocale)))
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                        
                        if let end = entry.endTime {
                            VStack(alignment: .leading) {
                                Text(L10n.Log.endTime)
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(end.formatted(Date.FormatStyle(date: .omitted, time: .standard, locale: Localized.currentLocale)))
                                    .font(.system(.caption2, design: .monospaced))
                            }
                        }
                        
                        if let dur = entry.duration {
                            VStack(alignment: .leading) {
                                Text(L10n.Log.duration)
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                                Text(dur.formattedAdaptive)
                                    .font(.system(.caption2, design: .monospaced).bold())
                                    .foregroundStyle(.appAccent)
                            }
                        }
                    }
                    .padding(.horizontal, AppUI.Timeline.detailHorizontalPadding)
                    .padding(.vertical, AppUI.Timeline.detailVerticalPadding)
                    .background(Color.appCard.opacity(AppUI.disabledOpacity * 1.33)) // 0.4
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))

                    // 失败原因
                    if let reason = entry.failureReason {
                        VStack(alignment: .leading, spacing: AppUI.tiny) {
                            Text(L10n.Log.failureReason)
                                .font(.caption2.bold())
                                .foregroundStyle(.red)
                            Text(reason)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.red.opacity(AppUI.secondaryOpacity))
                        }
                        .padding(AppUI.Timeline.detailHorizontalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(AppUI.dimmedOpacity * 0.25)) // 0.05
                        .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
                    }

                    if !entry.details.isEmpty {
                        Text(entry.details)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.appSecondary)
                            .padding(AppUI.Timeline.detailHorizontalPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppUI.Background.cardBackground())
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
