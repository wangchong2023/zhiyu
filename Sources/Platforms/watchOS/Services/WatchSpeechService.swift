//
//  WatchSpeechService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 WatchSpeech 模块的核心业务逻辑服务。
//
#if os(watchOS)
import Foundation
import Combine
import Observation

/// watchOS 语音处理实现（存根）
@Observable
final class WatchSpeechService: NSObject, SpeechServiceProtocol {
    var isRecording = false
    var isTranscribing = false
    var transcribedText = ""
    var audioLevel: Float = 0
    var audioLevelHistory: [Float] = Array(repeating: 0, count: 20)
    var statusMessage: String = "Not Supported"
    var supportedLanguages: [(code: String, name: String)] = []
    var selectedLanguage: String = "zh-CN"
    var hasPermission: Bool = false
    var recordings: [VoiceRecording] = []
    var currentAudioFileURL: URL? { nil }

    override init() {
        super.init()
    }
    
    /// 检查Permission
    func checkPermission() {}

    /// 启动Recording
    func startRecording() {}

    /// 停止Recording
    func stopRecording() {}

    /// transcribeFile
    /// - Parameter url: url
    /// - Returns: 字符串
    func transcribeFile(url: URL) async throws -> String { return "" }

    /// 保存Recording
    /// - Parameter title: title
    /// - Returns: 返回值
    func saveRecording(title: String) -> VoiceRecording {
        return VoiceRecording(id: UUID(), title: "", text: "", language: "", duration: 0, createdAt: Date())
    }

    /// 删除Recording
    /// - Parameter recording: recording
    func deleteRecording(_ recording: VoiceRecording) {}

    /// 清除Transcription
    func clearTranscription() {}
}
#endif
