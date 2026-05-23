//
//  BusinessConstants.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Models 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 业务领域常量
public struct BusinessConstants {
    
    // MARK: - AI & Token 算法
    public struct AI {
        /// 字符到 Token 的估算系数 (约 4 字符/Token)
        public static let charactersPerToken: Int = 4
        /// 默认历史消息上下文长度
        public static let maxChatHistorySize: Int = 10
        /// 默认文本模型
        public static let defaultTextModel: String = AppModel.gpt4o.rawValue
        /// 默认向量模型
        public static let defaultEmbeddingModel: String = AppModel.appleNLv1.rawValue
    }
    
    // MARK: - RAG 策略限制
    public struct RAG {
        /// 系统提示词中列出的实体最大数量
        public static let maxEntityOverview = 20
        /// 系统提示词中列出的概念最大数量
        public static let maxConceptOverview = 20
        /// 系统提示词中列出的来源最大数量
        public static let maxSourceOverview = 10
        /// 系统提示词中列出的最近更新页面最大数量
        public static let maxRecentOverview = 5
        /// 系统提示词中页面的预览长度
        public static let contentPreviewLength = 100
        /// 查询上下文中包含的最大页面数
        public static let maxContextPages = 10
        /// 查询上下文中每页的预览长度
        public static let contextPreviewLength = 500

        // MARK: - 混合检索算法参数
        /// Reciprocal Rank Fusion (RRF) 算法常数
        public static let rrfK: Int = 60
        /// 语义搜索的相似度动态门槛
        public static let semanticThresholdShort: Float = 0.85
        public static let semanticThresholdLong: Float = 0.75
        /// 短查询语义高信度门槛
        public static let semanticShortHighConfidence: Float = 0.88
        /// 短查询字符数判断阈值 (消除硬编码魔鬼数字)
        public static let shortQueryThreshold: Int = 4
    }

    // MARK: - 图谱物理仿真与布局
    public struct Graph {
        /// 2D 图谱逻辑配置
        public struct TwoD {
            public static let virtualSizeMultiplier: CGFloat = 2.0
            public static let simulationIterations: Int = 100
            public static let baseExpansionOffset: CGFloat = 20.0
            public static let expansionFactor: CGFloat = 0.05
        }
        
        /// 3D 图谱逻辑配置
        public struct ThreeD {
            public static let defaultCameraDistance: Float = 140.0
            public static let cameraZNear: Double = 0.1
            public static let cameraZFar: Double = 1000.0
            public static let baseSphereRadiusMultiplier: Double = 18.0
            public static let minSphereRadius: CGFloat = 60.0
            public static let maxSphereRadius: CGFloat = 250.0
            public static let starCount: Int = 500
        }
        
        /// 力导向算法物理常数
        public struct Physics {
            public static let repulsionForce: CGFloat = 5000.0
            public static let attractionForce: CGFloat = 0.01
            public static let damping: CGFloat = 0.85
            public static let centerGravity: CGFloat = 0.005
            public static let friction: CGFloat = 0.9
            public static let gridSize: CGFloat = 120.0
            public static let collisionDistance: CGFloat = 20.0
            public static let collisionForce: CGFloat = 10000.0
            public static let maxRepulsionDistanceSq: CGFloat = 40000.0
            public static let minDistanceSq: CGFloat = 0.01
        }
    }
}
