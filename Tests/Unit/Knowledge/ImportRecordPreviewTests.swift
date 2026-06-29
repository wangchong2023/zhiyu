//
//  ImportRecordPreviewTests.swift
//  ZhiYuTests
//
//  Created by Antigravity on 2026/06/28.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Tests] 单元测试层
//  核心职责：对 Ingest 导入记录的几种不同类型在点击和预览时的分发动作与逻辑（ImportPreviewHandler）进行完备的单元测试校验。
//

import XCTest
@testable import ZhiYu

final class ImportRecordPreviewTests: XCTestCase {
    
    private var mockURLOpener: MockURLOpener!
    private var mockShareSheet: MockShareSheet!
    private var router: Router!
    private var handler: ImportPreviewHandler!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockURLOpener = MockURLOpener()
        mockShareSheet = MockShareSheet()
        router = Router()
        handler = ImportPreviewHandler(
            urlOpener: mockURLOpener,
            shareSheet: mockShareSheet,
            router: router
        )
    }
    
    override func tearDown() {
        mockURLOpener = nil
        mockShareSheet = nil
        router = nil
        handler = nil
        super.tearDown()
    }
    
    // MARK: - 1. 优先跳转至关联页面详情测试 (第一优先级)
    func testNavigateToPage() {
        let pageUUID = UUID()
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.link.rawValue,
            title: "已完成并关联页面的链接",
            status: ImportRecordStatus.done,
            rawText: "一些解析文本",
            pageID: pageUUID.uuidString
        )
        
        let action = handler.resolveAction(for: record, fileExists: { _ in true })
        XCTAssertEqual(action, .navigateToPage(id: pageUUID))
    }
    
    // MARK: - 1b. 文件、OCR、语音即使关联页面也必须强制预览，不进行页面跳转的测试
    func testForcePreviewForSpecificCategories() {
        let pageUUID = UUID()
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.file.rawValue,
            title: "已完成并关联页面的文件",
            status: ImportRecordStatus.done,
            rawText: "一些解析文本",
            pageID: pageUUID.uuidString
        )
        
        // 虽然有关联页面，但因为属于强预览类型，且物理文件不存在，应该走文本预览
        let action = handler.resolveAction(for: record, fileExists: { _ in false })
        XCTAssertEqual(action, .rawTextPreview(text: "一些解析文本"))
    }
    
    // MARK: - 2. 手工记录跳转编辑测试 (第二优先级)
    func testManualEdit() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.manual.rawValue,
            title: "手工导入记录"
        )
        
        let action = handler.resolveAction(for: record, fileExists: { _ in false })
        XCTAssertEqual(action, .manualEdit)
    }
    
    // MARK: - 3. 本地文本文件预览测试 (第三优先级 - 纯文本)
    func testLocalTextFile() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.file.rawValue,
            title: "本地文本记录",
            filePath: "/path/to/notes.md"
        )
        
        // 模拟磁盘上存在该文件
        let action = handler.resolveAction(for: record, fileExists: { path in
            return path == "/path/to/notes.md"
        })
        XCTAssertEqual(action, .localTextFile(path: "/path/to/notes.md"))
    }
    
    // MARK: - 4. 本地二进制文件 QL 预览测试 (第三优先级 - 二进制)
    func testLocalBinaryFile() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.file.rawValue,
            title: "本地PDF记录",
            filePath: "/path/to/doc.pdf"
        )
        
        // 模拟磁盘上存在该文件
        let action = handler.resolveAction(for: record, fileExists: { path in
            return path == "/path/to/doc.pdf"
        })
        let expectedURL = URL(fileURLWithPath: "/path/to/doc.pdf")
        XCTAssertEqual(action, .localBinaryFile(url: expectedURL))
    }
    
    // MARK: - 5. 网页链接跳转浏览器测试 (第四优先级)
    func testOpenURL() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.link.rawValue,
            title: "链接记录",
            sourceURL: "https://example.com/source"
        )
        
        let action = handler.resolveAction(for: record, fileExists: { _ in false })
        let expectedURL = URL(string: "https://example.com/source")!
        XCTAssertEqual(action, .openURL(url: expectedURL))
    }
    
    // MARK: - 6. 提取出的纯文本弹窗预览测试 (第五优先级)
    func testRawTextPreview() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.ocr.rawValue,
            title: "无文件的OCR文本记录",
            rawText: "这是扫描提取出来的文字"
        )
        
        let action = handler.resolveAction(for: record, fileExists: { _ in false })
        XCTAssertEqual(action, .rawTextPreview(text: "这是扫描提取出来的文字"))
    }
    
    // MARK: - 7. 兜底回退测试
    func testNoneFallback() {
        let record = ImportRecord(
            id: UUID().uuidString,
            category: ImportCategory.file.rawValue,
            title: "什么都没有的记录"
        )
        
        let action = handler.resolveAction(for: record, fileExists: { _ in false })
        XCTAssertEqual(action, .none)
    }
}

// MARK: - Mocks

final class MockURLOpener: URLOpenerProtocol, @unchecked Sendable {
    var openedURL: URL?
    func open(_ url: URL) async {
        openedURL = url
    }
}

final class MockShareSheet: ShareSheetProtocol, @unchecked Sendable {
    var sharedItems: [Any]?
    func presentShareSheet(items: [Any]) async {
        sharedItems = items
    }
}
