// PageDetailAISection.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识详情页 AI 实验室结果展示区。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 PageDetailView 剥离，实现组件化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 页面详情 AI 结果展示区
struct PageDetailAISection: View {
    @Environment(AIWorkflowStore.self) var aiStore
    @Environment(Router.self) var router
    let pageTitle: String
    let onLinkTap: (String) -> Void
    
    var body: some View {
        if aiStore.isProcessingPageAI || aiStore.activePageAIResult != nil {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                HStack {
                    Image(systemName: DesignSystem.Icons.sparkles)
                        .foregroundStyle(.appAccent)
                    Text(L10n.Knowledge.Page.AI.labOutput)
                        .font(.headline)
                        .foregroundStyle(.appText)
                    Spacer()
                    if !aiStore.isProcessingPageAI {
                        if let result = aiStore.activePageAIResult, result.contains("- ") {
                            Button(action: {
                                Task {
                                    @Inject var workflowService: WorkflowService
                                    try await workflowService.syncToReminders(text: result, title: pageTitle)
                                }
                            }) {
                                Label(L10n.Common.syncToReminders, systemImage: DesignSystem.Icons.checklist)
                                    .font(.caption)
                                    .foregroundStyle(.appAccent)
                            }
                            .padding(.trailing, DesignSystem.small)
                        }
                        
                        Button(action: { 
                            AppPasteboard.string = aiStore.activePageAIResult
                            HapticFeedback.shared.trigger(.success)
                        }) {
                            Image(systemName: DesignSystem.Icons.copy)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        
                        Button(action: { aiStore.activePageAIResult = nil }) {
                            Image(systemName: DesignSystem.Icons.xmarkCircle)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                    }
                }
                
                if aiStore.isProcessingPageAI {
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        AppSkeleton(height: 20).frame(width: 200)
                        AppSkeleton(height: 120)
                        AppSkeleton(height: 60)
                    }
                } else if let result = aiStore.activePageAIResult {
                    MarkdownRendererView(content: result, isPrivate: false, onLinkTap: onLinkTap)
                    .appContainer(padding: true)
                }
            }
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
