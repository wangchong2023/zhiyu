//
//  FileSystemSyncService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 FileSystemSync 模块的核心业务逻辑服务。
//
import Foundation

/// 文件系统同步服务：将数据库内容导出为物理 Markdown 文件
final class FileSystemSyncService {
    
    /// 导出整个知识库到指定目录，按 PageType 分类存放
    func exportToMarkdown(pages: [KnowledgePage], destinationURL: URL) throws {
        let fm = FileManager.default
        
        // 确保主目录存在
        if !fm.fileExists(atPath: destinationURL.path) {
            try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }
        
        for page in pages {
            // 确定子目录 (如 knowledge/entities/)
            let subfolder = page.folderName
            let folderURL = destinationURL.appendingPathComponent(subfolder)
            
            if !fm.fileExists(atPath: folderURL.path) {
                try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
            
            // 构建文件名 (处理非法字符)
            let safeTitle = page.title.replacingOccurrences(of: "/", with: "-")
                                      .replacingOccurrences(of: ":", with: "-")
            let fileURL = folderURL.appendingPathComponent("\(safeTitle).md")
            
            // 构建 Markdown 内容 (包含元数据 YAML)
            let yaml = """
            ---
            title: \(page.title)
            type: \(page.pageType.rawValue)
            tags: \(page.tags.joined(separator: ", "))
            updated: \(page.updatedAt.formatted())
            ---
            
            """
            let fullContent = yaml + page.content
            
            try fullContent.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
