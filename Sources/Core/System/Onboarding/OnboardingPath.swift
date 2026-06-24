//
//  OnboardingPath.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：引导路径选择 + 里程碑触发系统

import Foundation
import SwiftUI

// MARK: - 引导路径

public enum OnboardingPath: String, CaseIterable, Sendable {
    case quickStart
    case importData
    case explore

    public var icon: String {
        switch self {
        case .quickStart: return "rocket.fill"
        case .importData: return "tray.and.arrow.down.fill"
        case .explore: return "safari.fill"
        }
    }

    public var color: Color {
        switch self {
        case .quickStart: return .blue
        case .importData: return .green
        case .explore: return .orange
        }
    }
}

// MARK: - 引导里程碑

public enum OnboardingMilestone: String, CaseIterable, Sendable {
    case firstPageCreated
    case firstAIChat
    case firstGraphView
    case firstSynthesis
    case pageCount10
    case pageCount50
    case pageCount100

    // MARK: - KeyStore

    private static let prefix = "onboarding.milestone"
    /// Factory 风格：属性类型标注为可选（T?），@Inject 自动使用 resolveOptional
    @Inject private static var keyStore: (any KeyStoreProtocol)?

    var key: String { "\(Self.prefix).\(rawValue)" }

    public var hasBeenShown: Bool {
        Self.keyStore?.bool(forKey: key) ?? false
    }

    public func markAsShown() {
        Self.keyStore?.set(true, forKey: key)
    }

    // MARK: - Toast

    public var toastMessage: String {
        switch self {
        case .firstPageCreated: return L10n.Onboarding.Milestone.firstPage
        case .firstAIChat: return L10n.Onboarding.Milestone.firstChat
        case .firstGraphView: return L10n.Onboarding.Milestone.firstGraph
        case .firstSynthesis: return L10n.Onboarding.Milestone.firstSynthesis
        case .pageCount10: return L10n.Onboarding.Milestone.page10
        case .pageCount50: return L10n.Onboarding.Milestone.page50
        case .pageCount100: return L10n.Onboarding.Milestone.page100
        }
    }

    // MARK: - 触发阈值

    public static func checkPageCountMilestone(_ count: Int) -> OnboardingMilestone? {
        switch count {
        case 1: return .firstPageCreated
        case 10: return .pageCount10
        case 50: return .pageCount50
        case 100: return .pageCount100
        default: return nil
        }
    }
}
