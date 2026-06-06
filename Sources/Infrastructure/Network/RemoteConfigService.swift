//
//  RemoteConfigService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：动态拉取云端大模型白名单 Manifest 与 Agent 智能技能配置的具体服务实现。实现自 Domain 层的 RemoteConfigCapabilities 协议，提供极致的网络容灾及离线本地预设兜底。
//

import Foundation

/// 远程配置拉取具体实现服务类
public final class RemoteConfigService: RemoteConfigCapabilities, Sendable {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    /// 异步拉取云端大模型兼容白名单列表
    public func fetchLLMManifests() async throws -> [LLMManifest] {
        // 根据 DEBUG/RELEASE 环境自动选择 URL
        let remoteURLString = AppConfig.modelStoreURL

        guard let url = URL(string: remoteURLString) else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200 else {
                throw NetworkError.serverError(500, String(data: Data(base64Encoded: "RmV0Y2ggcmVtb3RlIG1vZGVscyBhbGxvd2xpc3QgZmFpbGVkLg==")!, encoding: .utf8)!)
            }

            let apiResponse = try decoder.decode(ApiResponse<[LLMManifest]>.self, from: data)
            if apiResponse.isSuccess, let list = apiResponse.data {
                return list
            }
            throw NetworkError.unexpected(String(data: Data(base64Encoded: "UmVtb3RlIG1vZGVscyBwYXlsb2FkIGlzIGVtcHR5Lg==")!, encoding: .utf8)!)
        } catch {
            Logger.shared.error("[RemoteConfigService] Error, using fallback: \(error)")
            return getFallbackLLMManifests()
        }
    }
    
    /// 异步拉取动态 Agent 智能技能（Prompt 模板及超参限制）集合
    public func fetchAgentSkills() async throws -> [AgentSkill] {
        let remoteURLString = AppConfig.backendBaseURL + "/api/ai/skills/list"
        
        guard let url = URL(string: remoteURLString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.serverError(500, String(data: Data(base64Encoded: "RmV0Y2ggcmVtb3RlIHNraWxscyBsaXN0IGZhaWxlZC4=")!, encoding: .utf8)!)
            }
            
            let apiResponse = try decoder.decode(ApiResponse<[AgentSkill]>.self, from: data)
            if apiResponse.isSuccess, let list = apiResponse.data {
                return list
            }
            throw NetworkError.unexpected(String(data: Data(base64Encoded: "UmVtb3RlIHNraWxscyBwYXlsb2FkIGlzIGVtcHR5Lg==")!, encoding: .utf8)!)
        } catch {
            // 🟢 离线预设兜底，确保日常的【语义分块】、【AI合成】核心技能完全存活
            return getFallbackAgentSkills()
        }
    }
    
    // MARK: - 离线预设与灾备机制 (High-Availability Presets)
    
    /// 从 model_allowlist.json 加载离线预设模型清单
    private func getFallbackLLMManifests() -> [LLMManifest] {
        guard let url = Bundle.main.url(forResource: "model_allowlist", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            return []
        }
        return models.compactMap { dict in
            guard let modelId = dict["modelId"] as? String,
                  let displayName = dict["displayName"] as? String,
                  let vendor = dict["vendor"] as? String else { return nil }
            let params = dict["defaultParameters"] as? [String: Any] ?? [:]
            return LLMManifest(
                modelId: modelId, displayName: displayName, vendor: vendor,
                fileSizeInBytes: (dict["fileSizeInBytes"] as? Int64) ?? 0,
                minDeviceMemoryInGb: (dict["minDeviceMemoryInGb"] as? Double) ?? 0,
                remoteURLString: (dict["remoteURLString"] as? String) ?? "",
                sha256Checksum: (dict["sha256Checksum"] as? String) ?? "",
                parameterCount: (dict["parameterCount"] as? String) ?? "",
                description: (dict["description"] as? String) ?? "",
                defaultParameters: InferenceParameters(
                    temperature: (params["temperature"] as? Double) ?? 0.7,
                    topP: (params["topP"] as? Double) ?? 0.9,
                    topK: (params["topK"] as? Int) ?? 40,
                    maxTokens: (params["maxTokens"] as? Int) ?? 2048)
            )
        }
    }

    /// (废弃：已迁移至 model_allowlist.json)
    private func _getFallbackLLMManifests_old() -> [LLMManifest] {
        return [
            LLMManifest(
                modelId: "gemma-2b-it",
                displayName: "Gemma-2-2B-IT",
                vendor: "Google",
                fileSizeInBytes: 1530000000, // 约 1.4 GB
                minDeviceMemoryInGb: 6.0,    // 最低 6GB 内存，iPhone 15+ 兼容良好
                remoteURLString: "https://cdn.zhiyu.app/models/gemma-2b-it-q4.bin",
                sha256Checksum: "21dbdf737aa7134914101e4a42828a2a7134aa7e42828a2a7134914101e4a428",
                parameterCount: "2B",
                description: "",
                defaultParameters: InferenceParameters(temperature: 0.7, topP: 0.9, topK: 40, maxTokens: 2048)
            ),
            LLMManifest(
                modelId: "llama3-8b-instruct",
                displayName: "Llama-3-8B-Instruct",
                vendor: "Meta",
                fileSizeInBytes: 4610000000, // 约 4.3 GB
                minDeviceMemoryInGb: 12.0,   // 最低需要 12GB 物理内存，仅限 iPad M系列 / Mac
                remoteURLString: "https://cdn.zhiyu.app/models/llama-3-8b-q4.bin",
                sha256Checksum: "a7134aa7e42828a2a7134914101e4a42828a2a7134aa7e42828a2a7134914101e",
                parameterCount: "8B",
                description: "Meta ",
                defaultParameters: InferenceParameters(temperature: 0.6, topP: 0.95, topK: 50, maxTokens: 4096)
            ),
            LLMManifest(
                modelId: "phi3-mini-instruct",
                displayName: "Phi-3-Mini-Instruct",
                vendor: "Microsoft",
                fileSizeInBytes: 2360000000, // 约 2.2 GB
                minDeviceMemoryInGb: 8.0,    // 最低需要 8GB 内存，适合主流 iPhone 真机
                remoteURLString: "https://cdn.zhiyu.app/models/phi-3-mini-q4.bin",
                sha256Checksum: "31dbdf737aa7134914101e4a42828a2a7134aa7e42828a2a7134914101e4a428",
                parameterCount: "3.8B",
                description: " RAG ",
                defaultParameters: InferenceParameters(temperature: 0.5, topP: 0.85, topK: 30, maxTokens: 2048)
            )
        ]
    }
    
    /// 获取本地物理预设的 Agent 智能技能灾备列表
    private func getFallbackAgentSkills() -> [AgentSkill] {
        return [
            AgentSkill(
                skillId: "chunking_formatter",
                displayName: " ",
                description: "",
                systemPromptTemplate: String(data: Data(base64Encoded: "XG57e2lucHV0fX1cbiAzLTUgIEpTT04gU2NoZW1hIA==")!, encoding: .utf8)!,
                tags: ["Tagging", "Offline"],
                customParameters: InferenceParameters(temperature: 0.2, topP: 0.95, maxTokens: 1024)
            ),
            AgentSkill(
                skillId: "presentation_generator",
                displayName: "  Quiz ",
                description: " Markdown ",
                systemPromptTemplate: "\n{{input}}\n '# '  '## ' ",
                tags: ["Synthesis", "Edge-Cloud"],
                customParameters: InferenceParameters(temperature: 0.6, topP: 0.9, maxTokens: 3072)
            ),
            AgentSkill(
                skillId: "link_discovery",
                displayName: " ",
                description: "",
                systemPromptTemplate: "\n{{input}}\n [[]] ",
                tags: ["Graph", "Offline"],
                customParameters: InferenceParameters(temperature: 0.3, topP: 0.8, maxTokens: 2048)
            )
        ]
    }
}
