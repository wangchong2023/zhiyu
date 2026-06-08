//
//  WatchWidgets.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：watchOS 平台实现：语音听写、健康数据同步、紧凑 UI。
//
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 手表端小组件
/// 手表端专用捕获意图（与 ShortcutManager.CaptureIntent 分离，避免元数据冲突）
struct WatchCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = .init("watch.widget.title", table: "Watch")
    static let description = IntentDescription(.init("watch.widget.desc", table: "Watch"))
    static let persistentIdentifier: String = "com.zhiyu.watch.captureIntent"
    
    /// 执行
    /// - Returns: 返回值
    func perform() async throws -> some IntentResult {
        // 点击表盘时由系统拉起 App 并进入采集界面
        return .result()
    }
}

/// 智宇表盘组件
struct WatchCaptureWidget: Widget {
    let kind: String = "WatchCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Watch.widgetCapture)
        .description(L10n.Watch.widgetDescription)
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct Provider: TimelineProvider {
    /// 供系统调用的占位 entry 接口
    func placeholder(in context: Context) -> SimpleEntry {
        makePlaceholder()
    }

    /// 供系统调用的快照数据接口
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        makeSnapshot(completion: completion)
    }

    /// 供系统调用的时间线数据接口
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        makeTimeline(completion: completion)
    }
    
    // MARK: - 单元测试可达逻辑
    
    /// 单元测试可直接调用的占位数据生成逻辑
    func makePlaceholder() -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    /// 单元测试可直接调用的快照数据生成逻辑
    func makeSnapshot(completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    /// 单元测试可直接调用的时间线生成逻辑
    func makeTimeline(completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WatchWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        // 使用带有 Intent 的 Button，点击即触发 App 逻辑
        Button(intent: WatchCaptureIntent()) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.gradient)
                Image(systemName: DesignSystem.Icons.micFill)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .containerBackground(Color.appAccent.gradient, for: .widget)
    }
}
