//
//  VaultDataIsolationTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 VaultDataIsolation 开展自动化单元测试验证。
//
import XCTest
import GRDB
@testable import ZhiYu

/// 物理笔记本数据强隔离功能单元测试类（VaultDataIsolationTests）
/// 专职验证系统核心功能：当物理切换不同的知识金库（Vault）时，底层的物理 SQLite 数据库能够实现强力物理数据隔离。
@MainActor
final class VaultDataIsolationTests: XCTestCase {
    
    /// 临时物理沙盒隔离存储目录
    private var tempDirectory: URL!
    
    /// 笔记本 A 与 笔记本 B 的物理 SQLite 文件路径
    private var dbAURL: URL!
    private var dbBURL: URL!
    
    /// 笔记本 A 与 笔记本 B 的唯一识别 UUID
    private let vaultAID = UUID()
    private let vaultBID = UUID()
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 核心步骤 1：开辟本次测试专属的物理临时沙盒目录，防止对其他测试甚至生产数据造成污染
        let systemTemp = FileManager.default.temporaryDirectory
        tempDirectory = systemTemp.appendingPathComponent("ZhiYu_VaultIsolationTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // 核心步骤 2：生成两个物理隔离的专属库路径
        dbAURL = tempDirectory.appendingPathComponent("vault_A.sqlite3")
        dbBURL = tempDirectory.appendingPathComponent("vault_B.sqlite3")
        
        // 核心步骤 2.5：将 UserDefaults 播种标记预设为 true，严防 KnowledgeStore 后台异步 Task 自动播种冷启动引导数据干扰隔离测试
        UserDefaults.standard.set(true, forKey: "seeded_vault_\(vaultAID.uuidString)")
        UserDefaults.standard.set(true, forKey: "seeded_vault_\(vaultBID.uuidString)")
        
        // 核心步骤 3：重置并搭建纯净的全 Mock 运行环境以防止 DI 服务泄漏与死锁
        ServiceContainer.shared.reset()
        setupFullMockEnvironment()
    }
    
    override func tearDown() async throws {
        // 核心步骤 4：显式将 dbWriter 析构以释放 WAL 锁，随后物理擦除测试临时沙盒目录下的所有物理残留文件
        DatabaseManager.shared.dbWriter = nil
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        // 清理播种标记，确保测试无状态残留
        UserDefaults.standard.removeObject(forKey: "seeded_vault_\(vaultAID.uuidString)")
        UserDefaults.standard.removeObject(forKey: "seeded_vault_\(vaultBID.uuidString)")
        
        tempDirectory = nil
        dbAURL = nil
        dbBURL = nil
        
        try await super.tearDown()
    }
    
    // MARK: - 核心隔离测试用例
    
    /// 测试核心业务：验证在切换不同的物理笔记本（Vault）时，页面数据能够实现彻底的物理隔离与防泄露。
    func testVaultDataIsolationAndPersistence() async throws {
        // 🚀 【阶段一：切入笔记本 A 并写入专有数据，验证写入持久化成功】
        print("🎬 【Phase 1】物理挂载切换至 笔记本 A => ID: \(vaultAID.uuidString)")
        try DatabaseManager.shared.switchDatabase(to: vaultAID, at: dbAURL)
        
        // 核心动作：由于物理库已经切换，必须显式刷新 DI 服务容器内绑定的 Storage 模块
        // 这将用全新已就绪的 dbAURL Pool 初始化并重装 SQLiteStore 与 Repository
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        
        // 解析当前活跃的知识页面存储层
        let storeA = ServiceContainer.shared.resolve((any AnyPageStoreCapabilities).self)
        
        // 写入专属于 笔记本 A 的页面
        let pageATitle = "专属于笔记本A的绝密构想"
        let pageAContent = "这是笔记本 A 中的专有内容，包含其独特的设计模式与架构规约。"
        _ = try await storeA.anyCreatePage(
            title: pageATitle,
            pageType: .concept,
            customIcon: "doc.text.fill",
            content: pageAContent,
            tags: ["VaultA", "Design"],
            sourceURL: nil,
            rawSnippet: nil,
            fileSize: nil,
            sourceType: nil,
            forceDeepScan: false
        )
        
        // 断言笔记本 A 内部能够成功检索到该页面
        let pagesInA = try await storeA.fetchAllPages()
        XCTAssertEqual(pagesInA.count, 1, "笔记本 A 中应当有且仅有 1 个页面")
        XCTAssertEqual(pagesInA.first?.title, pageATitle, "笔记本 A 中的页面标题应当一致")
        XCTAssertEqual(pagesInA.first?.content, pageAContent, "笔记本 A 中的页面内容应当一致")
        
        // 🚀 【阶段二：热插拔物理切换至 笔记本 B，验证数据强隔离，页面数据应为空，随后写入专有数据 B】
        print("🎬 【Phase 2】物理挂载热切换至 笔记本 B => ID: \(vaultBID.uuidString)")
        try DatabaseManager.shared.switchDatabase(to: vaultBID, at: dbBURL)
        
        // 再次刷新 DI 服务容器，绑定 笔记本 B 的全新连接池
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        
        let storeB = ServiceContainer.shared.resolve((any AnyPageStoreCapabilities).self)
        
        // 关键物理断言：此时读取笔记本 B 的页面列表，必须为空，从而有力证明多租户笔记本数据是强隔离防泄漏的！
        let pagesInBBefore = try await storeB.fetchAllPages()
        XCTAssertTrue(pagesInBBefore.isEmpty, "关键断言：切换到全新的 笔记本 B 时，不应包含 笔记本 A 的任何数据，数据必须 100% 物理隔离")
        
        // 写入专属于 笔记本 B 的页面
        let pageBTitle = "专属于笔记本B的独立规划"
        let pageBContent = "这是笔记本 B 中的专有内容，主要包括其独立的产品演进大纲与里程碑节点。"
        _ = try await storeB.anyCreatePage(
            title: pageBTitle,
            pageType: .concept,
            customIcon: "chart.bar.fill",
            content: pageBContent,
            tags: ["VaultB", "Roadmap"],
            sourceURL: nil,
            rawSnippet: nil,
            fileSize: nil,
            sourceType: nil,
            forceDeepScan: false
        )
        
        // 断言笔记本 B 内部能够成功检索到该页面
        let pagesInBAfter = try await storeB.fetchAllPages()
        XCTAssertEqual(pagesInBAfter.count, 1, "笔记本 B 中应当有且仅有 1 个页面")
        XCTAssertEqual(pagesInBAfter.first?.title, pageBTitle, "笔记本 B 中的页面标题应当一致")
        
        // 🚀 【阶段三：再次物理切回 笔记本 A，验证原本的数据依然存在，且不混入 笔记本 B 的任何痕迹】
        print("🎬 【Phase 3】物理挂载切换回 笔记本 A => ID: \(vaultAID.uuidString)")
        try DatabaseManager.shared.switchDatabase(to: vaultAID, at: dbAURL)
        
        // 重新刷新并重装 DI 服务容器绑定的连接通道
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        
        let storeAagain = ServiceContainer.shared.resolve((any AnyPageStoreCapabilities).self)
        
        // 断言：笔记本 A 中的数据仍然完好无损地持久化保留，并且 100% 隔离了 笔记本 B 的所有写入数据
        let pagesInAagain = try await storeAagain.fetchAllPages()
        XCTAssertEqual(pagesInAagain.count, 1, "切回 笔记本 A 后，原本的数据应当完好保留")
        XCTAssertEqual(pagesInAagain.first?.title, pageATitle, "切回 笔记本 A 后，读出的应依然是 笔记本 A 的页面标题")
        XCTAssertEqual(pagesInAagain.first?.content, pageAContent, "切回 笔记本 A 后，读出的应依然是 笔记本 A 的页面内容")
        
        // 确保没有混入笔记本 B 的数据
        let containsB = pagesInAagain.contains(where: { $0.title == pageBTitle })
        XCTAssertFalse(containsB, "切回 笔记本 A 后，不应包含任何属于 笔记本 B 的残留数据")
        
        print("✅ 【Success】笔记本物理数据强隔离与持久化切换验证 100% 顺利通过！")
    }
}
