// UnsupportedFileArchiver.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：FileArchiverProtocol 的兜底实现，用于不支持文件归档的平台 (如 watchOS)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 不支持的文件归档服务占位符
public final class UnsupportedFileArchiver: FileArchiverProtocol, @unchecked Sendable {
    public init() {}
    
    public func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        throw NSError(
            domain: "FileArchiver",
            code: 405,
            userInfo: [NSLocalizedDescriptionKey: "File archiving is not supported on this platform."]
        )
    }
}
