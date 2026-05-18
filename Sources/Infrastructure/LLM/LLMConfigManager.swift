// LLMConfigManager.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：LLM 配置管理器，负责 API Key、模型选择及服务端点管理。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 LLMService 剥离配置逻辑，实现职责解耦。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import Combine

/// LLM 配置管理器 (L1-Infra)
@MainActor
@Observable
public final class LLMConfigManager {
    
    // MARK: - 持久化状态
    public var provider: LLMProvider {
        get { configStore.provider }
        set { configStore.provider = newValue; refreshSubServices() }
    }
    public var apiKey: String {
        get { configStore.apiKey }
        set { configStore.apiKey = newValue; refreshSubServices() }
    }
    public var baseURL: String {
        get { configStore.baseURL }
        set { configStore.baseURL = newValue; refreshSubServices() }
    }
    public var model: String {
        get { configStore.model }
        set { configStore.model = newValue; refreshSubServices() }
    }
    public var isEnabled: Bool {
        get { configStore.isEnabled }
        set { configStore.isEnabled = newValue; refreshSubServices() }
    }
    public var autoScan: Bool {
        get { configStore.autoScan }
        set { configStore.autoScan = newValue }
    }
    public var autoRefactor: Bool {
        get { configStore.autoRefactor }
        set { configStore.autoRefactor = newValue }
    }

    /// 服务是否已就绪
    public var isReady: Bool {
        isEnabled && !apiKey.isEmpty
    }

    private let configStore: LLMConfigStore
    private var cancellables = Set<AnyCancellable>()
    
    /// 子服务刷新闭包
    private var onRefresh: (@MainActor () -> Void)?

    public init() {
        self.configStore = LLMConfigStore()
        
        // 订阅配置层底层变更
        configStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshSubServices()
            }
            .store(in: &cancellables)
    }
    
    public func setRefreshHandler(_ handler: @escaping @MainActor () -> Void) {
        self.onRefresh = handler
    }

    private func refreshSubServices() {
        onRefresh?()
    }
}
