//
//  AppConstants.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Constants 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// [L0] 底层基座层：硬编码常量配置 (AppConstants)
public struct AppConstants {
    
    // MARK: - Network
    public struct Network {
        public static let jwtTokenKey = "jwt_token_key"
        public static let requestTimeout: TimeInterval = 30.0
        public static let contentTypeJSON = "application/json"
        public static let headerContentType = "Content-Type"
    }
    
    // MARK: - 存储与基础配置
    public struct Storage {
        /// 数据库文件名 (向下兼容)
        public static let databaseName: String = "App.sqlite"
        /// 系统全局配置数据库文件名
        public static let globalDatabaseName: String = "global.sqlite3"
        /// 笔记本专属物理数据库文件名
        public static let vaultDatabaseName: String = "vault.sqlite3"
        /// 旧版本 legacy 物理数据库文件名 (兼容向下迁移)
        public static let legacyDatabaseName: String = "App.sqlite"
        /// 笔记本沙盒存储子目录名称
        public static let vaultsDirectoryName: String = "Vaults"
        /// 间隔重复算法(SRS)默认易用度因子 (SuperMemo-2 经典默认值)
        public static let defaultEaseFactor: Double = 2.5
        /// 日志文件名
        public static let logsFileName: String = "audit_logs.json"
        /// 性能监控回溯天数 (最近 30 天)
        public static let observabilityWindowDays: Int = 30
        /// 30 天的秒数 (用于 SQL 查询)
        public static let thirtyDaysSeconds: TimeInterval = 30 * 24 * 3600
        /// 默认调用状态
        public static let defaultCallStatus: String = "success"
        
        // MARK: - 表名定义
        /// 存储系统内所有数据表的物理名称。
        public struct Tables {
            public static let pages = "pages"
            public static let pagesFTS = "pages_fts"
            public static let links = "links"
            public static let pageChunks = "page_chunks"
            public static let pageEmbeddings = "page_embeddings"
            public static let tokenUsage = "token_usage"
            public static let llmCallLogs = "llm_call_logs"
            public static let ragEvaluations = "rag_evaluations"
            public static let globalVaults = "global_vaults"
            public static let fileSignatures = "file_signatures"
            public static let globalSettings = "global_settings"
            public static let auditLogs = "audit_logs"
            public static let tags = "tags"
            public static let pageTags = "page_tags"
            public static let srsMetadata = "srs_metadata"
        }

        // MARK: - 通用列名 (物理)
        /// 定义数据库中高频使用的物理列名称，解除对模型的依赖。
        public struct Columns {
            public static let id = "id"
            public static let title = "title"
            public static let pageType = "page_type"
            public static let content = "content"
            public static let tags = "tags"
            public static let created = "created_at"
            public static let updated = "updated_at"
            public static let fileSize = "file_size"
            public static let sourceType = "source_type"
            public static let lamportTimestamp = "lamport_timestamp"

            // MARK: - 链接表列
            public static let sourceId = "source_id"
            public static let targetId = "target_id"

            // MARK: - RAG 评估列
            public static let faithfulness = "faithfulness_score"
            public static let relevance = "relevance_score"
            public static let precision = "context_precision"
        }
    }

    // MARK: - 性能与监控
    public struct Performance {
        /// 延迟警告阈值 (毫秒)
        public static let latencyWarningThreshold: Int = 2000
    }

    // MARK: - 全局存储键名 (Magic Strings)
    public struct Keys {
        public struct Storage {
            public static let languageMode = "app_language_mode"
            public static let userHasOnboarded = "app_user_has_onboarded"
            public static let lastUsedModel = "app_last_used_model"
            public static let themePreference = "app_theme_preference"
            public static let hasSeenSplash = "app_has_seen_splash"
            public static let colorSchemeMode = "app_color_scheme_mode"
            public static let accentColor = "app_accent_color"
            public static let userName = "app_username"
            public static let isPrivacyModeEnabled = "app_is_privacy_mode_enabled"
            public static let isBiometricEnabled = "app_is_biometric_enabled"
            public static let hasShownGraphCoachMark = "app_has_shown_graph_coach_mark"
            public static let iCloudConflictResolution = "app_icloud_conflict_resolution"
            public static let iCloudAutoSync = "app_icloud_auto_sync"
            public static let hasCompletedOnboarding = "app_has_completed_onboarding"
            public static let selectedTab = "app_selected_tab"
            
            // ── 认证与会话 ──
            public static let authIsAuthenticated = "auth.isAuthenticated"
            public static let authIsGuest = "auth.isGuest"
            
            // ── 笔记本与知识库 ──
            public static let vaultsList = "vaults.list"
            public static let vaultsSelectedID = "vaults.selectedID"
            public static let lastLintIssues = "lastLintIssues"
            public static let earnedMedals = "earned_medals"
            public static let dailyRecapPrefix = "daily_recap_"
            
            // ── 协作与同步 ──
            public static let vaultBookmarkPrefix = "vault_bookmark_"
            public static let signaturePrefix = "zhiyu.integrity.sig."
            public static let securitySalt = "zhiyu_security_salt"
            public static let dbPassphrase = "zhiyu_db_passphrase"
            public static let defaultLegacySalt = "App-Integrity-Salt-2026"
            public static let suspendedPlugins = "zhiyu.security.suspendedPlugins"
            
            // ── 语音与录音 ──
            public static let voiceRecordings = "voice_recordings_list"
            
            // ── watchOS / Widget 同步缓存 ──
            public static let watchTotalPages = "watch_totalPages"
            public static let watchTotalWords = "watch_totalWords"
            public static let watchRecentTitles = "watch_recentTitles"
            
            // ── 提示词资产 ──
            public static let promptMindmap = "prompt_mindmap"
            public static let promptQuiz = "prompt_quiz"
            public static let promptSlides = "prompt_slides"
            public static let promptReport = "prompt_report"
            public static let promptExpansion = "prompt_expansion"
            
            // ── 旧版本迁移键名 (用于数据迁移校验) ──
            public struct Legacy {
                public static let hasCompletedOnboarding = "hasCompletedOnboarding"
                public static let isPrivacyModeEnabled = "isPrivacyModeEnabled"
                public static let isBiometricEnabled = "isBiometricEnabled"
                public static let hasShownGraphCoachMark = "hasShownGraphCoachMark"
                public static let colorSchemeMode = "colorSchemeMode"
                public static let accentColor = "accentColor"
                public static let isDarkMode = "isDarkMode"
                public static let synthesisDocsPrefix = "synthesis_docs_"
            }
        }
    }

    // MARK: - 3D 图谱视觉引擎配置 (@SRS-6.1)
    public struct Graph {
        /// 节点渲染大小
        public static let nodeSize: Float = 0.08
        /// 选中节点的放大倍率
        public static let selectionScale: Float = 1.5
        /// 连线默认不透明度
        public static let edgeOpacity: Float = 0.3
        /// 节点默认颜色 (十六进制)
        public static let defaultNodeColor: String = "60A5FA"
        /// 选中的节点颜色
        public static let selectedNodeColor: String = "F59E0B"
        /// 默认力场强度
        public static let chargeStrength: Float = -200
        /// 默认链接距离
        public static let linkDistance: Float = 30.0
        /// 粒子扩散范围
        public static let particleRadius: Float = 2.0
    }
}

/// 支持的 AI 模型枚举 (技术层标识)
public enum AppModel: String, CaseIterable, Sendable {
    case gpt4o = "gpt-4o"
    case gpt35Turbo = "gpt-3.5-turbo"
    case appleNLv1 = "apple_nl_v1"
    case localLlama3 = "llama3"
    case evaluator = "evaluator"
}

/// 评估指标枚举 (技术层标识)
public enum EvaluationMetric: String, CaseIterable, Sendable {
    case faithfulness = "faithfulness"
    case relevance = "relevance"
    case precision = "context_precision"
}
