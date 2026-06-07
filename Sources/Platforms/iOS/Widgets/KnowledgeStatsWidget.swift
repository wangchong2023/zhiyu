//
//  KnowledgeStatsWidget.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：iOS 平台实现：后台任务、Widget、文件归档、Spotlight 索引。
//
import SwiftUI
import WidgetKit

// MARK: - Widget 设计常量（独立于 DesignSystem，Widget Extension 无法引入主 App 模块）

private enum WidgetMetrics {
    static let cardPadding: CGFloat = 16
    static let contentPadding: CGFloat = 12
    static let footerPadding: CGFloat = 18
    static let iconSize: CGFloat = 20
    static let bulletSize: CGFloat = 4
    static let progressBarWidth: CGFloat = 80
    static let widgetCornerRadius: CGFloat = 6
    static let microCornerRadius: CGFloat = 4
}

// MARK: - Timeline Entry
/// 桌面静态小组件的时间线实体
struct KnowledgeStatsEntry: TimelineEntry {
    let date: Date
    let vaultName: String
    let pageCount: Int
    let linkCount: Int
    let tagCount: Int
    let lastUpdatedPages: [(title: String, typeName: String, colorName: String)]
}

// MARK: - Timeline Provider
/// 桌面静态小组件的时间线提供商
struct KnowledgeStatsProvider: TimelineProvider {
    typealias Entry = KnowledgeStatsEntry

    /// placeholder
    /// - Returns: 返回值
    func placeholder(in context: Context) -> KnowledgeStatsEntry {
        fetchWidgetEntry(date: Date())
    }

    /// 获取Snapshot
    /// - Parameter completion: completion
    /// - Returns: 返回值
    func getSnapshot(in context: Context, completion: @escaping (KnowledgeStatsEntry) -> Void) {
        completion(fetchWidgetEntry(date: Date()))
    }

    /// 获取Timeline
    /// - Parameter completion: completion
    /// - Returns: 返回值
    func getTimeline(in context: Context, completion: @escaping (Timeline<KnowledgeStatsEntry>) -> Void) {
        let timeline = calculateTimeline(date: Date())
        completion(timeline)
    }

    /// 核心数据构建方法，供小组件渲染与单元测试直接调用，实现高内聚与100%可测试性
    /// - Parameter date: 基准日期时间
    /// - Returns: 拟真的小组件概览数据实体
    func fetchWidgetEntry(date: Date) -> KnowledgeStatsEntry {
        return KnowledgeStatsEntry(
            date: date,
            vaultName: WidgetL10n.vaultName,
            pageCount: AppConstants.Demo.mockPageCount,
            linkCount: AppConstants.Demo.mockLinkCount,
            tagCount: AppConstants.Demo.mockTagCount,
            lastUpdatedPages: [
                ("Planning (Concept)", "concept", "accent"),
                ("Memory (Concept)", "concept", "accent"),
                (WidgetL10n.vaultName, "entity", "purple")
            ]
        )
    }

    /// 核心时间线刷新策略计算方法，解耦系统级 Context 依赖，便于在单元测试中直接施加断言
    /// - Parameter date: 触发时间线的起始基准日期
    /// - Returns: 计算好的 Timeline
    func calculateTimeline(date: Date) -> Timeline<KnowledgeStatsEntry> {
        // 核心安全策略：每 30 分钟刷新一次小组件，限制能耗开销
        let nextUpdate = date.addingTimeInterval(AppConstants.Demo.widgetRefreshIntervalMinutes * 60)
        let entry = fetchWidgetEntry(date: date)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

}

// MARK: - Widget View
/// 桌面静态小组件的主体渲染视图
struct KnowledgeStatsWidgetEntryView: View {
    var entry: KnowledgeStatsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // 背景：采用智宇标志性的沉浸式暗色渐变
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.11, blue: 0.18), Color(red: 0.06, green: 0.07, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 霓虹光环点缀 (Platinum UI Design)
            RadialGradient(
                colors: [Color.purple.opacity(0.15), Color.clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 180
            )

            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            case .systemExtraLarge:
                // iPad 超大尺寸：复用 Large 布局
                largeView
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                // 锁屏/StandBy 辅助小组件：降级展示紧凑摘要
                smallView
            @unknown default:
                smallView
            }
        }
        // 应用 WidgetKit 最新的内容边距安全策略
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // MARK: - Small 尺寸布局
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "books.vertical.fill")
                    .font(.footnote)
                    .foregroundStyle(.purple)
                Text(entry.vaultName)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.pageCount)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                
                Text(WidgetL10n.vaultName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                statItem(label: WidgetL10n.links, value: "\(entry.linkCount)", color: .blue)
                statItem(label: WidgetL10n.tags, value: "\(entry.tagCount)", color: .orange)
            }
        }
        .padding(WidgetMetrics.contentPadding)
    }

    // MARK: - Medium 尺寸布局
    private var mediumView: some View {
        HStack(spacing: 16) {
            // 左侧：数据面板
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.purple)
                        .font(.caption)
                    Text(entry.vaultName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    mainStatItem(label: WidgetL10n.vaultName, value: "\(entry.pageCount)", color: .purple)
                    mainStatItem(label: WidgetL10n.links, value: "\(entry.linkCount)", color: .blue)
                }
                
                HStack(spacing: 16) {
                    mainStatItem(label: WidgetL10n.tags, value: "\(entry.tagCount)", color: .orange)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            // 右侧：Deep Link 快捷操作区
            VStack(spacing: 8) {
                actionButton(label: WidgetL10n.vaultName, icon: "plus.circle.fill", color: .purple, url: "zhiyu://create")
                actionButton(label: WidgetL10n.aiChat, icon: "sparkles", color: .blue, url: "zhiyu://chat")
                actionButton(label: WidgetL10n.search, icon: "magnifyingglass", color: .orange, url: "zhiyu://search")
            }
            .frame(width: WidgetMetrics.progressBarWidth)
        }
        .padding(WidgetMetrics.cardPadding)
    }

    // MARK: - Large 尺寸布局
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶半部复用 Medium 的统计信息
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text(entry.vaultName)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 24) {
                        mainStatItem(label: WidgetL10n.vaultName, value: "\(entry.pageCount)", color: .purple)
                        mainStatItem(label: WidgetL10n.links, value: "\(entry.linkCount)", color: .blue)
                        mainStatItem(label: WidgetL10n.tags, value: "\(entry.tagCount)", color: .orange)
                    }
                }
                
                Spacer()
                
                // 快捷大按钮
                Link(destination: URL(string: "zhiyu://chat")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text(WidgetL10n.ai)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.purple))
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // 下半部：最近更新的知识页卡片列表
            VStack(alignment: .leading, spacing: 10) {
                Text(WidgetL10n.vaultName)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
                
                ForEach(entry.lastUpdatedPages.indices, id: \.self) { index in
                    let page = entry.lastUpdatedPages[index]
                    HStack(spacing: 8) {
                        Image(systemName: page.typeName == "concept" ? "lightbulb.fill" : "person.text.rectangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(page.colorName == "accent" ? .blue : .purple)
                            .frame(width: WidgetMetrics.iconSize, height: WidgetMetrics.iconSize)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: WidgetMetrics.microCornerRadius))
                        
                        Text(page.title)
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: WidgetMetrics.widgetCornerRadius))
                }
            }
        }
        .padding(WidgetMetrics.footerPadding)
    }

    // MARK: - 辅助子视图构建
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: WidgetMetrics.bulletSize, height: WidgetMetrics.bulletSize)
            Text("\(label):")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    private func mainStatItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
    
    private func actionButton(label: String, icon: String, color: Color, url: String) -> some View {
        Link(destination: URL(string: url) ?? URL(string: "about:blank")!) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: WidgetMetrics.widgetCornerRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: WidgetMetrics.widgetCornerRadius))
        }
    }
}

// MARK: - Widget Definition
/// 智宇静态桌面小组件定义
struct KnowledgeStatsWidget: Widget {
    let kind: String = "KnowledgeStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KnowledgeStatsProvider()) { entry in
            KnowledgeStatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetL10n.title)
        .description(WidgetL10n.vaultName)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
