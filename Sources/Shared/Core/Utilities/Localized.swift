// Localized.swift
//
// 作者: Wang Chong
// 功能说明: 语言偏好选项
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Language Mode
/// 语言偏好选项
enum LanguageMode: String, CaseIterable {
    case system
    case chinese
    case english

    var displayName: String {
        switch self {
        case .system: return L10n.Settings.tr("language.system")
        case .chinese: return L10n.Settings.tr("language.chinese")
        case .english: return L10n.Settings.tr("language.english")
        }
    }

    var icon: String {
        switch self {
        case .system:  return "globe"                      // 跟随系统
        case .chinese: return "globe.asia.australia.fill"  // 简体中文
        case .english: return "globe.americas.fill"        // English
        }
    }
}

// MARK: - Localization Helper
/// String Catalog 原生支持的本地化系统.
/// 使用直接读取 .strings 文件的方式，确保能响应运行时语言切换.
enum Localized {

    // MARK: - Language Preference
    private static let languageModeKey = "app_language_mode"
    private static var languageModeRaw: String {
        get { UserDefaults.standard.string(forKey: languageModeKey) ?? LanguageMode.system.rawValue }
        set { UserDefaults.standard.set(newValue, forKey: languageModeKey) }
    }

    static var languageMode: LanguageMode {
        get { LanguageMode(rawValue: languageModeRaw) ?? .system }
        set {
            languageModeRaw = newValue.rawValue

            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                let preferred = (newValue == .chinese) ? "zh-Hans" : "en"
                UserDefaults.standard.set([preferred], forKey: "AppleLanguages")
            }

            // 立即刷新提示词服务
            PromptService.shared.updateLocalizables()
        }
    }

    static var currentLanguage: String {
        // 如果设置为跟随系统，或者没有 AppleLanguages 覆盖，则读取系统首选语言
        if languageMode == .system || UserDefaults.standard.stringArray(forKey: "AppleLanguages") == nil {
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        }

        // 读取手动覆盖的语言
        if let appleLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages"),
           let preferred = appleLanguages.first {
            if preferred.hasPrefix("zh") {
                return "zh-Hans"
            }
        }
        return "en"
    }

    static var isChinese: Bool { currentLanguage == "zh-Hans" }

    /**
     * @description: 读取本地化字符串，支持动态语言切换与多表查询
     * @param {String} key 本地化键值
     * @param {String?} table 目标翻译表名称 (String Catalog 文件名)
     * @return {String} 翻译后的文本，若未找到则返回带标记的 Key
     */
    static func tr(_ key: String, table: String? = nil) -> String {
        let lang = currentLanguage

        let result: String
        // 尝试加载对应语言的 Bundle 以支持运行时语言切换
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            result = NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
        } else {
            // Fallback 到标准方式
            result = NSLocalizedString(key, tableName: table, value: key, comment: "")
        }
        
        #if DEBUG
        if result == key && table != "Localizable" {
            print("🔍 [Localization] Lookup failed in table '\(table ?? "Main")' for key: '\(key)'")
        }
        #endif

        // --- 修复逻辑：如果指定的 table 中找不到 (返回了 key 本身)，尝试从默认 Localizable 中找 ---
        if result == key && table != nil && table != "Localizable" {
            let fallbackResult: String
            if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                fallbackResult = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
            } else {
                fallbackResult = NSLocalizedString(key, tableName: "Localizable", value: key, comment: "")
            }
            if fallbackResult != key {
                return fallbackResult
            }
        }

        #if DEBUG
        if result == key && !key.isEmpty && key.contains(".") {
            let lang = currentLanguage
            let path = Bundle.main.path(forResource: lang, ofType: "lproj") ?? "NOT FOUND"
            // 如果返回结果等于 key，通常意味着该 table 中没有对应的翻译条目
            let message = "⚠️ [Localization] Missing key: '\(key)' in table: '\(table ?? "Localizable")' [Lang: \(lang), Path: \(path)]"
            print(message)
            // 返回带标记的字符串以便在 UI 中识别，但不崩溃
            return "[MISSING: \(key)]"
        }
        #endif

        return result
    }

    /**
     * @description: 读取并格式化本地化字符串 (带参数替换)
     * @param {String} key 本地化键值
     * @param {String?} table 目标翻译表名称
     * @param {CVarArg...} args 格式化变量
     * @return {String} 格式化后的翻译文本
     */
    static func trf(_ key: String, table: String? = nil, _ args: CVarArg...) -> String {
        let template = tr(key, table: table ?? "Localizable")
        if args.isEmpty {
            return template
        }
        return String(format: template, arguments: args)
    }
}

// MARK: - Type-Safe Localization
/// 强类型本地化常量访问器，提供对各功能模块名称及静态文案的集中管理。
struct L10n {
    /// 知识图谱模块：提供语义网状结构的交互与可视化展示。
    struct Graph {
        static func tr(_ key: String) -> String { Localized.tr("graph.\(key)", table: "Graph") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：知识图谱
        static var title: String { tr("title") }
        static var optimizingLayout: String { tr("optimizingLayout") }
        static var insights: String { tr("insights") }
        static var legend: String { tr("legend") }

        struct ThreeD {
            static func tr(_ key: String) -> String { Localized.tr("graph3d.\(key)", table: "Graph") }
        }
    }

    /// 设置模块：管理 AI 模型、语言偏好、存储安全等全局配置。
    struct Settings {
        static func tr(_ key: String) -> String { Localized.tr("settings.\(key)", table: "Settings") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：设置
        static var title: String { tr("settings") }
        static var systemLanguage: String { tr("systemLanguage") }
        static var version: String { tr("version") }
        static var about: String { tr("aboutApp") }
        static var privacyMode: String { tr("privacyMode") }
        static var security: String { tr("section.security") }
        static var accentColor: String { tr("accentColor") }
        static var llmSettings: String { tr("llmConfig") }
        static var onDeviceLLM: String { tr("onDeviceLLM") }
        static var promptLab: String { tr("promptWorkshop") }
        static var iCloudSync: String { tr("iCloudSync") }
        static var backupRestore: String { L10n.Backup.title }
        static var exportAllMarkdown: String { tr("exportMarkdown") }
        static var resetData: String { tr("reset") }
        static var resetConfirmationTitle: String { tr("resetOnboarding.title") }
        static var resetConfirmationMessage: String { tr("resetOnboarding.message") }
        static var privacyModeDesc: String { tr("privacyMode.desc") }
        static var biometricProtection: String { tr("biometricProtection") }
        static var operationLog: String { tr("operationLog") }

        struct Section {
            static var appearance: String { Settings.tr("appearance") }
            static var ai: String { Settings.tr("section.ai") }
            static var data: String { Settings.tr("section.data") }
            static var security: String { Settings.tr("section.security") }
            static var danger: String { Settings.tr("section.danger") }
            static var developer: String { Settings.tr("section.developer") }
        }
    }

    /// AI 智能化模块：处理后台扫描、任务管理及合成逻辑。
    struct AI {
        static func tr(_ key: String) -> String { Localized.tr("ai.\(key)", table: "AITasks") }

        /// 运行时状态反馈
        struct Status {
            static var analyzing: String { AI.tr("status.analyzing") }
            static var preprocessing: String { AI.tr("status.preprocessing") }
            static var scanning: String { AI.tr("status.scanning") }
            static var thinking: String { AI.tr("status.thinking") }
        }

        /// 任务中心 (AITask 前缀)
        struct Task {
            static func tr(_ key: String) -> String { Localized.tr("aitask.\(key)", table: "AITasks") }
            static func trf(_ key: String, _ args: CVarArg...) -> String {
                let template = tr(key)
                return String(format: template, arguments: args)
            }

            /// 页面名称：任务中心
            static var centerTitle: String { tr("center.title") }
            static var emptyTitle: String { tr("empty.title") }
            static var emptyDesc: String { tr("empty.desc") }
            static var clearAll: String { tr("clearAll") }

            struct TypeName {
                static var aiScan: String { Task.tr("type.aiScan") }
                static var healthCheck: String { Task.tr("type.healthCheck") }
                static var synthesis: String { Task.tr("type.synthesis") }
            }
        }
    }

    /// 备份与迁移模块。
    struct Backup {
        static func tr(_ key: String) -> String { Localized.tr("backup.\(key)", table: "Backup") }
        static var title: String { tr("title") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：数据备份
    }

    /// 导入模块：处理文档上传、OCR、网页抓取等入库流程。
    struct Ingest {
        static func tr(_ key: String) -> String { Localized.tr("ingest.\(key)", table: "Ingest") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：导入知识
        static var title: String { tr("title") }
    }

    /// 通用操作按钮与动作定义。
    struct Action {
        static func tr(_ key: String) -> String { Localized.tr("action.\(key)", table: "Actions") }

        static var createPage: String { tr("createPage") }
        static var browseGraph: String { tr("browseGraph") }
        static var ingestKnowledge: String { tr("ingestKnowledge") }
    }

    /// 公共词条库：包含按钮、对话框常用语。
    struct Common {
        static func tr(_ key: String) -> String { Localized.tr("misc.\(key)", table: "Common") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        static var ok: String { tr("ok") }
        static var cancel: String { tr("cancel") }
        static var done: String { tr("done") }
        static var delete: String { tr("delete") }
        static var save: String { tr("save") }
        static var edit: String { tr("edit") }
        static var view: String { tr("view") }
        static var refresh: String { tr("refresh") }

        struct Empty {
            static func tr(_ key: String) -> String { Localized.tr("empty.\(key)", table: "Common") }
        }
    }

    /// 无障碍访问支持文案。
    struct Accessibility {
        static func tr(_ key: String) -> String { Localized.tr("a11y.\(key)", table: "Accessibility") }

        static var links: String { tr("links") }
    }

    /// 聊天交互模块：RAG 问答主界面。
    struct Chat {
        static func tr(_ key: String) -> String { Localized.tr("chat.\(key)", table: "Chat") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：AI 助手
        static var title: String { tr("title") }
    }

    /// UI 通用组件库专有文案。
    struct Components {
        static func tr(_ key: String) -> String { Localized.tr("backlinks.\(key)", table: "Components") }

        struct Backlinks {
            static var noOutgoing: String { Components.tr("noOutgoing") }
            static var noBackLinks: String { Components.tr("noBackLinks") }
        }
    }

    /// Apple Watch 端独立 UI 文案。
    struct Watch {
        static func tr(_ key: String) -> String { Localized.tr("watch.\(key)", table: "Watch") }
    }

    /// 页面架构与元数据定义词条。
    struct Schema {
        static func tr(_ key: String) -> String { Localized.tr("schema.\(key)", table: "Schema") }
    }

    /// 核心领域模型状态及类型展示词条。
    struct CoreModels {
        static func tr(_ key: String) -> String { Localized.tr(key, table: "CoreModels") }

        struct TypeName {
            static func tr(_ key: String) -> String { CoreModels.tr("type.\(key)") }
        }
        struct Status {
            static func tr(_ key: String) -> String { CoreModels.tr("status.\(key)") }
        }
    }

    /// 协作与多用户共享模块。
    struct Collaboration {
        static func tr(_ key: String) -> String { Localized.tr("collab.\(key)", table: "Collaboration") }
    }

    /// 系统小组件文案。
    struct Widget {
        static func tr(_ key: String) -> String { Localized.tr("widget.\(key)", table: "Widget") }
    }

    /// 数据流转：导出与导入过程中的引导与提示。
    struct Transfer {
        static func tr(_ key: String) -> String { Localized.tr(key, table: "Transfer") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        struct Export {
            static func tr(_ key: String) -> String { Transfer.tr("export.\(key)") }
            static func trf(_ key: String, _ args: CVarArg...) -> String {
                let template = tr(key)
                return String(format: template, arguments: args)
            }
        }
        struct Import {
            static func tr(_ key: String) -> String { Transfer.tr("import.\(key)") }
            static func trf(_ key: String, _ args: CVarArg...) -> String {
                let template = tr(key)
                return String(format: template, arguments: args)
            }
            static var folder: String { L10n.Settings.tr("importFromFolder") }
            static var externalVault: String { tr("externalVault") }
        }
    }

    /// 新手指引：功能引导与说明气泡。
    struct Coachmark {
        static func tr(_ key: String) -> String { Localized.tr("coachmark.\(key)", table: "Coachmark") }
    }

    /// 内容创建流程文案。
    struct Creation {
        static func tr(_ key: String) -> String { Localized.tr("create.\(key)", table: "Creation") }
    }

    /// 仪表盘：统计分析与概览界面。
    struct Dashboard {
        static func tr(_ key: String) -> String { Localized.tr("dashboard.\(key)", table: "Dashboard") }

        /// 页面名称：仪表盘
        static var title: String { tr("title") }
        static var totalPages: String { tr("totalPages") }
        static var totalLinks: String { tr("totalLinks") }
        static var density: String { tr("density") }
        static var dailyInsights: String { tr("dailyInsights") }
        static var hotTopics: String { tr("hotTopics") }
        
        static var graphShortcut: String { tr("graphShortcut") }
        static var densityDetails: String { tr("density.details") }
        static var densityOutbound: String { tr("density.outbound") }
        static var densityInbound: String { tr("density.inbound") }
        
        static var insightsLoading: String { tr("insights.loading") }
        static var insightsPageDeleted: String { tr("insights.pageDeleted") }
        static var insightsEmpty: String { tr("insights.empty") }
    }

    /// Markdown 编辑器及相关操作文案。
    struct Editor {
        static func tr(_ key: String) -> String { Localized.tr("editor.\(key)", table: "Editor") }
    }

    /// iCloud 备份与同步状态。
    struct ICloud {
        static func tr(_ key: String) -> String { Localized.tr("icloud.\(key)", table: "ICloud") }
    }

    /// 内容巡检：合规性与链接完整性检查。
    struct Lint {
        static func tr(_ key: String) -> String { Localized.tr("lint.\(key)", table: "Lint") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }
    }

    /// 知识合成：将多个来源聚合为深度知识。
    struct Synthesis {
        static func tr(_ key: String) -> String { Localized.tr("synthesis.\(key)", table: "Localizable") }
        static func trf(_ key: String, _ args: CVarArg...) -> String {
            let template = tr(key)
            return String(format: template, arguments: args)
        }

        /// 页面名称：合成实验室
        static var title: String { tr("title") }
    }

    /// 标签管理与分类索引。
    struct Tag {
        static func tr(_ key: String) -> String { Localized.tr("tag.\(key)", table: "Localizable") }
        /// 页面名称：标签管理
        static var title: String { tr("title") }
        static var allTags: String { tr("allTags") }
        static var relatedPagesTitle: String { tr("relatedPagesTitle") }
        static var noRelatedPages: String { tr("noRelatedPages") }
        static var editTags: String { tr("edit") }
        static var deleteConfirmTitle: String { tr("deleteConfirmTitle") }
        static var deleteConfirmMessage: String { tr("deleteConfirmMessage") }
    }

    /// 操作日志与审计。
    struct Log {
        static func tr(_ key: String) -> String { Localized.tr("log.\(key)", table: "Localizable") }
        
        static var noLogs: String { tr("noLogs") }
        static var clearConfirmTitle: String { tr("clearConfirmTitle") }
        static var startTime: String { tr("startTime") }
        static var endTime: String { tr("endTime") }
        static var duration: String { tr("duration") }
        static var failureReason: String { tr("failureReason") }
        
        static var success: String { L10n.Common.tr("success") }
        static var failed: String { L10n.Common.tr("failed") }
        static var processing: String { L10n.Common.tr("processing") }
    }
}
