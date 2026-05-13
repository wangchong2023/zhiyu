// iOSOCRService.swift
//
// 作者: Wang Chong
// 功能说明: OCRServiceProtocol 的 iOS/macOS 实现，基于 Vision 框架。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if canImport(Vision)
import Foundation
import Vision

/// iOS/macOS OCR 处理实现
final class iOSOCRService: OCRServiceProtocol {
    func recognizeText(from image: AppImage) async throws -> String {
        guard let cgImage = image.appCGImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noResults)
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            // Support Chinese + English + Japanese + Korean
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja", "ko"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - OCR Error
enum OCRError: LocalizedError {
    case invalidImage
    case noResults
    case cameraUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage: return Localized.tr("ocr.error.invalidImage")
        case .noResults: return Localized.tr("ocr.error.noResults")
        case .cameraUnavailable: return Localized.tr("ocr.error.cameraUnavailable")
        }
    }
}
#endif
