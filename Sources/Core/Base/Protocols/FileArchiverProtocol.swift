// FileArchiverProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：归档与压缩服务抽象协议，用于解耦特定平台的 ZIP 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 文件归档协议
public protocol FileArchiverProtocol: Sendable {
    /// 将指定目录的内容压缩为 ZIP 文件
    /// - Parameters:
    ///   - sourceDir: 待压缩的源目录
    ///   - destinationURL: 目标文件路径 (应以 .zip 或 .pptx 结尾)
    func zip(directory sourceDir: URL, to destinationURL: URL) async throws
}
