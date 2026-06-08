//
//  L10n+Ingest.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Ingest 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Ingest {
        public static let t = "Ingest"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// - Parameter key: key
        /// - Parameter args: args
        /// - Returns: 返回值
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        /// 获取智能导入完成的提示描述
        /// - Parameter type: 导入类型
        /// - Returns: 本地化文案
        public static func smartIngestDoneDesc(_ type: String) -> String { Localized.trf("ingest.smartIngestDoneDesc", table: t, type) }

        /// 获取当前活动导入任务数文案
        /// - Parameter count: 活动任务数
        /// - Returns: 本地化文案
        public static func activeTasks(_ count: Int) -> String { Localized.trf("ingest.activeTasks", table: t, count) }

        /// 获取PDF页数格式化文案
        /// - Parameter count: 页数
        /// - Returns: 本地化文案
        public static func pdfPageCountFormat(_ count: Int) -> String { Localized.trf("pdf.pageCountFormat", table: t, count) }

        /// 获取PDF创建页面后的提示文案
        /// - Parameter title: 页面标题
        /// - Returns: 本地化文案
        public static func pdfCreatedPage(_ title: String) -> String { Localized.trf("pdf.createdPage", table: t, title) }

        /// 获取PDF页码文本
        /// - Parameter num: 页码
        /// - Returns: 本地化文案
        public static func pdfPageNumber(_ num: Int) -> String { Localized.trf("pdf.pageNumber", table: t, num) }

        /// 获取OCR扫描识别字符数字文案
        /// - Parameter count: 字符数
        /// - Returns: 本地化文案
        public static func ocrCharCountFormat(_ count: Int) -> String { Localized.trf("ocr.charCountFormat", table: t, count) }

        /// 获取PDF导入模式格式化文案
        /// - Parameter mode: 导入模式描述
        /// - Returns: 本地化文案
        public static func pdfIngestModeFormat(_ mode: String) -> String { Localized.trf("pdf.ingestModeFormat", table: t, mode) }

        /// 获取PDF高亮标记个数格式化文案
        /// - Parameter count: 高亮标记数
        /// - Returns: 本地化文案
        public static func pdfHighlightCountFormat(_ count: Int) -> String { Localized.trf("pdf.highlightCountFormat", table: t, count) }

        // MARK: - Ingest 表词条
        public static var title: String { tr("ingest.title") }
        public static var manualEntry: String { tr("ingest.manualEntry") }

        public static var importFailed: String { Ingest.tr("ingest.importFailed") }
        public static var importingFile: String { Ingest.tr("ingest.importingFile") }
        public static var invalidURL: String { Ingest.tr("ingest.invalidURL") }
        public static var fetchingURL: String { Ingest.tr("ingest.fetchingURL") }
        public static var fileImport: String { Ingest.tr("ingest.fileImport") }
        public static var urlImport: String { Ingest.tr("ingest.urlImport") }
        public static var ocrScan: String { Ingest.tr("ingest.ocrScan") }
        public static var clipboardImport: String { Ingest.tr("ingest.clipboardImport") }
        public static var voiceNote: String { Ingest.tr("ingest.voiceNote") }
        public static var fileTooLarge: String { Ingest.tr("ingest.error.fileTooLarge") }
        public static var storageFull: String { Ingest.tr("ingest.error.storageFull") }
        public static var error: String { Ingest.tr("ingest.error") }
        public static var smartToggle: String { Ingest.tr("ingest.smartToggle") }
        public static var smartToggleHint: String { Ingest.tr("ingest.smartToggleHint") }
        public static var deepScan: String { Ingest.tr("ingest.deepScan") }
        public static var deepScanDesc: String { Ingest.tr("ingest.deepScanDesc") }
        public static var submitting: String { Ingest.tr("ingest.submitting") }
        public static var submit: String { Ingest.tr("ingest.submit") }
        public static var iconCustom: String { Ingest.tr("ingest.iconCustom") }
        public static var iconDefault: String { Ingest.tr("ingest.iconDefault") }
        public static var iconReset: String { Ingest.tr("ingest.iconReset") }
        public static var preview: String { Ingest.tr("ingest.preview") }
        public static var previewConfirm: String { Ingest.tr("ingest.previewConfirm") }
        public static var previewDiscard: String { Ingest.tr("ingest.previewDiscard") }
        public static var suggestLinks: String { Ingest.tr("ingest.suggestLinks") }
        public static var tips: String { Ingest.tr("ingest.tips") }
        public static var urlImportPlaceholder: String { Ingest.tr("ingest.urlImportPlaceholder") }
        public static var webDesc: String { Ingest.tr("ingest.webDesc") }
        public static var ok: String { Common.tr("misc.ok") }
        public static var llmRequired: String { Ingest.tr("ingest.llmRequired") }
        public static var actions: String { Ingest.tr("ingest.actions") }
        public static var sources: String { Ingest.tr("ingest.sources") }
        public static var recentActivity: String { Ingest.tr("ingest.recentActivity") }
        public static var recent: String { Ingest.tr("ingest.recent") }
        public static var noActivities: String { Ingest.tr("ingest.noActivities") }
        public static var smartIngest: String { Ingest.tr("ingest.smartIngest") }
        public static var smartIngestDesc: String { Ingest.tr("ingest.smartIngestDesc") }
        public static var ecoIndexingLowPower: String { Ingest.tr("ingest.ecoIndexingLowPower") }

        public enum hero {
            public static var subtitle: String { Ingest.tr("ingest.hero.subtitle") }
        }

        public enum field {
            public static var title: String { Ingest.tr("ingest.field.title") }
            public static var titlePlaceholder: String { Ingest.tr("ingest.field.titlePlaceholder") }
            public static var tags: String { Ingest.tr("ingest.field.tags") }
            public static var tagsPlaceholder: String { Ingest.tr("ingest.field.tagsPlaceholder") }
            public static var content: String { Ingest.tr("schema.field.content") } // 修正映射
            public static var type: String { Ingest.tr("schema.field.type") }
            public static var icon: String { Ingest.tr("schema.field.icon") }
        }

        public enum method {
            public static var file: String { Ingest.tr("ingest.method.file") }
            public static var fileDesc: String { Ingest.tr("ingest.method.fileDesc") }
            public static var ocr: String { Ingest.tr("ingest.method.ocr") }
            public static var ocrDesc: String { Ingest.tr("ingest.method.ocrDesc") }
            public static var manual: String { Ingest.tr("ingest.method.manual") }
            public static var manualDesc: String { Ingest.tr("ingest.method.manualDesc") }
        }

        public typealias ocr = OCR
        public enum OCR {
            public static var title: String { Ingest.tr("ocr.title") }
            public static var pageType: String { Ingest.tr("ocr.pageType") }
            public static var saveToKnowledge: String { Ingest.tr("ocr.saveToKnowledge") }
            public static var processing: String { Ingest.tr("ocr.processing") }
            public static var result: String { Ingest.tr("ocr.result") }
            public static var selectImage: String { Ingest.tr("ocr.selectImage") }
            public static var fromAlbum: String { Ingest.tr("ocr.fromAlbum") }
            public static var recognize: String { Ingest.tr("ocr.recognize") }
            public static var copy: String { Ingest.tr("ocr.copy") }
            public static var pageTitle: String { Common.tr("pageTitle") }
            public static var changeIcon: String { Ingest.tr("ocr.changeIcon") }
            public static var customIcon: String { Ingest.tr("ocr.customIcon") }
            public static var scanTag: String { Ingest.tr("ocr.scanTag") }
            public static var confirmAndEdit: String { Ingest.tr("ocr.confirmAndEdit") }
            public static var scanFailed: String { Ingest.tr("ocr.scanFailed") }
            public static var addTag: String { Ingest.tr("ocr.addTag") }

            public enum Error {
                public static var cameraUnavailable: String { Ingest.tr("ocr.error.cameraUnavailable") }
                public static var invalidImage: String { Ingest.tr("ocr.error.invalidImage") }
                public static var noResults: String { Ingest.tr("ocr.error.noResults") }
            }
        }

        public typealias pdf = PDF
        public enum PDF {
            public static var notSupported: String { Ingest.tr("pdf.notSupported") }
            public static var notSupportedDesc: String { Ingest.tr("pdf.notSupportedDesc") }
            public static var pageSeparator: String { Ingest.tr("pdf.pageSeparator") }
            public static var contentPreview: String { Ingest.tr("pdf.contentPreview") }

            public static var ingestToKnowledge: String { Ingest.tr("pdf.ingestToKnowledge") }
            public static var ingest: String { Ingest.tr("pdf.ingest") }
            public static var pageTitle: String { Common.tr("pageTitle") }
            public static var pageType: String { Ingest.tr("pdf.pageType") }
            public static var targetPage: String { Ingest.tr("pdf.targetPage") }
            public static var extractionMethod: String { Ingest.tr("pdf.extractionMethod") }
            public static var fullText: String { Ingest.tr("pdf.fullText") }
            public static var pageRange: String { Ingest.tr("pdf.pageRange") }
            public static var highlightsOnly: String { Ingest.tr("pdf.highlightsOnly") }
            public static var fromPage: String { Ingest.tr("pdf.fromPage") }
            public static var toPage: String { Ingest.tr("pdf.toPage") }
            public static var page: String { Ingest.tr("pdf.page") }
            public static var extractionRange: String { Ingest.tr("pdf.extractionRange") }
            public static var noHighlights: String { Ingest.tr("pdf.noHighlights") }
            public static var cannotLoadPDF: String { Ingest.tr("pdf.cannotLoadPDF") }
            public static var noteLabel: String { Ingest.tr("pdf.noteLabel") }

            public static var title: String { Ingest.tr("pdf.title") }
            public static var library: String { Ingest.tr("pdf.library") }
            public static var libraryHint: String { Ingest.tr("pdf.libraryHint") }
            public static var delete: String { Common.tr("misc.delete") }
            public static var annotateSelected: String { Ingest.tr("pdf.annotateSelected") }
            public static var add: String { Ingest.tr("pdf.add") }
            public static var addNote: String { Ingest.tr("pdf.addNote") }
            public static var saveAnnotation: String { Ingest.tr("pdf.saveAnnotation") }
        }

        public enum Status {
            public static var starting: String { Ingest.tr("ingest.status.starting") }
            public static var aiEnriching: String { Ingest.tr("ingest.status.aiEnriching") }
            public static var generatingSummary: String { Ingest.tr("ingest.status.generatingSummary") }
            public static var chunking: String { Ingest.tr("ingest.status.chunking") }
            public static var processingChunk: String { Ingest.tr("ingest.status.processingChunk") }
            public static var vectorizing: String { Ingest.tr("ingest.status.vectorizing") }
            public static var completed: String { Ingest.tr("ingest.status.completed") }
            
            // WebScraper cascade statuses
            public static var webscraperLevel1Success: String { Ingest.tr("ingest.status.webscraper.level1_success") }
            public static var webscraperLevel1Failed: String { Ingest.tr("ingest.status.webscraper.level1_failed") }
            public static var webscraperLevel2Success: String { Ingest.tr("ingest.status.webscraper.level2_success") }
            public static var webscraperLevel2Failed: String { Ingest.tr("ingest.status.webscraper.level2_failed") }
            public static var webscraperLevel3Success: String { Ingest.tr("ingest.status.webscraper.level3_success") }
            public static var webscraperLevel3Failed: String { Ingest.tr("ingest.status.webscraper.level3_failed") }
            public static var webscraperLevel4Success: String { Ingest.tr("ingest.status.webscraper.level4_success") }

            /// webscraperPaywallDetected
            /// /// - Parameter code: code
            /// /// - Returns: 字符串
            public static func webscraperPaywallDetected(_ code: Int) -> String {
                String(format: Ingest.tr("ingest.status.webscraper.paywall_detected"), code)
            }
        }
    }

    public struct Status {
        public static let extraction = Localized.tr("ingest.status.extraction")
        public static let enhancement = Localized.tr("ingest.status.enhancement")
        public static let chunking = Localized.tr("ingest.status.chunking")
        public static let embedding = Localized.tr("ingest.status.embedding")
    }

}
