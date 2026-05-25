//
//  ThemeManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Themes 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage(AppConstants.Keys.Storage.colorSchemeMode) var colorSchemeModeRaw: String = ColorSchemeMode.dark.rawValue
    
    nonisolated var accentColorRaw: String {
        get { UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.accentColor) ?? "blue" }
    }

    /// Migrate legacy isDarkMode key on first access
    private nonisolated(unsafe) static var didMigrate = false

    var colorSchemeMode: ColorSchemeMode {
        get {
            if !Self.didMigrate {
                Self.didMigrate = true
                // Migrate: if old key exists and new key is default
                if UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.Legacy.isDarkMode) != nil,
                   UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.colorSchemeMode) == nil {
                    let wasDark = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.Legacy.isDarkMode)
                    colorSchemeModeRaw = wasDark ? ColorSchemeMode.dark.rawValue : ColorSchemeMode.light.rawValue
                    UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.Legacy.isDarkMode)
                }

                // 额外迁移：处理从 colorSchemeMode 到 app_color_scheme_mode 的重命名
                if let oldMode = UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.Legacy.colorSchemeMode),
                   UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.colorSchemeMode) == nil {
                    colorSchemeModeRaw = oldMode
                    UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.Legacy.colorSchemeMode)
                }

                if let oldAccent = UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.Legacy.accentColor),
                   UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.accentColor) == nil {
                    UserDefaults.standard.set(oldAccent, forKey: AppConstants.Keys.Storage.accentColor)
                    UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.Legacy.accentColor)
                }
            }
            return ColorSchemeMode(rawValue: colorSchemeModeRaw) ?? .dark
        }
        set {
            colorSchemeModeRaw = newValue.rawValue
        }
    }

    /// setAccentColor
    /// /// - Parameter color: color
    func setAccentColor(_ color: String) {
        UserDefaults.standard.set(color, forKey: AppConstants.Keys.Storage.accentColor)
        objectWillChange.send()
    }

    /// Live color: reads from UserDefaults on every access (no cache).
    /// @AppStorage already handles observation via Combine.
    nonisolated var accentColor: Color {
        ThemeManager.colorForName(accentColorRaw)
    }

    /// Maps a color name string (stored in UserDefaults) to a system Color.
    nonisolated static func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }

    /// Instance method wrapper for convenience.
    nonisolated func colorForName(_ name: String) -> Color {
        Self.colorForName(name)
    }

    /// 提供统一的背景渲染入口
    @MainActor

    /// pageBackground
    func pageBackground() -> some View {
        PageBackgroundView(accentColor: accentColor)
    }
}

extension ThemeManager: @unchecked Sendable {}
