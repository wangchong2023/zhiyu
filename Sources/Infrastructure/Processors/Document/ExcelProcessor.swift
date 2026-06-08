//
//  ExcelProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：文档处理器：Markdown 解析、文本分块、图谱布局、网页抓取。
//
import Foundation

final class ExcelProcessor: NSObject, XMLParserDelegate {
    private let xmlData: Data
    private(set) var values: [String] = []
    private var inCellElement = false
    private var inValueElement = false
    private var currentText = ""
    private var currentCellType: String?

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
        if elementName == "c" {
            currentCellType = attributeDict["t"]
            inCellElement = true
            currentText = ""
        } else if elementName == "v" {
            inValueElement = true
            currentText = ""
        }
    }

    /// parser
    /// - Parameter parser: parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inValueElement {
            currentText += string
        }
    }

    /// parser
    /// - Parameter parser: parser
    /// - Parameter namespaceURI: namespaceURI
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "v" {
            inValueElement = false
        } else if elementName == "c" {
            if !currentText.isEmpty && (currentCellType == "s" || currentCellType == "inlineStr") {
                if let value = Int(currentText), value < 10000 {
                    values.append("[\(value)]")
                }
            }
            inCellElement = false
            currentCellType = nil
            currentText = ""
        }
    }
}