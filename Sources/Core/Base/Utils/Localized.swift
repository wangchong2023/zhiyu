//
//  Localized.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：通用工具函数（向量数学、本地化辅助、ZIP 工具等）。
//
import Foundation

/// 智宇系统支持的语言模式定义。
public enum LanguageMode: String, CaseIterable, Identifiable {
    /// 自动随系统首选语言环境。
    case auto = "auto"
    
    /// 强制英文环境。
    case english = "en"
    
    /// 强制简体中文环境。
    case chinese = "zh-Hans"
    
    /// 遵循 Identifiable 协议的唯一识别码。
    public var id: String { self.rawValue }
    
    /// 针对当前语言模式显示的本地化可读标题。
    public var displayName: String {
        switch self {
        case .auto: return L10n.Settings.languageSystem
        case .english: return L10n.Settings.languageEnglish
        case .chinese: return L10n.Settings.languageChinese
        }
    }
}

/// 智宇本地化翻译执行中枢（Localized）。
/// 托管多语言翻译的实际加载、缓存和查找降级逻辑。
///
/// 架构设计亮点：
/// - 引入了高性能 `cachedBundle` 内存常驻结构，仅当语言环境变更时才重新装载 Bundle，避免滚动长列表时的昂贵文件系统 I/O 损耗。
/// - 支持跨表 Fallback 策略：当在特定垂直业务域（如 `Knowledge`）表查无此 Key 时，自动降级至 `Common` 共享表检索，彻底规避线上 Missing 崩溃。
internal struct Localized {
    
    /// 锁屏障，保证静态缓存读写的并发安全
    private static let cacheLock = NSLock()
    
    /// 缓存的已加载本地化 Bundle 实例，实现内存级常驻。
    nonisolated(unsafe) private static var cachedBundle: Bundle?
    
    /// 当前缓存的 Bundle 对应的语言标识码（如 "zh-Hans" 或 "en"）。
    nonisolated(unsafe) private static var cachedLanguage: String?
    
    /// 获取当前应用处于激活状态的首选语言代码（如 "zh-Hans", "en"）。
    static var currentLanguage: String {
        switch languageMode {
        case .auto: return Bundle.main.preferredLocalizations.first ?? "en"
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }
    
    /// 获取当前生效的 Locale 实例。
    /// 主要供外部强类型日期、时间等自定义格式化器（Formatters）对齐语言环境。
    static var currentLocale: Locale {
        Locale(identifier: currentLanguage)
    }
    
    /// 检查当前系统是否运行于中文（包括各种中文变体）语言环境下。
    static var isChinese: Bool {
        currentLanguage.hasPrefix("zh")
    }
    
    /// 用户在应用偏好设置中手动指定的语言模式。
    static var languageMode: LanguageMode {
        get { LanguageMode(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.languageMode) ?? "auto") ?? .auto }
        set { 
            UserDefaults.standard.set(newValue.rawValue, forKey: AppConstants.Keys.Storage.languageMode)
            // 语言变更时，重置内存常驻的 Bundle 缓存
            clearBundleCache()
        }
    }
    
    /// 清除当前的 Bundle 缓存，迫使下一次翻译查找时执行磁盘装载。
    private static func clearBundleCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cachedBundle = nil
        cachedLanguage = nil
    }
    
    /// 高性能内存缓存获取当前语言的本地化 Bundle。
    /// 仅在当前语言与已缓存语言不一致，或者缓存为空时，才执行磁盘 I/O 检索。
    /// - Returns: 指向对应语言的 `.lproj` 常驻 Bundle 实例。
    private static func getOrLoadBundle() -> Bundle {
        let currentLang = currentLanguage
        
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        // 击中缓存：如果已经装载过相同语言的 Bundle，直接闪回内存对象
        if let cached = cachedBundle, cachedLanguage == currentLang {
            return cached
        }
        
        // 未击中缓存：执行物理路径扫描与重装载
        let bundle: Bundle
        if let path = Bundle.main.path(forResource: currentLang, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
        
        // 缓存实体与时序标记
        cachedBundle = bundle
        cachedLanguage = currentLang
        return bundle
    }
    
    /// 根据传入的本地化 Key 及原请求表名，自动计算路由映射的目标物理表名。
    /// 贯彻 智宇 去中心化多 Catalog 架构。
    /// - Parameters:
    ///   - key: 本地化键名。
    ///   - table: 默认或请求传入的表名。
    /// - Returns: 经过强路由映射后，真实对应的 `.xcstrings` 表名。
    private static func resolveTableName(for key: String, defaultTable table: String) -> String {
        // 1. 全量核心领域路由表映射 (Core Domain Mapping)
        let domainMap: [String: String] = [
            L10nTable.localizable: L10nTable.common,
            L10nTable.accessibility: L10nTable.common,
            L10nTable.search: L10nTable.common,
            
            L10nTable.editor: L10nTable.knowledge,
            L10nTable.creation: L10nTable.knowledge,
            L10nTable.vault: L10nTable.knowledge,
            L10nTable.quiz: L10nTable.knowledge,
            L10nTable.knowledgeBase: L10nTable.knowledge,
            
            L10nTable.chat: L10nTable.ai,
            L10nTable.voice: L10nTable.ai,
            L10nTable.aiTasks: L10nTable.ai,
            
            L10nTable.graph: L10nTable.insight,
            L10nTable.dashboard: L10nTable.insight,
            
            L10nTable.auth: L10nTable.system,
            L10nTable.settings: L10nTable.system,
            L10nTable.lint: L10nTable.system,
            L10nTable.onboarding: L10nTable.system,
            L10nTable.coachmark: L10nTable.system,
            
            L10nTable.sync: L10nTable.ingest,
            L10nTable.transfer: L10nTable.ingest,
            
            L10nTable.collaboration: L10nTable.plugin,
            
            L10nTable.watch: L10nTable.platform,
            L10nTable.widget: L10nTable.platform
        ]
        
        return domainMap[table] ?? table
    }

    /// 获取特定本地化词条文本（支持高性能常驻内存缓存和优雅降级查找）。
    /// - Parameters:
    ///   - key: 本地化 Key。
    ///   - table: 本地化表名。
    /// - Returns: 转换后的本地化多语言文本。
    static func tr(_ key: String, table: String) -> String {
        let resolvedTable = resolveTableName(for: key, defaultTable: table)
        
        // 通过常驻缓存机制，极速获取 Bundle 实例，免去重复实例化 Bundle 磁盘损耗
        let bundle = getOrLoadBundle()
        
        let marker = "MISSING_KEY_MARKER"
        var result = NSLocalizedString(key, tableName: resolvedTable, bundle: bundle, value: marker, comment: "")
        
        // 优雅 Fallback 降级检索：如果在特定的垂直领域表中未找到该 Key，自动降级至 Common 共享表重试
        if result == marker && resolvedTable != "Common" {
            result = NSLocalizedString(key, tableName: "Common", bundle: bundle, value: marker, comment: "")
        }
        
        // 若最终未命中，输出警示信息并返回 Missing 标签，防空崩溃
        if result == marker {
            print(" [L10n" + " Error] Missing" + " Key: \(key)@\(resolvedTable)")
            return "[MISSING: \(key)@\(resolvedTable)]"
        }
        return result
    }
    
    /// 从 Common 默认表中高性能获取特定本地化词条文本。
    /// - Parameter key: 本地化 Key。
    /// - Returns: 本地化翻译内容。
    static func tr(_ key: String) -> String {
        tr(key, table: "Common")
    }
    
    /// 从 Common 默认表中高性能获取特定本地化格式化词条文本。
    /// - Parameters:
    ///   - key: 本地化 Key。
    ///   - args: 动态格式化参数。
    /// - Returns: 动态格式化完成后的本地化多语言文本。
    static func trf(_ key: String, _ args: CVarArg...) -> String {
        return trf(key, table: "Common", arguments: args)
    }
    
    /// 在指定的本地化表中高性能获取词条文本并以传入参数完成格式化。
    /// - Parameters:
    ///   - key: 本地化 Key。
    ///   - table: 目标物理表名。
    ///   - arguments: 参数数组。
    /// - Returns: 格式化后的翻译文本。
    static func trf(_ key: String, table: String, arguments: [CVarArg]) -> String {
        let template = tr(key, table: table)
        return String(format: template, arguments: arguments)
    }
    
    /// 在指定的本地化表中高性能获取词条文本并以传入参数参数组完成格式化。
    /// - Parameters:
    ///   - key: 本地化 Key。
    ///   - table: 目标物理表名。
    ///   - args: 动态格式化参数。
    /// - Returns: 格式化后的翻译文本。
    static func trf(_ key: String, table: String, _ args: CVarArg...) -> String {
        return trf(key, table: table, arguments: args)
    }

    /// 从多语言字典中匹配最佳语言（zh-Hans > zh > en > first）
    /// - Parameters:
    ///   - dict: [语言代码: 值] 字典
    ///   - fallback: 所有语言都不匹配时的默认值
    /// - Returns: 最佳匹配的值
    static func bestMatch(in dict: [String: String], fallback: String = "") -> String {
        let fullId = Locale.current.identifier  // e.g. "zh-Hans_CN"
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"  // e.g. "zh"
        // 1. 完整 ID 前缀匹配 (zh-Hans)
        for key in dict.keys {
            if fullId.hasPrefix(key) { return dict[key] ?? fallback }
        }
        // 2. 仅语言码匹配 (zh)
        for key in dict.keys {
            if key.hasPrefix(langCode) { return dict[key] ?? fallback }
        }
        // 3. en fallback
        if let en = dict["en"] { return en }
        // 4. 任意值
        return dict.values.first ?? fallback
    }
}

/// 智宇本地化资源表名常量定义
private enum L10nTable {
    static let common = "Common"
    static let knowledge = "Knowledge"
    static let ai = "AI"
    static let insight = "Insight"
    static let system = "System"
    static let ingest = "Ingest"
    static let plugin = "Plugin"
    static let platform = "Platform"
    
    // 来源表映射
    static let localizable = "Localizable"
    static let accessibility = "Accessibility"
    static let search = "Search"
    static let editor = "Editor"
    static let creation = "Creation"
    static let vault = "Vault"
    static let quiz = "Quiz"
    static let knowledgeBase = "KnowledgeBase"
    static let chat = "Chat"
    static let voice = "Voice"
    static let aiTasks = "AITasks"
    static let graph = "Graph"
    static let dashboard = "Dashboard"
    static let auth = "Auth"
    static let settings = "Settings"
    static let lint = "Lint"
    static let onboarding = "Onboarding"
    static let coachmark = "Coachmark"
    static let sync = "Sync"
    static let transfer = "Transfer"
    static let collaboration = "Collaboration"
    static let watch = "Watch"
    static let widget = "Widget"
}

/// 智宇全局本地化强类型访问中枢的静态命名空间。
public enum L10n {}

// MARK: - 评估指标本地化强类型适配

extension EvaluationMetric {
    /// 指标在 UI 层对应的本地化多语言显示名称。
    public var displayName: String {
        switch self {
        case .faithfulness: return L10n.Dashboard.stats.faithfulness
        case .relevance: return L10n.Dashboard.stats.relevance
        case .precision: return L10n.Dashboard.stats.precision
        case .hallucinationRate: return L10n.Dashboard.stats.hallucinationRate
        case .citationAccuracy: return L10n.Dashboard.stats.citationAccuracy
        }
    }
}
