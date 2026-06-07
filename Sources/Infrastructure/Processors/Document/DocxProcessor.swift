//
//  DocxProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：文档处理器：Markdown 解析、文本分块、图谱布局、网页抓取。
//
import Foundation

final class DocxProcessor: NSObject, XMLParserDelegate {
    private let xmlData: Data
    private(set) var extractedText: String = ""
    private var inTextElement = false
    private var currentText = ""
    private var lastWasText = false

    init(xmlData: Data) {
        self.xmlData = xmlData
    }

    /// 解析
    /// - Returns: 是否成功
    func parse() -> Bool {
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        return parser.parse()
    }

    /// parser
    /// - Parameter parser: parser
    /// - Parameter namespaceURI: namespaceURI
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "w:t" {
            inTextElement = true
            currentText = ""
        }
    }

    /// parser
    /// - Parameter parser: parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inTextElement {
            currentText += string
        }
    }

    /// parser
    /// - Parameter parser: parser
    /// - Parameter namespaceURI: namespaceURI
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:t" {
            if !currentText.isEmpty {
                if lastWasText {
                    extractedText += " "
                }
                extractedText += currentText
                lastWasText = true
            }
            inTextElement = false
            currentText = ""
        } else if elementName == "w:p" {
            if lastWasText {
                extractedText += "\n"
                lastWasText = false
            }
        }
    }
}
