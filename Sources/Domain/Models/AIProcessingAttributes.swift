// AIProcessingAttributes.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：灵动岛实时活动 (Live Activity) 数据模型协议定义。
//           本文件定义了 App 与 Widget 扩展之间共享的属性结构，用于在灵动岛上展示长时 AI 任务的进度。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

#if os(iOS) && !targetEnvironment(macCatalyst)
/// AI 治理/处理任务的实时活动属性
public struct AIProcessingAttributes: ActivityAttributes, Hashable, Sendable {
    /// 动态数据：在活动期间会频繁变化的内容（如进度、状态文本）
    public struct ContentState: Codable, Hashable, Sendable {
        /// 当前处理进度 (0.0 - 1.0)
        public var progress: Double
        /// 当前步骤的状态描述文字
        public var status: String
        
        public init(progress: Double, status: String) {
            self.progress = progress
            self.status = status
        }
    }

    /// 静态数据：在活动开启时确定且不再变化的内容
    /// 任务显示名称 (例如: "AI 治理扫描", "知识库导入")
    public var taskName: String
    /// 任务启动时间
    public var startTime: Date
    
    public init(taskName: String, startTime: Date) {
        self.taskName = taskName
        self.startTime = startTime
    }
}
#endif
