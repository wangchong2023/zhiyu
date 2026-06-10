//
//  iOSSpeechService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 iOSSpeech 模块的核心业务逻辑服务。
//
#if !os(watchOS)
import Foundation
#if canImport(Speech)
@preconcurrency import Speech
#endif
import AVFoundation
import Combine
import Observation

/// iOS 语音处理实现
@Observable
final class iOSSpeechService: NSObject, SpeechServiceProtocol {
    var isRecording = false
    var isTranscribing = false
    var transcribedText = ""
    var audioLevel: Float = 0
    var audioLevelHistory: [Float] = Array(repeating: 0, count: 20)
    var statusMessage: String = ""
    var supportedLanguages: [(code: String, name: String)] = []
    var selectedLanguage: String = "zh-CN"
    var hasPermission: Bool = false
    var recordings: [VoiceRecording] = []

#if canImport(Speech)
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
#endif
    private var audioEngine: AVAudioEngine?
    private var audioRecorder: AVAudioRecorder?
    var currentAudioFileURL: URL? {
        audioRecorder?.url
    }

    override init() {
        super.init()
        loadSupportedLanguages()
        checkPermission()
        loadRecordings()
    }

    /// 检查Permission
    func checkPermission() {
#if canImport(Speech)
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.hasPermission = status == .authorized
                switch status {
                case .authorized:
                    self.statusMessage = L10n.Voice.Speech.Status.ready
                case .denied:
                    self.statusMessage = L10n.Voice.Speech.Status.denied
                case .restricted:
                    self.statusMessage = L10n.Voice.Speech.Status.restricted
                case .notDetermined:
                    self.statusMessage = L10n.Voice.Speech.Status.notDetermined
                @unknown default:
                    self.statusMessage = L10n.Voice.Speech.Status.unknown
                }
            }
        }
#endif
    }

    private func loadSupportedLanguages() {
        let locales: [(String, String)] = [
            ("zh-CN", L10n.Voice.Speech.Lang.zhHans),
            ("zh-TW", L10n.Voice.Speech.Lang.zhHant),
            ("en-US", L10n.Voice.Speech.Lang.enUS),
            ("en-GB", L10n.Voice.Speech.Lang.enGB),
            ("ja-JP", L10n.Voice.Speech.Lang.jaJP),
            ("ko-KR", L10n.Voice.Speech.Lang.koKR),
            ("fr-FR", L10n.Voice.Speech.Lang.frFR),
            ("de-DE", L10n.Voice.Speech.Lang.deDE),
            ("es-ES", L10n.Voice.Speech.Lang.esES),
            ("pt-BR", L10n.Voice.Speech.Lang.ptBR)
        ]

#if canImport(Speech)
        supportedLanguages = locales.filter { locale in
            SFSpeechRecognizer(locale: Locale(identifier: locale.0)) != nil
        }
#endif

        let preferred = Locale.preferredLanguages.first ?? "en-US"
        if preferred.hasPrefix("zh-Hans") || preferred.hasPrefix("zh-CN") {
            selectedLanguage = "zh-CN"
        } else if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") {
            selectedLanguage = "zh-TW"
        } else if let match = supportedLanguages.first(where: { preferred.hasPrefix($0.code) }) {
            selectedLanguage = match.code
        }
    }

    /// 启动Recording
    func startRecording() {
        guard hasPermission else {
            statusMessage = L10n.Voice.Speech.Status.denied
            return
        }

#if canImport(Speech)
        let locale = Locale(identifier: selectedLanguage)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            statusMessage = L10n.Voice.Speech.Status.localeNotSupported
            return
        }

        speechRecognizer = recognizer
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        #if targetEnvironment(simulator)
        statusMessage = L10n.Voice.Speech.Status.simulatorNotSupported
        #else
        setupRecognitionRequest()
        guard recognitionRequest != nil else { return }

        setupAudioTap(inputNode: audioEngine.inputNode)
        startAudioEngine(audioEngine)
        startRecognitionTask(recognizer: recognizer)
        #endif

        // 并行录制原始音频到文件
        startAudioRecorder()
#endif
    }

    private func startAudioRecorder() {
        let tempDir = FileManager.default.temporaryDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let ts = formatter.string(from: Date())
        let fileName = "voice_\(ts).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try? AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()
    }

    private func setupRecognitionRequest() {
#if canImport(Speech)
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
#endif
    }

    private func setupAudioTap(inputNode: AVAudioInputNode) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
#if canImport(Speech)
            self?.recognitionRequest?.append(buffer)
#endif
            self?.calculateAudioLevel(from: buffer)
        }
    }

    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
        let channelData = buffer.floatChannelData?[0]
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        let avgPower = 20 * log10(max(rms, 1e-8))

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.audioLevel = max(0, min(1, (avgPower + 50) / 50))
            self.audioLevelHistory.removeFirst()
            self.audioLevelHistory.append(max(0, min(1, (avgPower + 50) / 50)))
        }
    }

    private func startAudioEngine(_ audioEngine: AVAudioEngine) {
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            statusMessage = L10n.Voice.Speech.Status.recording
        } catch {
            statusMessage = L10n.Voice.Speech.Status.audioError
        }
    }

    private func startRecognitionTask(recognizer: SFSpeechRecognizer) {
#if canImport(Speech)
        guard let request = recognitionRequest else { return }
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    if result.isFinal { self.stopRecording() }
                }
                if let error = error {
                    self.statusMessage = "\(L10n.Voice.Speech.Status.error): \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
#endif
    }

    /// 停止Recording
    func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
#if canImport(Speech)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
#endif
        audioRecorder?.stop()
        isRecording = false
        audioLevel = 0
        audioLevelHistory = Array(repeating: 0, count: 20)
        statusMessage = transcribedText.isEmpty ? L10n.Voice.Speech.Status.ready : L10n.Voice.Speech.Status.complete
    }

    /// transcribeFile
    /// - Parameter url: url
    /// - Returns: 字符串
    func transcribeFile(url: URL) async throws -> String {
        isTranscribing = true
        defer { isTranscribing = false }
#if canImport(Speech)
        let locale = Locale(identifier: selectedLanguage)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else { throw SpeechError.localeNotSupported }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error { continuation.resume(throwing: error); return }
                if let result = result, result.isFinal { continuation.resume(returning: result.bestTranscription.formattedString) }
            }
        }
#else
        return ""
#endif
    }

    /// 保存Recording
    /// - Parameter title: title
    /// - Returns: 返回值
    func saveRecording(title: String) -> VoiceRecording {
        let recording = VoiceRecording(id: UUID(), title: title, text: transcribedText, language: selectedLanguage, duration: 0, createdAt: Date())
        recordings.insert(recording, at: 0)
        saveRecordingsToDisk()
        return recording
    }

    /// 删除Recording
    /// - Parameter recording: recording
    func deleteRecording(_ recording: VoiceRecording) {
        recordings.removeAll { $0.id == recording.id }
        saveRecordingsToDisk()
    }

    /// 清除Transcription
    func clearTranscription() {
        transcribedText = ""
        statusMessage = L10n.Voice.Speech.Status.ready
    }

    private let recordingsKey = AppConstants.Keys.Storage.voiceRecordings
    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: recordingsKey), let decoded = try? JSONDecoder().decode([VoiceRecording].self, from: data) { recordings = decoded }
    }
    private func saveRecordingsToDisk() {
        if let data = try? JSONEncoder().encode(recordings) { UserDefaults.standard.set(data, forKey: recordingsKey) }
    }
}
#endif
