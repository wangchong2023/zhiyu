// 功能说明: [Shared]
//
// L10n+Quiz.swift
// 智宇 (ZhiYu) 多语言 Quiz 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum Quiz {
        public static let t = "Quiz"
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
