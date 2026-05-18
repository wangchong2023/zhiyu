// 功能说明: [Shared]
//
// L10n+Schema.swift
// 智宇 (ZhiYu) 多语言 Schema 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Schema {
        public static let t = "Common" // 假设 Schema 放在 Common 表中，或者根据实际情况调整
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public struct concept {
            public static var template: String { Schema.tr("schema.concept.template") }
            public static var prompt: String { Schema.tr("schema.concept.prompt") }
            public struct field {
                public static var applications: String { Schema.tr("schema.concept.field.applications") }
                public static var theory: String { Schema.tr("schema.concept.field.theory") }
            }
        }
        public struct entity {
            public static var template: String { Schema.tr("schema.entity.template") }
            public static var prompt: String { Schema.tr("schema.entity.prompt") }
            public struct field {
                public static var attributes: String { Schema.tr("schema.entity.field.attributes") }
                public static var definition: String { Schema.tr("schema.entity.field.definition") }
                public static var relations: String { Schema.tr("schema.entity.field.relations") }
            }
        }
    }
}
