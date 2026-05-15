// ActivityService.swift
//
// 作者: Wang Chong
// 功能说明: 灵动岛与实时活动管理服务 (iOS 专属)
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 适配 Mac Catalyst，禁用不支持的 ActivityKit 逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
@preconcurrency import ActivityKit
#endif

/// 灵动岛与实时活动管理服务 (iOS 专属)
/// 负责在 Dynamic Island 展示 AI 扫描、导出、同步等长时任务的进度。
@MainActor
final class ActivityService {
    static let shared = ActivityService()

    #if os(iOS) && !targetEnvironment(macCatalyst)
    /// 任务 ID 与实时活动的映射表，支持多任务并发展示
    nonisolated(unsafe) private var activeActivities: [UUID: Activity<AIProcessingAttributes>] = [:]
    #endif

    private init() {}

    /// 启动实时活动
    func startActivity(id: UUID, name: String, target: String) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        Task { @MainActor in
            Logger.shared.debug("🏝️ [Dynamic Island] 准备为任务 \(id) 启动实时活动: \(name)")
            
            let attributes = AIProcessingAttributes(taskName: name, startTime: Date())
            let contentState = AIProcessingAttributes.ContentState(progress: 0.05, status: target)
            
            do {
                if activeActivities.count >= 5 {
                    if let oldestID = activeActivities.keys.first {
                        await activeActivities[oldestID]?.end(nil, dismissalPolicy: .immediate)
                        activeActivities.removeValue(forKey: oldestID)
                    }
                }
                
                let activity = try Activity<AIProcessingAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: contentState, staleDate: nil)
                )
                activeActivities[id] = activity
                Logger.shared.debug("✅ [Dynamic Island] 任务 \(id) 实时活动已启动")
            } catch {
                Logger.shared.error("❌ [Dynamic Island] 启动失败: \(error.localizedDescription)")
            }
        }
        #endif
    }

    /// 更新指定任务的实时进度
    func updateProgress(id: UUID, progress: Double, message: String) async {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        guard let activity = activeActivities[id] else { return }
        
        let newState = AIProcessingAttributes.ContentState(progress: progress, status: message)
        let title = LocalizedStringResource(stringLiteral: "\(Int(progress * 100))%")
        let body = LocalizedStringResource(stringLiteral: message)
        let alertConfiguration = AlertConfiguration(title: title, body: body, sound: .default)
        
        await activity.update(
            ActivityContent(state: newState, staleDate: nil),
            alertConfiguration: alertConfiguration
        )
        #endif
    }

    /// 结束指定任务的实时活动
    func endActivity(id: UUID) async {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        guard let activity = activeActivities[id] else { return }
        
        Logger.shared.debug("🏝️ [Dynamic Island] 任务 \(id) 实时活动即将结束")
        
        let content = ActivityContent(state: activity.content.state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        activeActivities.removeValue(forKey: id)
        #endif
    }
}
