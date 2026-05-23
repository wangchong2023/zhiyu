//
//  ColorSchemeMode.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Themes 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

// MARK: - Color Scheme Mode
enum ColorSchemeMode: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return L10n.Settings.theme.system
        case .light: return L10n.Settings.theme.light
        case .dark: return L10n.Settings.theme.dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
