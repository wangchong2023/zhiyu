// OCRServiceProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：OCR 文字识别服务抽象协议。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// OCR 文字识别服务协议
public protocol OCRServiceProtocol: Sendable {
    /// 从图像中识别文本
    func recognizeText(from image: AppImage) async throws -> String
}
