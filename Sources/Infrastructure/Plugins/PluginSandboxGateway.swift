//
//  PluginSandboxGateway.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Plugins 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 插件沙盒双向通信安全网关 (PluginSandboxGateway)
/// 作为 JavaScript 运行环境与 Swift 原生系统的安全屏障，实施全量网络与持久化数据的 DLP 深度审计。
struct PluginSandboxGateway {
    /// 统一物理限制大小：5MB 载荷上限
    private static let maxPayloadSize = 5 * 1024 * 1024
    
    /// 限制本地存储 Key 最大长度
    private static let maxKeyLength = 256
    
    // MARK: - 网络请求审计
    
    /// 审计并清洗插件发起的异步 Fetch 请求参数
    /// - Parameters:
    ///   - urlString: 目标 URL
    ///   - options: 附加请求选项 (Headers, Body 等)
    ///   - allowedDomains: 插件 manifest 中声明的允许域名白名单列表
    /// - Returns: 净化并构建好的安全 URLRequest
    /// - Throws: 包含域名拦截或大小超限的安全错误说明
    static func auditFetch(url urlString: String, options: [String: Any]?, allowedDomains: [String]) throws -> URLRequest {
        guard let requestURL = URL(string: urlString), let host = requestURL.host else {
            throw NSError(
                domain: "PluginSandboxGateway",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.invalidURL(urlString)]
            )
        }
        
        // 1. 域名安全白名单 DLP 审计
        let isAllowed = allowedDomains.contains(where: { host.contains($0) })
        guard isAllowed else {
            throw NSError(
                domain: "PluginSandboxGateway",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.dlpFetchBlocked(host)]
            )
        }
        
        var request = URLRequest(url: requestURL)
        
        // 2. 网络载荷大小过滤审计
        if let opts = options {
            request.httpMethod = (opts["method"] as? String)?.uppercased() ?? "GET"
            if let headers = opts["headers"] as? [String: String] {
                for (key, val) in headers {
                    request.setValue(val, forHTTPHeaderField: key)
                }
            }
            
            if let body = opts["body"] as? String {
                guard body.utf8.count <= maxPayloadSize else {
                    throw NSError(
                        domain: "PluginSandboxGateway",
                        code: 413,
                        userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.payloadTooLarge]
                    )
                }
                request.httpBody = body.data(using: .utf8)
            }
        }
        
        return request
    }
    
    // MARK: - 持久化数据审计
    
    /// 审计并限制插件通过 saveData 持久化在宿主 App 内部的键值对大小
    /// - Parameters:
    ///   - key: 持久化 Key
    ///   - value: 持久化文本数据
    /// - Throws: 包含存储超限的异常错误
    static func auditStorage(key: String, value: String) throws {
        guard key.count <= maxKeyLength else {
            throw NSError(
                domain: "PluginSandboxGateway",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.keyLengthExceeded(maxKeyLength)]
            )
        }
        
        guard value.utf8.count <= maxPayloadSize else {
            throw NSError(
                domain: "PluginSandboxGateway",
                code: 413,
                userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.payloadTooLarge]
            )
        }
    }
}
