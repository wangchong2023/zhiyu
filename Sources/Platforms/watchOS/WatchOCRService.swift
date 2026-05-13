// WatchOCRService.swift
//
// 作者: Wang Chong
// 功能说明: OCRServiceProtocol 的 watchOS 实现 (存根)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import Foundation

/// watchOS OCR 处理实现 (手表暂不支持 OCR)
final class WatchOCRService: OCRServiceProtocol {
    func recognizeText(from image: AppImage) async throws -> String {
        return ""
    }
}
#endif
