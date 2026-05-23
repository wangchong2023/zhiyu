//
//  WebScraperProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Network 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 网页内容提取处理器：负责从 URL 提取 Markdown 内容
final class WebScraperProcessor: @unchecked Sendable {

    enum ScraperError: Error {
        case invalidURL
        case networkError(Error)
        case parsingFailed
    }

    /// 抓取网页内容并转换为 Markdown (使用 Jina Reader API 作为中转，适合 LLM)
    func fetchMarkdown(from urlString: String) async throws -> (markdown: String, title: String) {
        let startTime = Date()
        var normalizedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedString.lowercased().hasPrefix("http://") && !normalizedString.lowercased().hasPrefix("https://") {
            normalizedString = "https://" + normalizedString
        }

        guard let url = URL(string: normalizedString) else {
            throw ScraperError.invalidURL
        }

        // 使用 r.jina.ai 这是一个非常棒的工具，可以将任何网页转为干净的 Markdown
        let jinaURLString = "\(AppConfig.jinaReaderURL)\(url.absoluteString)"
        guard let jinaURL = URL(string: jinaURLString) else {
            throw ScraperError.invalidURL
        }

        var request = URLRequest(url: jinaURL)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ScraperError.parsingFailed
            }

            if httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                print("Scraper HTTP Error \(httpResponse.statusCode): \(body)")
                throw ScraperError.networkError(NSError(domain: "WebScraper", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
            }

            guard let content = String(data: data, encoding: .utf8) else {
                throw ScraperError.parsingFailed
            }

            // 尝试从 Markdown 中提取标题（通常第一行是 # Title）
            let lines = content.components(separatedBy: .newlines)
            let title = lines.first(where: { $0.hasPrefix("# ") })?.replacingOccurrences(of: "# ", with: "")
                        ?? url.host ?? "未命名网页"

            let duration = Date().timeIntervalSince(startTime)
            Logger.shared.addLog(
                action: .ingest,
                target: url.host ?? urlString,
                details: "Successfully scraped webpage. Length: \(content.count)",
                duration: duration,
                startTime: startTime,
                endTime: Date(),
                module: "WebScraper"
            )

            return (content, title)
        } catch let error as ScraperError {
            let duration = Date().timeIntervalSince(startTime)
            Logger.shared.addLog(
                action: .error,
                target: urlString,
                details: "Scraper Error: \(error)",
                duration: duration,
                startTime: startTime,
                endTime: Date(),
                module: "WebScraper"
            )
            throw error
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            Logger.shared.addLog(
                action: .error,
                target: urlString,
                details: "Network Error: \(error.localizedDescription)",
                duration: duration,
                startTime: startTime,
                endTime: Date(),
                module: "WebScraper"
            )
            throw ScraperError.networkError(error)
        }
    }
}
