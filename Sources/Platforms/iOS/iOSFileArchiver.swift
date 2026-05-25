//
//  iOSFileArchiver.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 iOS 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// iOS/watchOS 归档实现 (目前暂不支持)
final class iOSFileArchiver: FileArchiverProtocol, Sendable {

    /// zip
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws {
        throw FileArchiverError.platformNotSupported
    }
}
