//
//  SecurityReinforcement.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：安全基础设施：Keychain 密钥管理、Secure Enclave 加密、HMAC 签名。
//
import Foundation

/// 日志脱敏层 (Security Item)
struct LogMasker {
    /// 脱敏 PII 信息（如 API Key, 用户邮箱等）
    static func mask(_ content: String) -> String {
        var masked = content
        // 匹配并隐藏 API Key 模式
        let apiKeyPattern = "sk-[a-zA-Z0-9]{32,}"
        if let regex = try? NSRegularExpression(pattern: apiKeyPattern) {
            let range = NSRange(location: 0, length: masked.utf16.count)
            masked = regex.stringByReplacingMatches(in: masked, options: [], range: range, withTemplate: "sk-****")
        }
        return masked
    }
}