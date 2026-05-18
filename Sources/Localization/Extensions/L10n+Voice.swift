// 功能说明: [Shared]
//
// L10n+Voice.swift
// 智宇 (ZhiYu) 多语言 Voice 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum Voice {
        public static let t = "Voice"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public enum Speech {
            public static var title: String { Voice.tr("speech.title") }
            public static var subtitle: String { Voice.tr("speech.subtitle") }
            public static var audioLevel: String { Voice.tr("speech.audioLevel") }
            public static var defaultTitle: String { Voice.tr("speech.defaultTitle") }
            public static var saveTitle: String { Voice.tr("speech.saveTitle") }
            public static var noteTitle: String { Voice.tr("speech.noteTitle") }
            public static var noteTitlePlaceholder: String { Voice.tr("speech.noteTitlePlaceholder") }
            public static var voiceNote: String { Voice.tr("speech.voiceNote") }
            public static var voiceTag: String { Voice.tr("speech.voiceTag") }
            public static var Language: String { Voice.tr("speech.language") }
            public static var needPermission: String { Voice.tr("speech.needPermission") }
            public static var requestPermission: String { Voice.tr("speech.requestPermission") }
            public static var result: String { Voice.tr("speech.result") }
            public static var history: String { Voice.tr("speech.history") }
            public static var saveToKnowledge: String { Voice.tr("speech.saveToKnowledge") }
            public static var tapToRecord: String { Voice.tr("speech.tapToRecord") }
            public static var tapToStop: String { Voice.tr("speech.tapToStop") }
            public static var characters: String { Voice.tr("speech.characters") }
            public static var confirmAndEdit: String { Voice.tr("speech.confirmAndEdit") }

            public enum Status {
                public static var ready: String { Voice.tr("speech.status.ready") }
                public static var recording: String { Voice.tr("speech.status.recording") }
                public static var complete: String { Voice.tr("speech.status.complete") }
                public static var denied: String { Voice.tr("speech.status.denied") }
                public static var restricted: String { Voice.tr("speech.status.restricted") }
                public static var notDetermined: String { Voice.tr("speech.status.notDetermined") }
                public static var unknown: String { Voice.tr("speech.status.unknown") }
                public static var error: String { Voice.tr("speech.status.error") }
                public static var audioError: String { Voice.tr("speech.status.audioError") }
                public static var localeNotSupported: String { Voice.tr("speech.status.localeNotSupported") }
                public static var simulatorNotSupported: String { Voice.tr("speech.status.simulatorNotSupported") }
            }

            public enum Error {
                public static var audioEngine: String { Voice.tr("speech.error.audioEngine") }
                public static var localeNotSupported: String { Voice.tr("speech.error.localeNotSupported") }
                public static var notAuthorized: String { Voice.tr("speech.error.notAuthorized") }
            }

            public enum Lang {
                public static var zhHans: String { Voice.tr("speech.lang.zhHans") }
                public static var zhHant: String { Voice.tr("speech.lang.zhHant") }
                public static var enUS: String { Voice.tr("speech.lang.enUS") }
                public static var enGB: String { Voice.tr("speech.lang.enGB") }
                public static var jaJP: String { Voice.tr("speech.lang.jaJP") }
                public static var koKR: String { Voice.tr("speech.lang.koKR") }
                public static var frFR: String { Voice.tr("speech.lang.frFR") }
                public static var deDE: String { Voice.tr("speech.lang.deDE") }
                public static var esES: String { Voice.tr("speech.lang.esES") }
                public static var ptBR: String { Voice.tr("speech.lang.ptBR") }
            }
        }
    }
}
