//
//  VersionInfoFormatter.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/27.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 基础设施层
//  核心职责：将 Info.plist 中的版本号字段格式化为 UI 展示字符串，
//          从 AboutView 中抽离以便独立单元测试。

import Foundation

/// 版本信息格式化器，将 Info.plist 原始字典转换为 UI 展示文本
enum VersionInfoFormatter {

    // MARK: - 版本号展示

    /// 从 infoDictionary 组装版本展示字符串
    /// - Parameter info: `Bundle.main.infoDictionary`，测试时可注入任意字典
    /// - Returns: 格式 `"1.2.3 (342 · abc1234)"`，缺失字段使用 fallback
    static func versionDisplayString(from info: [String: Any]?) -> String {
        guard let info else {
            return "0.0.0 (? · unknown)"
        }
        let version = info["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = info["CFBundleVersion"] as? String ?? "?"
        let hash = info["GIT_SHORT_HASH"] as? String ?? "unknown"
        return "\(version) (\(build) · \(hash))"
    }

    // MARK: - 构建时间展示

    /// 从 infoDictionary 读取 BUILD_TIMESTAMP 并转换为本地化短格式
    /// - Parameter info: `Bundle.main.infoDictionary`，测试时可注入任意字典
    /// - Returns: 格式 `"2026-06-27 15:30"`；无数据返回 `""`；解析失败返回原始值
    static func buildTimestampString(from info: [String: Any]?) -> String {
        guard let info else { return "" }
        let raw = info["BUILD_TIMESTAMP"] as? String
        guard let raw else { return "" }

        // ISO 8601 → 本地化短格式: 2026-06-27T15:30:00Z → 2026-06-27 15:30
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        guard let date = isoFormatter.date(from: raw) else { return raw }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        displayFormatter.timeZone = TimeZone.current
        return displayFormatter.string(from: date)
    }
}
