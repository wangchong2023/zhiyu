// MacFileArchiver.swift
//
// 作者: Wang Chong
// 功能说明: FileArchiverProtocol 的 macOS 实现，调用系统 /usr/bin/zip。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(macOS)
import Foundation

/// macOS 原生归档实现
final class MacFileArchiver: FileArchiverProtocol, @unchecked Sendable {
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = sourceDir
        process.arguments = ["-r", destinationURL.path, "."]

        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "MacFileArchiver", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Zip process failed"])
        }
    }
}
#endif
