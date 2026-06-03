--
--  global_schema.sql
--  ZhiYu
--
--  Created by Antigravity on 2026/05/30.
--  Copyright © 2026 WangChong. All rights reserved.
--
--  系统层级：[L1] 基础设施层
--  核心职责：提供全局配置数据库初始化时所需要的完整表结构 DDL。
--

-- 1. 笔记本元数据主表：托管所有多笔记本卡片信息
CREATE TABLE IF NOT EXISTS global_vaults (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    icon TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. 物理文件防篡改 HMAC 完整性指纹表：取代原 UserDefaults 强寄生
CREATE TABLE IF NOT EXISTS file_signatures (
    file_path TEXT PRIMARY KEY,
    signature TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. 全局设置表：系统级全局偏好持久化
CREATE TABLE IF NOT EXISTS global_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. 全局安全及 Token 损耗审计日志表
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    details TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. 插件元数据与状态表
CREATE TABLE IF NOT EXISTS plugin_records (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    author TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'local',
    status TEXT NOT NULL DEFAULT 'active',
    permissions_json TEXT NOT NULL DEFAULT '[]',
    load_duration REAL NOT NULL DEFAULT 0,
    unload_duration REAL NOT NULL DEFAULT 0,
    total_execution_time REAL NOT NULL DEFAULT 0,
    call_count INTEGER NOT NULL DEFAULT 0,
    installed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    manifest_json TEXT NOT NULL DEFAULT ''
);

-- 6. 插件 FTS5 全文搜索虚拟表（独立内容表，非 external content）
CREATE VIRTUAL TABLE IF NOT EXISTS plugin_records_fts USING fts5(
    id UNINDEXED, name, author, description
);
