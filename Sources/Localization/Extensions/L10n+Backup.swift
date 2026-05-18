// 功能说明: [Shared]
//
// L10n+Backup.swift
// 智宇 (ZhiYu) 多语言 Backup 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum Backup {
        public static let t = "Transfer"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var title: String { tr("backup.title") }
        public static var autoBackup: String { tr("backup.autoBackup") }
        public static var createNow: String { tr("backup.createNow") }
        public static var exportCurrent: String { tr("backup.exportCurrent") }
        public static var pages: String { tr("backup.pages") }
        public static var words: String { tr("backup.words") }
        public static var restoreTitle: String { tr("backup.restoreTitle") }
        public static var deleteConfirmTitle: String { tr("backup.deleteConfirmTitle") }
        public static var lastBackup: String { tr("backup.lastBackup") }
        public static var restore: String { tr("backup.restore") }
        public static var restoreMessage: String { tr("backup.restoreMessage") }
        public static var settings: String { tr("backup.settings") }
        public static var actions: String { tr("backup.actions") }
        public static var noBackups: String { tr("backup.noBackups") }
        public static var noBackupsDesc: String { tr("backup.noBackupsDesc") }
        public static var deleteConfirmMessage: String { tr("backup.deleteConfirmMessage") }
        public static var history: String { tr("backup.history") }

        public enum log {
            public static var createFailed: String { tr("backup.log.createFailed") }
            public static var restoreFailed: String { tr("backup.log.restoreFailed") }
            public static var saveIndexFailed: String { tr("backup.log.saveIndexFailed") }
            public static var crashRecovery: String { tr("backup.log.crashRecovery") }
        }
    }
}
