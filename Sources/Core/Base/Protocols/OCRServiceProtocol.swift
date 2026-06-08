//
//  OCRServiceProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 OCRService 模块的抽象契约接口。
//
import Foundation

/// OCR 文字识别服务协议
public protocol OCRServiceProtocol: Sendable {
    /// 从图像中识别文本
    func recognizeText(from image: AppImage) async throws -> String
}
