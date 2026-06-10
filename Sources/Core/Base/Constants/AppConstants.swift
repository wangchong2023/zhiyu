//
//  AppConstants.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：应用级编译时常量定义（存储 key、超时、默认值等）。
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
        /// 笔记本沙盒存储子目录名称
        public static let vaultsDirectoryName: String = "Vaults"
        /// 间隔重复算法(SRS)默认易用度因子 (SuperMemo-2 经典默认值)
        public static let defaultEaseFactor: Double = 2.5
        /// 日志文件名
        public static let logsFileName: String = "audit_logs.json"
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
            public static let retrievalSnapshots = "retrieval_snapshots"
            public static let relevanceJudgments = "relevance_judgments"
            public static let globalVaults = "global_vaults"
            public static let fileSignatures = "file_signatures"
            public static let globalSettings = "global_settings"
            public static let auditLogs = "audit_logs"
            public static let tags = "tags"
            public static let pageTags = "page_tags"
            public static let srsMetadata = "srs_metadata"
            public static let importRecords = "import_records"
            public static let feedbackEntries = "feedback_entries"
            public static let pluginRecords = "plugin_records"
            public static let pluginRecordsFTS = "plugin_records_fts"
        }

        // MARK: - 通用列名 (物理)
        /// 定义数据库中高频使用的物理列名称，解除对模型的依赖。
        public struct Columns {
            // 通用
            public static let id = "id"
            public static let title = "title"
            public static let name = "name"
            public static let content = "content"
            public static let created = "created_at"
            public static let updated = "updated_at"
            public static let tags = "tags"
            
            // pages 表
            public static let pageType = "page_type"
            public static let aliases = "aliases"
            public static let status = "status"
            public static let confidence = "confidence"
            public static let sources = "sources"
            public static let relatedPageIds = "related_page_ids"
            public static let isPinned = "is_pinned"
            public static let contentHash = "content_hash"
            public static let customIcon = "custom_icon"
            public static let sourceUrl = "source_url"
            public static let rawSnippet = "raw_snippet"
            public static let fileSize = "file_size"
            public static let sourceType = "source_type"
            public static let lamportTimestamp = "lamport_timestamp"

            // links 表
            public static let sourceId = "source_id"
            public static let targetId = "target_id"
            public static let context = "context"

            // page_chunks 表
            public static let pageId = "page_id"
            public static let parentId = "parent_id"
            public static let chunkType = "chunk_type"
            public static let anchorPath = "anchor_path"
            public static let chunkIndex = "chunk_index"
            public static let embedding = "embedding"
            public static let startIndex = "start_index"

            // page_embeddings 表
            public static let vectorBlob = "vector_blob"
            public static let modelName = "model_name"

            // token_usage & llm_call_logs 表
            public static let model = "model"
            public static let promptTokens = "prompt_tokens"
            public static let completionTokens = "completion_tokens"
            public static let totalTokens = "total_tokens"
            public static let latencyMs = "latency_ms"

            // rag_evaluations 表
            public static let query = "query"
            public static let answer = "answer"
            public static let faithfulness = "faithfulness_score"
            public static let relevance = "relevance_score"
            public static let precision = "context_precision"
            public static let evaluatorModel = "evaluator_model"
            
            // page_tags 表
            public static let tagId = "tag_id"
            
            // srs_metadata 表
            public static let easeFactor = "ease_factor"
            public static let repetitions = "repetitions"
            public static let reviewInterval = "review_interval"
            public static let nextReviewAt = "next_review_at"
            
            // global_vaults 表
            public static let path = "path"
            public static let icon = "icon"
            public static let lastAccessedAt = "last_accessed_at"
            
            // file_signatures 表
            public static let filePath = "file_path"
            public static let signature = "signature"
            public static let salt = "salt"
            
            // global_settings 表
            public static let key = "key"
            public static let value = "value"
            
            // audit_logs 表
            public static let action = "action"
            public static let details = "details"
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

        // MARK: - 导入限制

        public enum ImportLimits {
            /// 单文件最大大小：10 MB
            public static let maxFileSizeBytes: Int64 = 10 * 1_024 * 1_024
            /// 语音录制最大时长：15 分钟
            public static let maxVoiceDurationSeconds: TimeInterval = 15 * 60
            /// OCR 图片最大大小：5 MB
            public static let maxOCRImageSizeBytes: Int64 = 5 * 1_024 * 1_024
            /// AI 标签分析截取字符数
            public static let aiTagSnippetLength: Int = 3000
            /// 导入冷却间隔（秒）
            public static let importCooldownSeconds: TimeInterval = 1.0
            /// Sheet 关闭后延迟执行操作的等待时间（纳秒）
            public static let dismissDelayNS: UInt64 = 400_000_000
            /// 批量导入 URL 最大数量
            public static let maxURLCount: Int = 10
            /// 图片提取：单张最大大小（5 MB）
            public static let maxImageSizeBytes: Int64 = 5 * 1_024 * 1_024
            /// 图片提取：每页最多数量
            public static let maxImagesPerPage: Int = 10
            /// 图片提取：下载超时（秒）
            public static let imageDownloadTimeoutSeconds: TimeInterval = 10
            /// PDF 页面渲染缩放比例
            public static let pdfRenderScale: CGFloat = 0.5
            /// 图片 JPEG 压缩质量
            public static let imageJPEGQuality: CGFloat = 0.8
            /// 支持图片提取的 Office 文件扩展名
            public static let officeExtensions: Set<String> = ["docx", "xlsx", "pptx"]
            /// 支持的图片格式扩展名
            public static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif"]
            /// 支持图片提取的 PDF 扩展名
            public static let pdfExtension: String = "pdf"
            /// Office ZIP 中排除的图片路径关键词（页眉页脚背景通常为装饰性图像）
            public static let officeImageExcludeKeywords: Set<String> = ["header", "footer", "background"]
        }
    }
}

/// 支持的 AI 模型枚举 (技术层标识)
public enum AppModel: String, CaseIterable, Sendable {
    case gpt4o = "gpt-4o"
    case appleNLv1 = "apple_nl_v1"
    case evaluator = "evaluator"
}

/// 评估指标枚举 (技术层标识)
public enum EvaluationMetric: String, CaseIterable, Sendable {
    case faithfulness = "faithfulness"
    case relevance = "relevance"
    case precision = "context_precision"
    /// 幻觉率：AI 生成内容中缺乏上下文支撑的比例（越低越好）
    case hallucinationRate = "hallucination_rate"
    /// 引用准确度：引用是否真实指向原文对应位置（越高越好）
    case citationAccuracy = "citation_accuracy"
}
