// 功能说明: [Shared]
//
// L10n+Settings.swift
// 智宇 (ZhiYu) 多语言 Settings 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Settings {
        public static let t = "Settings"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
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
        public static var systemTheme: String { tr("systemTheme") }
        public static var languageEnglish: String { tr("language.english") }
        public static var languageChinese: String { tr("language.chinese") }
        public static var systemLanguage: String { tr("language.system") }
        public static var languageSystem: String { tr("language.system") }
        public static var llmSettings: String { tr("llmSettings") }
        public static var promptLab: String { tr("promptLab") }
        public static var iCloudSync: String { Localized.tr("settings.iCloudSync", table: "Settings") }
        public static var backupRestore: String { Localized.tr("backup.restore", table: "Transfer") }
        public static var operationLog: String { Localized.tr("settings.operationLog", table: "Settings") }
        public static var privacyMode: String { tr("privacyMode") }
        public static var biometricProtection: String { tr("biometricProtection") }
        public static var injectDemoData: String { Localized.tr("settings.injectDemoData", table: "Settings") }
        public static var resetData: String { tr("resetData") }
        public static var advancedMaintenance: String { Localized.tr("settings.advancedMaintenance", table: "Settings") }
        public static var about: String { tr("aboutApp") }
        public static var version: String { tr("version") }

        public struct resetOnboarding {
            public static var title: String { Localized.tr("settings.resetOnboarding.title", table: "Settings") }
            public static var message: String { Localized.tr("settings.resetOnboarding.message", table: "Settings") }
            public static var label: String { Localized.tr("settings.resetOnboarding", table: "Settings") }
        }

        public struct clearAll {
            public static var action: String { Localized.tr("settings.clearAll.action", table: "Settings") }
            public static var confirmTitle: String { Localized.tr("settings.clearAll.confirmTitle", table: "Settings") }
            public static var message: String { Localized.tr("settings.clearAll.message", table: "Settings") }
            public static var label: String { Localized.tr("settings.clearAll", table: "Settings") }
        }

        public struct injectConfirm {
            public static var title: String { Localized.tr("settings.injectConfirm.title", table: "Settings") }
            public static var message: String { Localized.tr("settings.injectConfirm.message", table: "Settings") }
        }

        public struct developer {
            public struct section {
                public static var data: String { Localized.tr("settings.developer.section.data", table: "Settings") }
                public static var dataReset: String { Localized.tr("settings.developer.section.dataReset", table: "Settings") }
                public static var operationInfo: String { Localized.tr("settings.developer.section.operationInfo", table: "Settings") }
                public static var performance_test: String { Localized.tr("settings.developer.section.performance_test", table: "Settings") }
            }

            public struct stressTest {
                public static var count: String { Localized.tr("settings.developer.stressTest.count", table: "Settings") }
                public static var run: String { Localized.tr("settings.developer.stressTest.run", table: "Settings") }
                public static var confirmTitle: String { Localized.tr("settings.developer.stressTest.confirmTitle", table: "Settings") }
                public static var confirmMessage: String { Localized.tr("settings.developer.stressTest.confirmMessage", table: "Settings") }
                public static func success(_ n: Int) -> String { Localized.trf("settings.developer.stressTest.success", table: "Settings", n) }
                public static func confirmAction(_ n: Int) -> String { Localized.trf("settings.developer.stressTest.confirmAction", table: "Settings", n) }
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
            public static var tabData: String { Localized.tr("settings.developer.section.tabData", table: "Settings") }
            public static var tabQuality: String { Localized.tr("settings.developer.section.tabQuality", table: "Settings") }
        }

        public struct InjectDemo {
            public static func successMessage(_ n: Int) -> String { Localized.trf("settings.injectDemo.successMessage", table: "Settings", n) }
            public static var errorMessage: String { Localized.tr("settings.injectDemo.errorMessage", table: "Settings") }
        }

        public struct About {
            public static var developer: String { Localized.tr("settings.about.developer", table: "Settings") }
            public static var developerName: String { Localized.tr("settings.about.developerName", table: "Settings") }
            public static var website: String { Localized.tr("settings.about.website", table: "Settings") }
            public static var version: String { Localized.tr("settings.about.version", table: "Settings") }
        }

        public struct theme {
            public static var dark: String { Localized.tr("settings.theme.dark", table: "Settings") }
            public static var light: String { Localized.tr("settings.theme.light", table: "Settings") }
            public static var system: String { Localized.tr("settings.theme.system", table: "Settings") }
        }
    }
}
