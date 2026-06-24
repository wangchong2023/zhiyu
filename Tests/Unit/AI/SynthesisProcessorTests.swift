//
//  SynthesisProcessorTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 SynthesisProcessor 的 Mermaid 格式化、标题提取、Markdown 清理等功能开展单元测试。
//

import XCTest
@testable import ZhiYu

final class SynthesisProcessorTests: XCTestCase {

    // MARK: - formatMermaid

    func testFormatMermaid_mindmap() {
        let input = "mindmap\n  Root\n    A\n    B"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.hasPrefix("mindmap"))
        XCTAssertTrue(result.contains("Root"))
        XCTAssertTrue(result.contains("A"))
        XCTAssertTrue(result.contains("B"))
    }

    func testFormatMermaid_mindmap_withFence() {
        let input = "```mermaid\nmindmap\n  Root\n    Child\n```"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.hasPrefix("mindmap"))
        XCTAssertTrue(result.contains("Child"))
    }

    func testFormatMermaid_graphTD() {
        let input = "graph TD\n  A-->B\n  B-->C"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.contains("graph TD"))
        XCTAssertTrue(result.contains("A-->B"))
    }

    func testFormatMermaid_noPattern_usesFallback() {
        let input = "some random text"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.contains("graph TD"))
    }

    func testFormatMermaid_bareGraphKeyword() {
        let input = "graph"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.contains("graph TD"))
    }

    func testFormatMermaid_preservesTitle() {
        let input = "# My Diagram\nmindmap\n  Root"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.hasPrefix("# My Diagram"))
        XCTAssertTrue(result.contains("mindmap"))
    }

    func testFormatMermaid_timeline() {
        let input = "timeline\n  title History\n  2020: Event"
        let result = SynthesisProcessor.formatMermaid(input, fallbackPrefix: "graph TD")
        XCTAssertTrue(result.contains("timeline"))
        XCTAssertTrue(result.contains("Event"))
    }

    // MARK: - extractTitle

    func testExtractTitle_firstH1() {
        let content = "# Main Title\n\nSome content"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertEqual(result, "Main Title")
    }

    func testExtractTitle_ignoresH2() {
        let content = "## Not H1\n\n# Real Title"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertEqual(result, "Real Title")
    }

    func testExtractTitle_noHeader_returnsNil() {
        let content = "plain text without headers"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertNil(result)
    }

    func testExtractTitle_emptyContent_returnsNil() {
        let result = SynthesisProcessor.extractTitle(from: "")
        XCTAssertNil(result)
    }

    func testExtractTitle_stripsCodeFence() {
        let content = "# Title ```\nmore content"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertEqual(result, "Title")
    }

    func testExtractTitle_multipleH1_takesFirst() {
        let content = "# First\n\n# Second"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertEqual(result, "First")
    }

    func testExtractTitle_h1WithExtraHashSigns() {
        let content = "## H2\n#  H1 with space"
        let result = SynthesisProcessor.extractTitle(from: content)
        XCTAssertEqual(result, "H1 with space")
    }

    // MARK: - cleanMarkdown

    func testCleanMarkdown_escapedPlus() {
        let result = SynthesisProcessor.cleanMarkdown("list\\+item")
        XCTAssertEqual(result, "list+item")
    }

    func testCleanMarkdown_escapedMinus() {
        let result = SynthesisProcessor.cleanMarkdown("\\- item")
        XCTAssertEqual(result, "- item")
    }

    func testCleanMarkdown_escapedAsterisk() {
        let result = SynthesisProcessor.cleanMarkdown("\\*bold\\*")
        XCTAssertEqual(result, "*bold*")
    }

    func testCleanMarkdown_escapedBrackets() {
        let result = SynthesisProcessor.cleanMarkdown("\\[\\[link\\]\\]")
        XCTAssertEqual(result, "[[link]]")
    }

    func testCleanMarkdown_noEscapes_unmodified() {
        let input = "plain text"
        let result = SynthesisProcessor.cleanMarkdown(input)
        XCTAssertEqual(result, input)
    }

    func testCleanMarkdown_trimWhitespace() {
        let result = SynthesisProcessor.cleanMarkdown("  hello  ")
        XCTAssertEqual(result, "hello")
    }

    func testCleanMarkdown_combinedEscapes() {
        let result = SynthesisProcessor.cleanMarkdown("\\+ \\- \\* \\. ")
        XCTAssertEqual(result, "+ - * .")
    }

    func testCleanMarkdown_emptyString() {
        let result = SynthesisProcessor.cleanMarkdown("")
        XCTAssertEqual(result, "")
    }
}
