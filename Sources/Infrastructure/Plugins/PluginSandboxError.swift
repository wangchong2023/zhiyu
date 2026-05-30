//
//  PluginSandboxError.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Plugins 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 插件沙盒环境下的安全边界与运行异常错误枚举
public enum PluginSandboxError: Error, LocalizedError {
    /// 目标 URL 无效
    case invalidURL(String)
    /// 域名未在白名单中 (DLP 拦截)
    case dlpFetchBlocked(String)
    /// 请求体或持久化数据超过最大载荷限制
    case payloadTooLarge
    /// 存储键长度超限
    case keyLengthExceeded(Int)
    /// 插件环境执行超时
    case timeout
    /// 预处理异常
    case preProcessException(String)
    /// 后处理异常
    case postProcessException(String)
    /// 数字签名防篡改校验失败
    case invalidSignature
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return L10n.Plugin.Error.invalidURL(url)
        case .dlpFetchBlocked(let host):
            return L10n.Plugin.Error.dlpFetchBlocked(host)
        case .payloadTooLarge:
            return L10n.Plugin.Error.payloadTooLarge
        case .keyLengthExceeded(let maxLen):
            return L10n.Plugin.Error.keyLengthExceeded(maxLen)
        case .timeout:
            // Assuming this exists in Localized strings
            return "Plugin execution timed out."
        case .preProcessException(let reason):
            return L10n.Plugin.Error.preProcessException(reason)
        case .postProcessException(let reason):
            return L10n.Plugin.Error.postProcessException(reason)
        case .invalidSignature:
            return "Failed to load plugin: invalid digital signature or compromised script."
        }
    }
}
