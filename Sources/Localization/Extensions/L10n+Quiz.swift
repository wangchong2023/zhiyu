//
//  L10n+Quiz.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Quiz 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Quiz {
        public static let t = "Knowledge"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var title: String { tr("quiz.title") }
        public static var completed: String { tr("quiz.completed") }
        public static var yourScore: String { tr("quiz.yourScore") }
        public static var backToPage: String { tr("quiz.backToPage") }
        public static var showAnswer: String { tr("quiz.showAnswer") }
        public static var correctAnswer: String { tr("quiz.correctAnswer") }
        public static var explanation: String { tr("quiz.explanation") }

        public static func questionFormat(_ current: Int, _ total: Int) -> String {
            trf("quiz.questionFormat", current, total)
        }
        public static func scoreFormat(_ score: Int) -> String {
            trf("quiz.scoreFormat", score)
        }
    }
}
