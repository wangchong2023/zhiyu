// 功能说明: [Shared]
//
// L10n+Graph.swift
// 智宇 (ZhiYu) 多语言 Graph 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Graph {
        public static let t = "Graph"

        public static func tr(_ key: String) -> String {
            Localized.tr("graph." + key, table: t)
        }
        /// 获取图谱节点和连接的统计提示文案
        /// - Parameters:
        ///   - nodes: 节点个数
        ///   - connections: 连接个数
        /// - Returns: 本地化格式化文案
        public static func nodesConnections(_ nodes: Int, _ connections: Int) -> String { Localized.trf("graph.nodesConnections", table: "Graph", nodes, connections) }

        /// 获取图谱连接数统计文案
        /// - Parameter count: 连接数
        /// - Returns: 本地化格式化文案
        public static func linksCountFormat(_ count: Int) -> String { Localized.trf("graph.linksCountFormat", table: "Graph", count) }

        /// 获取聚类群组名称文案
        /// - Parameter index: 群组索引序号
        /// - Returns: 本地化格式化文案
        public static func clusterName(_ index: Int) -> String { Localized.trf("graph.cluster.name", table: "Graph", index) }

        public static var filter: String { Localized.tr("graph.filter", table: "Graph") }
        public static var insights: String { Localized.tr("graph.insights", table: "Graph") }
        public static var emptyTitle: String { Localized.tr("graph.emptyTitle", table: "Graph") }
        public static var emptyDesc: String { Localized.tr("graph.emptyDesc", table: "Graph") }
        public static var startBuilding: String { Localized.tr("graph.startBuilding", table: "Graph") }
        public static var all: String { Localized.tr("graph.all", table: "Graph") }

        public static var legend: String { Localized.tr("graph.legend", table: "Graph") }
        public static var viewDetail: String { Localized.tr("graph.viewDetail", table: "Graph") }
        public static var copyPageLink: String { Localized.tr("graph.copyPageLink", table: "Graph") }

        public static var insightSurprising: String { Localized.tr("graph.insightSurprising", table: "Graph") }
        public static var insightSurprisingDesc: String { Localized.tr("graph.insightSurprisingDesc", table: "Graph") }
        public static var title: String { Localized.tr("graph.title", table: "Graph") }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf("graph." + key, table: "Graph", args) }
        public static var insightOrphans: String { Localized.tr("graph.insightOrphans", table: "Graph") }
        public static var insightOrphansDesc: String { Localized.tr("graph.insightOrphansDesc", table: "Graph") }
        public static var insightSparse: String { Localized.tr("graph.insightSparse", table: "Graph") }
        public static var insightSparseDesc: String { Localized.tr("graph.insightSparseDesc", table: "Graph") }
        public static var insightBridges: String { Localized.tr("graph.insightBridges", table: "Graph") }
        public static var insightBridgesDesc: String { Localized.tr("graph.insightBridgesDesc", table: "Graph") }

        public static let accessibility = Accessibility()
        public struct Accessibility: Sendable {
            public var nodeHint: String { Localized.tr("graph.accessibility.nodeHint", table: "Graph") }
        }

        public struct ThreeD {
            public static let t = "Graph"
            public static func tr(_ key: String) -> String {
                Localized.tr("graph3d." + key, table: t)
            }
            public static var title: String { Localized.tr("graph3d.title", table: t) }
        }
    }
}
