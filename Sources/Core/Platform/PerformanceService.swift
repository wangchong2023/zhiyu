// PerformanceService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的运行期性能监控与诊断服务，负责资源监控、耗时分析及性能看板数据支撑。
// MARK: [RR-03] 内存占用在常规运行下不得超过 300MB，防止被系统 OOM
// 版本: 1.3
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
#if canImport(MachO)
import MachO
#endif

// MARK: - Performance Service
/// Runtime performance monitoring and diagnostics for Knowledge Base.
@MainActor
final class PerformanceService: ObservableObject {
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    @Published var isMonitoring: Bool = false
    
    struct PerformanceMetrics: Identifiable {
        let id = UUID()
        var pageCount: Int = 0
        var totalWords: Int = 0
        var graphNodeCount: Int = 0
        var graphEdgeCount: Int = 0
        var memoryUsageMB: Double = 0
        var saveDuration: TimeInterval = 0
        var loadDuration: TimeInterval = 0
        var lintDuration: TimeInterval = 0
        var graphLayoutDuration: TimeInterval = 0
        var searchDuration: TimeInterval = 0
        
        // RAG & AI 指标
        var ragChainDuration: TimeInterval = 0
        var llmCallCount: Int = 0
        var aiSuccessRate: Double = 1.0
        
        var lastUpdated: Date = Date()
    }
    
    // MARK: - Timing Helpers
    func measure<T>(_ label: String, operation: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        updateMetric(label, duration: duration)
        return result
    }

    /// 异步测量支持
    func measureAsync<T>(_ label: String, operation: () async throws -> T) async throws -> T {
        let start = CFAbsoluteTimeGetCurrent()
        do {
            let result = try await operation()
            let duration = CFAbsoluteTimeGetCurrent() - start
            updateMetric(label, duration: duration)
            return result
        } catch {
            // 记录失败率
            metrics.aiSuccessRate = (metrics.aiSuccessRate * Double(metrics.llmCallCount) + 0.0) / Double(metrics.llmCallCount + 1)
            throw error
        }
    }

    private func updateMetric(_ label: String, duration: TimeInterval) {
        switch label {
        case "save": metrics.saveDuration = duration
        case "load": metrics.loadDuration = duration
        case "lint": metrics.lintDuration = duration
        case "graphLayout": metrics.graphLayoutDuration = duration
        case "search": metrics.searchDuration = duration
        case "ragChain": metrics.ragChainDuration = duration
        default: break
        }
        
        if label.contains("ai") || label.contains("llm") || label == "ragChain" {
            metrics.llmCallCount += 1
        }
        
        metrics.lastUpdated = Date()
    }
    
    // MARK: - Memory
    func updateMemoryUsage() {
        // Use task_info via Mach API
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kernReturn: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kernReturn == KERN_SUCCESS {
            metrics.memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
        }
    }
    
    // MARK: - Page Metrics
    func updatePageMetrics(pages: [KnowledgePage]) {
        metrics.pageCount = pages.count
        metrics.totalWords = pages.reduce(0) { $0 + $1.wordCount }
        metrics.lastUpdated = Date()
    }
    
    // MARK: - Graph Metrics
    func updateGraphMetrics(nodes: Int, edges: Int) {
        metrics.graphNodeCount = nodes
        metrics.graphEdgeCount = edges
        metrics.lastUpdated = Date()
    }
    
    // MARK: - Summary
    var summary: String {
        """
        \(Localized.tr("perf.summary.title"))
        ━━━━━━━━━━━━━━━━━━━
        \(Localized.tr("perf.summary.pages")): \(metrics.pageCount) (\(metrics.totalWords) \(Localized.tr("perf.summary.words")))
        \(Localized.tr("perf.summary.graph")): \(metrics.graphNodeCount) \(Localized.tr("perf.summary.nodes")), \(metrics.graphEdgeCount) \(Localized.tr("perf.summary.edges"))
        \(Localized.tr("perf.summary.memory")): \(String(format: "%.1f", metrics.memoryUsageMB)) MB
        \(Localized.tr("perf.summary.save")): \(String(format: "%.3f", metrics.saveDuration))s
        \(Localized.tr("perf.summary.load")): \(String(format: "%.3f", metrics.loadDuration))s
        \(Localized.tr("perf.summary.lint")): \(String(format: "%.3f", metrics.lintDuration))s
        \(Localized.tr("perf.summary.graphLayout")): \(String(format: "%.3f", metrics.graphLayoutDuration))s
        \(Localized.tr("perf.summary.search")): \(String(format: "%.3f", metrics.searchDuration))s
        """
    }
}
