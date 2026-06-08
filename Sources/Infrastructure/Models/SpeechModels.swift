//
//  SpeechModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：数据模型与状态管理，定义数据结构与 @Observable 状态。
//
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
        case .localeNotSupported: return L10n.Voice.Speech.Error.localeNotSupported
        case .notAuthorized: return L10n.Voice.Speech.Error.notAuthorized
        case .audioEngineError: return L10n.Voice.Speech.Error.audioEngine
        }
    }
}
