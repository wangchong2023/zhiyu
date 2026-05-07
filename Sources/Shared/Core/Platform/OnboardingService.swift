// OnboardingService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的新手引导服务（OnboardingService），旨在为新用户提供沉浸式的产品价值呈现与交互教学。
// 该服务通过状态驱动的蒙层系统，引导用户快速掌握系统的核心能力，主要功能点如下：
// 1. 线性引导流程：定义了从知识图谱、AI 实验室到安全金库的阶段性引导步骤（OnboardingStep），支持状态化的步进控制。
// 2. 状态持久化管理：利用 UserDefaults 记录用户的引导完成状态，确保在不同设备或安装周期下的逻辑一致性。
// 3. 沉浸式交互覆盖层：提供高度定制化的 OnboardingOverlay 组件，支持跨平台的缩放动画与触感反馈。
// 4. 智适应资源加载：根据当前引导阶段动态加载对应的图标与本地化文案，通过视觉分级提升品牌感知。
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，规范化引导页面的图标尺寸与圆角常量
//   - 2026-05-07: 移除 SwiftUI 依赖，将视图层解耦至 OnboardingOverlay.swift，使用 UserDefaults 替换 @AppStorage
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// 用户引导服务 (产品视角：价值呈现与留存)
final class OnboardingService: ObservableObject {
    private let onboardingKey = "hasCompletedOnboarding"
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }
    
    @Published var currentStep: OnboardingStep?
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    enum OnboardingStep: Int, CaseIterable, Identifiable {
        case graph = 0
        case aiLab = 1
        case vault = 2
        
        var id: Int { self.rawValue }
        
        var title: String {
            switch self {
            case .graph: return Localized.tr("onboarding.step.graph.title")
            case .aiLab: return Localized.tr("onboarding.step.aiLab.title")
            case .vault: return Localized.tr("onboarding.step.vault.title")
            }
        }
        
        var description: String {
            switch self {
            case .graph: return Localized.tr("onboarding.step.graph.desc")
            case .aiLab: return Localized.tr("onboarding.step.aiLab.desc")
            case .vault: return Localized.tr("onboarding.step.vault.desc")
            }
        }

        var icon: String {
            switch self {
            case .graph: return "network"
            case .aiLab: return "sparkles"
            case .vault: return "lock.shield"
            }
        }
    }
    
    func nextStep() {
        if let current = currentStep, let next = OnboardingStep(rawValue: current.rawValue + 1) {
            currentStep = next
        } else if currentStep == nil {
            currentStep = .graph
        } else {
            completeOnboarding()
        }
    }
    
    func completeOnboarding() {
        currentStep = nil
        hasCompletedOnboarding = true
    }
    
    func reset() {
        hasCompletedOnboarding = false
        currentStep = nil
    }
}
