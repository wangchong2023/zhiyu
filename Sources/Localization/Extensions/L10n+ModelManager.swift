//
//  L10n+ModelManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/05.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 基础设施层
//  核心职责：本地大模型管理模块的国际化词条扩展
//

import Foundation

extension L10n {
    public enum ModelManager: L10nTableEntry {
        public static let tableName = "ModelManager"
        public static var t: String { tableName }
        // MARK: - Tab 标题

        public static var storeTitle: String {
            ModelManager.tr("model_manager.store.title")
        }

        public static var parametersTitle: String {
            ModelManager.tr("model_manager.parameters.title")
        }

        public static var serversTitle: String {
            ModelManager.tr("model_manager.servers.title")
        }

        public static var routingTitle: String {
            ModelManager.tr("model_manager.routing.title")
        }

        // MARK: - 卡片组件

        public enum Card {
            /// 模型供应商名称
            /// - Parameter name: 供应商名称
            /// - Returns: 格式化的供应商文本
            public static func vendor(_ name: String) -> String {
                ModelManager.trf("model_manager.card.vendor", name)
            }

            /// 模型大小
            /// - Parameter gb: 大小（GB）
            /// - Returns: 格式化的大小文本
            public static func size(_ gb: String) -> String {
                ModelManager.trf("model_manager.card.size", gb)
            }

            public static var ready: String {
                ModelManager.tr("model_manager.card.ready")
            }

            public static var activated: String {
                ModelManager.tr("model_manager.card.activated")
            }

            public static var activate: String {
                ModelManager.tr("model_manager.card.activate")
            }

            public static var download: String {
                ModelManager.tr("model_manager.card.download")
            }

            public static var pause: String {
                ModelManager.tr("model_manager.card.pause")
            }

            public static var resume: String {
                ModelManager.tr("model_manager.card.resume")
            }

            public static var cancel: String {
                ModelManager.tr("model_manager.card.cancel")
            }

            public static var unavailable: String {
                ModelManager.tr("model_manager.card.unavailable")
            }
        }

        // MARK: - 顶部摘要

        public enum Header {
            public static var availableModels: String { ModelManager.tr("model_manager.header.availableModels") }
        }

        // MARK: - 任务标签

        public enum Task {
            public static var chat: String { ModelManager.tr("model_manager.task.chat") }
            public static var completion: String { ModelManager.tr("model_manager.task.completion") }
            public static var reasoning: String { ModelManager.tr("model_manager.task.reasoning") }
            public static var code: String { ModelManager.tr("model_manager.task.code") }
            public static var rag: String { ModelManager.tr("model_manager.task.rag") }
            public static var translation: String { ModelManager.tr("model_manager.task.translation") }
        }

        // MARK: - 规格详表（Model Spec Sheet）

        public enum Spec {
            public static var memory: String { ModelManager.tr("model_manager.spec.memory") }
            public static var downloadSize: String { ModelManager.tr("model_manager.spec.downloadSize") }
            public static var parameters: String { ModelManager.tr("model_manager.spec.parameters") }
            public static var checksum: String { ModelManager.tr("model_manager.spec.checksum") }
            public static var tasks: String { ModelManager.tr("model_manager.spec.tasks") }
        }

        // MARK: - 参数调节

        public enum Parameters {
            public static var temperature: String {
                ModelManager.tr("model_manager.params.temperature")
            }

            public static var topP: String {
                ModelManager.tr("model_manager.params.top_p")
            }

            public static var topK: String {
                ModelManager.tr("model_manager.params.top_k")
            }

            public static var maxTokens: String {
                ModelManager.tr("model_manager.params.max_tokens")
            }

            public static var presetCreative: String {
                ModelManager.tr("model_manager.params.preset.creative")
            }

            public static var presetBalanced: String {
                ModelManager.tr("model_manager.params.preset.balanced")
            }

            public static var presetPrecise: String {
                ModelManager.tr("model_manager.params.preset.precise")
            }

            public static var custom: String { ModelManager.tr("model_manager.params.custom") }

            public static var resetToDefaults: String {
                ModelManager.tr("model_manager.params.reset_to_defaults")
            }

            public static var saveConfiguration: String {
                ModelManager.tr("model_manager.params.save_configuration")
            }

            public static var currentModel: String {
                ModelManager.tr("model_manager.params.current_model")
            }

            public static var presetTemplate: String {
                ModelManager.tr("model_manager.params.preset_template")
            }

            public static var tipTemperature: String {
                ModelManager.tr("model_manager.params.tip.temperature")
            }

            public static var tipTopP: String {
                ModelManager.tr("model_manager.params.tip.top_p")
            }

            public static var tipTopK: String {
                ModelManager.tr("model_manager.params.tip.top_k")
            }

            public static var tipMaxTokens: String {
                ModelManager.tr("model_manager.params.tip.max_tokens")
            }

            public static var selectModel: String {
                ModelManager.tr("model_manager.params.select_model")
            }

            public static var reset: String {
                ModelManager.tr("model_manager.params.reset")
            }

            public static var save: String {
                ModelManager.tr("model_manager.params.save")
            }
        }

        // MARK: - 服务器配置

        public enum Server {
            public static var addServer: String {
                ModelManager.tr("model_manager.server.add")
            }

            public static var editServer: String {
                ModelManager.tr("model_manager.server.edit")
            }

            public static var testConnection: String {
                ModelManager.tr("model_manager.server.test")
            }

            public static var deleteServer: String {
                ModelManager.tr("model_manager.server.delete")
            }

            public static var setDefault: String {
                ModelManager.tr("model_manager.server.set_default")
            }

            /// 服务器延迟
            /// - Parameter ms: 延迟时间（毫秒）
            /// - Returns: 格式化的延迟文本
            public static func latency(_ ms: Int) -> String {
                ModelManager.trf("model_manager.server.latency", ms)
            }

            public static var emptyTitle: String {
                ModelManager.tr("model_manager.server.empty.title")
            }

            public static var emptySubtitle: String {
                ModelManager.tr("model_manager.server.empty.subtitle")
            }

            public static var serverName: String {
                ModelManager.tr("model_manager.server.name")
            }

            public static var serverURL: String {
                ModelManager.tr("model_manager.server.url")
            }

            public static var apiKey: String {
                ModelManager.tr("model_manager.server.api_key")
            }

            public static var emptyTitleAlt: String {
                ModelManager.tr("model_manager.server.empty_title")
            }

            public static var emptySubtitleAlt: String {
                ModelManager.tr("model_manager.server.empty_subtitle")
            }

            /// 最后测试时间
            /// - Parameter date: 格式化的日期字符串
            /// - Returns: 格式化的测试时间文本
            public static func lastTested(_ date: String) -> String {
                ModelManager.trf("model_manager.server.last_tested", date)
            }

            /// 服务器延迟（毫秒）
            /// - Parameter ms: 延迟时间（毫秒）
            /// - Returns: 格式化的延迟文本
            public static func latencyMs(_ ms: Int) -> String {
                ModelManager.trf("model_manager.server.latency_ms", ms)
            }

            public static var editAction: String {
                ModelManager.tr("model_manager.server.edit_action")
            }

            public static var deleteAction: String {
                ModelManager.tr("model_manager.server.delete_action")
            }

            public static var setDefaultAction: String {
                ModelManager.tr("model_manager.server.set_default_action")
            }

            public static var formNameLabel: String {
                ModelManager.tr("model_manager.server.form.name_label")
            }

            public static var formURLLabel: String {
                ModelManager.tr("model_manager.server.form.url_label")
            }

            public static var formAPIKeyLabel: String {
                ModelManager.tr("model_manager.server.form.api_key_label")
            }

            public static var formSetDefault: String {
                ModelManager.tr("model_manager.server.form.set_default")
            }

            public static var formEnableSSL: String {
                ModelManager.tr("model_manager.server.form.enable_ssl")
            }

            public static var testSuccess: String {
                ModelManager.tr("model_manager.server.test_success")
            }

            public static var formAddTitle: String {
                ModelManager.tr("model_manager.server.form.add_title")
            }

            public static var formEditTitle: String {
                ModelManager.tr("model_manager.server.form.edit_title")
            }

            public static var formCancel: String {
                ModelManager.tr("model_manager.server.form.cancel")
            }

            public static var formSave: String {
                ModelManager.tr("model_manager.server.form.save")
            }

            public static var testResult: String {
                ModelManager.tr("model_manager.server.test_result")
            }

            public static var mockLocalDev: String {
                ModelManager.tr("model_manager.server.mock_local_dev")
            }
        }

        // MARK: - 智能路由

        public enum Routing {
            public static var cloudEscalation: String {
                ModelManager.tr("model_manager.routing.cloud_escalation")
            }

            public static var modelStrategy: String {
                ModelManager.tr("model_manager.routing.modelStrategy")
            }

            public static var runtimeStatus: String {
                ModelManager.tr("model_manager.routing.runtimeStatus")
            }

            public static var cloudModel: String {
                ModelManager.tr("model_manager.routing.cloud_model")
            }

            public static var routingRules: String {
                ModelManager.tr("model_manager.routing.rules")
            }

            public static var networkStatus: String {
                ModelManager.tr("model_manager.routing.network_status")
            }

            public static var advancedSettings: String {
                ModelManager.tr("model_manager.routing.advanced_settings")
            }

            public static var cloudEscalationTitle: String {
                ModelManager.tr("model_manager.routing.cloud_escalation_title")
            }

            public static var cloudEscalationToggle: String {
                ModelManager.tr("model_manager.routing.cloud_escalation_toggle")
            }

            public static var cloudEscalationDesc: String {
                ModelManager.tr("model_manager.routing.cloud_escalation_desc")
            }

            public static var cloudModelSelection: String {
                ModelManager.tr("model_manager.routing.cloud_model_selection")
            }

            /// 当前云端模型
            /// - Parameter model: 模型名称
            /// - Returns: 格式化的云端模型文本
            public static func currentCloudModel(_ model: String) -> String {
                ModelManager.trf("model_manager.routing.current_cloud_model", model)
            }

            public static var taskRules: String {
                ModelManager.tr("model_manager.routing.task_rules")
            }

            public static var taskSemanticChunking: String {
                ModelManager.tr("model_manager.routing.task.semantic_chunking")
            }

            public static var taskLinkDiscovery: String {
                ModelManager.tr("model_manager.routing.task.link_discovery")
            }

            public static var taskSynthesis: String {
                ModelManager.tr("model_manager.routing.task.synthesis")
            }

            public static var taskChat: String {
                ModelManager.tr("model_manager.routing.task.chat")
            }

            public static var taskTagGeneration: String {
                ModelManager.tr("model_manager.routing.task.tag_generation")
            }

            public static var strategyForceLocal: String {
                ModelManager.tr("model_manager.routing.strategy.force_local")
            }

            public static var strategySmartRouting: String {
                ModelManager.tr("model_manager.routing.strategy.smart_routing")
            }

            public static var networkMonitoring: String {
                ModelManager.tr("model_manager.routing.network_monitoring")
            }

            public static var networkCurrent: String {
                ModelManager.tr("model_manager.routing.network.current")
            }

            public static var networkLatency: String {
                ModelManager.tr("model_manager.routing.network.latency")
            }

            public static var networkBandwidth: String {
                ModelManager.tr("model_manager.routing.network.bandwidth")
            }

            public static var networkBandwidthExcellent: String {
                ModelManager.tr("model_manager.routing.network.bandwidth_excellent")
            }

            public static var localModelReady: String {
                ModelManager.tr("model_manager.routing.local_model_ready")
            }

            public static var currentDecision: String {
                ModelManager.tr("model_manager.routing.current_decision")
            }

            public static var advanced: String {
                ModelManager.tr("model_manager.routing.advanced")
            }

            public static var wifiOnly: String {
                ModelManager.tr("model_manager.routing.wifi_only")
            }

            public static var autoFallback: String {
                ModelManager.tr("model_manager.routing.auto_fallback")
            }

            public static var preferLocal: String {
                ModelManager.tr("model_manager.routing.prefer_local")
            }

            public static var decisionUnselected: String {
                ModelManager.tr("model_manager.routing.decision.unselected")
            }

            public static var decisionCloud: String {
                ModelManager.tr("model_manager.routing.decision.cloud")
            }

            public static var decisionLocal: String {
                ModelManager.tr("model_manager.routing.decision.local")
            }

            public static var decisionAutoCloud: String {
                ModelManager.tr("model_manager.routing.decision.auto_cloud")
            }
        }

        // MARK: - 状态与提示

        public enum Status {
            public static var downloading: String {
                ModelManager.tr("model_manager.status.downloading")
            }

            public static var verifying: String {
                ModelManager.tr("model_manager.status.verifying")
            }

            public static var completed: String {
                ModelManager.tr("model_manager.status.completed")
            }

            public static var failed: String {
                ModelManager.tr("model_manager.status.failed")
            }

            public static var paused: String {
                ModelManager.tr("model_manager.status.paused")
            }
        }
    }
}
