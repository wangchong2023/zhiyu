//
//  AppConfig.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：应用级编译时常量定义（存储 key、超时、默认值等）。
//
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
    
    // MARK: - 内部键名定义
    private enum ConfigKey {
        enum Network: String {
            case pluginMarketProduction = "plugin_market_production"
            case pluginMarketDebug = "plugin_market_debug"
            case modelStoreProduction = "model_store_production"
            case modelStoreDebug = "model_store_debug"
            case jinaReaderBase = "jina_reader_base"
            case ollamaBase = "ollama_base"
            case deepseekBase = "deepseek_base"
            case backendBaseURL = "backend_base_url"
        }
        
        enum Performance: String {
            case searchDebounce = "search_debounce_ms"
            case rerankTopLimit = "rerank_top_limit"
            case maxLogEntries = "max_log_entries"
            case aiTemperature = "ai_temperature"
            case similarityThreshold = "similarity_threshold"
            case topKResults = "top_k_results"
            case rerankThreshold = "rerank_threshold"
            case maxContextLength = "max_context_length"
            case previewTextLength = "preview_text_length"
            case evaluatorModel = "evaluator_model"
            case defaultModel = "default_model"
        }
        
        enum Storage: String {
            case logsFilename = "logs_filename"
            case pagesFilename = "pages_filename"
            case sqliteFilename = "sqlite_filename"
        }
    }

    /// 获取Network
    /// - Parameter key: key
    /// - Returns: 字符串
    private static func getNetwork(_ key: ConfigKey.Network) -> String {
        (configData["network"] as? [String: String])?[key.rawValue] ?? ""
    }
    
    /// 获取Performance
    /// - Parameter key: key
    /// - Parameter default: default
    /// - Returns: 返回值
    private static func getPerformance<T>(_ key: ConfigKey.Performance, default: T) -> T {
        (configData["performance"] as? [String: Any])?[key.rawValue] as? T ?? `default`
    }
    
    /// 获取Storage
    /// - Parameter key: key
    /// - Returns: 字符串
    private static func getStorage(_ key: ConfigKey.Storage) -> String {
        (configData["storage"] as? [String: String])?[key.rawValue] ?? ""
    }

    /// 获取 LLM 提供商 URL
    /// - Parameter provider: 提供商 ID
    /// - Returns: Base URL
    static func llmProviderURL(for provider: String) -> String {
        (configData["llm_providers"] as? [String: String])?[provider] ?? ""
    }

    /// 获取 CDN 资源配置
    /// - Parameter resource: 资源名称
    /// - Returns: CDN URL 或 "local"
    static func cdnResource(_ resource: String) -> String {
        (configData["cdn"] as? [String: String])?[resource] ?? ""
    }

    // MARK: - 网络与服务器
    static var productionURL: String { getNetwork(.pluginMarketProduction) }
    static var mockServerURL: String { getNetwork(.pluginMarketDebug) }

    /// 模型商店 URL（根据环境自动选择）
    static var modelStoreURL: String {
        #if DEBUG
        return getNetwork(.modelStoreDebug)
        #else
        return getNetwork(.modelStoreProduction)
        #endif
    }

    static var jinaReaderURL: String { getNetwork(.jinaReaderBase) }
    static var ollamaDefaultURL: String { getNetwork(.ollamaBase) }
    static var deepseekDefaultURL: String { getNetwork(.deepseekBase) }
    static var backendBaseURL: String { getNetwork(.backendBaseURL) }
    
    // MARK: - 性能参数
    static var searchDebounceMS: Int { getPerformance(.searchDebounce, default: 300) }
    static var rerankTopLimit: Int { getPerformance(.rerankTopLimit, default: 10) }
    static var maxLogEntries: Int { getPerformance(.maxLogEntries, default: 500) }
    
    // MARK: - 存储
    static var logsFileName: String { getStorage(.logsFilename) }
    static var pagesFileName: String { getStorage(.pagesFilename) }
    static var sqliteFileName: String { getStorage(.sqliteFilename) }

    // MARK: - AI 检索相关阈值 (业务调优参数)
    struct AI {
        /// 默认模型 Temperature
        static var defaultTemperature: Double { getPerformance(.aiTemperature, default: 0.3) }
        /// 向量相似度初始召回阈值
        static var similarityThreshold: Float { getPerformance(.similarityThreshold, default: 0.35) }
        /// 多路召回结果数 (Top K)
        static var topKResults: Int { getPerformance(.topKResults, default: 20) }
        /// Rerank 之后的接受阈值
        static var rerankScoreThreshold: Double { getPerformance(.rerankThreshold, default: 0.7) }
        /// 最大上下文 Token 长度 (估算)
        static var maxContextLength: Int { getPerformance(.maxContextLength, default: 3000) }
        /// 页面内容预览截断长度
        static var previewTextLength: Int { getPerformance(.previewTextLength, default: 1000) }
        
        /// 评估模型 (用于 LLM-as-a-Judge)
        static var evaluatorModel: String { getPerformance(.evaluatorModel, default: AppModel.gpt4o.rawValue) }
        
        /// 默认大模型名称
        static var defaultModel: String { getPerformance(.defaultModel, default: "deepseek-v4-pro") }
    }
    
    // MARK: - UI 交互与动画
    struct UI {
        static let graphLODZoomThreshold: CGFloat = 0.5
        static let animationDuration: Double = 0.3
        static let glassOpacity: Double = 0.15
    }

    // MARK: - 插件安全
    static let pluginTimeoutLimit: Double = 0.5
}
