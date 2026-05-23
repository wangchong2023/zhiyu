//
//  DocxProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Document 模块，提供相关的结构体或工具支撑。
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

    func parse() -> Bool {
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        return parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "w:t" {
            inTextElement = true
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inTextElement {
            currentText += string
        }
    }

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
