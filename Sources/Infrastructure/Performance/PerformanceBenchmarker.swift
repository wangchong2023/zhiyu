//
//  PerformanceBenchmarker.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Performance 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 性能压测工具 (仅限 Debug/Internal 使用)
/// 专门用于验证 50,000+ 文档规模下的系统承载力
@MainActor
final class PerformanceBenchmarker {
    static let shared = PerformanceBenchmarker()

    /// 模拟海量文档导入并测量索引耗时
    func runStressTest(count: Int = 50000, store: any AnyPageStore) async {
        print(" [Benchmark]  \(count) ...")

        let startTime = CFAbsoluteTimeGetCurrent()

        // 批量创建模拟数据
        for i in 1...count {
            if i % 5000 == 0 {
                let currentTotal = await store.pages.count
                print(" [Benchmark]  \(i) ...  DB : \(currentTotal)")
            }

            _ = try? await store.createPage(
                title: "Stress Test Page #\(i)",
                pageType: .raw,
                customIcon: nil,
                content: " \(i)" + "  SQLite" + " FTS5 \(UUID().uuidString)",
                tags: ["benchmark", "stress-test"],
                sourceURL: nil,
                rawSnippet: nil,
                fileSize: nil,
                sourceType: nil
            )
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print(" [Benchmark] ")
        print(" : \(String(format: "%.2f", duration))s")
        print(" : \(String(format: "%.2f", Double(count)/duration)) docs/s")

        // 触发一次全量搜索测试
        await measureSearchPerformance(store: store)
    }

    private func measureSearchPerformance(store: any AnyPageStore) async {
        let query = "Stress Test"
        let startTime = CFAbsoluteTimeGetCurrent()

        let results = await store.searchPages(query: query)

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print(" [Benchmark] \"\(query)\"")
        print(" : \(String(format: "%.2f", duration * 1000))ms")
        print(" : \(results.count)")

        if duration > 0.8 {
            print(" [Warning]  800ms ")
        }
    }
}
