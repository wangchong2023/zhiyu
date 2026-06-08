//
//  PluginLoadUnloadTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/06.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对插件加载/卸载端到端流程开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

#if canImport(JavaScriptCore)
import JavaScriptCore

/// 插件加载/卸载端到端测试 — 真实 JSContext 覆盖池化污染导致的 SyntaxError
@MainActor
final class PluginLoadUnloadTests: XCTestCase {

    /// 项目根目录：XCTest 在模拟器中运行，需用绝对路径
    private static let projectRoot = "/Users/constantine/Documents/work/code/projects/ZhiYu"

    /// 读取插件 JS 源码
    private func readJS(_ relativePath: String) -> String? {
        let full = Self.projectRoot + "/" + relativePath
        return try? String(contentsOfFile: full, encoding: .utf8)
    }

    /// 1. 5 个插件 JS 能被 JavaScriptCore 正确解析
    func testAllPluginJSParse() {
        let paths: [(String, String)] = [
            ("toc-generator", "Tools/Plugins/Local/toc-generator/index.js"),
            ("word-counter", "Tools/Plugins/Local/word-counter/index.js"),
            ("smart-cleaner", "Tools/Plugins/smart-cleaner/index.js"),
            ("link-preview", "Tools/Plugins/Remote/link-preview/index.js"),
            ("ai-translator", "Tools/Plugins/Remote/ai-translator/index.js"),
        ]
        for (name, path) in paths {
            guard let js = readJS(path) else {
                XCTFail("\(name): 无法读取 \(path)"); continue
            }
            let m = PluginManifest(id: "test.\(name)", version: "1.0.0", author: "Test",
                                    permissions: ["log"], names: ["en": name], descriptions: ["en": "Test"])
            XCTAssertNotNil(JavaScriptPlugin(script: js, manifest: m),
                            "\(name): init nil — JS 语法校验不通过")
        }
    }

    /// 2. 完整生命周期：init → load → preProcess → postProcess → unload
    func testFullLifecycle() {
        guard let js = readJS("Tools/Plugins/Local/toc-generator/index.js") else {
            XCTFail("无法读取"); return
        }
        let m = PluginManifest(id: "test.life", version: "1.0.0", author: "T",
                                permissions: ["writeContent","log"], names: ["en": "T"], descriptions: ["en": "T"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init fail"); return }
        let r = PluginRegistry.shared

        r.loadPlugin(p)
        XCTAssertTrue(r.plugins.contains(where: { $0.manifest.id == m.id }), "加载失败")

        XCTAssertNoThrow(try p.preProcess(content: "# Title\n\nBody"), "preProcess 异常")
        XCTAssertNoThrow(try p.postProcess(content: "# Title\n\nBody"), "postProcess 异常")

        r.unloadPlugin(id: m.id)
        XCTAssertFalse(r.plugins.contains(where: { $0.manifest.id == m.id }), "卸载失败")
    }

    /// 3. 重复加载去重
    func testDuplicatePrevented() {
        guard let js = readJS("Tools/Plugins/Local/word-counter/index.js") else {
            XCTFail("无法读取"); return
        }
        let m = PluginManifest(id: "test.dedup", version: "1.0.0", author: "T",
                                permissions: ["log"], names: ["en": "D"], descriptions: ["en": "D"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init fail"); return }
        let r = PluginRegistry.shared
        r.loadPlugin(p)
        XCTAssertEqual(r.plugins.filter({ $0.manifest.id == m.id }).count, 1)
        r.loadPlugin(p)
        XCTAssertEqual(r.plugins.filter({ $0.manifest.id == m.id }).count, 1, "重复加载不应增加")
        r.unloadPlugin(id: m.id)
    }

    // MARK: - 功能测试：每个插件的核心逻辑

    /// TOC 生成器：preProcess 应在标题前插入 TOC
    func testTocGeneratorInsertsTOC() {
        guard let js = readJS("Tools/Plugins/Local/toc-generator/index.js") else { XCTFail("读取"); return }
        let m = PluginManifest(id: "test.toc.func", version: "1.0.0", author: "T",
                                permissions: ["writeContent","log"], names: ["en": "TOC"], descriptions: ["en": "T"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init"); return }
        PluginRegistry.shared.loadPlugin(p)
        let input = "# Chapter 1\n\nContent here\n\n## Section 1.1\n\nMore content"
        let output = (try? p.preProcess(content: input)) ?? input
        // TOC 应包含目录标记和标题链接
        XCTAssertTrue(output.contains("TOC"), "应包含 TOC 标记")
        XCTAssertTrue(output.contains("Chapter 1") || output.contains("Section 1.1"), "应保留原标题")
        PluginRegistry.shared.unloadPlugin(id: m.id)
    }

    /// 字数统计：postProcess 不应抛异常
    func testWordCounterPostProcess() {
        guard let js = readJS("Tools/Plugins/Local/word-counter/index.js") else { XCTFail("读取"); return }
        let m = PluginManifest(id: "test.word.func", version: "1.0.0", author: "T",
                                permissions: ["readContent","log"], names: ["en": "WC"], descriptions: ["en": "WC"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init"); return }
        PluginRegistry.shared.loadPlugin(p)
        let input = "Hello world 你好世界\n\nThis is a test."
        XCTAssertNoThrow(try p.postProcess(content: input), "postProcess 不应抛异常")
        PluginRegistry.shared.unloadPlugin(id: m.id)
    }

    /// 智能清洗器：preProcess 应合并多余空行
    func testSmartCleanerMergesBlankLines() {
        guard let js = readJS("Tools/Plugins/smart-cleaner/index.js") else { XCTFail("读取"); return }
        let m = PluginManifest(id: "test.clean.func", version: "1.0.0", author: "T",
                                permissions: ["writeContent","log"], names: ["en": "SC"], descriptions: ["en": "SC"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init"); return }
        PluginRegistry.shared.loadPlugin(p)
        // 3+ 连续空行应被合并为 2 个
        let input = "Line1\n\n\n\nLine2"
        let output = (try? p.preProcess(content: input)) ?? input
        let blankCount = output.components(separatedBy: "\n").filter { $0.isEmpty }.count
        XCTAssertLessThanOrEqual(blankCount, 2, "连续空行应 ≤ 2")
        PluginRegistry.shared.unloadPlugin(id: m.id)
    }

    /// 链接预览：postProcess 不应抛异常
    func testLinkPreviewPostProcess() {
        guard let js = readJS("Tools/Plugins/Remote/link-preview/index.js") else { XCTFail("读取"); return }
        let m = PluginManifest(id: "test.link.func", version: "1.0.0", author: "T",
                                permissions: ["network","log"], names: ["en": "LP"], descriptions: ["en": "LP"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init"); return }
        PluginRegistry.shared.loadPlugin(p)
        XCTAssertNoThrow(try p.postProcess(content: "Check https://example.com"), "postProcess 不应抛异常")
        PluginRegistry.shared.unloadPlugin(id: m.id)
    }

    /// AI 翻译器：无 AI 服务时 postProcess 会因 ZhiYu.requestAI 缺失而失败，但不应 crash
    func testAITranslatorHandlesMissingAIGracefully() {
        guard let js = readJS("Tools/Plugins/Remote/ai-translator/index.js") else { XCTFail("读取"); return }
        let m = PluginManifest(id: "test.trans.func", version: "1.0.0", author: "T",
                                permissions: ["readContent","writeContent","aiAccess","log"], names: ["en": "TR"], descriptions: ["en": "TR"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init"); return }
        PluginRegistry.shared.loadPlugin(p)
        // 无 LLM 服务时 postProcess 会抛异常，但不应 crash
        let input = "<!-- translate:en -->\nHello\n<!-- /translate -->"
        _ = try? p.postProcess(content: input) // 无 AI 服务时忽略错误
        // 验证卸载正常
        PluginRegistry.shared.unloadPlugin(id: m.id)
        XCTAssertFalse(PluginRegistry.shared.plugins.contains(where: { $0.manifest.id == m.id }))
    }

    /// 4. 5 个插件批量安装 → 全部卸载，零崩溃
    func testBatchInstallUninstall() {
        let specs: [(String, String, String, [String])] = [
            ("toc", "Tools/Plugins/Local/toc-generator/index.js", "test.b.toc", ["writeContent","log"]),
            ("word", "Tools/Plugins/Local/word-counter/index.js", "test.b.word", ["readContent","log"]),
            ("clean", "Tools/Plugins/smart-cleaner/index.js", "test.b.clean", ["writeContent","log"]),
            ("link", "Tools/Plugins/Remote/link-preview/index.js", "test.b.link", ["network","log"]),
            ("trans", "Tools/Plugins/Remote/ai-translator/index.js", "test.b.trans", ["aiAccess","log"]),
        ]
        let r = PluginRegistry.shared
        var ids: [String] = []
        for (name, path, id, perms) in specs {
            guard let js = readJS(path) else { XCTFail("\(name): 读取"); continue }
            let m = PluginManifest(id: id, version: "1.0.0", author: "T", permissions: perms,
                                    names: ["en": name], descriptions: ["en": "B"])
            guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("\(name): init"); continue }
            r.loadPlugin(p)
            XCTAssertTrue(r.plugins.contains(where: { $0.manifest.id == id }), "\(name): 加载")
            ids.append(id)
        }
        for id in ids.reversed() {
            r.unloadPlugin(id: id)
            XCTAssertFalse(r.plugins.contains(where: { $0.manifest.id == id }), "\(id): 卸载")
        }
    }
}
#endif