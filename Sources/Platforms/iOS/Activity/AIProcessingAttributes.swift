//
//  AIProcessingAttributes.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 Activity 模块，提供相关的结构体或工具支撑。
//
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
    /// 任务显示名称 (例如: "AI ", "")
    public var taskName: String
    /// 任务启动时间
    public var startTime: Date
    
    public init(taskName: String, startTime: Date) {
        self.taskName = taskName
        self.startTime = startTime
    }
}
#endif
