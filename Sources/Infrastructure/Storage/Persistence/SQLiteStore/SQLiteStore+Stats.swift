// SQLiteStore+Stats.swift
//
// 作者: Wang Chong
// 功能说明: SQLiteStore 扩展：负责存储统计、资源监控及物理指标计算。
// MARK: [RR-03] 内存与资源监控 (可运维性)
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

extension SQLiteStore {
    
    // MARK: - 存储统计结构

    struct StorageStats {
        let databaseSize: Int64
        let logsSize: Int64
        let importsSize: Int64
        let exportsSize: Int64
    }

    /// 获取真实的存储分类统计数据
    func getStorageStats() -> StorageStats {
        let fm = FileManager.default
        
        // 1. 数据库大小
        let dbSize = (try? fm.attributesOfItem(atPath: dbPath.path)[.size] as? Int64) ?? 0
        
        // 2. 操作日志大小
        let logsSize = (try? fm.attributesOfItem(atPath: Logger.shared.logsFileURL.path)[.size] as? Int64) ?? 0
        
        // 3. 数据导入大小 (从 pages 表中统计)
        let importsSize = pages.reduce(0) { $0 + ($1.fileSize ?? 0) }
        
        // 4. 数据导出大小 (尝试统计默认导出目录)
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return StorageStats(databaseSize: dbSize, logsSize: logsSize, importsSize: importsSize, exportsSize: 0)
        }
        let exportsURL = docsDir.appendingPathComponent("Exports")
        let exportsSize: Int64 = (try? fm.subpathsOfDirectory(atPath: exportsURL.path).reduce(0) { sum, path in
            let fullPath = exportsURL.appendingPathComponent(path).path
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue {
                return sum + ((try? fm.attributesOfItem(atPath: fullPath)[.size] as? Int64) ?? 0)
            }
            return sum
        }) ?? 0
        
        return StorageStats(
            databaseSize: dbSize,
            logsSize: logsSize,
            importsSize: importsSize,
            exportsSize: exportsSize
        )
    }

    // MARK: - 指标快照 (Metrics)

    var totalPages: Int { (try? repository.count()) ?? 0 }
    var entityCount: Int { (try? repository.count(type: .entity)) ?? 0 }
    var conceptCount: Int { (try? repository.count(type: .concept)) ?? 0 }
    var sourceCount: Int { (try? repository.count(type: .source)) ?? 0 }
    var totalWords: Int { pages.reduce(0) { $0 + $1.wordCount } }

    // MARK: - 磁盘重载

    func reloadFromDisk() {
        onSaveNeeded?()
    }
}
