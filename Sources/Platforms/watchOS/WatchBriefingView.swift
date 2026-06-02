//
//  WatchBriefingView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/02.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：构建 watchOS 端的每日知识语音简报播客界面。
//
#if os(watchOS)
import SwiftUI
import AVFoundation

/// 手表端语音简报收听界面
@MainActor
struct WatchBriefingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var watchSync: any WatchSyncProtocol
    
    @State private var isPlaying = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var delegate = SpeechDelegate()
    
    var body: some View {
        VStack(spacing: 12) {
            if watchSync.isBriefingLoading {
                ProgressView("正在合成简报...")
                    .foregroundStyle(.purple)
            } else if let briefing = watchSync.latestBriefing {
                ScrollView {
                    Text(briefing)
                        .font(.body)
                        .padding()
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        if isPlaying {
                            synthesizer.pauseSpeaking(at: .word)
                            isPlaying = false
                        } else {
                            if synthesizer.isPaused {
                                synthesizer.continueSpeaking()
                            } else {
                                startSpeaking(text: briefing)
                            }
                            isPlaying = true
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        isPlaying = false
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "headphones")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                    Text("获取今日知识简报")
                        .font(.headline)
                    Button("立即生成") {
                        watchSync.requestDailyBriefing()
                    }
                    .tint(.purple)
                }
            }
        }
        .navigationTitle("语音简报")
        .onAppear {
            setupAudioSession()
            synthesizer.delegate = delegate
            delegate.onFinish = {
                isPlaying = false
            }
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func startSpeaking(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }
}

class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    
    /// speechSynthesizer回调
    /// /// - Parameter synthesizer: synthesizer
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinish?()
        }
    }
}
#endif
