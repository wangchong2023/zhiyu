//
//  GraphCommunityProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：文档处理器：Markdown 解析、文本分块、图谱布局、网页抓取。
//
import Foundation

// MARK: - 社区发现
extension GraphLayoutProcessor {

    /// 检测Communities
    /// - Parameter nodes: nodes
    /// - Parameter edges: edges
    /// - Returns: 列表
    static func detectCommunities(nodes: [GraphNode], edges: [GraphEdge]) -> [GraphNode] {
        guard !nodes.isEmpty else { return [] }

    /// 图结构构建结果
    private struct GraphStructure {
        let adjacency: [UUID: Set<UUID>]
        let nodeMap: [UUID: GraphNode]
    }

        let (adjacency, nodeDegree, undirectedEdges) = buildGraphStructures(nodes: nodes, edges: edges)
        let m = Double(undirectedEdges.count)

        guard m > 0 else {
            return assignIndependentCommunities(nodes: nodes)
        }

        var (community, communityNodes) = initializeCommunities(nodes: nodes)

        refineCommunities(
            community: &community,
            communityNodes: &communityNodes,
            adjacency: adjacency,
            nodeDegree: nodeDegree,
            m: m
        )

        return finalizeCommunities(
            nodes: nodes,
            community: community,
            undirectedEdges: undirectedEdges
        )
    }

    // MARK: - 私有优化组件

    // 构建图的邻接关系与度数信息
    // swiftlint:disable:next large_tuple
    private static func buildGraphStructures(nodes: [GraphNode], edges: [GraphEdge]) -> (adjacency: [UUID: Set<UUID>], nodeDegree: [UUID: Int], undirectedEdges: Set<EdgePair>) {
        let nodeIDs = Set(nodes.map { $0.id })
        var adjacency: [UUID: Set<UUID>] = [:]
        var nodeDegree: [UUID: Int] = [:]

        for nodeID in nodeIDs {
            adjacency[nodeID] = []
            nodeDegree[nodeID] = 0
        }

        var undirectedEdges: Set<EdgePair> = []
        for edge in edges {
            if nodeIDs.contains(edge.source) && nodeIDs.contains(edge.target) {
                let pair = EdgePair(min(edge.source, edge.target), max(edge.source, edge.target))
                if undirectedEdges.insert(pair).inserted {
                    adjacency[edge.source]?.insert(edge.target)
                    adjacency[edge.target]?.insert(edge.source)
                    nodeDegree[edge.source, default: 0] += 1
                    nodeDegree[edge.target, default: 0] += 1
                }
            }
        }
        return (adjacency, nodeDegree, undirectedEdges)
    }

    /// 当没有边时，为每个节点分配独立的社区
    private static func assignIndependentCommunities(nodes: [GraphNode]) -> [GraphNode] {
        var workingNodes = nodes
        for i in workingNodes.indices {
            workingNodes[i].communityID = i
            workingNodes[i].communityCohesion = 1.0
        }
        return workingNodes
    }

    /// 初始化社区分配，每个节点独立为一个社区
    private static func initializeCommunities(nodes: [GraphNode]) -> (community: [UUID: Int], communityNodes: [Int: Set<UUID>]) {
        var community: [UUID: Int] = [:]
        var communityNodes: [Int: Set<UUID>] = [:]
        for (index, node) in nodes.enumerated() {
            community[node.id] = index
            communityNodes[index] = [node.id]
        }
        return (community, communityNodes)
    }

    /// 迭代优化社区分配
    private static func refineCommunities(
        community: inout [UUID: Int],
        communityNodes: inout [Int: Set<UUID>],
        adjacency: [UUID: Set<UUID>],
        nodeDegree: [UUID: Int],
        m: Double
    ) {
        var currentModularity = calculateModularity(community: community, adjacency: adjacency, nodeDegree: nodeDegree, m: m)
        var improved = true
        var iteration = 0
        let maxIterations = 10
        let nodeIDs = Array(community.keys)

        while improved && iteration < maxIterations {
            improved = false
            iteration += 1

            for nodeID in nodeIDs {
                guard let currentComm = community[nodeID] else { continue }
                let bestComm = findBestCommunity(
                    for: nodeID,
                    currentComm: currentComm,
                    community: community,
                    communityNodes: communityNodes,
                    adjacency: adjacency,
                    nodeDegree: nodeDegree,
                    m: m
                )

                if bestComm != currentComm {
                    communityNodes[currentComm]?.remove(nodeID)
                    communityNodes[bestComm, default: []].insert(nodeID)
                    community[nodeID] = bestComm
                    improved = true
                }
            }

            let newModularity = calculateModularity(community: community, adjacency: adjacency, nodeDegree: nodeDegree, m: m)
            if newModularity <= currentModularity {
                improved = false
            } else {
                currentModularity = newModularity
            }
        }
    }

    /// 寻找节点的最佳目标社区
    private static func findBestCommunity(
        for nodeID: UUID,
        currentComm: Int,
        community: [UUID: Int],
        communityNodes: [Int: Set<UUID>],
        adjacency: [UUID: Set<UUID>],
        nodeDegree: [UUID: Int],
        m: Double
    ) -> Int {
        var neighborCommunities: [Int: [UUID]] = [:]
        if let neighbors = adjacency[nodeID] {
            for neighbor in neighbors {
                guard let neighborComm = community[neighbor] else { continue }
                if neighborComm != currentComm {
                    neighborCommunities[neighborComm, default: []].append(neighbor)
                }
            }
        }

        var bestComm = currentComm
        var bestGain = 0.0

        for (targetComm, _) in neighborCommunities {
            let gain = calculateModularityGain(
                nodeID: nodeID,
                targetComm: targetComm,
                currentComm: currentComm,
                adjacency: adjacency,
                nodeDegree: nodeDegree,
                community: community,
                communityNodes: communityNodes,
                m: m
            )
            if gain > bestGain {
                bestGain = gain
                bestComm = targetComm
            }
        }
        return bestComm
    }

    /// 计算最终的内聚力并更新节点状态
    private static func finalizeCommunities(
        nodes: [GraphNode],
        community: [UUID: Int],
        undirectedEdges: Set<EdgePair>
    ) -> [GraphNode] {
        var workingNodes = nodes
        var communityInternalEdges: [Int: Int] = [:]
        var communityTotalEdges: [Int: Int] = [:]

        for edge in undirectedEdges {
            guard let comm0 = community[edge.source] else { continue }
            guard let comm1 = community[edge.target] else { continue }
            communityTotalEdges[comm0, default: 0] += 1
            communityTotalEdges[comm1, default: 0] += 1
            if comm0 == comm1 {
                communityInternalEdges[comm0, default: 0] += 1
            }
        }

        let nodeIndexMap = Dictionary(uniqueKeysWithValues: workingNodes.enumerated().map { ($0.element.id, $0.offset) })

        for (nodeID, comm) in community {
            let internalEdges = communityInternalEdges[comm] ?? 0
            let totalEdges = communityTotalEdges[comm] ?? 1
            let cohesion = Double(internalEdges) / Double(totalEdges)

            if let idx = nodeIndexMap[nodeID] {
                workingNodes[idx].communityID = comm
                workingNodes[idx].communityCohesion = cohesion
            }
        }

        return workingNodes
    }

    /// 计算模块度
    private static func calculateModularity(
        community: [UUID: Int],
        adjacency: [UUID: Set<UUID>],
        nodeDegree: [UUID: Int],
        m: Double
    ) -> Double {
        guard m > 0 else { return 0 }

        var modularity = 0.0
        for (nodeID, neighbors) in adjacency {
            let ki = Double(nodeDegree[nodeID] ?? 0)
            for neighborID in neighbors where nodeID < neighborID // 每条边只计算一次 {
                    let kj = Double(nodeDegree[neighborID] ?? 0)
                    let sameCommunity = community[nodeID] == community[neighborID] ? 1.0 : 0.0
                    Q += (1.0 - (ki * kj) / (2 * m)) * sameCommunity
            }
        }
        return Q / (2 * m)
    }

    /// 计算将节点移动到目标社区的模块度增益
    private static func calculateModularityGain(
        nodeID: UUID,
        targetComm: Int,
        currentComm: Int,
        adjacency: [UUID: Set<UUID>],
        nodeDegree: [UUID: Int],
        community: [UUID: Int],
        communityNodes: [Int: Set<UUID>],
        m: Double
    ) -> Double {
        guard m > 0 else { return 0 }

        let ki = Double(nodeDegree[nodeID] ?? 0)

        // 计算目标社区的内部边数和度数
        var targetInternalEdges = 0
        var targetTotalDegree = 0

        if let neighbors = adjacency[nodeID] {
            for neighborID in neighbors {
                if community[neighborID] == targetComm {
                    targetInternalEdges += 1
                }
                targetTotalDegree += nodeDegree[neighborID] ?? 0
            }
        }

        let kcInTarget = Double(targetInternalEdges)
        let sumKjInTarget = Double(targetTotalDegree)

        // 模块度增益公式
        let gain = (kcInTarget - (ki * sumKjInTarget) / (2 * m)) - (ki / (2 * m)) * (sumKjInTarget - ki)
        return gain
    }

    /// 获取低内聚力社区的节点 ID
    static func lowCohesionCommunities(nodes: [GraphNode], threshold: Double = 0.15) -> [UUID] {
        return nodes.filter { node in
            if let cohesion = node.communityCohesion {
                return cohesion < threshold
            }
            return false
        }.map { $0.id }
    }
}

// MARK: - 辅助类型

/// 无向边表示，用于去重
struct EdgePair: Hashable {
    let source: UUID
    let target: UUID

    init(_ source: UUID, _ target: UUID) {
        self.source = source
        self.target = target
    }
}
