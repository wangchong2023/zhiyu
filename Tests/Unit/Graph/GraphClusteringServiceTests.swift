//
//  GraphClusteringServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 GraphClusteringService 的 K-Means 聚类算法开展自动化单元测试。
//

import XCTest
@testable import ZhiYu

final class GraphClusteringServiceTests: ZhiYuTestCase {

    private let service = GraphClusteringService()

    // MARK: - 基础聚类

    func testCluster_basicKMeans() {
        let pages = [
            KnowledgePage(title: "A"),
            KnowledgePage(title: "B"),
            KnowledgePage(title: "C"),
            KnowledgePage(title: "D"),
            KnowledgePage(title: "E"),
            KnowledgePage(title: "F")
        ]
        let embeddings: [UUID: [Float]] = [
            pages[0].id: [1, 0],
            pages[1].id: [1.1, 0],
            pages[2].id: [0, 1],
            pages[3].id: [0, 1.1],
            pages[4].id: [10, 10],
            pages[5].id: [10, 10.1]
        ]
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 3)
        XCTAssertTrue(clusters.count > 0 && clusters.count <= 3, "应生成 1-3 个有效聚类")
        for cluster in clusters {
            XCTAssertFalse(cluster.pageIDs.isEmpty, "每个聚类应包含页面")
            XCTAssertFalse(cluster.centroid.isEmpty, "质心不应为空")
        }
    }

    func testCluster_pagesLessThanK_returnsEmpty() {
        let pages = [KnowledgePage(title: "A"), KnowledgePage(title: "B")]
        let embeddings: [UUID: [Float]] = [
            pages[0].id: [1, 2],
            pages[1].id: [3, 4]
        ]
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 3)
        XCTAssertTrue(clusters.isEmpty, "页面数少于 k 时应返回空")
    }

    func testCluster_singleCluster() {
        let pages = (0..<5).map { KnowledgePage(title: "\($0)") }
        let embeddings: [UUID: [Float]] = Dictionary(uniqueKeysWithValues:
            pages.map { ($0.id, [Float($0.id.hashValue % 10), Float($0.id.hashValue % 5)]) }
        )
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 1)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters[0].pageIDs.count, 5, "所有页面应归入唯一聚类")
    }

    func testCluster_consistentColors() {
        let pages = (0..<10).map { KnowledgePage(title: "\($0)") }
        let embeddings: [UUID: [Float]] = Dictionary(uniqueKeysWithValues:
            pages.map { ($0.id, [Float.random(in: 0...10), Float.random(in: 0...10)]) }
        )
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 3)
        for cluster in clusters {
            XCTAssertFalse(cluster.colorName.isEmpty, "每个聚类应有颜色")
        }
    }

    func testCluster_allPagesAccounted() {
        let pages = (0..<6).map { KnowledgePage(title: "\($0)") }
        let embeddings: [UUID: [Float]] = Dictionary(uniqueKeysWithValues:
            pages.map { ($0.id, [Float($0.id.hashValue), Float($0.id.hashValue)]) }
        )
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 2)
        let allIDs = clusters.flatMap(\.pageIDs)
        XCTAssertEqual(Set(allIDs).count, pages.count, "所有页面应被分配到某个聚类")
    }

    func testCluster_dimensionality() {
        let pages = (0..<6).map { KnowledgePage(title: "\($0)") }
        let embeddings: [UUID: [Float]] = Dictionary(uniqueKeysWithValues:
            pages.map { ($0.id, [1, 2, 3, 4]) }
        )
        let clusters = service.cluster(pages: pages, embeddings: embeddings, k: 2)
        for cluster in clusters {
            XCTAssertEqual(cluster.centroid.count, 4, "质心维度应与 embedding 维度一致")
        }
    }
}
