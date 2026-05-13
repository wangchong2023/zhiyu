// WatchSpeechService.swift
//
// 作者: Wang Chong
// 功能说明: SpeechServiceProtocol 的 watchOS 实现（当前作为存根，待集成 watchOS 录音能力）。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
    
    override init() {
        super.init()
    }
    
    func checkPermission() {}
    func startRecording() {}
    func stopRecording() {}
    func transcribeFile(url: URL) async throws -> String { return "" }
    func saveRecording(title: String) -> VoiceRecording {
        return VoiceRecording(id: UUID(), title: "", text: "", language: "", duration: 0, createdAt: Date())
    }
    func deleteRecording(_ recording: VoiceRecording) {}
    func clearTranscription() {}
}
#endif
