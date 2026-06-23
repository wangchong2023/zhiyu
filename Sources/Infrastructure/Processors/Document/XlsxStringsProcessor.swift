//
//  XlsxStringsProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：文档处理器：Markdown 解析、文本分块、图谱布局、网页抓取。
//
import Foundation

final class XlsxSharedStringsParser: NSObject, XMLParserDelegate {
    private let xmlData: Data
    private(set) var strings: [String] = []
    private var inTextElement = false
    private var currentText = ""

    init(xmlData: Data) {
        self.xmlData = xmlData
    }

    /// 启动 XML 解析：解析 XLSX 的 sharedStrings.xml，提取所有共享字符串。
    /// - Returns: true 表示解析成功
    func parse() -> Bool {
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        return parser.parse()
    }

    /// XMLParserDelegate: 元素开始 — 进入 <t>（文本）节点，重置累积缓冲区。
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "t" {
            inTextElement = true
            currentText = ""
        }
    }

    /// XMLParserDelegate: 字符捕获 — 在 <t> 节点内累积文本字符。
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inTextElement {
            currentText += string
        }
    }

    /// XMLParserDelegate: 元素结束 — <t> 闭合时将累积文本追加到共享字符串数组。
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            strings.append(currentText)
            inTextElement = false
            currentText = ""
        }
    }
}
