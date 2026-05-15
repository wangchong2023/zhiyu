// SQLiteStore+Search.swift
//
// 作者: Wang Chong
// 功能说明: SQLiteStore 扩展：处理全文搜索、反向链接发现及混合检索调度逻辑。
// MARK: [LR-02] 搜索算法支持 CJK 分词增强
// MARK: [PR-01] 全文搜索 (FTS5) 响应延迟 < 100ms
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB
import NaturalLanguage

extension SQLiteStore {
    
    // MARK: - 基础查找

    func pageByID(_ id: UUID) -> KnowledgePage? {
        pages.first { $0.id == id }
    }

    func pageByTitle(_ title: String) -> KnowledgePage? {
        let lower = title.lowercased()
        if let exact = try? repository.fetchByTitle(title) {
            return exact
        }
        return pages.first { page in
            page.aliases.contains { $0.lowercased() == lower }
        }
    }

    // MARK: - 全文搜索 (FTS5)

    /// 执行全文搜索，若查询为空则返回全表
    func searchPages(query: String) -> [KnowledgePage] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return pages }

        do {
            return try repository.search(query: trimmed)
        } catch {
            Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Search failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 链接发现 (Backlinks)

    func fetchBacklinksByID(for pageID: UUID) -> [KnowledgePage] {
        guard let page = pageByID(pageID) else { return [] }
        let sourceIDs = (try? repository.fetchBacklinks(for: page.title)) ?? []
        return sourceIDs.compactMap { id in pageByID(id) }
    }

    // MARK: - RAG 深度扫描

    /// 执行知识深度扫描，利用 RAG 管道进行语义切分与向量化
    func performDeepScan(for page: KnowledgePage) async {
        _ = await KnowledgeIngestPipeline.shared.process(
            content: page.content,
            pageID: page.id,
            llm: nil, 
            embeddingManager: self.embeddingManager
        )
        onLog?(.update, page.title, "DeepScan completed (RAG Pipeline)")
    }

    // MARK: - 旧数据迁移

    func migrateLegacyJSONIfNeeded(docsDir: URL) {
        let jsonURL = docsDir.appendingPathComponent("zhiyu_pages.json")
        guard FileManager.default.fileExists(atPath: jsonURL.path) else { return }
        guard (try? repository.count()) == 0 else { return }

        Logger.shared.addLog(action: .systemInit, target: "SQLiteStore", details: "Migrating legacy JSON...")
        do {
            let data = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let legacyPages = try decoder.decode([KnowledgePage].self, from: data)

            for page in legacyPages {
                try repository.save(page)
            }

            try? FileManager.default.moveItem(at: jsonURL, to: jsonURL.appendingPathExtension("migrated"))
        } catch {
            Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Migration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 全量操作 (Bulk Operations)

    func replaceAllPages(_ newPages: [KnowledgePage]) {
        try? repository.deleteAll()
        for page in newPages {
            _ = try? repository.save(page)
        }
    }

    func removeAllPages() {
        try? repository.deleteAll()
    }

    // MARK: - 引导填充 (Seeding)

    func seedDefaultContent(logAction: (LogAction, String, String) -> Void) async {
        let hasSeeded = UserDefaults.standard.bool(forKey: "has_seeded_initial_content")
        if hasSeeded && !pages.isEmpty { return }

        let appName = Localized.tr("app.name")

        // 1. 欢迎页
        _ = await createPage(
            title: "👋 \(Localized.tr("welcome.title")) \(appName)",
            type: .concept,
            content: """
            # \(Localized.tr("welcome.header"))

            \(appName) \(Localized.tr("welcome.desc1")) [[3D \(Localized.tr("sidebar.graph"))]] \(Localized.tr("welcome.desc2"))

            ### \(Localized.tr("welcome.startTitle"))
            - \(Localized.tr("welcome.start1")) [[\(Localized.tr("sidebar.chat"))]] \(Localized.tr("welcome.start2"))
            - \(Localized.tr("welcome.start3"))
            - \(Localized.tr("welcome.start4"))
            """,
            tags: [Localized.tr("welcome.tag1"), Localized.tr("welcome.tag2")]
        )

        // 2. 关于图谱
        _ = await createPage(
            title: Localized.tr("sidebar.graph"),
            type: .concept,
            content: Localized.tr("demo.planning.content"),
            tags: [Localized.tr("welcome.tag1"), Localized.tr("sidebar.graph")]
        )

        // 3. AI 助手指南
        _ = await createPage(
            title: Localized.tr("sidebar.chat"),
            type: .concept,
            content: Localized.tr("demo.aiAgent.content"),
            tags: ["AI", "RAG"]
        )

        UserDefaults.standard.set(true, forKey: "has_seeded_initial_content")
        logAction(.systemInit, "SystemVault", Localized.tr("log.seedSuccess"))
    }

    // MARK: - 私有辅助 (Utility)

    /// 对 FTS5 关键字进行安全转义，防止 SQL 注入或语法错误
    private func sanitizeFTSQuery(_ query: String) -> String {
        // 在 FTS5 中，转义双引号的方式是使用两个双引号
        return query.replacingOccurrences(of: "\"", with: "\"\"")
    }

    /// 从查询字符串中提取关键词进行分词分析
    private func extractSearchKeywords(from query: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = query
        var keywords: [String] = []

        tagger.enumerateTags(in: query.startIndex..<query.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            if let tag = tag, tag == .noun || tag == .otherWord {
                keywords.append(String(query[range]))
            }
            return true
        }
        return keywords
    }
}
