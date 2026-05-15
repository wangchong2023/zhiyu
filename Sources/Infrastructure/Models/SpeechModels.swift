// SpeechModels.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：语音处理模块的通用模型与错误定义。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Voice Recording Model
/// 语音录音数据模型
public struct VoiceRecording: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var text: String
    public var language: String
    public var duration: TimeInterval
    public var createdAt: Date
    
    public init(id: UUID = UUID(), title: String, text: String, language: String, duration: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.text = text
        self.language = language
        self.duration = duration
        self.createdAt = createdAt
    }
}

// MARK: - Speech Error
/// 语音处理模块错误定义
public enum SpeechError: LocalizedError, Sendable {
    case localeNotSupported
    case notAuthorized
    case audioEngineError

    public var errorDescription: String? {
        switch self {
        case .localeNotSupported: return Localized.tr("speech.error.localeNotSupported")
        case .notAuthorized: return Localized.tr("speech.error.notAuthorized")
        case .audioEngineError: return Localized.tr("speech.error.audioEngine")
        }
    }
}
