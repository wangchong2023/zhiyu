// AppConstants.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：全局常量定义。
// 集中管理魔鬼数字、RAG 参数、模型 ID 及存储配置。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [L0] 基础设施层：硬编码常量配置 (AppConstants)
/// 注意：动态配置 (如阈值、温度等) 请参考 AppConfig.swift
struct AppConstants {
    
    // MARK: - AI & Token 算法 (系统底座)
    struct AI {
        /// 字符到 Token 的估算系数 (约 4 字符/Token)
        static let charactersPerToken: Int = 4
        /// 默认历史消息上下文长度
        static let maxChatHistorySize: Int = 10
        /// 默认文本模型
        static let defaultTextModel: String = AppModel.gpt4o.rawValue
        /// 默认向量模型
        static let defaultEmbeddingModel: String = AppModel.appleNLv1.rawValue
    }
    
    // MARK: - RAG 策略固定限制
    struct RAG {
        // MARK: - 系统提示词概览限制 (固定 UI 逻辑)
        /// 系统提示词中列出的实体最大数量
        static let maxEntityOverview = 20
        /// 系统提示词中列出的概念最大数量
        static let maxConceptOverview = 20
        /// 系统提示词中列出的来源最大数量
        static let maxSourceOverview = 10
        /// 系统提示词中列出的最近更新页面最大数量
        static let maxRecentOverview = 5
        /// 系统提示词中页面的预览长度
        static let contentPreviewLength = 100
        /// 查询上下文中包含的最大页面数
        static let maxContextPages = 10
        /// 查询上下文中每页的预览长度
        static let contextPreviewLength = 500

        // MARK: - 混合检索算法参数
        /// Reciprocal Rank Fusion (RRF) 算法常数
        static let rrfK: Int = 60
        /// 语义搜索的相似度动态门槛 (长短查询区分)
        static let semanticThresholdShort: Float = 0.85
        static let semanticThresholdLong: Float = 0.75
        /// 短查询语义高信度门槛
        static let semanticShortHighConfidence: Float = 0.88
    }
    
    // MARK: - 存储与基础配置
    struct Storage {
        /// 数据库文件名
        static let databaseName: String = "App.sqlite"
        /// 性能监控回溯天数 (最近 30 天)
        static let observabilityWindowDays: Int = 30
        /// 30 天的秒数 (用于 SQL 查询)
        static let thirtyDaysSeconds: TimeInterval = 30 * 24 * 3600
        /// 默认调用状态
        static let defaultCallStatus: String = "success"
        
        // MARK: - 表名定义
        /// 存储系统内所有数据表的物理名称，便于统一维护和防错。
        struct Tables {
            /// 核心知识页面主表 (KnowledgePage)
            static let pages = "pages"
            /// 全文搜索 (FTS5) 索引表，用于高效内容搜索
            static let pagesFTS = "pages_fts"
            /// 页面间的双向链接关系表 (Graph)
            static let links = "links"
            /// 语义分块存储表，支持 RAG 细粒度检索
            static let pageChunks = "page_chunks"
            /// 文本向量映射表，支持语义搜索
            static let pageEmbeddings = "page_embeddings"
            /// AI 调用额度与 Token 统计表
            static let tokenUsage = "token_usage"
            /// LLM 请求执行详细日志，用于监控与计费
            static let llmCallLogs = "llm_call_logs"
            /// RAG 检索效果离线评估结果表
            static let ragEvaluations = "rag_evaluations"
        }

        // MARK: - 核心列名定义
        /// 定义数据库中高频使用的列名称。引用自模型内部定义，确保类型安全。
        struct Columns {
            static let id = KnowledgePage.Columns.id.name
            static let title = KnowledgePage.Columns.title.name
            static let pageType = KnowledgePage.Columns.pageType.name
            static let content = KnowledgePage.Columns.content.name
            static let tags = KnowledgePage.Columns.tags.name
            static let created = KnowledgePage.Columns.createdAt.name
            static let updated = KnowledgePage.Columns.updatedAt.name
            static let fileSize = KnowledgePage.Columns.fileSize.name
            static let sourceType = KnowledgePage.Columns.sourceType.name
            static let lamportTimestamp = KnowledgePage.Columns.lamportTimestamp.name

            // MARK: - 链接表列
            /// 链接起始页面 ID
            static let sourceId = "source_id"
            /// 链接目标页面 ID
            static let targetId = "target_id"

            // MARK: - RAG 评估列
            /// 忠实度得分 (Faithfulness)：回答是否忠于参考上下文
            static let faithfulness = "faithfulness_score"
            /// 相关性得分 (Relevance)：回答是否直接解决了用户问题
            static let relevance = "relevance_score"
            /// 上下文精确度 (Precision)：检索到的块是否全部相关
            static let precision = "context_precision"
        }
    }

    // MARK: - 性能与监控
    struct Performance {
        /// 延迟警告阈值 (毫秒)
        static let latencyWarningThreshold: Int = 2000
    }

    // MARK: - Graph (知识图谱算法与逻辑)
    struct Graph {
        /// 2D 图谱逻辑配置
        struct TwoD {
            static let virtualSizeMultiplier: CGFloat = 2.0
            static let simulationIterations: Int = 100
            static let baseExpansionOffset: CGFloat = 20.0
            static let expansionFactor: CGFloat = 0.05
        }
        
        /// 3D 图谱逻辑配置
        struct ThreeD {
            static let defaultCameraDistance: Float = 140.0
            static let cameraZNear: Double = 0.1
            static let cameraZFar: Double = 1000.0
            
            // 布局逻辑系数 (非视觉尺寸)
            static let baseSphereRadiusMultiplier: Double = 18.0
            static let minSphereRadius: CGFloat = 60.0
            static let maxSphereRadius: CGFloat = 250.0
            
            static let starCount: Int = 500
        }
        
        /// 力导向算法物理常数
        struct Physics {
            static let repulsionForce: CGFloat = 5000.0
            static let attractionForce: CGFloat = 0.01
            static let damping: CGFloat = 0.85
            static let centerGravity: CGFloat = 0.005
            static let friction: CGFloat = 0.9
            
            // 内部优化常数
            static let gridSize: CGFloat = 120.0
            static let collisionDistance: CGFloat = 20.0
            static let collisionForce: CGFloat = 10000.0
            static let maxRepulsionDistanceSq: CGFloat = 40000.0
            static let minDistanceSq: CGFloat = 0.01
        }
    }

    // MARK: - 全局存储键名 (Magic Strings)
    struct Keys {
        struct Storage {
            static let languageMode = "app_language_mode"
            static let userHasOnboarded = "app_user_has_onboarded"
            static let lastUsedModel = "app_last_used_model"
            static let themePreference = "app_theme_preference"
            static let hasSeenSplash = "app_has_seen_splash"
            static let colorSchemeMode = "app_color_scheme_mode"
            static let accentColor = "app_accent_color"
            static let userName = "app_username"
            static let isPrivacyModeEnabled = "app_is_privacy_mode_enabled"
            static let isBiometricEnabled = "app_is_biometric_enabled"
            static let hasShownGraphCoachMark = "app_has_shown_graph_coach_mark"
            static let iCloudConflictResolution = "app_icloud_conflict_resolution"
            static let iCloudAutoSync = "app_icloud_auto_sync"
            static let hasCompletedOnboarding = "app_has_completed_onboarding"
        }
    }
}

/// 支持的 AI 模型枚举
enum AppModel: String, CaseIterable {
    case gpt4o = "gpt-4o"
    case gpt35Turbo = "gpt-3.5-turbo"
    case appleNLv1 = "apple_nl_v1"
    case localLlama3 = "llama3"
    case evaluator = "evaluator"
}

/// 评估指标枚举
enum EvaluationMetric: String, CaseIterable, Sendable {
    case faithfulness = "faithfulness"
    case relevance = "relevance"
    case precision = "context_precision"
    
    var displayName: String {
        switch self {
        case .faithfulness: return L10n.Dashboard.tr("stats.faithfulness")
        case .relevance: return L10n.Dashboard.tr("stats.relevance")
        case .precision: return L10n.Dashboard.tr("stats.precision")
        }
    }
}
