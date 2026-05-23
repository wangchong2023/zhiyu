//
//  FileArchiverProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 FileArchiver 模块的抽象契约接口。
//
import Foundation

/// 文件归档协议
public protocol FileArchiverProtocol: Sendable {
    /// 将指定目录的内容压缩为 ZIP 文件
    /// - Parameters:
    ///   - sourceDir: 待压缩的源目录
    ///   - destinationURL: 目标文件路径 (应以 .zip 或 .pptx 结尾)
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws
}

/// 文件归档过程中抛出的强类型异常枚举
public enum FileArchiverError: Error, Sendable {
    /// 目标平台不支持压缩归档操作 (替代原 405 错误码)
    case platformNotSupported
    /// 压缩流写入异常或物理磁盘空间不足
    case compressionFailed
}
