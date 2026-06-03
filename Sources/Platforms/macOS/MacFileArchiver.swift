//
//  MacFileArchiver.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 macOS 模块，提供相关的结构体或工具支撑。
//
#if os(macOS) && !targetEnvironment(macCatalyst)
import Foundation

/// macOS 原生归档实现
final class MacFileArchiver: FileArchiverProtocol, @unchecked Sendable {

    /// zip
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = sourceDir
        process.arguments = ["-r", destinationURL.path, "."]

        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "MacFileArchiver", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Zip_Failed"])
        }
    }
}
#endif
