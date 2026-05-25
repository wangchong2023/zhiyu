//
//  UnsupportedFileArchiver.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Stubs 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 不支持的文件归档服务占位符
public final class UnsupportedFileArchiver: FileArchiverProtocol, @unchecked Sendable {
    public init() {}
    
    /// zip
    public func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        throw FileArchiverError.platformNotSupported
    }
}
