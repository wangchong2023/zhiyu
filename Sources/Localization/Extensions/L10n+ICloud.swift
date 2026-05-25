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

        /// 本地化翻译
        /// /// - Parameter key: key
        /// /// - Returns: 返回值
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

        public enum Conflict {
            public static var manualMergeTitle: String { "同步冲突手动合并" }
            public static var completeMerge: String { "完成合并" }
            public static var noPhysicalConflict: String { "没有检测到文档内容的物理冲突" }
            public static var metaConflictAutoSolved: String { "日志或元数据冲突将自动通过智能融合算法解决。" }
            public static var runSmartMerge: String { "执行智能融合" }

            /// docList计数
            /// /// - Parameter count: 计数
            /// /// - Returns: 字符串
            public static func docListCount(_ count: Int) -> String { "冲突文档列表 (\(count))" }

            /// localVersionTime
            /// /// - Parameter timeStr: timeStr
            /// /// - Returns: 字符串
            public static func localVersionTime(_ timeStr: String) -> String { "本地版本时间：\(timeStr)" }

            /// remoteVersionTime
            /// /// - Parameter timeStr: timeStr
            /// /// - Returns: 字符串
            public static func remoteVersionTime(_ timeStr: String) -> String { "云端版本时间：\(timeStr)" }
            public static var smartOverwriteMode: String { "智能覆盖模式" }
            public static var allChooseLocal: String { "全部选用本地" }
            public static var allChooseRemote: String { "全部选用云端" }
            public static var localVersionHeader: String { "💻 本地版本 (Local)" }
            public static var remoteVersionHeader: String { "☁️ 云端版本 (iCloud)" }
            public static var mergedResultEditorHeader: String { "📝 最终合并结果编辑器 (Markdown)" }
            public static var chooseLocalContent: String { "取本地内容" }
            public static var chooseRemoteContent: String { "取云端内容" }
            public static var noTimeInfo: String { "无时间信息" }
        }
    }
}
