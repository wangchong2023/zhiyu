# 智宇 (KM) 数据库 Schema 设计

本文件记录了智宇 (KM) 核心数据库的结构设计及其版本演进历程。系统基于 SQLite 存储，使用 GRDB.swift 进行版本管理与对象映射。

## 1. 核心表结构

### 1.1 `pages` (知识页面表)
存储所有知识条目的元数据与核心内容。

| 字段 | 类型 | 约束 | 说明 |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | 页面唯一标识符 |
| `title` | TEXT | NOT NULL, UNIQUE | 标题（V4 强制唯一索引） |
| `content` | TEXT | | Markdown 原始内容 |
| `type` | TEXT | NOT NULL | 页面类型 (concept, entity, source, etc.) |
| `file_size` | INTEGER | NOT NULL | 物理字节大小 |
| `tags` | TEXT | | 标签列表（以逗号分隔） |
| `aliases` | TEXT | | 别名列表（以逗号分隔） |
| `updated_at` | DATETIME | NOT NULL | 最后更新时间 |
| `vector` | BLOB | | 页面级向量（传统 RAG 使用） |

### 1.2 `page_chunks` (RAG 分块表)
支持高级 RAG（层级分块、问答对、摘要）的核心存储。

| 字段 | 类型 | 约束 | 说明 |
| :--- | :--- | :--- | :--- |
| `id` | TEXT | PRIMARY KEY | 分块 ID (格式: p_{uuid}_{index}) |
| `page_id` | UUID | NOT NULL, REFERENCES pages(id) | 所属页面 ID |
| `parent_id` | TEXT | INDEX | 父块 ID（V5 引入，支持 Small-to-Big） |
| `chunk_type` | TEXT | NOT NULL | 类型: `regular`, `summary`, `qa_pair` |
| `content` | TEXT | NOT NULL | 分块文本内容 |
| `embedding` | BLOB | | 向量数据 |
| `start_index` | INTEGER | NOT NULL | 在原文档中的字符偏移位置 |

### 1.3 `token_usage` (AI 资源审计表)
记录 LLM 调用的开销情况（V6 引入）。

| 字段 | 类型 | 约束 | 说明 |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | 记录 ID |
| `model` | TEXT | NOT NULL | 使用的模型 ID (e.g., gpt-4o) |
| `prompt_tokens` | INTEGER | NOT NULL | 输入消耗 Token |
| `completion_tokens` | INTEGER | NOT NULL | 输出产生 Token |
| `total_tokens` | INTEGER | NOT NULL | 总消耗 |
| `created` | DATETIME | NOT NULL, INDEX | 产生时间 |

---

## 2. 索引与搜索增强

### 2.1 全文检索 (FTS5)
系统创建了 `pages_fts` 虚拟表，并与 `pages` 表同步：
```sql
CREATE VIRTUAL TABLE pages_fts USING fts5(
    title, 
    content, 
    content='pages', 
    content_rowid='id'
);
```

### 2.2 触发器 (Triggers)
系统通过触发器确保全文检索索引与物理数据自动同步。

---

## 3. 版本迁移历史 (Migration Logs)

| 版本 | 标识 | 变更描述 |
| :--- | :--- | :--- |
| **V1** | `v1_initial` | 创建核心 `pages` 表。 |
| **V2** | `v2_fts` | 启用 SQLite FTS5 全文检索模块。 |
| **V3** | `v3_rag_chunks` | 引入初步的分块存储支持。 |
| **V4** | `v4_unique_title` | **重大变更**：清理同名页面，为 `title` 字段添加 UNIQUE 唯一约束。 |
| **V5** | `v5_upgrade_page_chunks` | **RAG 升级**：为分块表添加 `parent_id` (层级支持) 和 `chunk_type` (分类支持)。 |
| **V6** | `v6_resource_audit` | **资源治理**：创建 `token_usage` 表，支持 Token 消耗统计。 |
