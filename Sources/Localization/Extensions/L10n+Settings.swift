//
//  L10n+Settings.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Settings 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Settings {
        public static let t = "System"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// - Parameter key: key
        /// - Parameter args: args
        /// - Returns: 返回值
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        /// 获取插件权限提示文案
        /// - Parameter name: 插件名称
        /// - Returns: 本地化格式化文案
        public static func pluginPermissionMessage(_ name: String) -> String { Settings.trf("plugin.permission.message", name) }

        /// 获取端侧模型加载失败错误文案
        /// - Parameter code: 错误代码
        /// - Returns: 本地化格式化文案
        public static func onDeviceErrorFormat(_ code: String) -> String { Settings.trf("ondevice.errorFormat", code) }

        /// 获取iCloud最后同步时间文案
        /// - Parameter date: 同步时间字符串
        /// - Returns: 本地化格式化文案
        public static func iCloudLastSyncFormat(_ date: String) -> String { Settings.trf("icloud.lastSyncFormat", date) }

        public static var title: String { tr("settings") }
        public static var systemTheme: String { tr("settings.systemTheme") }
        public static var languageEnglish: String { tr("language.english") }
        public static var languageChinese: String { tr("language.chinese") }
        public static var systemLanguage: String { tr("settings.systemLanguage") }
        public static var languageSystem: String { tr("language.system") }
        public static var llmSettings: String { tr("llmSettings") }
        public static var promptLab: String { tr("promptLab") }
        public static var onDeviceLLM: String { tr("settings.onDeviceLLM") }
        public static var iCloudSync: String { Localized.tr("settings.iCloudSync", table: t) }
        public static var backupRestore: String { Localized.tr("backup.restore", table: "Transfer") }
        public static var operationLog: String { Localized.tr("settings.operationLog", table: t) }
        public static var privacyMode: String { tr("privacyMode") }
        public static var biometricProtection: String { tr("biometricProtection") }
        public static var injectDemoData: String { Localized.tr("settings.injectDemoData", table: t) }
        public static var resetData: String { tr("resetData") }
        public static var advancedMaintenance: String { Localized.tr("settings.advancedMaintenance", table: t) }
        public static var about: String { tr("aboutApp") }
        public static var version: String { tr("version") }
        /// 选择设置大类的占位提示文本
        public static var selectCategoryTip: String { tr("settings.selectCategoryTip") }

        public struct resetOnboarding {
            public static var title: String { Localized.tr("settings.resetOnboarding.title", table: t) }
            public static var message: String { Localized.tr("settings.resetOnboarding.message", table: t) }
            public static var label: String { Localized.tr("settings.resetOnboarding", table: t) }
        }

        public struct clearAll {
            public static var action: String { Localized.tr("settings.clearAll.action", table: t) }
            public static var confirmTitle: String { Localized.tr("settings.clearAll.confirmTitle", table: t) }
            public static var message: String { Localized.tr("settings.clearAll.message", table: t) }
            public static var label: String { Localized.tr("settings.clearAll", table: t) }
        }

        public struct injectConfirm {
            public static var title: String { Localized.tr("settings.injectConfirm.title", table: t) }
            public static var message: String { Localized.tr("settings.injectConfirm.message", table: t) }
        }

        public struct developer {
            public struct section {
                public static var data: String { Localized.tr("settings.developer.section.data", table: t) }
                public static var dataReset: String { Localized.tr("settings.developer.section.dataReset", table: t) }
                public static var operationInfo: String { Localized.tr("settings.developer.section.operationInfo", table: t) }
                public static var performance_test: String { Localized.tr("settings.developer.section.performance_test", table: t) }
            }

            public struct stressTest {
                public static var count: String { Localized.tr("settings.developer.stressTest.count", table: t) }
                public static var run: String { Localized.tr("settings.developer.stressTest.run", table: t) }
                public static var confirmTitle: String { Localized.tr("settings.developer.stressTest.confirmTitle", table: t) }
                public static var confirmMessage: String { Localized.tr("settings.developer.stressTest.confirmMessage", table: t) }

                /// success
                /// - Parameter n: n
                /// - Returns: 字符串
                public static func success(_ n: Int) -> String { Localized.trf("settings.developer.stressTest.success", table: t, n) }

                /// confirmAction
                /// - Parameter n: n
                /// - Returns: 字符串
                public static func confirmAction(_ n: Int) -> String { Localized.trf("settings.developer.stressTest.confirmAction", table: t, n) }
            }
        }

        public struct Section {
            public static var appearance: String { Settings.tr("section.appearance") }
            public static var ai: String { Settings.tr("section.ai") }
            public static var data: String { Settings.tr("section.data") }
            public static var security: String { Settings.tr("section.security") }
            public static var maintenance: String { Settings.tr("section.maintenance") }
            public static var about: String { Settings.tr("section.about") }
            public static var developer: String { Settings.tr("section.developer") }
            public static var plugins: String { Settings.tr("section.plugins") }
            public static var tabData: String { Localized.tr("settings.developer.section.tabData", table: t) }
            public static var tabQuality: String { Localized.tr("settings.developer.section.tabQuality", table: t) }
        }

        public struct InjectDemo {

            /// successMessage
            /// - Parameter n: n
            /// - Returns: 字符串
            public static func successMessage(_ n: Int) -> String { Localized.trf("settings.injectDemo.successMessage", table: t, n) }
            public static var errorMessage: String { Localized.tr("settings.injectDemo.errorMessage", table: t) }
        }

        public struct About {
            public static var developer: String { Localized.tr("settings.about.developer", table: t) }
            public static var developerName: String { Localized.tr("settings.about.developerName", table: t) }
            public static var website: String { Localized.tr("settings.about.website", table: t) }
            public static var version: String { Localized.tr("settings.about.version", table: t) }
        }

        public struct theme {
            public static var dark: String { Localized.tr("settings.theme.dark", table: t) }
            public static var light: String { Localized.tr("settings.theme.light", table: t) }
            public static var system: String { Localized.tr("settings.theme.system", table: t) }
        }

        public struct OnDevice {
            public static var npuAcceleration: String { Localized.tr("settings.ondevice.npu", table: t) }
            public static var descNpu: String { Localized.tr("settings.ondevice.descNpu", table: t) }
            public static var ramAllocation: String { Localized.tr("settings.ondevice.ram", table: t) }
            public static var descRam: String { Localized.tr("settings.ondevice.descRam", table: t) }
            public static var maxContext: String { Localized.tr("settings.ondevice.context", table: t) }
            public static var descContext: String { Localized.tr("settings.ondevice.descContext", table: t) }
            public static var overheatProtection: String { Localized.tr("settings.ondevice.overheat", table: t) }
            public static var descOverheat: String { Localized.tr("settings.ondevice.descOverheat", table: t) }
            public static var performanceConfig: String { Localized.tr("settings.ondevice.perfConfig", table: t) }
        }
    }
}
