// SynthesisActionButton.swift
//
// 作者: Wang Chong
// 功能说明: 合成操作启动按钮组件，负责单个合成任务（如思维导图生成）的触发逻辑、前置校验、生成进度展示及超限状态控制。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 合成操作启动按钮组件
/// 负责单个合成任务（如思维导图生成）的触发逻辑、前置校验、生成进度展示及超限状态控制
struct SynthesisActionButton: View {
    let type: SynthesisStore.SynthesisType
    let store: AppStore
    @Environment(SynthesisStore.self) var synthesisStore
    
    @EnvironmentObject var llmService: LLMService
    @Binding var showNoPagesAlert: Bool
    @Binding var showLimitAlert: Bool
    @Binding var showLLMAlert: Bool
    
    var body: some View {
        let state = synthesisStore.synthesisStates[type] ?? .idle
        let currentCount = synthesisStore.synthesisResults[type]?.count ?? 0
        let isLimitReached = currentCount >= synthesisStore.maxSynthesisDocsPerType
        
        VStack(spacing: 8) {
            Button(action: { 
                HapticFeedback.shared.trigger(.selection)
                
                // Pre-check: LLM Config (Key, URL, Model)
                if !llmService.isReady {
                    HapticFeedback.shared.trigger(.error)
                    showLLMAlert = true
                    return
                }
                
                if store.pages.isEmpty {
                    HapticFeedback.shared.trigger(.error)
                    showNoPagesAlert = true
                    return
                }
                
                if isLimitReached {
                    HapticFeedback.shared.trigger(.error)
                    showLimitAlert = true
                    return
                }
                
                let combinedContent = store.pages.map { "# \($0.title)\n\($0.content)" }.joined(separator: "\n\n---\n\n")
                synthesisStore.performSynthesis(type: type, combinedContent: combinedContent)
            }) {
                VStack(spacing: AppUI.Graph.tightPadding * 0.75) {
                    ZStack {
                        Circle().fill(Color.appAccent.opacity(0.05)).frame(width: AppUI.Graph.selectedNodeSize, height: AppUI.Graph.selectedNodeSize)
                        Image(systemName: type.icon)
                            .font(.system(size: AppUI.chipRadius))
                            .opacity((state == .generating || isLimitReached) ? 0.2 : 1.0)
                        
                        if state == .generating {
                            ProgressView()
                                .scaleEffect(1.0)
                                .tint(.appAccent)
                        } else if isLimitReached {
                            Image(systemName: "lock.fill")
                                .font(.system(size: AppUI.subheadlineFontSize))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                    }
                    Text(type.title).font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppUI.medium)
                .appCardStyle(cornerRadius: AppUI.large)
                .foregroundStyle(isLimitReached ? .appSecondary : .appText)
            }
            .buttonStyle(SynthesisButtonStyle())
            .disabled(state == .generating || isLimitReached)
            .animation(.spring(response: 0.3), value: state)
            .animation(.spring(response: 0.3), value: isLimitReached)
            
            if isLimitReached {
                Text(Localized.tr("synthesis.limitReachedWarning"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct SynthesisButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
