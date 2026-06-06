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
    private static let defaultTimeout: TimeInterval = 30
    private static let streamingTimeout: TimeInterval = 30
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

    /// 解析 SSE 字节流为文本 chunk 序列。
    /// 兼容 OpenAI / DeepSeek / Qwen / Zhipu 等主流提供商的流式格式差异。
    ///
    /// - Parameter bytes: URLSession 异步字节流
    /// - Parameter logger: 可选的诊断日志记录器，用于排查格式兼容问题
    /// - Returns: 逐 chunk 产出的文本流
    static func parse(
        bytes: URLSession.AsyncBytes,
        logger: (any LoggerProtocol)? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var lineCount = 0
                var chunkCount = 0
                var rawLinesForDiagnostic: [String] = []
                do {
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        lineCount += 1

                        // 诊断：记录前 15 行 SSE 数据，用于排查不同提供商的格式差异
                        if let logger, lineCount <= 15 {
                            let preview = String(line.prefix(250))
                            rawLinesForDiagnostic.append(preview)
                            if !preview.isEmpty {
                                logger.debug("[SSE] L\(lineCount): \(preview)")
                            }
                        }

                        // 兼容 "data: xxx" 和 "data:xxx"（无空格）两种格式
                        let dataPrefix = "data:"
                        guard line.hasPrefix(dataPrefix) else { continue }
                        let dataString = String(line.dropFirst(line.hasPrefix("data: ") ? 6 : 5))

                        if dataString == "[DONE]" { break }

                        guard let data = dataString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            if let logger, !dataString.isEmpty {
                                logger.debug("[SSE] 跳过非 JSON 行: \(String(dataString.prefix(120)))")
                            }
                            continue
                        }

                        // 兼容多种主流提供商的流式字段差异:
                        //   标准 OpenAI → delta.content
                        //   DeepSeek v4 Pro 等推理模型 → delta.reasoning_content
                        //   非流式回退 → message.content
                        if let choices = json["choices"] as? [[String: Any]],
                           let first = choices.first {
                            let content: String?
                            if let delta = first["delta"] as? [String: Any] {
                                // 优先取 content；推理模型文本走 reasoning_content
                                content = (delta["content"] as? String)
                                    ?? (delta["reasoning_content"] as? String)
                            } else if let message = first["message"] as? [String: Any] {
                                content = (message["content"] as? String)
                                    ?? (message["reasoning_content"] as? String)
                            } else {
                                content = nil
                            }

                            if let content, !content.isEmpty {
                                chunkCount += 1
                                continuation.yield(content)
                            }
                        }
                    }

                    if let logger {
                        logger.debug("[SSE] 流结束 — \(lineCount) 行, \(chunkCount) chunk")
                    }
                    continuation.finish()
                } catch {
                    if let logger {
                        logger.error("[SSE] 流解析异常 — 已读 \(lineCount) 行, \(chunkCount) chunk", error: error)
                        if !rawLinesForDiagnostic.isEmpty {
                            logger.debug("[SSE] 异常前收到的原始行:\n\(rawLinesForDiagnostic.joined(separator: "\n"))")
                        }
                    }
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}