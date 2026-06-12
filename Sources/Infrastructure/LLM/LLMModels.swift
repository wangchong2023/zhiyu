//
//  LLMModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：大语言模型客户端：多提供商适配、流式响应解析、端侧推理。
//
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
public enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case zhipu = "zhipu"
    case minimax = "minimax"
    case qwen = "qwen"
    case deepSeek = "deepseek"
    case kimi = "kimi"
    case siliconflow = "siliconflow"
    case custom = "custom"

    /// 获取提供商唯一标识
    public var id: String { rawValue }

    /// 内部获取关联元数据
    private var metadata: LLMProviderMetadata? {
        LLMRegistry.shared.metadata(for: rawValue)
    }

    /// 本地化显示名称
    public var displayName: String {
        if let key = metadata?.nameKey {
            return L10n.AI.tr(key)
        }
        return rawValue.capitalized
    }

    /// 默认 API 基础路径
    public var defaultBaseURL: String {
        metadata?.baseURL ?? ""
    }

    /// 默认模型名称
    public var defaultModel: String {
        metadata?.defaultModel ?? ""
    }

    /// 建议模型列表
    public var suggestedModels: [String] {
        metadata?.suggestedModels ?? ["default"]
    }

    public var icon: String {
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

    /// 从安全的 Keychain 或硬件芯片解密加载特定 LLM 提供商的 API 密钥
    /// - Parameter provider: 大模型提供商类型
    /// - Returns: 解密后的 API 密钥。如果失败，支持降级至已加密的本地备份，否则返回空字符串。
    private func loadAPIKey(for provider: LLMProvider) -> String {
        let key = keychainKey(for: provider)
        
        do {
            if let encryptedValue = try KeychainService.shared.retrieve(key: key) {
                if let decrypted = try? SecureEnclaveCryptoService.shared.decrypt(encryptedValue) {
                    return decrypted
                } else {
                    Logger.shared.warning("[LLMConfigStore] 硬件解密 API 密钥失败，可能由于硬件私钥更新。")
                }
            }
        } catch {
            Logger.shared.error("[LLMConfigStore] 从钥匙串读取 API 密钥失败", error: error)
        }
        
        // 迁移逻辑：如果新版分提供商 Key 不存在，尝试读取旧版全局 Key
        if let legacyValue = try? KeychainService.shared.retrieve(key: legacyKeychainAPIKey) {
            // 对迁移上来的明文进行物理级硬件加密，持久化回 Keychain
            if let encrypted = try? SecureEnclaveCryptoService.shared.encrypt(legacyValue) {
                try? KeychainService.shared.store(key: key, value: encrypted)
            }
            return legacyValue
        }

        // 软件级加密兜底：在钥匙串存取受限（如未签名、沙盒受限环境）下，读取经应用级 AES-GCM 加密后的本地备份，避免直接暴露明文
        let fallbackKey = "zhiyu_llm_api_key_fallback_\(provider.rawValue)"
        if let fallbackEncrypted = UserDefaults.standard.string(forKey: fallbackKey) {
            if let decrypted = try? SecurityManager.shared.decrypt(fallbackEncrypted) {
                Logger.shared.debug("[LLMConfigStore] 已启用本地加密备份的 API 密钥兜底。")
                return decrypted
            }
        }

        return ""
    }

    /// 将特定 LLM 提供商的 API 密钥物理加密并安全存储到钥匙串
    /// - Parameter provider: 大模型提供商类型
    private func saveAPIKey(for provider: LLMProvider) {
        let key = keychainKey(for: provider)
        
        // 软件级加密备份：将 API 密钥通过应用级 AES-GCM 软件加密，备份在 UserDefaults，防范 Keychain 写入限制
        let fallbackKey = "zhiyu_llm_api_key_fallback_\(provider.rawValue)"
        if apiKey.isEmpty {
            UserDefaults.standard.removeObject(forKey: fallbackKey)
        } else {
            if let encryptedFallback = try? SecurityManager.shared.encrypt(apiKey) {
                UserDefaults.standard.set(encryptedFallback, forKey: fallbackKey)
            }
        }

        guard !apiKey.isEmpty else {
            try? KeychainService.shared.delete(key: key)
            return
        }
        
        do {
            // 引入 Secure Enclave 硬件安全芯片物理级锁定
            let encrypted = try SecureEnclaveCryptoService.shared.encrypt(apiKey)
            try KeychainService.shared.store(key: key, value: encrypted)
        } catch {
            Logger.shared.error("[LLMConfigStore] 写入加密的 API 密钥至钥匙串失败", error: error)
        }
    }
}
