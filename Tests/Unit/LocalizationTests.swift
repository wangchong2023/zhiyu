// LocalizationTests.swift
//
// 作者: Wang Chong
// 功能说明: 验证本地化模块的完整性与 Key 的存在性
// 版本: 1.0
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
@testable import ZhiYu

final class LocalizationTests: XCTestCase {

    /// 验证核心模块的 Key 是否能正确解析（而非原样返回 Key）
    func testLocalizationKeysExistence() {
        // 1. Common 模块
        print("--- DIAGNOSTICS ---")
        print("Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
        let testBundle = Bundle(for: Self.self)
        print("Test Bundle Path: \(testBundle.bundlePath)")
        if let paths = Bundle.main.urls(forResourcesWithExtension: "lproj", subdirectory: nil) {
            print("Bundle.main lproj urls: \(paths.map { $0.lastPathComponent })")
        }
        if let paths = testBundle.urls(forResourcesWithExtension: "lproj", subdirectory: nil) {
            print("Test Bundle lproj urls: \(paths.map { $0.lastPathComponent })")
        }
        print("Current Language Mode: \(Localized.languageMode.rawValue)")
        print("Current Language: \(Localized.currentLanguage)")
        let lang = Localized.currentLanguage
        let pathInMain = Bundle.main.path(forResource: lang, ofType: "lproj")
        print("Path of \(lang).lproj in main: \(pathInMain ?? "nil")")
        let pathInTest = testBundle.path(forResource: lang, ofType: "lproj")
        print("Path of \(lang).lproj in test: \(pathInTest ?? "nil")")
        
        let okVal = Localized.tr("misc.ok", table: "Localizable")
        print("misc.ok in Localizable table: \(okVal)")
        
        print("--- END DIAGNOSTICS ---")
        
        XCTAssertNotEqual(L10n.Common.ok, "misc.ok", "Common.ok 应该被正确翻译")
        XCTAssertNotEqual(L10n.Common.cancel, "misc.cancel", "Common.cancel 应该被正确翻译")
        
        // 2. Settings 模块
        XCTAssertNotEqual(L10n.Settings.title, "settings.settings", "Settings.title 应该被正确翻译")
        
        // 3. Chat 模块
        XCTAssertNotEqual(L10n.Chat.title, "chat.title", "Chat.title 应该被正确翻译")
        
        // 4. Ingest 模块
        XCTAssertNotEqual(L10n.Ingest.title, "ingest.title", "Ingest.title 应该被正确翻译")
        
        // 5. Backup 模块
        XCTAssertNotEqual(L10n.Backup.title, "backup.title", "Backup.title 应该被正确翻译")
    }
    
    /// 验证不同语言环境下的切换逻辑（模拟环境）
    func testLanguageSwitchingLogic() {
        let currentMode = Localized.languageMode
        
        // 测试切换到英文
        Localized.languageMode = .english
        XCTAssertEqual(Localized.currentLanguage, "en")
        
        // 测试切换到中文
        Localized.languageMode = .chinese
        XCTAssertEqual(Localized.currentLanguage, "zh-Hans")
        
        // 还原现场
        Localized.languageMode = currentMode
    }
    
    /// 验证格式化字符串是否正常工作
    func testParameterizedLocalization() {
        // 验证 trf 接口不会崩溃且能正常注入参数
        // "aitask.status.runningFormat" 定义在 Localizable 和 AITasks xcstrings 中，接收两个参数
        let formatted = L10n.AI.Task.trf("status.runningFormat", "测试A", "测试B")
        XCTAssertTrue(formatted.contains("测试A") || formatted.contains("测试B"), "格式化调用应正常执行且包含传入参数")
    }
    
    /// 自动化全量审计：动态遍历所有 L10n 模块并验证 Key 的存在性
    func testComprehensiveLocalizationAudit() {
        let modules: [(name: String, table: String, keys: [String])] = [
            ("Common", "Common", ["ok", "cancel", "done"]),
            ("Settings", "Settings", ["aboutApp", "version", "section.about"]),
            ("Chat", "Chat", ["chat.title", "inputPlaceholder"]),
            ("Ingest", "Ingest", ["ingest.title", "ingest.manualEntry"]),
            ("AITasks", "AITasks", ["aitask.center.title", "aitask.status.thinking"]),
            ("Auth", "Auth", ["guestMode", "login"]),
            ("Coachmark", "Coachmark", ["onboarding.action.next"]),
            ("Collaboration", "Collaboration", ["collab.title"]),
            ("Creation", "Creation", ["pageTitle", "content"]),
            ("Dashboard", "Dashboard", ["hotTopics", "density"]),
            ("Graph", "Graph", ["title"]),
            ("Lint", "Lint", ["noIssues", "noIssuesHint"]),
            ("Plugin", "Plugin", ["section.rag"]),
            ("Vault", "Vault", ["vault.label"]),
            ("Watch", "Watch", ["watch.capture"]),
            ("Widget", "Widget", ["widget.title"]),
            ("Localizable", "Localizable", ["misc.ok", "misc.cancel", "misc.done"])
        ]
        
        var missingKeys: [String] = []
        
        for module in modules {
            for key in module.keys {
                let translated = Localized.tr(key, table: module.table)
                // 如果返回了 [MISSING: key] 说明翻译缺失
                if translated.contains("[MISSING:") {
                    missingKeys.append("\(module.table).\(key)")
                }
            }
        }
        
        XCTAssertTrue(missingKeys.isEmpty, "以下本地化 Key 缺失或未在对应的表中定义: \n\(missingKeys.joined(separator: "\n"))")
    }
}

