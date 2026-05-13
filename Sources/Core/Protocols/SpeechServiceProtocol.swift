// SpeechServiceProtocol.swift
//
// 作者: Wang Chong
// 功能说明: 语音处理服务抽象协议。
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，支持物理隔离多平台实现。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine
import Observation

/// 语音处理服务协议
@MainActor
public protocol SpeechServiceProtocol: AnyObject, Observable {
    var isRecording: Bool { get }
    var isTranscribing: Bool { get }
    var transcribedText: String { get set }
    var audioLevel: Float { get }
    var audioLevelHistory: [Float] { get }
    var statusMessage: String { get }
    var supportedLanguages: [(code: String, name: String)] { get }
    var selectedLanguage: String { get set }
    var hasPermission: Bool { get }
    var recordings: [VoiceRecording] { get }
    
    func checkPermission()
    func startRecording()
    func stopRecording()
    func transcribeFile(url: URL) async throws -> String
    func saveRecording(title: String) -> VoiceRecording
    func deleteRecording(_ recording: VoiceRecording)
    func clearTranscription()
}
