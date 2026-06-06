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

/// 插件加载/卸载端到端测试 — 真实 JSContext 覆盖此前池化污染导致的 SyntaxError crash
@MainActor
final class PluginLoadUnloadTests: XCTestCase {

    /// 1. 5 个插件 JS 能被 JavaScriptCore 正确解析（init 中校验不通过会返回 nil）
    func testAllPluginJSParse() {
        let paths: [(String, String)] = [
            ("toc-generator", "Tools/Plugins/Local/toc-generator/index.js"),
            ("word-counter", "Tools/Plugins/Local/word-counter/index.js"),
            ("smart-cleaner", "Tools/Plugins/smart-cleaner/index.js"),
            ("link-preview", "Tools/Plugins/Remote/link-preview/index.js"),
            ("ai-translator", "Tools/Plugins/Remote/ai-translator/index.js"),
        ]
        for (name, path) in paths {
            guard let js = try? String(contentsOfFile: path, encoding: .utf8) else {
                XCTFail("\(name): 无法读取"); continue
            }
            let m = PluginManifest(id: "test.\(name)", version: "1.0.0", author: "Test",
                                    permissions: ["log"], names: ["en": name], descriptions: ["en": "Test"])
            XCTAssertNotNil(JavaScriptPlugin(script: js, manifest: m), "\(name): init 返回 nil — JS 语法不通过")
        }
    }

    /// 2. 完整生命周期：init → load → preProcess → postProcess → unload
    func testFullLifecycle() {
        guard let js = try? String(contentsOfFile: "Tools/Plugins/Local/toc-generator/index.js", encoding: .utf8) else {
            XCTFail("无法读取"); return
        }
        let m = PluginManifest(id: "test.life", version: "1.0.0", author: "T",
                                permissions: ["writeContent","log"], names: ["en": "T"], descriptions: ["en": "T"])
        guard let p = JavaScriptPlugin(script: js, manifest: m) else { XCTFail("init fail"); return }
        let r = PluginRegistry.shared

        r.loadPlugin(p)
        XCTAssertTrue(r.plugins.contains(where: { $0.manifest.id == m.id }))

        XCTAssertNoThrow(try p.preProcess(content: "# Title\n\nBody"))
        XCTAssertNoThrow(try p.postProcess(content: "# Title\n\nBody"))

        r.unloadPlugin(id: m.id)
        XCTAssertFalse(r.plugins.contains(where: { $0.manifest.id == m.id }))
    }

    /// 3. 重复加载去重
    func testDuplicatePrevented() {
        guard let js = try? String(contentsOfFile: "Tools/Plugins/Local/word-counter/index.js", encoding: .utf8) else {
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
            guard let js = try? String(contentsOfFile: path, encoding: .utf8) else { XCTFail("\(name): 读取"); continue }
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
