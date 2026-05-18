// PromptSanitizer.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：AI 提示词输入脱敏工具。
// 旨在识别并拦截针对大语言模型 (LLM) 的恶意指令注入（Prompt Injection）攻击。
// 版本: 1.0
// 修改记录:
//   - 2026-05-16: 初始版本：建立基础正则表达式过滤机制 (@P0)。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Infra] Prompt 注入防护工具
/// 负责对进入 LLM 的外部数据进行清洗与风险评估。
public struct PromptSanitizer: Sendable {
    
    /// 恶意指令模式库 (基于常用攻击向量)
    private static let maliciousPatterns: [String] = [
        #"(?i)ignore\s+(all\s+)?(previous|prior)\s+instructions"#, // 忽略之前指令
        #"(?i)ignore\s+(everything|all\s+above|the\s+above)"#,     // 忽略上述所有内容
        #"(?i)disregard\s+the\s+above"#,                          // 漠视上方内容
        #"(?i)you\s+are\s+now\s+a\s+developer"#,                  // 角色窃取
        #"(?i)system\s+override"#,                                // 系统覆盖
        #"(?i)reveal\s+your\s+system\s+prompt"#,                  // 泄露系统提示词
        #"(?i)output\s+the\s+entire\s+prompt"#,                   // 输出完整提示词
        #"(?i)jailbreak"#,                                        // 越狱词汇
        #"(?i)do\s+not\s+follow"#,                                // 不遵循指令
        #"(?i)dan\s+mode"#,                                       // 臭名昭著的 DAN 模式
        #"(?i)stay\s+in\s+character"#,                            // 强制保持角色
        #"(?i)exec\s*\(.*\)"#                                     // 代码执行意图
    ]
    
    /// 执行深度清洗
    /// - Parameter rawInput: 原始输入字符串
    /// - Returns: 清洗后的安全字符串，若检测到高危攻击则返回 nil 或 预设警告。
    public static func sanitize(_ rawInput: String) -> String {
        var sanitized = rawInput
        
        // 1. 拦截危险字符序列 (例如 Markdown 注释注入)
        sanitized = sanitized.replacingOccurrences(of: "<!--", with: "&lt;!--")
        sanitized = sanitized.replacingOccurrences(of: "-->", with: "--&gt;")
        
        // 2. 检查恶意指令模式
        for pattern in maliciousPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: sanitized.utf16.count)
                if regex.firstMatch(in: sanitized, options: [], range: range) != nil {
                    // 如果发现攻击向量，我们不直接阻断（防止误伤），而是进行“语义降噪”
                    // 将其替换为非指令性的描述文本
                    sanitized = "[指令注入拦截: \(pattern)]" 
                }
            }
        }
        
        return sanitized
    }
    
    /// 评估输入风险等级
    /// - Parameter input: 待评估内容
    /// - Returns: 是否包含高危指令
    public static func containsHighRiskInstruction(_ input: String) -> Bool {
        for pattern in maliciousPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: input.utf16.count)
                if regex.firstMatch(in: input, options: [], range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
}
