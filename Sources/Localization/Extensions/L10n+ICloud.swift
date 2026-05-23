//
//  L10n+ICloud.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 ICloud 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum ICloud {
        public static let t = "Ingest"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        public static var pushToCloud: String { tr("icloud.push") }
        public static var pullFromCloud: String { tr("icloud.pull") }
        public static var bidirectionalSync: String { tr("icloud.sync") }
        public static var clearCloudData: String { tr("icloud.clear") }
        public static var pushComplete: String { tr("icloud.push.complete") }
        public static var pullComplete: String { tr("icloud.pull.complete") }
        public static var syncComplete: String { tr("icloud.sync.complete") }
        public static var lastSync: String { tr("icloud.lastSync") }
        public static var never: String { tr("icloud.lastSync.never") }

        public enum Status {
            public static var syncing: String { ICloud.tr("icloud.status.syncing") }
            public static var uploading: String { ICloud.tr("icloud.status.uploading") }
            public static var downloading: String { ICloud.tr("icloud.status.downloading") }
            public static var upToDate: String { ICloud.tr("icloud.status.upToDate") }
            public static var error: String { ICloud.tr("icloud.status.error") }
            public static var notAvailable: String { ICloud.tr("icloud.status.notAvailable") }
        }

        public enum Error {
            public static var auth: String { ICloud.tr("icloud.error.auth") }
            public static var quota: String { ICloud.tr("icloud.error.quota") }
            public static var network: String { ICloud.tr("icloud.error.network") }
            public static var conflict: String { ICloud.tr("icloud.error.conflict") }
            public static var decoding: String { ICloud.tr("icloud.error.decoding") }
            public static var encoding: String { ICloud.tr("icloud.error.encoding") }
            public static var notAvailable: String { ICloud.tr("icloud.error.notAvailable") }
        }
    }
}
