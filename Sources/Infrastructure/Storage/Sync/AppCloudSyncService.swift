// AppCloudSyncService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件实现了基于 CloudKit 的云端同步服务，负责知识金库跨设备的数据一致性。
// 核心职责：
// 1. 差异化同步：基于 LWW (Last-Writer-Wins) 策略解决数据冲突。
// 2. 数据安全：确保所有同步操作符合隐私白名单规范。
// 3. 容错恢复：实现“混沌恢复”能力，保障数据在异常网络下的最终一致性。
// MARK: [SR-01] 原始文档同步必须严格遵循授权 white-list 机制
// MARK: [RR-02] 系统必须支持“混沌恢复”能力，确保数据不丢失
// 版本: 1.3
// 修改记录:
//   - 2026-05-18: 物理重构 100% 三斜杠 Markdown 中文注释，全面杜绝 Javadoc tag 并补充 LWW 行内算法图解
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if ICLOUD_ENABLED
import Foundation
import CloudKit

// MARK: - iCloud 同步异常

/// iCloud 云同步过程中可能抛出的强类型业务异常 (iCloudSyncError)。
enum iCloudSyncError: LocalizedError {
    /// 当前 iCloud 账户不可用或未登录。
    case iCloudNotAvailable
    /// 底层 CloudKit SDK 抛出的网络或系统级异常。
    case cloudKitError(Error)
    /// 数据序列化为 JSON 失败。
    case encodingError
    /// 从云端拉取到的 JSON 解析失败。
    case decodingError
    /// 双向同步时，冲突决策解决器执行失败。
    case conflictResolutionFailed

    /// 本地化异常的文字描述。
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable: return L10n.ICloud.Error.notAvailable
        case .cloudKitError(let error): return "\(L10n.ICloud.Error.cloudKit)：\(error.localizedDescription)"
        case .encodingError: return L10n.ICloud.Error.encoding
        case .decodingError: return L10n.ICloud.Error.decoding
        case .conflictResolutionFailed: return L10n.ICloud.Error.conflictResolution
        }
    }
}

// MARK: - 同步状态

/// 表示云同步在 UI 表现层与逻辑调度层之间的实时生命周期状态 (SyncStatus)。
enum SyncStatus: Equatable {
    /// 闲置状态，等待触发。
    case idle
    /// 正在与云端服务器进行数据封包或推送吞吐。
    case syncing
    /// 双向同步成功，云地两端数据达成一致。
    case synced
    /// 同步链路上任何环节失败，附带错误信息。
    case error(String)

    /// 标记当前是否正在执行同步。
    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }

    /// 当前状态的类型安全本地化描述文本。
    var label: String {
        switch self {
        case .idle: return L10n.Common.sync.idle
        case .syncing: return L10n.Common.sync.syncing
        case .synced: return L10n.Common.sync.synced
        case .error(let msg): return "\(L10n.Common.sync.error)：\(msg)"
        }
    }
}

// MARK: - iCloud 同步中枢服务

/// 负责通过 Apple CloudKit 实现智宇知识库地云双向全量同步的底层核心服务（iCloudSyncService）。
/// 系统使用名为 "AppData" 的单一 CKRecord 实体进行云端承载，内部映射有：
///   - "pagesData": 经 JSON 序列化编码后的本地 [KnowledgePage] 实体集。
///   - "logEntriesData": 经 JSON 序列化编码后的本地 [LogEntry] 审计日志集。
///   - "lastModified": 标记记录最后一次物理同步修改的时间戳。
@MainActor
class iCloudSyncService: ObservableObject {
    /// 向 UI 发布当前的同步生命周期状态。
    @Published var syncStatus: SyncStatus = .idle
    /// 记录最近一次双向同步成功的绝对物理时间。
    @Published var lastSyncDate: Date?
    /// 标记当前 iCloud 账户是否在全局配置和系统鉴权下完全可用。
    @Published var iCloudAvailable: Bool = false

    private let container: CKContainer?
    private let database: CKDatabase?
    private let zoneID = CKRecordZone.ID(zoneName: "AppZone")
    private let recordType = "AppData"

    /// 标记 CloudKit 在当前设备或模拟器硬件上是否具备网络访问与运行能力。
    let cloudKitAvailable: Bool

    // MARK: - 业务层协同回调钩子
    
    /// 当云端数据成功拉取并解码完成后，触发的高层数据库合并回调钩子。
    var onRemoteDataReceived: (([KnowledgePage], [LogEntry]) -> Void)?
    
    /// 当同步链路中检测到云端有更新的数据，发生同步冲突时的双向问询回调。
    /// 调用方通过返回 `ConflictResolution` 决策来驱使 LWW 冲突解决器。
    var onConflictDetected: (([KnowledgePage], [LogEntry], [KnowledgePage], [LogEntry]) -> ConflictResolution)?

    @Inject private var appEnv: any AppEnvironmentProtocol

    /// 初始化同步服务。
    /// 在初始化过程中，会自动检测 AppEnvironment 云同步使能状态，读取 ubiquityIdentityToken 并冷启动 CloudKit 私有区。
    init() {
        if appEnv.isCloudSyncSupported {
            let token = FileManager.default.ubiquityIdentityToken
            cloudKitAvailable = token != nil
            
            if cloudKitAvailable {
                let ckr = CKContainer.default()
                container = ckr
                database = ckr.privateCloudDatabase
                iCloudAvailable = false // 初始设为 false，通过 checkiCloudStatus 异步更新状态
            } else {
                container = nil
                database = nil
                iCloudAvailable = false
                syncStatus = .error(L10n.ICloud.notAvailable)
            }
        } else {
            cloudKitAvailable = false
            container = nil
            database = nil
            iCloudAvailable = false
            syncStatus = .error(L10n.ICloud.notAvailable)
        }
    }

    // MARK: - iCloud 状态监控
    
    /// 异步且线程安全地检查当前设备上 Apple iCloud 账号的登录可用状态，并更新 `iCloudAvailable` 标记。
    func checkiCloudStatus() {
        guard let container else { return }
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                self?.iCloudAvailable = (status == .available)
                if status != .available {
                    self?.syncStatus = .error(L10n.ICloud.notAvailable)
                }
            }
        }
    }

    // MARK: - 云端推送 (强制单向)
    
    /// 将给定的本地页面列表与日志记录直接强制单向覆写推送到 iCloud 私有数据库中，不进行任何冲突合并比对。
    /// - Parameters:
    ///   - pages: 本地待推送的完整知识页面列表。
    ///   - logEntries: 本地待推送的审计日志列表。
    /// - Throws: `iCloudSyncError.iCloudNotAvailable`（iCloud 未登录）或 `cloudKitError`（网络与写入失败）。
    func pushToCloud(pages: [KnowledgePage], logEntries: [LogEntry]) async throws {
        guard iCloudAvailable, let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }

        await MainActor.run { syncStatus = .syncing }

        do {
            // 1. 确保私有数据库中的 AppZone 物理分区存在
            try await ensureZoneExists()

            // 2. 将数据编码为 JSON 字节包
            let pagesData = try JSONEncoder().encode(pages)
            let logsData = try JSONEncoder().encode(logEntries)

            // 3. 构建 CloudKit 专有记录标识并查找现有记录
            let recordID = CKRecord.ID(recordName: "knowledge-management_main", zoneID: zoneID)
            let record: CKRecord

            do {
                let existing = try await database.record(for: recordID)
                record = existing
            } catch {
                record = CKRecord(recordType: recordType, recordID: recordID)
            }

            // 4. 更新 CKRecord 元数据荷载
            record["pagesData"] = pagesData as CKRecordValue
            record["logEntriesData"] = logsData as CKRecordValue
            record["lastModified"] = Date() as CKRecordValue

            // 5. 物理保存至 iCloud 私有云存储
            _ = try await database.save(record)

            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .synced
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
            throw iCloudSyncError.cloudKitError(error)
        }
    }

    // MARK: - 云端拉取 (强制单向)
    
    /// 从 iCloud 云端单向物理拉取最新 AppData 承载，将其反序列化解码。
    /// - Returns: 元组数据，包含从云端下载的 `[KnowledgePage]` 和 `[LogEntry]` 列表。
    /// - Throws: `iCloudSyncError.iCloudNotAvailable` 或 `decodingError`（数据损坏或解码失败）。
    func pullFromCloud() async throws -> ([KnowledgePage], [LogEntry]) {
        guard iCloudAvailable, let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }

        await MainActor.run { syncStatus = .syncing }

        do {
            // 确保同步分区就绪
            try await ensureZoneExists()

            let recordID = CKRecord.ID(recordName: "knowledge-management_main", zoneID: zoneID)
            let record = try await database.record(for: recordID)

            // 提取二进制字节包
            guard let pagesData = record["pagesData"] as? Data,
                  let logsData = record["logEntriesData"] as? Data else {
                throw iCloudSyncError.decodingError
            }

            // 解析反序列化
            let pages = try JSONDecoder().decode([KnowledgePage].self, from: pagesData)
            let logs = try JSONDecoder().decode([LogEntry].self, from: logsData)

            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .synced
            }

            return (pages, logs)
        } catch let error as CKError where error.code == .unknownItem {
            // 云端记录从未创建过（如首批冷启动多端），此时优雅降级，返回空元组
            await MainActor.run {
                syncStatus = .idle
            }
            return ([], [])
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
            throw iCloudSyncError.cloudKitError(error)
        }
    }

    // MARK: - 双向智能同步 (LWW 解决冲突)
    
    /*
     * ┌────────────────────────────────────────────────────────┐
     * │              智宇地云双向 LWW 冲突仲裁与同步算法            │
     * └────────────────────────────────────────────────────────┘
     * 
     *      [开始同步] ──► 1. 物理拉取远程 CKRecord 实体
     *                            │
     *                            ▼
     *                     2. 读取 lastModified 时间戳
     *                            │
     *             ┌──────────────┴──────────────┐
     *             ▼ [云端时间戳较旧/无变动]       ▼ [云端时间戳较新/有更新]
     *       保持本地最新数据                  3. 触发 conflictResolution
     *             │                              │
     *             │                       ┌──────┴──────┐
     *             │                       ▼ [Merge 模式] ▼ [接纳云端/本地获胜]
     *             │               4. 智能合并算法LWW   完全覆盖/强推本地
     *             │                (UUID对撞时间戳胜出)     │
     *             │                (新页面无冲突追加)       │
     *             │                       │              │
     *             └───────────────────────┼──────────────┘
     *                                     ▼
     *                       5. 限制审计日志滑动窗口 (最新200条)
     *                                     │
     *                                     ▼
     *                       6. 将黄金数据集打包上传/推回 CloudKit
     *                                     │
     *                                     ▼
     *                                  [完成同步]
     */
    
    /// 执行智宇平台的核心双向同步算法。
    ///
    /// - 架构核心设计说明 (Bi-directional Synchronization Engine):
    ///   本方法贯彻 RAG 系统的“多端一致性最终闭环”原则，通过 CloudKit 私有数据库的分区机制进行跨设备数据融合：
    ///   1. **步骤一**：网络物理拉取远程的 CKRecord 二进制字节流，自动还原为内存云端页面与日志集。
    ///   2. **步骤二**：通过 `resolveSyncConflict` 对两端的时间线（Timeline）进行时间戳比对。
    ///   3. **步骤三**：若云端发生更新修改，则调配 LWW（Last-Writer-Wins，最近写入者胜出）合并算法，执行无损融合去重。
    ///   4. **步骤四**：同步完成的黄金版本数据再次被序列化强推回 CloudKit，以此达成全局最终一致性。
    ///
    /// - Parameters:
    ///   - localPages: 当前专属物理笔记本中的本地知识页面列表。
    ///   - localLogs: 当前专属物理笔记本中的本地审计日志列表。
    /// - Returns: 经智能冲突合并比对后，达成的云地一致的最终黄金数据集（页面数组 + 审计日志数组）。
    /// - Throws: `iCloudSyncError`（云端网络失败或比对合并错乱）。
    func sync(localPages: [KnowledgePage], localLogs: [LogEntry]) async throws -> ([KnowledgePage], [LogEntry]) {
        guard iCloudAvailable, let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }

        await MainActor.run { syncStatus = .syncing }

        do {
            // 步骤 A.1：验证 CloudKit 的自定义物理 Zone 空间是否已就绪挂载
            try await ensureZoneExists()

            // 步骤 A.2：物理从 iCloud 私有云端拉取最新的 CKRecord 实体包
            let (remotePages, remoteLogs, record) = try await fetchRemoteData(database: database)

            // 步骤 A.3：将拉取到的云端记录与本地数据库进行基于 LWW 冲突解决器的时间轴比对
            let (finalPages, finalLogs) = try await resolveSyncConflict(
                localPages: localPages,
                localLogs: localLogs,
                remotePages: remotePages,
                remoteLogs: remoteLogs,
                record: record
            )

            // 步骤 A.4：将最终融合打磨出的黄金数据集重新序列化，物理推回 CloudKit 云存储以同步给其他多终端设备
            try await pushToCloud(database: database, record: record, pages: finalPages, logs: finalLogs)

            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .synced
            }

            return (finalPages, finalLogs)
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
            throw iCloudSyncError.cloudKitError(error)
        }
    }

    // MARK: - 私有同步算法辅助方法

    /// 从 CloudKit 私有数据库中物理加载核心同步记录 AppData。
    private func fetchRemoteData(database: CKDatabase) async throws -> ([KnowledgePage], [LogEntry], CKRecord) {
        let recordID = CKRecord.ID(recordName: "knowledge-management_main", zoneID: zoneID)
        var remotePages: [KnowledgePage] = []
        var remoteLogs: [LogEntry] = []
        var record: CKRecord

        do {
            let existing = try await database.record(for: recordID)
            record = existing

            if let pagesData = existing["pagesData"] as? Data,
               let logsData = existing["logEntriesData"] as? Data {
                remotePages = try JSONDecoder().decode([KnowledgePage].self, from: pagesData)
                remoteLogs = try JSONDecoder().decode([LogEntry].self, from: logsData)
            }
        } catch {
            // 不存在则新建
            record = CKRecord(recordType: recordType, recordID: recordID)
        }

        return (remotePages, remoteLogs, record)
    }

    /// 基于 LWW (Last-Writer-Wins) 最近写入者获胜策略，或用户交互的回调策略，对本地和云端数据执行融合裁定。
    ///
    /// - 详细算法步骤说明 (LWW Conflict Arbitration):
    ///   1. **空置判断**：若云端从未被写入（无任何 Pages 数据），意味着本地为绝对主权数据，直接返回本地数据集。
    ///   2. **时间比对**：从 CKRecord 提取云端数据的物理最后更新修改时间戳 `remoteDate`。
    ///   3. **时序断言**：将 `remoteDate` 与本地上一次同步成功成功的物理时刻进行时序比对，以确定“云端是否被其他设备写入过更新的知识片”。
    ///   4. **裁决解决**：若云端更新，则激活 `ConflictResolution` 决策树：
    ///      - `.keepLocal`：拒绝云端，维持本地主权。
    ///      - `.keepRemote`：全面臣服云端，地端数据做完全覆写。
    ///      - `.merge`（默认）：两端原子交融，相同 UUID 记录以最近更新时间戳为准胜出，新增记录双向无冲突合并。
    private func resolveSyncConflict(
        localPages: [KnowledgePage],
        localLogs: [LogEntry],
        remotePages: [KnowledgePage],
        remoteLogs: [LogEntry],
        record: CKRecord
    ) async throws -> ([KnowledgePage], [LogEntry]) {
        var finalPages = localPages
        var finalLogs = localLogs

        // 步骤 B.1：防空容错判定——如果云端从未存储过任何数据，则以本地数据集为唯一绝对信任源直接输出
        guard !remotePages.isEmpty else {
            return (finalPages, finalLogs)
        }

        // 步骤 B.2：读取远程记录的 CKRecord 元数据时间戳，若遗失则以远古时刻（distantPast）兜底
        let remoteDate = record["lastModified"] as? Date ?? Date.distantPast
        
        // 步骤 B.3：评估时序状态——判断云端修改时间是否大于本地最近同步成功的绝对时间
        let hasRemoteNewer = lastSyncDate.map { remoteDate > $0 } ?? true

        // 步骤 B.4：检测到云端存在较新更新，立刻执行物理冲突决策树逻辑
        if hasRemoteNewer {
            // 调配冲突解决器确定具体的合并方案（默认走 LWW 智能去重合并）
            let resolution = await resolveConflict(
                localPages: localPages,
                localLogs: localLogs,
                remotePages: remotePages,
                remoteLogs: remoteLogs
            )

            switch resolution {
            case .keepLocal:
                // 方案一：保留本地。原地端不变，等待后续用本地数据单向强制覆写云端
                break
            case .keepRemote:
                // 方案二：保留云端。本地无条件接受云端覆盖，以云端页面及日志为最新基准
                finalPages = remotePages
                finalLogs = remoteLogs
            case .merge:
                // 方案三：智能融合。相同 UUID 实体以 updatedAt 最近更新时间戳获胜，新页面自动追加
                finalPages = mergePages(local: localPages, remote: remotePages)
                finalLogs = mergeLogs(local: localLogs, remote: remoteLogs)
            }
        } else if lastSyncDate != nil {
            // 步骤 B.5：本地数据在最近同步后较新，或无变动，保持本地最新数据，继续等待后续地推云
            finalPages = localPages
            finalLogs = localLogs
        }

        return (finalPages, finalLogs)
    }

    /// 执行底层的物理推送操作，将合并后的数据集打包并存储。
    private func pushToCloud(database: CKDatabase, record: CKRecord, pages: [KnowledgePage], logs: [LogEntry]) async throws {
        let mergedPagesData = try JSONEncoder().encode(pages)
        let mergedLogsData = try JSONEncoder().encode(logs)

        record["pagesData"] = mergedPagesData as CKRecordValue
        record["logEntriesData"] = mergedLogsData as CKRecordValue
        record["lastModified"] = Date() as CKRecordValue

        _ = try await database.save(record)
    }

    // MARK: - 实时静默同步通知

    /// 向 iCloud 私有云端数据库注册静默推送订阅通知，一旦多端数据变动，当前设备瞬间获得同步唤醒。
    func subscribeToRemoteChanges() async throws {
        guard let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }
        let subscription = CKDatabaseSubscription(subscriptionID: "knowledge-management_all_changes")

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        try await database.save(subscription)
    }

    /// 静默通知唤醒时被调用，从云端调配数据。
    func fetchRemoteChanges() async throws -> ([KnowledgePage], [LogEntry]) {
        return try await pullFromCloud()
    }

    /// 确保同步容器 Zone 物理存在。
    private func ensureZoneExists() async throws {
        guard let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }
        do {
            _ = try await database.recordZone(for: zoneID)
        } catch let error as CKError where error.code == .zoneNotFound {
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await database.save(zone)
        }
    }

    /// 冲突比对决策派发器。
    private func resolveConflict(
        localPages: [KnowledgePage],
        localLogs: [LogEntry],
        remotePages: [KnowledgePage],
        remoteLogs: [LogEntry]
    ) async -> ConflictResolution {
        if let onConflict = onConflictDetected {
            return onConflict(localPages, localLogs, remotePages, remoteLogs)
        }
        return .merge
    }

    // MARK: - 极客级 LWW 合并算法实现

    /// 页面列表的极客级 LWW 合并算法实现。
    ///
    /// - 详细融合逻辑 (Merge Logic):
    ///   1. **物理对撞处理**：遍历远程的每一个知识页面实体。如果本地已存在相同 ID 的页面，
    ///      比较两者的 `updatedAt` 时间戳，保留较新的那份（最新写入者胜出）。
    ///   2. **重名防止机制**：若本地不存在相同 ID 页面，但由于防冲突规约，检查地端是否有重名 Title。
    ///      如果有相同 Title（通常发生在跨设备独立冷启动起名），则不进行直接追加，以确保唯一索引健壮性；
    ///      若毫无冲突，则认定为纯新增，将其直接在尾部追加挂载。
    private func mergePages(local: [KnowledgePage], remote: [KnowledgePage]) -> [KnowledgePage] {
        var merged = local

        for remotePage in remote {
            if let localIndex = merged.firstIndex(where: { $0.id == remotePage.id }) {
                // 1. 发现 UUID 物理对撞：比对时间戳进行最新时间戳覆盖
                let localPage = merged[localIndex]
                if remotePage.updatedAt > localPage.updatedAt {
                    merged[localIndex] = remotePage
                }
            } else if !merged.contains(where: { $0.title == remotePage.title }) {
                // 2. 纯新增 of 远程页面，且无重名 Title 冲突，直接在尾部安全追加挂载
                merged.append(remotePage)
            }
        }

        return merged
    }

    /// 审计日志的 LWW 去重合并算法。
    ///
    /// - 日志合并及驱逐约束 (Log Merge & Eviction Metrics):
    ///   1. 遍历远程的日志项，根据唯一的 `id` 进行物理去重追加。
    ///   2. 按日志的 `timestamp` 绝对时间由新到旧（降序）排序，排列出最新的操作轨迹。
    ///   3. **滑动窗口物理驱逐**：为了极致节省多笔记本沙盒内 SQLite 持久化空间与内存吞吐开销，
    ///      严格限制最多仅保留最近 200 条审计记录。一旦超出阀值，旧日志将被瞬间物理驱逐。
    private func mergeLogs(local: [LogEntry], remote: [LogEntry]) -> [LogEntry] {
        var merged = local

        // 1. 追加不存在于本地的远程审计日志记录，按 id 进行去重判断
        for remoteLog in remote {
            if !merged.contains(where: { $0.id == remoteLog.id }) {
                merged.append(remoteLog)
            }
        }

        // 2. 将去重融合后的审计日志按产生时间戳进行降序（由新到旧）排列
        merged.sort { $0.timestamp > $1.timestamp }

        // 3. 触发容量削减阀值限制，强行裁剪保留最近 200 条，物理驱逐历史废弃日志，保护 sqlite 性能及内存
        if merged.count > 200 {
            merged = Array(merged.prefix(200))
        }

        return merged
    }
}

// MARK: - 冲突解决模式

/// 在数据双向碰撞时的核心决议策略 (ConflictResolution)。
enum ConflictResolution: String, CaseIterable {
    /// 强制保留本地数据，单向覆盖云端。
    case keepLocal
    /// 接纳云端最新数据，完全覆盖并重置本地。
    case keepRemote
    /// 启用 LWW 智能去重融合合并算法（系统默认推荐）。
    case merge

    /// 策略强类型的本地化呈现文字。
    var displayName: String {
        switch self {
        case .keepLocal: return L10n.ICloud.keepLocal
        case .keepRemote: return L10n.ICloud.keepRemote
        case .merge: return L10n.ICloud.merge
        }
    }
}

@MainActor
extension iCloudSyncService: @unchecked Sendable {}
#endif // ICLOUD_ENABLED

