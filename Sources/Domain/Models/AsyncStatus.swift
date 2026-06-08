//
//  AsyncStatus.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：核心领域模型定义（KnowledgePage、PageLink、PluginRecord 等）。
//
import Foundation

/// 统一管理异步任务的状态枚举
public enum AsyncStatus<T>: Equatable where T: Equatable {
    case idle
    case loading(String) // 带有描述信息的加载中
    case success(T)
    case failure(String)
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}