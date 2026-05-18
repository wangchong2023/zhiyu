// 功能说明: [Shared]
//
// L10n+AI.swift
// 智宇 (ZhiYu) 多语言 AI 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum AI {
        public static let t = "AI"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public enum Status {
            public static var analyzing: String { AI.tr("ai.status.analyzing") }
            public static var digging: String { AI.tr("ai.status.digging") }
            public static var extracting: String { AI.tr("ai.status.extracting") }
            public static var generating: String { AI.tr("ai.status.generating") }
            public static var organizing: String { AI.tr("ai.status.organizing") }
            public static var preprocessing: String { AI.tr("ai.status.preprocessing") }
            public static var scanning: String { AI.tr("ai.status.scanning") }
            public static var structuring: String { AI.tr("ai.status.structuring") }
            public static var synthesizing: String { AI.tr("ai.status.synthesizing") }
            public static var thinking: String { AI.tr("ai.status.thinking") }
            public static var visualizing: String { AI.tr("ai.status.visualizing") }

            public static func indexing(_ current: Int, _ total: Int, _ filename: String) -> String {
                AI.trf("ai.status.indexing", current, total, filename)
            }
        }

        public enum LLM {
            public static var title: String { AI.tr("llm.title") }
            public static var apiAddress: String { AI.tr("llm.apiAddress") }
            public static var apiKey: String { AI.tr("llm.apiKey") }
            public static var model: String { AI.tr("llm.model") }
            public static var status: String { AI.tr("llm.status") }
            public static var testConnection: String { AI.tr("llm.testConnection") }
            public static var testing: String { AI.tr("llm.testing") }
            public static var connectionSuccess: String { AI.tr("llm.connectionSuccess") }
            public static var validation: String { AI.tr("llm.validation") }
            public static var validationFailed: String { AI.tr("llm.validationFailed") }
            public static var configuration: String { AI.tr("llm.configuration") }
            public static var enableAssistant: String { AI.tr("llm.enableAssistant") }
            public static var chatHistory: String { AI.tr("llm.chatHistory") }
            public static var clearHistory: String { AI.tr("llm.clearHistory") }
            public static var chatSection: String { AI.tr("llm.chatSection") }
            public static var messages: String { AI.tr("llm.messages") }
            public static var infoString: String { AI.tr("llm.info") }

            public enum Provider {
                public static var title: String { AI.tr("llm.provider") }
                public static var openai: String { AI.tr("llm.provider.openai") }
                public static var anthropic: String { AI.tr("llm.provider.anthropic") }
                public static var deepseek: String { AI.tr("llm.provider.deepseek") }
                public static var ollama: String { AI.tr("llm.provider.ollama") }
                public static var qwen: String { AI.tr("llm.provider.qwen") }
                public static var zhipu: String { AI.tr("llm.provider.zhipu") }
                public static var siliconflow: String { AI.tr("llm.provider.siliconflow") }
                public static var minimax: String { AI.tr("llm.provider.minimax") }
            }

            public enum Error {
                public static var invalidURL: String { AI.tr("llm.error.invalidURL") }
                public static var invalidResponse: String { AI.tr("llm.error.invalidResponse") }
                public static var httpError: String { AI.tr("llm.error.httpError") }
                public static var apiError: String { AI.tr("llm.error.apiError") }
                public static var rateLimited: String { AI.tr("llm.error.rateLimited") }
                public static var unauthorized: String { AI.tr("llm.error.unauthorized") }
                public static var notConfigured: String { AI.tr("llm.error.notConfigured") }
                public static var cancelled: String { AI.tr("llm.error.cancelled") }
            }

            public enum info {
                public static var localKey: String { AI.tr("llm.info.localKey") }
                public static var contextSent: String { AI.tr("llm.info.contextSent") }
                public static var openAICompatible: String { AI.tr("llm.info.openAICompatible") }
                public static var smartIngest: String { AI.tr("llm.info.smartIngest") }
            }

            public typealias prompt = Prompt
            public enum Prompt {
                public static var role: String { AI.tr("llm.prompt.role") }
                public static var duty1: String { AI.tr("llm.prompt.duty1") }
                public static var duty2: String { AI.tr("llm.prompt.duty2") }
                public static var duty3: String { AI.tr("llm.prompt.duty3") }
                public static var duty4: String { AI.tr("llm.prompt.duty4") }
                public static var rule1: String { AI.tr("llm.prompt.rule1") }
                public static var rule2: String { AI.tr("llm.prompt.rule2") }
                public static var rule3: String { AI.tr("llm.prompt.rule3") }
                public static var rule4: String { AI.tr("llm.prompt.rule4") }
                public static var overview: String { AI.tr("llm.prompt.overview") }
                public static var totalPages: String { AI.tr("llm.prompt.totalPages") }
                public static var entityCount: String { AI.tr("llm.prompt.entityCount") }
                public static var conceptCount: String { AI.tr("llm.prompt.conceptCount") }
                public static var sourceCount: String { AI.tr("llm.prompt.sourceCount") }
                public static var entityList: String { AI.tr("llm.prompt.entityList") }
                public static var conceptList: String { AI.tr("llm.prompt.conceptList") }
                public static var sourceList: String { AI.tr("llm.prompt.sourceList") }
                public static var recentUpdates: String { AI.tr("llm.prompt.recentUpdates") }
                public static var relevantPages: String { AI.tr("llm.prompt.relevantPages") }
                public static var typeLabel: String { AI.tr("llm.prompt.typeLabel") }
                public static var relevanceScore: String { AI.tr("llm.prompt.relevanceScore") }
                public static var chunkType: String { AI.tr("llm.prompt.chunkType") }
                public static var pageTitle: String { Common.tr("pageTitle") }
                public static var issueDesc: String { AI.tr("llm.prompt.issueDesc") }
                public static var issueType: String { AI.tr("llm.prompt.issueType") }
                public static var pageContentSnippet: String { AI.tr("llm.prompt.pageContentSnippet") }
                public static var otherPageTitles: String { AI.tr("llm.prompt.otherPageTitles") }
            }

            public typealias ingest = Ingest
            public enum Ingest {
                public static var compileRules: String { AI.tr("llm.ingest.compileRules") }
                public static var compileInstruction: String { AI.tr("llm.ingest.compileInstruction") }
                public static var existingPages: String { AI.tr("llm.ingest.existingPages") }
                public static var rawTitle: String { AI.tr("llm.ingest.rawTitle") }
                public static var rawContent: String { AI.tr("llm.ingest.rawContent") }
                public static var jsonCompiledContent: String { AI.tr("llm.ingest.jsonCompiledContent") }
                public static var jsonSummary: String { AI.tr("llm.ingest.jsonSummary") }
                public static var jsonSuggestedTags: String { AI.tr("llm.ingest.jsonSuggestedTags") }
                public static var jsonFormat: String { AI.tr("llm.ingest.jsonFormat") }
                public static var systemPrompt: String { AI.tr("llm.ingest.systemPrompt") }
                public static var enrichSystemPrompt: String { AI.tr("llm.ingest.enrichSystemPrompt") }
                public static var rule1: String { AI.tr("llm.ingest.rule1") }
                public static var rule2: String { AI.tr("llm.ingest.rule2") }
                public static var rule3: String { AI.tr("llm.ingest.rule3") }
                public static var rule4: String { AI.tr("llm.ingest.rule4") }
                public static var rule5: String { AI.tr("llm.ingest.rule5") }
                public static var rule6: String { AI.tr("llm.ingest.rule6") }
            }
        }

        public enum OnDevice {
            public static var assistMode: String { AI.tr("ondevice.assistMode") }
            public static var assistDesc: String { AI.tr("ondevice.assistDesc") }
            public static var available: String { AI.tr("ondevice.available") }
            public static var connected: String { AI.tr("ondevice.connected") }
            public static var statusReady: String { AI.tr("ondevice.status.ready") }
            public static var statusLoading: String { AI.tr("ondevice.status.loading") }
            public static var appleIntelligence: String { AI.tr("ondevice.appleIntelligence") }
            public static var enableAutoScan: String { AI.tr("ondevice.enableAutoScan") }
            public static var autoRefactor: String { AI.tr("ondevice.autoRefactor") }
            public static func errorFormat(_ code: String) -> String { AI.trf("ondevice.errorFormat", code) }

            public enum Error {
                public static var loadFailed: String { AI.tr("ondevice.error.loadFailed") }
                public static var compilationFailed: String { AI.tr("ondevice.error.compilationFailed") }
            }
        }

        public enum Eval {
            public static var systemPrompt: String { AI.tr("llm.eval.systemPrompt") }
            public static func judgePrompt(_ context: String, _ query: String, _ answer: String) -> String {
                AI.trf("llm.eval.judgePrompt", context, query, answer)
            }
            
            public enum Status {
                public static var pass: String { AI.tr("llm.eval.status.pass") }
                public static var warning: String { AI.tr("llm.eval.status.warning") }
                public static var fail: String { AI.tr("llm.eval.status.fail") }
                public static var error: String { AI.tr("llm.eval.status.error") }
            }
        }

        public enum Prompt {
            public static var relevanceScore: String { AI.tr("llm.prompt.relevanceScore") }
            public static var chunkType: String { AI.tr("llm.prompt.chunkType") }
            public static var fixSuggestion: String { AI.tr("prompt.fixSuggestion") }
            public static var queryRewrite: String { AI.tr("prompt.queryRewrite") }
            public static var rerank: String { AI.tr("prompt.rerank") }
            public static var potentialLinks: String { AI.tr("prompt.potentialLinks") }
            public static var folding: String { AI.tr("prompt.folding") }
            public static var refactor: String { AI.tr("prompt.refactor") }
            public static var resetConfirm: String { AI.tr("prompt.resetConfirm") }
            public static var resetWarning: String { AI.tr("prompt.resetWarning") }
            public static var resetToDefault: String { AI.tr("prompt.resetToDefault") }

            public enum QueryRewrite {
                public static var instruction: String { AI.tr("prompt.queryRewrite.instruction") }
                public static var rules: String { AI.tr("prompt.queryRewrite.rules") }
                public static var rule1: String { AI.tr("prompt.queryRewrite.rule1") }
                public static var rule2: String { AI.tr("prompt.queryRewrite.rule2") }
                public static var rule3: String { AI.tr("prompt.queryRewrite.rule3") }
                public static var rule4: String { AI.tr("prompt.queryRewrite.rule4") }
                public static var userQuery: String { AI.tr("prompt.queryRewrite.userQuery") }
                public static var footer: String { AI.tr("prompt.queryRewrite.footer") }
            }

            public enum Quiz {
                public static var defaultTitle: String { AI.tr("prompt.quiz.defaultTitle") }
                public static var question: String { AI.tr("prompt.quiz.question") }
                public static var option: String { AI.tr("prompt.quiz.option") }
                public static var explanation: String { AI.tr("prompt.quiz.explanation") }
            }

            public enum Expert {
                public enum Mindmap {
                    public static var title: String { AI.tr("prompt.expert.mindmap.title") }
                    public static var footer: String { AI.tr("prompt.expert.mindmap.footer") }
                }
                public enum Quiz {
                    public static var title: String { AI.tr("prompt.expert.quiz.title") }
                    public static var footer: String { AI.tr("prompt.expert.quiz.footer") }
                }
                public enum Slides {
                    public static var title: String { AI.tr("prompt.expert.slides.title") }
                    public static var footer: String { AI.tr("prompt.expert.slides.footer") }
                }
                public enum Report {
                    public static var title: String { AI.tr("prompt.expert.report.title") }
                    public static var footer: String { AI.tr("prompt.expert.report.footer") }
                }
            }

            public enum Default {
                public static var mindmap: String { AI.tr("prompt.default.mindmap") }
                public static var quiz: String { AI.tr("prompt.default.quiz") }
                public static var slides: String { AI.tr("prompt.default.slides") }
                public static var summary: String { AI.tr("prompt.default.summary") }
                public static var actions: String { AI.tr("prompt.default.actions") }
                public static var infographic: String { AI.tr("prompt.default.infographic") }
                public static var insightQuestions: String { AI.tr("prompt.default.insightQuestions") }
                public static var report: String { AI.tr("prompt.default.report") }
                public static var expansion: String { AI.tr("prompt.default.expansion") }
            }

            public enum Shortcut {
                public static var deepReview: String { AI.tr("prompt.shortcut.deepReview") }
                public static var findGaps: String { AI.tr("prompt.shortcut.findGaps") }
                public static var studyPath: String { AI.tr("prompt.shortcut.studyPath") }
            }

            public enum reset {
                public static var factory: String { AI.tr("prompt.reset.factory") }
            }

            public typealias factory = Factory
            public enum Factory {
                public static var title: String { AI.tr("prompt.factory.title") }
            }

            public typealias workshop = Workshop
            public enum Workshop {
                public static var add: String { AI.tr("prompt.workshop.add") }
                
                public enum Intro {
                    public static var title: String { AI.tr("prompt.workshop.intro.title") }
                    public static var desc: String { AI.tr("prompt.workshop.intro.desc") }
                }
                public enum shortcuts {
                    public static var title: String { AI.tr("prompt.workshop.shortcuts.title") }
                    public static var footer: String { AI.tr("prompt.workshop.shortcuts.footer") }
                }
                public enum input {
                    public static var placeholder: String { AI.tr("prompt.workshop.input.placeholder") }
                }
            }
        }

        public enum Synthesis {
            public static var title: String { AI.tr("synthesis.title") }
            public static var sidebarTitle: String { AI.tr("sidebar.synthesis") }
            public static var limitReachedWarning: String { AI.tr("synthesis.limitReachedWarning") }
            public static var batchDeleteConfirm: String { AI.tr("synthesis.batchDeleteConfirm") }
            public static var clearAllConfirm: String { AI.tr("synthesis.clearAllConfirm") }
            public static var noDocs: String { AI.tr("synthesis.noDocs") }
            public static var documentList: String { AI.tr("synthesis.documentList") }
            public static var actions: String { AI.tr("synthesis.actions") }
            
            public enum Mindmap {
                public static var title: String { AI.tr("synthesis.mindmap.title") }
                public static var renderError: String { AI.tr("synthesis.mindmap.renderError") }
            }

            public enum Error {
                public static var limitReached: String { AI.tr("synthesis.error.limitReached") }
                public static var noPages: String { AI.tr("synthesis.error.noPages") }
            }
        }

        public enum Task {
            public static let t = "AI"
            public static var running: String { Localized.tr("aitask.status.running", table: t) }
            public static var centerTitle: String { Localized.tr("aitask.center.title", table: t) }
            public static var emptyTitle: String { Status.emptyTitle }
            public static var emptyDesc: String { Status.emptyDesc }
            
            public static func starting(_ name: String, _ target: String) -> String {
                Localized.trf("aitask.status.startingFormat", table: t, name, target)
            }
            public static func running(_ name: String, _ target: String) -> String {
                Localized.trf("aitask.status.runningFormat", table: t, name, target)
            }
            public static func completed(_ name: String) -> String {
                Localized.trf("aitask.status.completedFormat", table: t, name)
            }
            public static func failed(_ name: String) -> String {
                Localized.trf("aitask.status.failedFormat", table: t, name)
            }

            public enum Status {
                public static let t = "AI"
                public static var ready: String { Localized.tr("aitask.status.ready", table: t) }
                public static var running: String { Localized.tr("aitask.status.running", table: t) }
                public static var emptyTitle: String { Localized.tr("aitask.empty.title", table: t) }
                public static var emptyDesc: String { Localized.tr("aitask.empty.desc", table: t) }
            }
        }
    }
}
