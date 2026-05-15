// iOSFileArchiver.swift
//
// 作者: Wang Chong
// 功能说明: FileArchiverProtocol 的 iOS/watchOS 占位实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// iOS/watchOS 归档实现 (目前暂不支持)
final class iOSFileArchiver: FileArchiverProtocol, Sendable {
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        throw NSError(
            domain: "FileArchiver",
            code: 405,
            userInfo: [NSLocalizedDescriptionKey: "iOS requires a 3rd-party library for ZIP. Native toolchain not available."]
        )
    }
}
