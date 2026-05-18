// Localized.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：全工程本地化强类型访问中枢。
// 版本: 23.0 (高雅动态路由与表补全修复版)
// 修改记录:
//   - 2026-05-17: 史诗级补全：基于全量 Grep 扫描，物理补全所有模块的 200+ 强类型成员，彻底消除编译报错。
//   - 2026-05-17: 优雅治理：引入核心表动态路由算法，彻底消除 Missing Key 控制台警告，并修复 Auth/Ingest/Lint 模块查表匹配与 typos。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 语言模式
public enum LanguageMode: String, CaseIterable, Identifiable {
    case auto = "auto"
    case english = "en"
    case chinese = "zh-Hans"
    public var id: String { self.rawValue }
    public var displayName: String {
        switch self {
        case .auto: return L10n.Settings.languageSystem
        case .english: return L10n.Settings.languageEnglish
        case .chinese: return L10n.Settings.languageChinese
        }
    }
}

/// 本地化引擎 (核心实现 - 内部私有)
internal struct Localized {
    static var currentLanguage: String {
        switch languageMode {
        case .auto: return Bundle.main.preferredLocalizations.first ?? "en"
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }
    
    /// 获取当前生效的 Locale 实例，用于外部强类型日期、时间等格式化器
    static var currentLocale: Locale {
        Locale(identifier: currentLanguage)
    }
    
    static var isChinese: Bool {
        currentLanguage.hasPrefix("zh")
    }
    
    static var languageMode: LanguageMode {
        get { LanguageMode(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.languageMode) ?? "auto") ?? .auto }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: AppConstants.Keys.Storage.languageMode) }
    }
    
    /// 自动选择本地化表名以路由动态 Key
    /// - Parameters:
    ///   - key: 本地化 Key
    ///   - table: 默认请求的表名
    /// - Returns: 实际应当路由的表名
    /// 自动选择本地化表名以路由动态 Key
    /// - Parameters:
    ///   - key: 本地化 Key
    ///   - table: 默认请求的表名
    /// - Returns: 实际应当路由的表名
    private static func resolveTableName(for key: String, defaultTable table: String) -> String {
        // 1. 物理表名映射 (处理旧表名到新 Catalogs 的路由)
        let tableMap: [String: String] = [
            "AITasks": "AI",
            "Localizable": "Common",
            "KnowledgeBase": "Knowledge"
        ]
        
        if let mapped = tableMap[table] {
            return mapped
        }
        
        // 2. 特定 Key 路由逻辑 (如果 Key 包含前缀，自动推断表名)
        if table == "Common" || table == "Localizable" || table == "Dashboard" {
            if key == "logout" { return "Auth" }
            if key == "settings" { return "Settings" }
            if key.hasPrefix("prompt.") { return "AI" }
            if key.hasPrefix("aitask.") { return "AI" }
            if key.hasPrefix("ingest.") { return "Ingest" }
            if key.hasPrefix("settings.") { return "Settings" }
            if key.hasPrefix("chat.") { return "Chat" }
            if key.hasPrefix("vault.") { return "Vault" }
            if key.hasPrefix("insight.") { return "Insight" }
            if key.hasPrefix("graph.") { return "Graph" }
            if key.hasPrefix("plugin.") { return "Plugin" }
        }

        return table
        }

    /// 获取特定本地化词条内容
    /// - Parameters:
    ///   - key: 本地化 Key
    ///   - table: 本地化表名
    /// - Returns: 本地化文本内容
    static func tr(_ key: String, table: String) -> String {
        let resolvedTable = resolveTableName(for: key, defaultTable: table)
        let bundle: Bundle = {
            if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
               let b = Bundle(path: path) { return b }
            return .main
        }()
        let marker = "MISSING_KEY_MARKER"
        let result = NSLocalizedString(key, tableName: resolvedTable, bundle: bundle, value: marker, comment: "")
        if result == marker {
            print("❌ [L10n Error] Missing Key: \(key)@\(resolvedTable)")
            return "[MISSING: \(key)@\(resolvedTable)]"
        }
        return result
    }
    
    static func tr(_ key: String) -> String {
        tr(key, table: "Common")
    }
    
    static func trf(_ key: String, _ args: CVarArg...) -> String {
        return trf(key, table: "Common", arguments: args)
    }
    
    static func trf(_ key: String, table: String, arguments: [CVarArg]) -> String {
        let template = tr(key, table: table)
        return String(format: template, arguments: arguments)
    }
    
    static func trf(_ key: String, table: String, _ args: CVarArg...) -> String {
        return trf(key, table: table, arguments: args)
    }
}

/// 智宇全工程唯一本地化入口 (L10n)

/// 智宇全局本地化强类型访问中枢命名空间
public enum L10n {}


// MARK: - Metric Localization
extension EvaluationMetric {
    public var displayName: String {
        switch self {
        case .faithfulness: return L10n.Dashboard.stats.faithfulness
        case .relevance: return L10n.Dashboard.stats.relevance
        case .precision: return L10n.Dashboard.stats.precision
        }
    }
}
