//
//  OnboardingService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：实现 Onboarding 模块的核心业务逻辑服务。
//
import Foundation
import Combine

/// 新手引导服务
/// 负责维护和持久化新手引导的状态，并在需要时触发引导视图
@MainActor final class OnboardingService: ObservableObject {
    static let shared = OnboardingService()
    
    private let onboardingKey = AppConstants.Keys.Storage.hasCompletedOnboarding
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }
    
    @Published var currentStep: OnboardingStep?
    
    init() {
        // Standardize on the constant key. 
        // If the legacy key exists, it will be handled by reading from the new key if they match,
        // or by accepting that we are standardizing on the new constant-defined key.
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.hasCompletedOnboarding)
    }
    
    enum OnboardingStep: Int, CaseIterable, Identifiable {
        case graph = 0
        case aiLab = 1
        case vault = 2
        
        var id: Int { self.rawValue }
        
        var icon: String {
            switch self {
            case .graph: return "network"
            case .aiLab: return "cpu"
            case .vault: return "archivebox"
            }
        }
        
        var title: String {
            switch self {
            case .graph: return L10n.Onboarding.Step.graph.title
            case .aiLab: return L10n.Onboarding.Step.aiLab.title
            case .vault: return L10n.Onboarding.Step.vault.title
            }
        }
        
        var description: String {
            switch self {
            case .graph: return L10n.Onboarding.Step.graph.desc
            case .aiLab: return L10n.Onboarding.Step.aiLab.desc
            case .vault: return L10n.Onboarding.Step.vault.desc
            }
        }
    }
    
    func reset() {
        hasCompletedOnboarding = false
        currentStep = .graph
    }
    
    func nextStep() {
        guard let current = currentStep else {
            currentStep = .graph
            return
        }
        
        if current.rawValue < OnboardingStep.allCases.count - 1 {
            currentStep = OnboardingStep(rawValue: current.rawValue + 1)
        } else {
            finish()
        }
    }
    
    func finish() {
        hasCompletedOnboarding = true
        currentStep = nil
    }
    
    func completeOnboarding() {
        finish()
    }
}
