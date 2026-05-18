// 功能说明: [Shared]
//
// L10n+CoreModels.swift
// 智宇 (ZhiYu) 多语言 CoreModels 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum CoreModels {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        public enum type {
            public static var entity: String { CoreModels.tr("type.entity") }
            public static var concept: String { CoreModels.tr("type.concept") }
            public static var source: String { CoreModels.tr("type.source") }
            public static var comparison: String { CoreModels.tr("type.comparison") }
            public static var map: String { CoreModels.tr("type.map") }
            public static var raw: String { CoreModels.tr("type.raw") }
        }

        public enum Status {
            public static var active: String { CoreModels.tr("status.active") }
            public static var stub: String { CoreModels.tr("status.stub") }
            public static var needsUpdate: String { CoreModels.tr("status.needsUpdate") }
            public static var deprecated: String { CoreModels.tr("status.deprecated") }
        }

        public enum confidence {
            public static var high: String { CoreModels.tr("confidence.high") }
            public static var medium: String { CoreModels.tr("confidence.medium") }
            public static var low: String { CoreModels.tr("confidence.low") }
        }
    }
}
