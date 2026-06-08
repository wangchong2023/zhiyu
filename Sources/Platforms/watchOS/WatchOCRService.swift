//
//  WatchOCRService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 WatchOCR 模块的核心业务逻辑服务。
//
#if os(watchOS)
import Foundation

/// watchOS OCR 处理实现 (手表暂不支持 OCR)
final class WatchOCRService: OCRServiceProtocol {

    /// 识别Text
    /// - Returns: 字符串
    func recognizeText(from image: AppImage) async throws -> String {
        return ""
    }
}
#endif