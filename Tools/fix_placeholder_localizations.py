#!/usr/bin/env python3
"""
批量修复 .xcstrings 中的 "(zh)" 占位符词条。

两类处理策略：
1. LLM 提示词模板键 — zh-Hans 设为与 en 相同（提示词本身是英文）
2. 用户可见 UI 字符串 — 提供正确的中文翻译
"""

import json
import os
import re

CATALOGS_DIR = "Sources/Localization/Catalogs"

# ── 用户可见 UI 键 → 中文翻译映射 ──
UI_TRANSLATIONS = {
    # Prompt Workshop（提示词实验室）
    "llm.prompt.workshop.intro.title": {"en": "What is Prompt Workshop?", "zh": "什么是提示词实验室？"},
    "llm.prompt.workshop.intro.desc": {"en": "Customize quick action shortcuts for AI Chat. These shortcuts appear as tappable chips in the chat input bar, letting you fire frequently used questions or instructions instantly without typing them every time.", "zh": "为 AI 对话定制快捷操作指令。这些快捷指令会以可点击的标签形式出现在聊天输入栏上方，让你一键发送常用提问或指令，无需每次重复输入。"},
    "llm.prompt.workshop.input.placeholder": {"en": "Enter a quick shortcut text...", "zh": "输入快捷指令文本..."},
    "llm.prompt.workshop.add": {"en": "Add Shortcut", "zh": "添加快捷指令"},
    "llm.prompt.workshop.shortcuts.title": {"en": "My Shortcuts", "zh": "我的快捷指令"},
    "llm.prompt.workshop.shortcuts.footer": {"en": "Swipe left to delete. Drag handle to reorder. Changes auto-save on leave.", "zh": "左滑删除，拖拽排序。离开页面自动保存。"},

    # Prompt 重置
    "llm.prompt.reset.factory": {"en": "Reset to Factory Defaults", "zh": "恢复出厂默认设置"},
    "llm.prompt.resetConfirm": {"en": "Reset all prompts to factory defaults?", "zh": "确认将所有提示词恢复为出厂默认设置？"},
    "llm.prompt.resetWarning": {"en": "This will overwrite all your custom prompt modifications. This action cannot be undone.", "zh": "此操作将覆盖您所有自定义提示词修改，不可撤销。"},

    # Chat（AI 对话）
    "chat.messageCount": {"en": "Message Count", "zh": "消息数"},
    "chat.contextLimitWarning": {"en": "Context Limit Warning", "zh": "上下文长度预警"},
    "chat.referenceCount": {"en": "Reference Count", "zh": "引用数"},
    "chat.activeSessionCount": {"en": "Active Sessions", "zh": "活跃会话数"},
    "chat.tokenUsage": {"en": "Token Usage", "zh": "Token 用量"},

    # Network errors（网络错误）
    "errorTokenExpired": {"en": "Token Expired", "zh": "Token 已过期"},
    "errorUnauthorized": {"en": "Unauthorized", "zh": "未授权"},
    "errorUnexpected": {"en": "Unexpected Error", "zh": "未知错误"},
    "errorDecodeFailed": {"en": "Decode Failed", "zh": "数据解析失败"},
    "missingRefreshToken": {"en": "Missing Refresh Token", "zh": "缺少刷新 Token"},
    "invalidHTTPResponse": {"en": "Invalid HTTP Response", "zh": "无效的 HTTP 响应"},
    "errorServer": {"en": "Server Error", "zh": "服务器错误"},
    "errorHTTP": {"en": "HTTP Error", "zh": "HTTP 错误"},
    "sessionInvalidated": {"en": "Session Invalidated", "zh": "会话已失效"},
    "missingDataPayload": {"en": "Missing Data Payload", "zh": "缺少数据负载"},
    "errorInvalidURL": {"en": "Invalid URL", "zh": "无效的 URL"},

    # Common / Log
    "logAction.aiscan": {"en": "AI Scan", "zh": "AI 扫描"},
    "action.export": {"en": "Export", "zh": "导出"},
    "common.comingSoon": {"en": "Coming Soon", "zh": "即将推出"},
    "ERROR": {"en": "Error", "zh": "错误"},

    # Demo data
    "demo.chunking.title": {"en": "Semantic Chunking", "zh": "语义分块"},
    "demo.chunking.content": {"en": "Documents are split into semantically coherent chunks using NLP-based boundary detection for optimal retrieval granularity.", "zh": "基于 NLP 边界检测将文档拆分为语义连贯的分块，以获得最佳检索粒度。"},
    "demo.consistency.title": {"en": "Data Consistency", "zh": "数据一致性"},
    "demo.consistency.content": {"en": "Transactional guarantees ensure knowledge graph and vector index remain synchronized across all write operations.", "zh": "事务性保证确保知识图谱与向量索引在所有写入操作中保持同步。"},
    "demo.embedding.title": {"en": "Vector Embedding", "zh": "向量嵌入"},
    "demo.embedding.content": {"en": "Text chunks are encoded into high-dimensional vectors using state-of-the-art embedding models for semantic search.", "zh": "使用最先进的嵌入模型将文本块编码为高维向量，支持语义搜索。"},
    "demo.gateway.title": {"en": "AI Gateway", "zh": "AI 网关"},
    "demo.gateway.content": {"en": "Unified gateway for all LLM providers with automatic failover, rate limiting, and cost tracking built in.", "zh": "统一的 LLM 提供商网关，内置自动故障转移、速率限制和成本追踪。"},
    "demo.hybridSearch.title": {"en": "Hybrid Search", "zh": "混合搜索"},
    "demo.hybridSearch.content": {"en": "Combines full-text search (FTS5) with vector similarity search for comprehensive and accurate retrieval results.", "zh": "结合全文搜索 (FTS5) 与向量相似度搜索，实现全面准确的检索结果。"},
    "demo.memoryMgmt.title": {"en": "Memory Management", "zh": "内存管理"},
    "demo.memoryMgmt.content": {"en": "Intelligent memory pressure monitoring with adaptive model unloading to prevent system resource exhaustion.", "zh": "智能内存压力监控，自适应模型卸载，防止系统资源耗尽。"},
    "demo.secureEnv.title": {"en": "Secure Environment", "zh": "安全环境"},
    "demo.secureEnv.content": {"en": "Hardware-backed Keychain encryption and sandboxed execution ensure your knowledge base remains private and secure.", "zh": "硬件级 Keychain 加密与沙箱执行确保您的知识库始终保持私密安全。"},
    "demo.toolInterface.title": {"en": "Tool Interface", "zh": "工具接口"},
    "demo.toolInterface.content": {"en": "Extensible plugin system allowing AI models to interact with external tools and services through a secure interface.", "zh": "可扩展插件系统，允许 AI 模型通过安全接口与外部工具和服务交互。"},
    "demo.toolchain.title": {"en": "AI Toolchain", "zh": "AI 工具链"},
    "demo.toolchain.content": {"en": "End-to-end pipeline from document ingestion through embedding, indexing, to AI-powered synthesis and insight generation.", "zh": "从文档摄入经嵌入、索引到 AI 驱动合成与洞察生成的端到端流水线。"},
    "demo.topology.title": {"en": "Knowledge Topology", "zh": "知识拓扑"},
    "demo.topology.content": {"en": "3D interactive knowledge graph revealing hidden connections and structural patterns across your entire knowledge base.", "zh": "3D 交互式知识图谱揭示知识库中隐藏的连接与结构模式。"},
    "demo.transformer.title": {"en": "Transformer Engine", "zh": "Transformer 引擎"},
    "demo.transformer.content": {"en": "Core AI engine leveraging transformer architecture for deep semantic understanding and content generation.", "zh": "基于 Transformer 架构的核心 AI 引擎，实现深度语义理解与内容生成。"},
    "demo.vectorDB.title": {"en": "Vector Database", "zh": "向量数据库"},
    "demo.vectorDB.content": {"en": "High-performance vector storage with approximate nearest neighbor search for sub-millisecond semantic retrieval.", "zh": "高性能向量存储，支持近似最近邻搜索，实现亚毫秒级语义检索。"},

    # Watch
    "watch.words": {"en": "Words", "zh": "字"},
    "watch.tenThousand": {"en": "10K", "zh": "万"},
    "watch.recentUpdates": {"en": "Recent Updates", "zh": "最近更新"},
    "watch.pages": {"en": "Pages", "zh": "页面"},

    # Widget
    "pageType": {"en": "Page Type", "zh": "页面类型"},

    # Graph
    "graph.": {"en": "Graph", "zh": "图谱"},
    "graph3d.": {"en": "3D Graph", "zh": "3D 图谱"},

    # Transfer
    "pagesCount": {"en": "Pages Count", "zh": "页面数量"},
    "icloud.error.systemBusy": {"en": "System Busy", "zh": "系统繁忙"},
    "icloud.error.engineNotReady": {"en": "Engine Not Ready", "zh": "引擎未就绪"},

    # Knowledge
    "icloud.error.internal": {"en": "Internal Error", "zh": "内部错误"},

    # Plugin
    "page.content": {"en": "Content", "zh": "内容"},

    # Coachmark
    "medal.\(id).desc": {"en": "Medal Description", "zh": "勋章描述"},
    "medal.\(id).title": {"en": "Medal Title", "zh": "勋章名称"},

    # AI Eval
    "ai.eval.performance": {"en": "Performance", "zh": "性能"},
    "ai.eval.accuracy": {"en": "Accuracy", "zh": "准确度"},
    "ai.eval.latency": {"en": "Latency", "zh": "延迟"},
    "ai.eval.tokensPerSecond": {"en": "Tokens/s", "zh": "Token/秒"},

    # AI Task
    "aitask.\(key)": {"en": "AI Task", "zh": "AI 任务"},
    "aitask.type.\(type)": {"en": "Task Type", "zh": "任务类型"},

    # Plugin permission
    "plugin.perm.\(id)": {"en": "Plugin Permission", "zh": "插件权限"},
}

# ── LLM 提示词模板键（zh-Hans 设为与 en 相同，保留英文）──
PROMPT_TEMPLATE_KEYS = {
    "llm.prompt.contentLabel", "llm.prompt.contentToExpandLabel",
    "llm.prompt.default.actions", "llm.prompt.default.expansion",
    "llm.prompt.default.infographic", "llm.prompt.default.insightQuestions",
    "llm.prompt.default.mindmap", "llm.prompt.default.quiz",
    "llm.prompt.default.report", "llm.prompt.default.summary",
    "llm.prompt.discoverLinksPrefix", "llm.prompt.discoverLinksPrefix1",
    "llm.prompt.discoverLinksPrefix2", "llm.prompt.fixSuggestion",
    "llm.prompt.folding", "llm.prompt.hydeSystem",
    "llm.prompt.hydeUserPrompt", "llm.prompt.ingestDiscoveryAssistant",
    "llm.prompt.ingestManagementAssistant", "llm.prompt.potentialLinks",
    "llm.prompt.queryExpansion", "llm.prompt.queryRewrite",
    "llm.prompt.quiz.defaultTitle", "llm.prompt.quiz.explanation",
    "llm.prompt.quiz.option", "llm.prompt.quiz.question",
    "llm.prompt.ragContextPrefix", "llm.prompt.refactor",
    "llm.prompt.replyInChinese", "llm.prompt.replyInEnglish",
    "llm.prompt.rerank", "llm.prompt.rerankSystem",
    "llm.prompt.rerankUserPrompt", "llm.prompt.reverseQAPrefix",
    "llm.prompt.rewrite.footer", "llm.prompt.rewrite.instruction",
    "llm.prompt.rewrite.rule1", "llm.prompt.rewrite.rule2",
    "llm.prompt.rewrite.rule3", "llm.prompt.rewrite.rule4",
    "llm.prompt.rewrite.rules", "llm.prompt.rewrite.userQuery",
    "llm.prompt.shortcut.deepReview", "llm.prompt.shortcut.findGaps",
    "llm.prompt.shortcut.studyPath", "llm.prompt.summaryPrefix",
    "llm.prompt.vaultContextPrefix",
    "llm.ingest.jsonSchemaDesc", "llm.ingest.jsonSchemaTitle",
}


def fix_xcstrings(catalogs_dir: str) -> dict:
    """修复所有 .xcstrings 中的 (zh) 占位符，返回修复统计。"""
    stats = {"fixed_ui": 0, "fixed_prompt": 0, "skipped": 0, "errors": []}

    for filename in sorted(os.listdir(catalogs_dir)):
        if not filename.endswith(".xcstrings"):
            continue

        filepath = os.path.join(catalogs_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)

        modified = False
        strings = data.get("strings", {})

        for key, value in strings.items():
            locs = value.get("localizations", {})
            zh_loc = locs.get("zh-Hans", {}).get("stringUnit", {})
            zh_val = zh_loc.get("value", "")

            if "(zh)" not in zh_val:
                continue

            en_loc = locs.get("en", {}).get("stringUnit", {})
            en_val = en_loc.get("value", "")

            if key in UI_TRANSLATIONS:
                trans = UI_TRANSLATIONS[key]
                en_loc["value"] = trans["en"]
                zh_loc["value"] = trans["zh"]
                stats["fixed_ui"] += 1
                modified = True
            elif key in PROMPT_TEMPLATE_KEYS:
                # 提示词模板：zh-Hans 保持与 en 相同
                zh_loc["value"] = en_val
                stats["fixed_prompt"] += 1
                modified = True
            else:
                stats["skipped"] += 1
                stats["errors"].append(f"{filename}: uncategorized key '{key}' with zh='{zh_val}'")

        if modified:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"  ✓ {filename}: fixed")

    return stats


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    print("Fixing (zh) placeholders in .xcstrings files...\n")
    stats = fix_xcstrings(CATALOGS_DIR)

    print(f"\n── Results ──")
    print(f"  UI translations fixed:  {stats['fixed_ui']}")
    print(f"  Prompt templates fixed: {stats['fixed_prompt']}")
    print(f"  Skipped (uncategorized): {stats['skipped']}")
    if stats["errors"]:
        print(f"\n  ⚠️  Uncategorized keys:")
        for e in stats["errors"]:
            print(f"    - {e}")
