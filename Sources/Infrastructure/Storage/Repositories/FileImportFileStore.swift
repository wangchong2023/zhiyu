//
//  FileImportFileStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：导入原始文件持久化实现

import Foundation

final class FileImportFileStore: ImportFileStore, Sendable {
    private let recordsDir: URL

    init() {
        let fm = FileManager.default
        let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        self.recordsDir = docDir.appendingPathComponent("import_records", isDirectory: true)
        try? fm.createDirectory(at: recordsDir, withIntermediateDirectories: true)
    }

    func saveContent(_ content: String, category: ImportCategory, ext: String = "md") -> String? {
        guard let data = content.data(using: .utf8) else { return nil }
        return saveData(data, category: category, ext: ext)
    }

    func saveData(_ data: Data, category: ImportCategory, ext: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let ts = formatter.string(from: Date())
        let fileName = "\(category.rawValue)_\(ts).\(ext)"
        let fileURL = recordsDir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            Logger.shared.error("[ImportFileStore] 保存文件失败: \(error)", error: error)
            return nil
        }
    }
}
