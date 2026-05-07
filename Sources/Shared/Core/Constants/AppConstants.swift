// AppConstants.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 基础设施层：全局常量定义。
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
    }
    
    // MARK: - 存储与基础配置
    struct Storage {
        /// 数据库文件名
        static let databaseName: String = "App.sqlite"
        /// 性能审计回溯天数 (最近 30 天)
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
            /// LLM 请求执行详细日志，用于审计与计费
            static let llmCallLogs = "llm_call_logs"
            /// RAG 检索效果离线评估结果表
            static let ragEvaluations = "rag_evaluations"
        }

        // MARK: - 核心列名定义
        /// 定义数据库中高频使用的列名称。
        struct Columns {
            /// 唯一标识符 (UUID)
            static let id = "id"
            /// 页面标题
            static let title = "title"
            /// 页面类型 (entity/concept/source 等)
            static let type = "type"
            /// 页面正文内容 (Markdown)
            static let content = "content"
            /// 标签列表 (JSON 字符串)
            static let tags = "tags"
            /// 创建时间戳
            static let created = "created"
            /// 最后更新时间戳
            static let updated = "updated"
            /// 关联文件的大小 (针对 Source 类型)
            static let fileSize = "file_size"
            /// 导入来源类型 (file/web/ocr)
            static let sourceType = "source_type"
            /// CRDT 兰伯特时间戳，用于多端同步冲突解决
            static let lamportTimestamp = "lamport_timestamp"

            // MARK: - 链接表列
            /// 链接起始页面 ID
            static let sourceId = "source_id"
            /// 链接目标页面标题 (支持未创建页面的链接)
            static let targetTitle = "target_title"

            // MARK: - RAG 评估列
            /// 忠实度得分 (Faithfulness)：回答是否忠于参考上下文
            static let faithfulness = "faithfulness_score"
            /// 相关性得分 (Relevance)：回答是否直接解决了用户问题
            static let relevance = "relevance_score"
            /// 上下文精确度 (Precision)：检索到的块是否全部相关
            static let precision = "context_precision"
        }
    }

    // MARK: - 性能与审计
    struct Performance {
        /// 延迟警告阈值 (毫秒)
        static let latencyWarningThreshold: Int = 2000
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
enum EvaluationMetric: String {
    case faithfulness = "faithfulness"
    case relevance = "relevance"
    case precision = "context_precision"
}
