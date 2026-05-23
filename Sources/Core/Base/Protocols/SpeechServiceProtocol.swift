//
//  SpeechServiceProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 SpeechService 模块的抽象契约接口。
//
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
