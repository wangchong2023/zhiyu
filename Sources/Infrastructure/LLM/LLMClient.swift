//
//  LLMClient.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 LLM 模块，提供相关的结构体或工具支撑。
//
import Foundation

// MARK: - LLM 客户端协议

/// LLM 客户端抽象，支持 Mock 替换
protocol LLMClientProtocol: Sendable {

    /// 发送请求
    /// - Parameter body: body
    func sendRequest(body: [String: Any]) async throws -> [String: Any]

    /// 发送Streaming请求
    /// - Parameter body: body
    func sendStreamingRequest(body: [String: Any]) async throws -> URLSession.AsyncBytes
}

// MARK: - LLM 网络客户端

/// 负责与兼容 OpenAI 协议的 LLM API 进行所有网络通信。
class LLMClient: LLMClientProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let baseURL: String
    private let apiKey: String
    
    // MARK: - Constants
    private static let defaultTimeout: TimeInterval = 90
    private static let streamingTimeout: TimeInterval = 180
    private static let maxRetries = 3
    
    // MARK: - Initialization
    
    /// 初始化 LLM 客户端
    /// - Parameters:
    ///   - baseURL: API 基础路径
    ///   - apiKey: API 密钥
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Private Methods
    
    private var normalizedBaseURL: String {
        baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    }
    
    // MARK: - Standard Request
    
    /// 发送非流式对话补全请求 (支持自动重试机制)
    /// - Parameter body: 请求体字典
    /// - Returns: API 响应字典
    /// - Throws: 网络或 API 错误
    func sendRequest(body: [String: Any]) async throws -> [String: Any] {
        var lastError: Error?
        
        for attempt in 0..<Self.maxRetries {
            do {
                return try await performRequest(body: body)
            } catch {
                lastError = error
                // 仅针对网络波动或 429 错误进行重试
                if shouldRetry(error: error, attempt: attempt) {
                    let delay = pow(2.0, Double(attempt)) // 指数退避: 1s, 2s, 4s
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
        throw lastError ?? LLMError.invalidResponse
    }

    private func performRequest(body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "\(normalizedBaseURL)/chat/completions") else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Self.defaultTimeout
        
        let httpBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 { throw LLMError.unauthorized }
        if httpResponse.statusCode == 429 { throw LLMError.rateLimited }
        
        guard httpResponse.statusCode == 200 else {
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorBody["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMError.apiError(message)
            }
            throw LLMError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        
        return json
    }

    private func shouldRetry(error: Error, attempt: Int) -> Bool {
        if attempt >= Self.maxRetries - 1 { return false }
        
        if let llmError = error as? LLMError {
            switch llmError {
            case .rateLimited, .httpError(500), .httpError(502), .httpError(503), .httpError(504):
                return true
            default:
                return false
            }
        }
        
        // 处理基础网络错误 (超时、断网等)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(nsError.code)
        }
        
        return false
    }
    
    // MARK: - Streaming Request
    
    /// 发送流式对话补全请求，返回原始 AsyncBytes 流
    /// - Parameter body: 请求体字典
    /// - Returns: 异步字节流
    /// - Throws: 网络或 API 错误
    func sendStreamingRequest(body: [String: Any]) async throws -> URLSession.AsyncBytes {
        guard let url = URL(string: "\(normalizedBaseURL)/chat/completions") else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Self.streamingTimeout
        
        let httpBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = httpBody
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        return bytes
    }
}

// MARK: - SSE 解析器

/// 负责从流式响应中解析服务器发送事件 (SSE)。
final class SSEParser {

    /// 解析
    /// - Parameter bytes: bytes
    /// - Returns: 返回值
    static func parse(bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let dataString = String(line.dropFirst(6))
                        if dataString == "[DONE]" { break }
                        
                        guard let data = dataString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
