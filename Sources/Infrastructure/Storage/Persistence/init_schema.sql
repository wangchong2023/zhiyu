--
--  init_schema.sql
--  ZhiYu
--
--  Created by Antigravity on 2026/05/30.
--  Copyright © 2026 WangChong. All rights reserved.
--
--  系统层级：[L1] 基础设施层
--  核心职责：提供专属笔记本数据库初始化时所需要的完整表结构 DDL 及触发器。
--

-- 1. 核心知识页面主表
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

-- 2. 知识图谱双向链接映射表
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

-- 3. 语义块切片表
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

-- 4. 页面层级高维稠密向量映射表
CREATE TABLE IF NOT EXISTS page_embeddings (
    id BLOB PRIMARY KEY,
    vector_blob BLOB NOT NULL,
    model_name TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id) REFERENCES pages(id) ON DELETE CASCADE
);

-- 5. 合规治理与 AI 资源开销审计表
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

-- 6. 范式化标签字典表
CREATE TABLE IF NOT EXISTS tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. 页面-标签多对多关联关联表
CREATE TABLE IF NOT EXISTS page_tags (
    page_id BLOB NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY (page_id, tag_id),
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- 8. 间隔重复记忆调度表 (SRS)
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

-- 9. 触发器：修改 pages 时同步更新物理更新时间
CREATE TRIGGER IF NOT EXISTS trigger_update_pages_timestamp
AFTER UPDATE ON pages
BEGIN
    UPDATE pages SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- 10. 配置 FTS5 全文搜索虚拟表与联动触发器
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
