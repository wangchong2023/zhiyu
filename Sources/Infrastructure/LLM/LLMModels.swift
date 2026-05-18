// LLMModels.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件定义了智宇 (ZhiYu) AI 域的核心数据模型，包括服务商元数据、对话消息、任务结果及错误类型。
// 核心职责：
// 1. 提供提供商注册表 (LLMRegistry)，支持动态加载模型配置。
// 2. 定义统一的消息模型 (ChatMessage) 与智能任务结果。
// 3. 实现基于 UserDefaults 与 Keychain 的配置持久化。
// MARK: [SR-02] 混合检索 (RAG) 核心模型与配置中心
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - LLM 提供商元数据

/// LLM 提供商元数据
/// 包含 API 端点、默认模型及 UI 展示参数。
@MainActor
struct LLMProviderMetadata: Codable {
    /// 唯一标识符
    let id: String
    /// 本地化名称键值
    let nameKey: String
    /// API 基础路径
    let baseURL: String
    /// 默认使用的模型名称
    let defaultModel: String
    /// 建议的模型列表
    let suggestedModels: [String]
    /// 显示图标 (SF Symbol)
    let icon: String
}

// MARK: - LLM Registry
final class LLMRegistry {
    nonisolated(unsafe) static let shared = LLMRegistry()
    private var providers: [String: LLMProviderMetadata] = [:]

    private init() {
        loadProviders()
    }

    private func loadProviders() {
        // 首先尝试从 Bundle 加载（Apple 推荐方式）
        if let url = Bundle.main.url(forResource: "LLMProviders", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([LLMProviderMetadata].self, from: data) {
            for item in list {
                providers[item.id] = item
            }
            return
        }

        // 兜底方案：如果 JSON 未能加载（如尚未打包），使用硬编码数据
        let fallbacks: [LLMProviderMetadata] = [
            .init(id: "zhipu", nameKey: "llm.provider.zhipu", baseURL: "https://open.bigmodel.cn/api/paas/v4", defaultModel: "glm-4-flash", suggestedModels: ["glm-4-flash", "glm-4", "glm-4v"], icon: "sparkles"),
            .init(id: "minimax", nameKey: "llm.provider.minimax", baseURL: "https://api.minimax.chat/v1", defaultModel: "abab6.5-chat", suggestedModels: ["abab6.5-chat", "abab5.5-chat"], icon: "cpu"),
            .init(id: "qwen", nameKey: "llm.provider.qwen", baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1", defaultModel: "qwen-plus", suggestedModels: ["qwen-plus", "qwen-max", "qwen-turbo"], icon: "cloud.fill"),
            .init(id: "deepseek", nameKey: "llm.provider.deepSeek", baseURL: "https://api.deepseek.com/v1", defaultModel: "deepseek-v4-pro", suggestedModels: ["deepseek-v4-pro", "deepseek-v4-lite"], icon: "wave.3.forward"),
            .init(id: "kimi", nameKey: "llm.provider.kimi", baseURL: "https://api.moonshot.cn/v1", defaultModel: "moonshot-v1-8k", suggestedModels: ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"], icon: "moon.fill"),
            .init(id: "siliconflow", nameKey: "llm.provider.siliconflow", baseURL: "https://api.siliconflow.cn/v1", defaultModel: "deepseek-ai/DeepSeek-V3", suggestedModels: ["deepseek-ai/DeepSeek-V3", "deepseek-ai/DeepSeek-V2.5", "Qwen/Qwen2.5-72B-Instruct"], icon: "bolt.fill"),
            .init(id: "custom", nameKey: "llm.provider.custom", baseURL: "", defaultModel: "", suggestedModels: ["default"], icon: "server.rack")
        ]
        for item in fallbacks {
            providers[item.id] = item
        }
    }

    /// 根据 ID 获取提供商元数据
    func metadata(for id: String) -> LLMProviderMetadata? {
        providers[id]
    }
}

// MARK: - LLM 提供商枚举
/// 智宇支持的所有 AI 服务商
enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case zhipu = "zhipu"
    case minimax = "minimax"
    case qwen = "qwen"
    case deepSeek = "deepseek"
    case kimi = "kimi"
    case siliconflow = "siliconflow"
    case custom = "custom"

    /// 获取提供商唯一标识
    var id: String { rawValue }

    /// 内部获取关联元数据
    private var metadata: LLMProviderMetadata? {
        LLMRegistry.shared.metadata(for: rawValue)
    }

    /// 本地化显示名称
    var displayName: String {
        if let key = metadata?.nameKey {
            return Localized.tr(key)
        }
        return rawValue.capitalized
    }

    /// 默认 API 基础路径
    var defaultBaseURL: String {
        metadata?.baseURL ?? ""
    }

    /// 默认模型名称
    var defaultModel: String {
        metadata?.defaultModel ?? ""
    }

    /// 建议模型列表
    var suggestedModels: [String] {
        metadata?.suggestedModels ?? ["default"]
    }

    var icon: String {
        metadata?.icon ?? "server.rack"
    }
}

// MARK: - Chat Message
typealias ChatMessage = ChatMessageDTO

// MARK: - Smart Ingest Result
typealias SmartIngestResult = SmartIngestResultDTO

// MARK: - LLM Errors
enum LLMError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(Int)
    case apiError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return L10n.AI.LLM.Error.notConfigured
        case .invalidURL:
            return L10n.AI.LLM.Error.invalidURL
        case .invalidResponse:
            return L10n.AI.LLM.Error.invalidResponse
        case .unauthorized:
            return L10n.AI.LLM.Error.unauthorized
        case .rateLimited:
            return L10n.AI.LLM.Error.rateLimited
        case .httpError(let code):
            return "\(L10n.AI.LLM.Error.httpError): \(code)"
        case .apiError(let message):
            return "\(L10n.AI.LLM.Error.apiError): \(message)"
        case .cancelled:
            return L10n.AI.LLM.Error.cancelled
        }
    }
}

// MARK: - LLM Config (Persistence)
/// Manages LLM provider configuration with UserDefaults + Keychain persistence.
final class LLMConfigStore: ObservableObject {
    @Published var provider: LLMProvider {
        didSet { 
            if oldValue != provider {
                saveConfig()
                // 切换提供商时，自动加载该提供商对应的 API Key
                self.apiKey = loadAPIKey(for: provider)
            }
        }
    }
    @Published var apiKey: String {
        didSet { saveAPIKey(for: provider) }
    }
    @Published var baseURL: String {
        didSet { saveConfig() }
    }
    @Published var model: String {
        didSet { saveConfig() }
    }
    @Published var isEnabled: Bool {
        didSet { saveConfig() }
    }
    @Published var autoScan: Bool {
        didSet { saveConfig() }
    }
    @Published var autoRefactor: Bool {
        didSet { saveConfig() }
    }

    private let configKey = "zhiyu_llm_config"
    private let legacyKeychainAPIKey = "llm_api_key"
    
    private func keychainKey(for provider: LLMProvider) -> String {
        return "llm_api_key_\(provider.rawValue)"
    }

    struct Config: Codable {
        let provider: LLMProvider
        let baseURL: String
        let model: String
        let isEnabled: Bool
        let autoScan: Bool
        let autoRefactor: Bool
    }

    init() {
        var initialProvider: LLMProvider = .deepSeek
        var initialBaseURL = LLMProvider.deepSeek.defaultBaseURL
        var initialModel = LLMProvider.deepSeek.defaultModel
        var initialIsEnabled = false
        var initialAutoScan = true
        var initialAutoRefactor = false

        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(Config.self, from: data) {
            initialProvider = config.provider
            initialBaseURL = config.baseURL
            initialModel = config.model
            initialIsEnabled = config.isEnabled
            initialAutoScan = config.autoScan
            initialAutoRefactor = config.autoRefactor
        }
        
        self.provider = initialProvider
        self.baseURL = initialBaseURL
        self.model = initialModel
        self.isEnabled = initialIsEnabled
        self.autoScan = initialAutoScan
        self.autoRefactor = initialAutoRefactor
        
        // 延迟初始化 apiKey 以支持迁移逻辑
        self.apiKey = "" 
        self.apiKey = loadAPIKey(for: initialProvider)
    }

    private func saveConfig() {
        let config = Config(
            provider: provider,
            baseURL: baseURL,
            model: model,
            isEnabled: isEnabled,
            autoScan: autoScan,
            autoRefactor: autoRefactor
        )
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    private func loadAPIKey(for provider: LLMProvider) -> String {
        let key = keychainKey(for: provider)
        if let value = try? KeychainService.shared.retrieve(key: key) {
            return value
        }
        
        // 迁移逻辑：如果新版分提供商 Key 不存在，尝试读取旧版全局 Key
        if let legacyValue = try? KeychainService.shared.retrieve(key: legacyKeychainAPIKey) {
            // 只有当当前提供商是“默认”或者是“自定义”时才尝试迁移，或者简单地全部尝试迁移一次
            try? KeychainService.shared.store(key: key, value: legacyValue)
            // 可选：迁移后删除旧 Key（慎重，如果用户有多个提供商可能导致丢失）
            // try? KeychainService.shared.delete(key: legacyKeychainAPIKey)
            return legacyValue
        }
        
        return ""
    }

    private func saveAPIKey(for provider: LLMProvider) {
        let key = keychainKey(for: provider)
        guard !apiKey.isEmpty else {
            try? KeychainService.shared.delete(key: key)
            return
        }
        try? KeychainService.shared.store(key: key, value: apiKey)
    }
}
