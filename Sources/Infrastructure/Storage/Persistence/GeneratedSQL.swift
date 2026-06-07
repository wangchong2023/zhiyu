//
//  GeneratedSQL.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/01.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：持久化引擎：GRDB/SQLite 仓库、同步、加密、数据库管理。
//
import Foundation

struct GeneratedSQL {
    /// 专属业务笔记本数据库初始化 SQL 脚本
    static let initSchemaSQL = """
--
--  init_schema.sql
--  ZhiYu
--
--  Created by Antigravity on 2026/05/30.
--  Copyright  2026 WangChong. All rights reserved.
--
--  [L1] 
--   DDL 
--

-- 1. 
CREATE TABLE IF NOT EXISTS pages (
    id BLOB PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,
    page_type TEXT NOT NULL,
    content TEXT NOT NULL,
    aliases TEXT,
    tags TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    confidence TEXT NOT NULL DEFAULT 'medium',
    sources TEXT,
    related_page_ids TEXT,
    is_pinned BOOLEAN NOT NULL DEFAULT 0,
    content_hash TEXT,
    custom_icon TEXT,
    source_url TEXT,
    raw_snippet TEXT,
    file_size INTEGER,
    source_type TEXT,
    lamport_timestamp INTEGER NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_pages_page_type ON pages(page_type);

-- 2. 
CREATE TABLE IF NOT EXISTS links (
    source_id BLOB NOT NULL,
    target_id BLOB NOT NULL,
    context TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (source_id, target_id),
    FOREIGN KEY (source_id) REFERENCES pages(id) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_links_target_id ON links(target_id);

-- 3. 
CREATE TABLE IF NOT EXISTS page_chunks (
    id TEXT PRIMARY KEY,
    page_id BLOB NOT NULL,
    parent_id TEXT,
    chunk_type TEXT NOT NULL,
    content TEXT NOT NULL,
    anchor_path TEXT,
    chunk_index INTEGER NOT NULL,
    embedding BLOB,
    start_index INTEGER,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES page_chunks(id) ON DELETE CASCADE
);

-- 4. 
CREATE TABLE IF NOT EXISTS page_embeddings (
    id BLOB PRIMARY KEY,
    vector_blob BLOB NOT NULL,
    model_name TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id) REFERENCES pages(id) ON DELETE CASCADE
);

-- 5.  AI 
CREATE TABLE IF NOT EXISTS token_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model TEXT NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    total_tokens INTEGER NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS llm_call_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model TEXT NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    latency_ms INTEGER NOT NULL,
    status TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rag_evaluations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    answer TEXT NOT NULL,
    faithfulness_score REAL NOT NULL,
    relevance_score REAL NOT NULL,
    context_precision REAL NOT NULL,
    evaluator_model TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. 
CREATE TABLE IF NOT EXISTS tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. -
CREATE TABLE IF NOT EXISTS page_tags (
    page_id BLOB NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY (page_id, tag_id),
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- 8.  (SRS)
CREATE TABLE IF NOT EXISTS srs_metadata (
    page_id BLOB PRIMARY KEY,
    ease_factor REAL NOT NULL DEFAULT 2.50,
    repetitions INTEGER NOT NULL DEFAULT 0,
    review_interval INTEGER NOT NULL DEFAULT 0,
    next_review_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_srs_next_review ON srs_metadata(next_review_at);

-- 9.  pages 
CREATE TRIGGER IF NOT EXISTS trigger_update_pages_timestamp
AFTER UPDATE ON pages
BEGIN
    UPDATE pages SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- 10.  FTS5 
CREATE VIRTUAL TABLE IF NOT EXISTS pages_fts USING fts5(
    id UNINDEXED, title, content, tags, aliases,
    content='pages'
);

CREATE TRIGGER IF NOT EXISTS pages_ai AFTER INSERT ON pages BEGIN
    INSERT INTO pages_fts(id, title, content, tags, aliases)
    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
END;

CREATE TRIGGER IF NOT EXISTS pages_ad AFTER DELETE ON pages BEGIN
    INSERT INTO pages_fts(pages_fts, id, title, content, tags, aliases)
    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
END;

CREATE TRIGGER IF NOT EXISTS pages_au AFTER UPDATE ON pages BEGIN
    INSERT INTO pages_fts(pages_fts, id, title, content, tags, aliases)
    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
    INSERT INTO pages_fts(id, title, content, tags, aliases)
    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
END;

"""

    /// 全局共享系统配置数据库初始化 SQL 脚本
    static let globalSchemaSQL = """
--
--  global_schema.sql
--  ZhiYu
--
--  Created by Antigravity on 2026/05/30.
--  Copyright  2026 WangChong. All rights reserved.
--
--  [L1] 
--   DDL
--

-- 1. 
CREATE TABLE IF NOT EXISTS global_vaults (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    icon TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2.  HMAC  UserDefaults 
CREATE TABLE IF NOT EXISTS file_signatures (
    file_path TEXT PRIMARY KEY,
    signature TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. 
CREATE TABLE IF NOT EXISTS global_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4.  Token 
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    details TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. 
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

-- 6.  FTS5  external content
CREATE VIRTUAL TABLE IF NOT EXISTS plugin_records_fts USING fts5(
    id UNINDEXED, name, author, description
);

"""
}
