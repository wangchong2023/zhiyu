// AppConfig.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：智宇 (ZhiYu) 全局配置中心
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 智宇 (ZhiYu) 全局配置中心
/// 采用“动态读取 + 静态分区”模式，确保系统的高可配置性与类型安全。
enum AppConfig {
    
    // MARK: - 动态配置加载器
    private nonisolated(unsafe) static var configData: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }()
    
    private static func getNetwork(_ key: String) -> String {
        (configData["network"] as? [String: String])?[key] ?? ""
    }
    
    private static func getPerformance<T>(_ key: String, default: T) -> T {
        (configData["performance"] as? [String: Any])?[key] as? T ?? `default`
    }
    
    private static func getStorage(_ key: String) -> String {
        (configData["storage"] as? [String: String])?[key] ?? ""
    }

    // MARK: - 网络与服务器
    static var productionURL: String { getNetwork("plugin_market_production") }
    static var mockServerURL: String { getNetwork("plugin_market_debug") }
    static var jinaReaderURL: String { getNetwork("jina_reader_base") }
    static var ollamaDefaultURL: String { getNetwork("ollama_base") }
    static var deepseekDefaultURL: String { getNetwork("deepseek_base") }
    
    // MARK: - 性能参数
    static var searchDebounceMS: Int { getPerformance("search_debounce_ms", default: 300) }
    static var rerankTopLimit: Int { getPerformance("rerank_top_limit", default: 10) }
    static var maxLogEntries: Int { getPerformance("max_log_entries", default: 500) }
    static let historyLimit: Int = 8
    
    // MARK: - 存储
    static var logsFileName: String { getStorage("logs_filename") }
    static var pagesFileName: String { getStorage("pages_filename") }
    static var sqliteFileName: String { getStorage("sqlite_filename") }

    // MARK: - AI 检索相关阈值 (业务调优参数)
    struct AI {
        /// 默认模型 Temperature
        static var defaultTemperature: Double { getPerformance("ai_temperature", default: 0.3) }
        /// 向量相似度初始召回阈值
        static var similarityThreshold: Float { getPerformance("similarity_threshold", default: 0.35) }
        /// 多路召回结果数 (Top K)
        static var topKResults: Int { getPerformance("top_k_results", default: 20) }
        /// Rerank 之后的接受阈值
        static var rerankScoreThreshold: Double { getPerformance("rerank_threshold", default: 0.7) }
        /// 最大上下文 Token 长度 (估算)
        static var maxContextLength: Int { getPerformance("max_context_length", default: 3000) }
        /// 页面内容预览截断长度
        static var previewTextLength: Int { getPerformance("preview_text_length", default: 1000) }
        
        static let summaryMaxLength = 200
        static let rewriteTemperature = 0.3
        
        /// 评估模型 (用于 LLM-as-a-Judge)
        static var evaluatorModel: String { getPerformance("evaluator_model", default: AppModel.gpt4o.rawValue) }
        
        /// 默认大模型名称
        static var defaultModel: String { getPerformance("default_model", default: "deepseek-v4-pro") }
    }
    
    // MARK: - UI 交互与动画
    struct UI {
        static let graphLODZoomThreshold: CGFloat = 0.5
        static let sidebarWidth: CGFloat = 280
        static let animationDuration: Double = 0.3
        static let glassOpacity: Double = 0.15
    }

    // MARK: - 插件安全
    static let pluginThrottlingWindow: Double = 0.5
    static let maxCallsPerThrottlingWindow: Int = 50
    static let pluginTimeoutLimit: Double = 0.5
}
