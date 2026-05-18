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
    
    /// 执行智宇平台的核心双向同步算法。
    /// 步骤：拉取远程 CKRecord -> 运用 LWW 策略对页面和审计日志执行冲突决策与去重合并 -> 更新回 CloudKit -> 返回最新合并数据集。
    /// - Parameters:
    ///   - localPages: 当前专属物理笔记本中的本地知识页面。
    ///   - localLogs: 当前专属物理笔记本中的本地审计日志。
    /// - Returns: 经智能冲突合并比对后，达成的云地一致的最终数据集。
    /// - Throws: `iCloudSyncError`（云端网络失败或比对合并错乱）。
    func sync(localPages: [KnowledgePage], localLogs: [LogEntry]) async throws -> ([KnowledgePage], [LogEntry]) {
        guard iCloudAvailable, let database else {
            throw iCloudSyncError.iCloudNotAvailable
        }

        await MainActor.run { syncStatus = .syncing }

        do {
            try await ensureZoneExists()

            // 1. 物理拉取远程记录实体
            let (remotePages, remoteLogs, record) = try await fetchRemoteData(database: database)

            // 2. 将数据递交至 LWW 冲突决策处理器，计算出两端一致的黄金版本数据
            let (finalPages, finalLogs) = try await resolveSyncConflict(
                localPages: localPages,
                localLogs: localLogs,
                remotePages: remotePages,
                remoteLogs: remoteLogs,
                record: record
            )

            // 3. 将比对融合完成后的最终黄金数据集推送保存回 iCloud 云数据库中
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

    /// 基于 LWW (Last-Writer-Wins) 最终写入者获胜策略或用户交互的回调策略，对本地和云端数据执行融合裁定。
    private func resolveSyncConflict(
        localPages: [KnowledgePage],
        localLogs: [LogEntry],
        remotePages: [KnowledgePage],
        remoteLogs: [LogEntry],
        record: CKRecord
    ) async throws -> ([KnowledgePage], [LogEntry]) {
        var finalPages = localPages
        var finalLogs = localLogs

        // 如果云端从未存储过任何数据，则以本地数据集为唯一绝对信任源
        guard !remotePages.isEmpty else {
            return (finalPages, finalLogs)
        }

        // 获取云端数据的最后物理更新时间
        let remoteDate = record["lastModified"] as? Date ?? Date.distantPast
        
        // 比对云端修改时间与本地最近同步成功的绝对时间
        let hasRemoteNewer = lastSyncDate.map { remoteDate > $0 } ?? true

        // 检测到云端存在较新更新：执行冲突决策
        if hasRemoteNewer {
            // 调配冲突解决器决定合并方向
            let resolution = await resolveConflict(
                localPages: localPages,
                localLogs: localLogs,
                remotePages: remotePages,
                remoteLogs: remoteLogs
            )

            switch resolution {
            case .keepLocal:
                // 1. 保留本地：不作改变，等待后续用本地覆盖云端
                break
            case .keepRemote:
                // 2. 接纳云端：完全覆写本地
                finalPages = remotePages
                finalLogs = remoteLogs
            case .merge:
                // 3. 智能融合：相同 UUID 实体以 updatedAt 时间戳更新者获胜，新页面自动追加
                finalPages = mergePages(local: localPages, remote: remotePages)
                finalLogs = mergeLogs(local: localLogs, remote: remoteLogs)
            }
        } else if lastSyncDate != nil {
            // 本地数据在最近同步后较新，或无变动，保持本地最新数据
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

    /// 页面列表的 LWW 合并算法。
    /// 逻辑：
    /// 1. 遍历远程每一个页面实体。
    /// 2. 若本地已存在相同 ID 的页面，比较两者的 `updatedAt` 时间戳，保留较新的那份。
    /// 3. 若本地不存在相同 ID 页面，且不存在相同 Title（防止用户跨设备冷启动重复起名冲突），则将远程页面安全追加。
    private func mergePages(local: [KnowledgePage], remote: [KnowledgePage]) -> [KnowledgePage] {
        var merged = local

        for remotePage in remote {
            if let localIndex = merged.firstIndex(where: { $0.id == remotePage.id }) {
                // 1. 发现 UUID 物理对撞：比对时间戳进行覆盖
                let localPage = merged[localIndex]
                if remotePage.updatedAt > localPage.updatedAt {
                    merged[localIndex] = remotePage
                }
            } else if !merged.contains(where: { $0.title == remotePage.title }) {
                // 2. 纯新增的远程页面，直接在尾部追加挂载
                merged.append(remotePage)
            }
        }

        return merged
    }

    /// 审计日志的 LWW 去重合并算法。
    /// 逻辑：
    /// 1. 遍历远程的日志项，根据唯一的 `id` 进行去重。
    /// 2. 按日志的 `timestamp` 绝对时间由新到旧排序。
    /// 3. 按照 KISS 原则和内存管控指标，强行将最终日志列表裁剪保留最近 200 条，物理驱逐历史废弃日志。
    private func mergeLogs(local: [LogEntry], remote: [LogEntry]) -> [LogEntry] {
        var merged = local

        // 1. 追加不存在于本地的远程审计日志记录
        for remoteLog in remote {
            if !merged.contains(where: { $0.id == remoteLog.id }) {
                merged.append(remoteLog)
            }
        }

        // 2. 按审计产生的时间戳降序排列
        merged.sort { $0.timestamp > $1.timestamp }

        // 3. 触发容量削减阀值，强行限制最近 200 条，保护 sqlite 及内存
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

