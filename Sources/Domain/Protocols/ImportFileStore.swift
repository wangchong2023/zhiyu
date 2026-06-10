//
//  ImportFileStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：导入原始文件持久化协议

import Foundation

public protocol ImportFileStore: Sendable {
    func saveContent(_ content: String, category: ImportCategory, ext: String) -> String?
    func saveData(_ data: Data, category: ImportCategory, ext: String) -> String?
}
