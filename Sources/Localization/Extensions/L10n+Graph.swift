//
//  L10n+Graph.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Graph 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Graph {
        public static let t = "Insight"

        public static func tr(_ key: String) -> String {
            Localized.tr("graph." + key, table: t)
        }
        /// 获取图谱节点和连接的统计提示文案
        /// - Parameters:
        ///   - nodes: 节点个数
        ///   - connections: 连接个数
        /// - Returns: 本地化格式化文案
        public static func nodesConnections(_ nodes: Int, _ connections: Int) -> String { Localized.trf("graph.nodesConnections", table: t, nodes, connections) }

        /// 获取图谱连接数统计文案
        /// - Parameter count: 连接数
        /// - Returns: 本地化格式化文案
        public static func linksCountFormat(_ count: Int) -> String { Localized.trf("graph.linksCountFormat", table: t, count) }

        /// 获取聚类群组名称文案
        /// - Parameter index: 群组索引序号
        /// - Returns: 本地化格式化文案
        public static func clusterName(_ index: Int) -> String { Localized.trf("graph.cluster.name", table: t, index) }

        public static var filter: String { Localized.tr("graph.filter", table: t) }
        public static var insights: String { Localized.tr("graph.insights", table: t) }
        public static var emptyTitle: String { Localized.tr("graph.emptyTitle", table: t) }
        public static var emptyDesc: String { Localized.tr("graph.emptyDesc", table: t) }
        public static var startBuilding: String { Localized.tr("graph.startBuilding", table: t) }
        public static var all: String { Localized.tr("graph.all", table: t) }

        public static var legend: String { Localized.tr("graph.legend", table: t) }
        public static var viewDetail: String { Localized.tr("graph.viewDetail", table: t) }
        public static var copyPageLink: String { Localized.tr("graph.copyPageLink", table: t) }

        public static var insightSurprising: String { Localized.tr("graph.insightSurprising", table: t) }
        public static var insightSurprisingDesc: String { Localized.tr("graph.insightSurprisingDesc", table: t) }
        public static var title: String { Localized.tr("graph.title", table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf("graph." + key, table: t, args) }
        public static var insightOrphans: String { Localized.tr("graph.insightOrphans", table: t) }
        public static var insightOrphansDesc: String { Localized.tr("graph.insightOrphansDesc", table: t) }
        public static var insightSparse: String { Localized.tr("graph.insightSparse", table: t) }
        public static var insightSparseDesc: String { Localized.tr("graph.insightSparseDesc", table: t) }
        public static var insightBridges: String { Localized.tr("graph.insightBridges", table: t) }
        public static var insightBridgesDesc: String { Localized.tr("graph.insightBridgesDesc", table: t) }

        public static let accessibility = Accessibility()
        
        /// 知识图谱专属无障碍本地化定义结构体
        public struct Accessibility: Sendable {
            /// 节点双击查看详情提示文案
            public var nodeHint: String { Localized.tr("graph.accessibility.nodeHint", table: t) }
            
            /// 放大图谱按钮无障碍标签
            public var zoomInLabel: String { Localized.tr("graph.accessibility.zoomInLabel", table: t) }
            /// 放大图谱按钮无障碍操作暗示
            public var zoomInHint: String { Localized.tr("graph.accessibility.zoomInHint", table: t) }
            
            /// 缩小图谱按钮无障碍标签
            public var zoomOutLabel: String { Localized.tr("graph.accessibility.zoomOutLabel", table: t) }
            /// 缩小图谱按钮无障碍操作暗示
            public var zoomOutHint: String { Localized.tr("graph.accessibility.zoomOutHint", table: t) }
            
            /// 重置并居中图谱按钮无障碍标签
            public var resetLabel: String { Localized.tr("graph.accessibility.resetLabel", table: t) }
            /// 重置并居中图谱按钮无障碍操作暗示
            public var resetHint: String { Localized.tr("graph.accessibility.resetHint", table: t) }
            
            /// 自适应视口图谱按钮无障碍标签
            public var fitToScreenLabel: String { Localized.tr("graph.accessibility.fitToScreenLabel", table: t) }
            /// 自适应视口图谱按钮无障碍操作暗示
            public var fitToScreenHint: String { Localized.tr("graph.accessibility.fitToScreenHint", table: t) }
            
            /// 重新计算图谱布局按钮无障碍标签
            public var relayoutLabel: String { Localized.tr("graph.accessibility.relayoutLabel", table: t) }
            /// 重新计算图谱布局按钮无障碍操作暗示
            public var relayoutHint: String { Localized.tr("graph.accessibility.relayoutHint", table: t) }
            
            /// 切换 3D 图谱模式按钮无障碍标签
            public var threeDLabel: String { Localized.tr("graph.accessibility.threeDLabel", table: t) }
            /// 切换 3D 图谱模式按钮无障碍操作暗示
            public var threeDHint: String { Localized.tr("graph.accessibility.threeDHint", table: t) }
            
            /// 顶部图谱数据面板无障碍标签
            public var statsBarLabel: String { Localized.tr("graph.accessibility.statsBarLabel", table: t) }
            /// 顶部图谱数据面板无障碍操作暗示
            public var statsBarHint: String { Localized.tr("graph.accessibility.statsBarHint", table: t) }
            
            /// 2D 图谱画布无障碍标签
            public var canvasLabel: String { Localized.tr("graph.accessibility.canvasLabel", table: t) }
            /// 2D 图谱画布无障碍操作暗示
            public var canvasHint: String { Localized.tr("graph.accessibility.canvasHint", table: t) }
        }

        public struct ThreeD {
            public static let t = "Insight"
            public static func tr(_ key: String) -> String {
                Localized.tr("graph3d." + key, table: t)
            }
            public static var title: String { Localized.tr("graph3d.title", table: t) }
        }
    }
}
