// 功能说明: [Shared]
//
// L10n+Transfer.swift
// 智宇 (ZhiYu) 多语言 Transfer 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Transfer {
        public static let t = "Ingest"
        public struct Export {
            public static func trf(_ key: String, _ args: CVarArg...) -> String {
                Localized.trf(key, table: Transfer.t, arguments: args)
            }
        }
    }
}
