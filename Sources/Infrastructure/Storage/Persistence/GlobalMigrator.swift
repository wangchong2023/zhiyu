//
//  GlobalMigrator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Persistence 模块，负责全局共享配置数据库的 Schema 迁移逻辑。
//
import Foundation
import GRDB

/// 全局配置数据库迁移器
struct GlobalMigrator {
    
    /// 获取配置好的迁移器实例
    static func makeMigrator(isInTesting: Bool) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        if !isInTesting {
            migrator.eraseDatabaseOnSchemaChange = true
        }
        #endif
        
        migrator.registerMigration("v1_global_schema") { db in
            try setupGlobalSchema(db)
        }
        
        return migrator
    }
    
    /// 创建全局共享表结构：vaults、global_config
    private static func setupGlobalSchema(_ db: Database) throws {
        // 1. 笔记本元数据主表
        try db.create(table: AppConstants.Storage.Tables.globalVaults) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull()
            t.column("path", .text).notNull()
            t.column("icon", .text)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
            t.column("last_accessed_at", .datetime).notNull().defaults(to: Date())
        }
        
        // 2. 物理文件指纹表
        try db.create(table: AppConstants.Storage.Tables.fileSignatures) { t in
            t.column("file_path", .text).primaryKey()
            t.column("signature", .text).notNull()
            t.column("salt", .text).notNull()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }
        
        // 3. 全局设置表
        try db.create(table: AppConstants.Storage.Tables.globalSettings) { t in
            t.column("key", .text).primaryKey()
            t.column("value", .text).notNull()
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }
        
        // 4. 审计日志表
        try db.create(table: AppConstants.Storage.Tables.auditLogs) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("action", .text).notNull()
            t.column("details", .text)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
        }
    }
}
