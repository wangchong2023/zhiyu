//
//  Character+CJK.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：通用工具函数（向量数学、本地化辅助、ZIP 工具等）。
//
import Foundation

extension Character {
    /// 判定是否为中日韩 (CJK) 字符 (Engineering Utility)
    var isCJKCharacter: Bool {
        let scalars = unicodeScalars
        return scalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||  // CJK Unified Ideographs
            (0x3400...0x4DBF).contains(scalar.value) ||  // CJK Extension A
            (0x3000...0x303F).contains(scalar.value) ||  // CJK Symbols and Punctuation
            (0xFF00...0xFFEF).contains(scalar.value) ||  // Halfwidth and Fullwidth Forms
            (0x2E80...0x2EFF).contains(scalar.value) ||  // CJK Radicals Supplement
            (0x3040...0x309F).contains(scalar.value) ||  // Hiragana
            (0x30A0...0x30FF).contains(scalar.value) ||  // Katakana
            (0xAC00...0xD7AF).contains(scalar.value)     // Korean Syllables
        }
    }
}