// WatchWidgets.swift
//
// 作者: Wang Chong
// 功能说明: 定义表盘点击意图
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 手表端小组件
/// 手表端专用捕获意图（与 ShortcutManager.CaptureIntent 分离，避免元数据冲突）
struct WatchCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = .init("watch.widget.title", defaultValue: "快速记录", table: "Watch")
    static let description = IntentDescription(.init("watch.widget.desc", defaultValue: "直接进入语音采集界面", table: "Watch"))
    static let persistentIdentifier: String = "com.zhiyu.watch.captureIntent"
    
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
        .configurationDisplayName(Localized.tr("watch.widget.displayName", table: "Watch"))
        .description(Localized.tr("watch.widget.displayDesc", table: "Watch"))
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
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
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .containerBackground(Color.appAccent.gradient, for: .widget)
    }
}
