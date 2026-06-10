# 导入原始内容留存 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 导入 Tab 新增原始内容留存功能——按分类（链接/文件/手工/OCR/剪贴板/语音）保存导入的原始内容，支持进度跟踪和存储统计。

**Architecture:** 新建 `ImportRecord` GRDB 模型存储原始内容元数据（大文件走磁盘），`ImportRecordRepository` 封装 CRUD。在 `IngestCoordinator` 各导入流程中插入记录创建/更新逻辑。IngestView 新增分段 Tab 卡片列表区。`SystemStatsCoordinator` 增加导入原始内容存储统计。

**Tech Stack:** SwiftUI, GRDB, Observation, CryptoKit (SHA256)

---

### File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `Sources/Infrastructure/Models/ImportRecord.swift` | Create | ImportRecord GRDB 模型 |
| `Sources/Infrastructure/Storage/Persistence/DatabaseSchemaMigrator.swift` | Modify | V7 迁移：import_records 表 |
| `Sources/Core/Base/Constants/AppConstants.swift` | Modify | 表名常量 |
| `Sources/Domain/Protocols/ImportRecordRepository.swift` | Create | Repository 协议 |
| `Sources/Infrastructure/Storage/Repositories/SQLiteImportRecordRepository.swift` | Create | SQLite 实现 |
| `Sources/App/Core/ModuleRegistrar.swift` | Modify | DI 注册 |
| `Sources/Features/Knowledge/Ingest/Coordinator/IngestCoordinator.swift` | Modify | 各导入流程插入 ImportRecord |
| `Sources/Features/Knowledge/Ingest/View/IngestView.swift` | Modify | 新增导入原始内容区域 |
| `Sources/Features/Knowledge/Ingest/View/Components/ImportRecordCard.swift` | Create | 导入记录卡片组件 |
| `Sources/Features/Knowledge/Ingest/View/Components/ImportRecordSection.swift` | Create | 分段 Tab + 卡片列表 |
| `Sources/Features/System/Settings/Coordinator/SystemStatsCoordinator.swift` | Modify | 存储统计增强 |
| `Sources/Localization/Extensions/L10n+Ingest.swift` | Modify | L10n 键值 |
| `Sources/Localization/Catalogs/Knowledge.xcstrings` | Modify | L10n 字符串 |
| `Tests/Unit/Storage/ImportRecordRepositoryTests.swift` | Create | 仓储层测试 |

---

### Task 1: ImportRecord 数据模型

**Files:**
- Create: `Sources/Infrastructure/Models/ImportRecord.swift`
- Modify: `Sources/Core/Base/Constants/AppConstants.swift:55-65`

- [ ] **Step 1: 在 AppConstants 中添加表名常量**

```swift
// Sources/Core/Base/Constants/AppConstants.swift，在 Tables 枚举中添加：
public static let importRecords = "import_records"
```

- [ ] **Step 2: 创建 ImportRecord 模型**

```swift
// Sources/Infrastructure/Models/ImportRecord.swift
import Foundation
import GRDB

/// 导入原始内容留存记录
public struct ImportRecord: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.importRecords

    public var id: String       // UUID 字符串
    public var category: String // link / file / manual / ocr / clipboard / voice
    public var title: String
    public var status: String   // pending / processing / done / failed
    public var rawText: String? // 文本类原始内容
    public var sourceURL: String?
    public var filePath: String? // 大文件磁盘路径
    public var fileSize: Int64?  // 文件大小（字节）
    public var pageID: String?   // 关联 KnowledgePage UUID
    public var vaultID: String?  // 关联 Vault UUID
    public var taskID: String?   // 关联 GlobalTask UUID
    public var createdAt: Date
    public var completedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id, category, title, status
        case rawText = "raw_text"
        case sourceURL = "source_url"
        case filePath = "file_path"
        case fileSize = "file_size"
        case pageID = "page_id"
        case vaultID = "vault_id"
        case taskID = "task_id"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let category = Column(CodingKeys.category)
        static let title = Column(CodingKeys.title)
        static let status = Column(CodingKeys.status)
        static let rawText = Column(CodingKeys.rawText)
        static let sourceURL = Column(CodingKeys.sourceURL)
        static let filePath = Column(CodingKeys.filePath)
        static let fileSize = Column(CodingKeys.fileSize)
        static let pageID = Column(CodingKeys.pageID)
        static let vaultID = Column(CodingKeys.vaultID)
        static let taskID = Column(CodingKeys.taskID)
        static let createdAt = Column(CodingKeys.createdAt)
        static let completedAt = Column(CodingKeys.completedAt)
    }

    public init(
        id: String = UUID().uuidString,
        category: String,
        title: String,
        status: String = "pending",
        rawText: String? = nil,
        sourceURL: String? = nil,
        filePath: String? = nil,
        fileSize: Int64? = nil,
        pageID: String? = nil,
        vaultID: String? = nil,
        taskID: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.status = status
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.filePath = filePath
        self.fileSize = fileSize
        self.pageID = pageID
        self.vaultID = vaultID
        self.taskID = taskID
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

/// 导入分类枚举
public enum ImportCategory: String, CaseIterable, Sendable {
    case link = "link"
    case file = "file"
    case manual = "manual"
    case ocr = "ocr"
    case clipboard = "clipboard"
    case voice = "voice"
}
```

- [ ] **Step 3: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Sources/Infrastructure/Models/ImportRecord.swift Sources/Core/Base/Constants/AppConstants.swift
git commit -m "feat: ImportRecord 数据模型 + ImportCategory 枚举"
```

---

### Task 2: V7 数据库迁移

**Files:**
- Modify: `Sources/Infrastructure/Storage/Persistence/DatabaseSchemaMigrator.swift:220-223`

- [ ] **Step 1: 在 vault migrator 中添加 V7 迁移**

在 `// MARK: - 全局数据库迁移方案` 之前插入：

```swift
        // V7: 导入原始内容留存表 (@P5: 导入原始数据持久化)
        migrator.registerMigration("v7_import_records") { db in
            try db.create(table: ImportRecord.databaseTableName, ifNotExists: true) { t in
                t.column(ImportRecord.Columns.id.name, .text).primaryKey()
                t.column(ImportRecord.Columns.category.name, .text).notNull().indexed()
                t.column(ImportRecord.Columns.title.name, .text).notNull()
                t.column(ImportRecord.Columns.status.name, .text).notNull().defaults(to: "pending")
                t.column(ImportRecord.Columns.rawText.name, .text)
                t.column(ImportRecord.Columns.sourceURL.name, .text)
                t.column(ImportRecord.Columns.filePath.name, .text)
                t.column(ImportRecord.Columns.fileSize.name, .integer)
                t.column(ImportRecord.Columns.pageID.name, .text)
                t.column(ImportRecord.Columns.vaultID.name, .text)
                t.column(ImportRecord.Columns.taskID.name, .text)
                t.column(ImportRecord.Columns.createdAt.name, .datetime).notNull().defaults(to: Date())
                t.column(ImportRecord.Columns.completedAt.name, .datetime)
            }
        }

        return migrator
    }
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Sources/Infrastructure/Storage/Persistence/DatabaseSchemaMigrator.swift
git commit -m "feat: V7 迁移 — import_records 表"
```

---

### Task 3: ImportRecordRepository 协议与实现

**Files:**
- Create: `Sources/Domain/Protocols/ImportRecordRepository.swift`
- Create: `Sources/Infrastructure/Storage/Repositories/SQLiteImportRecordRepository.swift`
- Modify: `Sources/App/Core/ModuleRegistrar.swift:85-92`

- [ ] **Step 1: 创建协议**

```swift
// Sources/Domain/Protocols/ImportRecordRepository.swift
import Foundation

public protocol ImportRecordRepository: Sendable {
    func save(_ record: ImportRecord) async throws
    func fetchAll(category: String?, limit: Int) async throws -> [ImportRecord]
    func fetchByID(_ id: String) async throws -> ImportRecord?
    func updateStatus(id: String, status: String, completedAt: Date?) async throws
    func delete(_ id: String) async throws
    func fetchInProgress() async throws -> [ImportRecord]
    func totalStorageSize() async throws -> Int64
}
```

- [ ] **Step 2: 创建 SQLite 实现**

```swift
// Sources/Infrastructure/Storage/Repositories/SQLiteImportRecordRepository.swift
import Foundation
import GRDB

final class SQLiteImportRecordRepository: ImportRecordRepository, @unchecked Sendable {
    private var dbWriter: any DatabaseWriter {
        get async {
            await MainActor.run {
                if let writer = DatabaseManager.shared.dbWriter { return writer }
                do { return try DatabaseQueue() } catch { fatalError("SQLiteImportRecordRepository: \(error)") }
            }
        }
    }

    init(dbWriter: any DatabaseWriter) {}

    func save(_ record: ImportRecord) async throws {
        let writer = await dbWriter
        try await writer.write { db in
            var r = record
            try r.save(db)
        }
    }

    func fetchAll(category: String?, limit: Int) async throws -> [ImportRecord] {
        let writer = await dbWriter
        return try await writer.read { db in
            var request = ImportRecord.order(ImportRecord.Columns.createdAt.desc)
            if let cat = category { request = request.filter(ImportRecord.Columns.category == cat) }
            return try request.limit(limit).fetchAll(db)
        }
    }

    func fetchByID(_ id: String) async throws -> ImportRecord? {
        let writer = await dbWriter
        return try await writer.read { db in try ImportRecord.fetchOne(db, key: id) }
    }

    func updateStatus(id: String, status: String, completedAt: Date?) async throws {
        let writer = await dbWriter
        try await writer.write { db in
            try db.execute(sql: "UPDATE import_records SET status = ?, completed_at = ? WHERE id = ?",
                arguments: [status, completedAt, id])
        }
    }

    func delete(_ id: String) async throws {
        let writer = await dbWriter
        try await writer.write { db in try ImportRecord.deleteOne(db, key: id) }
    }

    func fetchInProgress() async throws -> [ImportRecord] {
        let writer = await dbWriter
        return try await writer.read { db in
            try ImportRecord
                .filter(ImportRecord.Columns.status == "processing" || ImportRecord.Columns.status == "pending")
                .order(ImportRecord.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func totalStorageSize() async throws -> Int64 {
        let writer = await dbWriter
        let dbCount = try await writer.read { db in try ImportRecord.fetchCount(db) }
        var fileSize: Int64 = 0
        let records = try await fetchAll(category: nil, limit: 1000)
        for r in records {
            if let path = r.filePath, let size = r.fileSize { fileSize += size }
            if let text = r.rawText { fileSize += Int64(text.utf8.count) }
        }
        return fileSize
    }
}
```

- [ ] **Step 3: DI 注册**

在 `StorageModuleRegistrar` 中（第 90 行附近）添加：

```swift
let importRecordRepo = SQLiteImportRecordRepository(dbWriter: writer)
container.register(importRecordRepo as any ImportRecordRepository, for: (any ImportRecordRepository).self)
```

- [ ] **Step 4: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Sources/Domain/Protocols/ImportRecordRepository.swift Sources/Infrastructure/Storage/Repositories/SQLiteImportRecordRepository.swift Sources/App/Core/ModuleRegistrar.swift
git commit -m "feat: ImportRecordRepository 协议 + SQLite 实现 + DI 注册"
```

---

### Task 4: IngestCoordinator 集成 ImportRecord

**Files:**
- Modify: `Sources/Features/Knowledge/Ingest/Coordinator/IngestCoordinator.swift`

- [ ] **Step 1: 注入 ImportRecordRepository**

在 IngestCoordinator 类中添加：

```swift
@ObservationIgnored @Inject var importRecordRepo: any ImportRecordRepository
```

- [ ] **Step 2: 在 performIngest 中创建 ImportRecord**

修改 `performIngest()`，在调用 `ingestStore.performIngest()` 前后添加 ImportRecord 操作：

```swift
func performIngest() {
    isIngesting = true
    let title = newTitle, content = newContent, type = newType, icon = newCustomIcon, smart = useSmartIngest
    let recordID = UUID().uuidString
    let category = newURL.isEmpty ? ImportCategory.manual.rawValue : ImportCategory.link.rawValue

    // 创建导入记录
    let record = ImportRecord(
        id: recordID,
        category: category,
        title: title,
        status: "processing",
        rawText: content,
        sourceURL: newURL.isEmpty ? nil : newURL,
        vaultID: VaultService.shared.selectedVaultID?.uuidString,
        createdAt: Date()
    )
    Task { try? await importRecordRepo.save(record) }

    Task {
        do {
            let page = try await ingestStore.performIngest(
                title: title, content: content, type: type,
                tags: [], customIcon: icon, useSmart: smart, useDeepScan: true
            )
            // 更新记录为完成
            try? await importRecordRepo.updateStatus(
                id: recordID, status: "done", completedAt: Date()
            )
            // ... rest of existing code
        } catch {
            try? await importRecordRepo.updateStatus(
                id: recordID, status: "failed", completedAt: Date()
            )
            // ... existing error handling
        }
    }
}
```

- [ ] **Step 3: 同样处理 URL 导入**

在 `handleURLImport()` 中添加 ImportRecord 创建：

```swift
func handleURLImport() {
    let url = newURL
    let recordID = UUID().uuidString
    let record = ImportRecord(
        id: recordID,
        category: ImportCategory.link.rawValue,
        title: url,
        status: "processing",
        sourceURL: url,
        vaultID: VaultService.shared.selectedVaultID?.uuidString,
        createdAt: Date()
    )
    Task { try? await importRecordRepo.save(record) }
    // ... existing URL import logic, update status on completion
}
```

- [ ] **Step 4: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Sources/Features/Knowledge/Ingest/Coordinator/IngestCoordinator.swift
git commit -m "feat: IngestCoordinator 集成 ImportRecord 创建/更新"
```

---

### Task 5: 导入记录卡片 UI

**Files:**
- Create: `Sources/Features/Knowledge/Ingest/View/Components/ImportRecordCard.swift`

- [ ] **Step 1: 创建卡片组件**

```swift
// Sources/Features/Knowledge/Ingest/View/Components/ImportRecordCard.swift
import SwiftUI

struct ImportRecordCard: View {
    let record: ImportRecord

    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(record.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                detailLine
                timeLine
            }
            Spacer()
            statusBadge
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
    }

    private var detailLine: some View {
        HStack(spacing: DesignSystem.tightPadding) {
            switch ImportCategory(rawValue: record.category) {
            case .file:
                Label(record.fileSize.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "", systemImage: "doc")
            case .link:
                Label(record.sourceURL.flatMap { URL(string: $0)?.host } ?? "", systemImage: "link")
            case .voice:
                Label("", systemImage: "waveform")
            default:
                EmptyView()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var timeLine: some View {
        HStack(spacing: DesignSystem.small) {
            Label(record.createdAt.formatted(date: .numeric, time: .shortened), systemImage: "clock")
                .font(.caption2)
            if let done = record.completedAt {
                Label(done.formatted(date: .numeric, time: .shortened), systemImage: "flag.checkered")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.tertiary)
    }

    private var statusBadge: some View {
        Group {
            switch record.status {
            case "done":
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case "failed":
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            case "processing", "pending":
                ProgressView().scaleEffect(0.8)
            default:
                EmptyView()
            }
        }
    }

    private var categoryIcon: String {
        switch ImportCategory(rawValue: record.category) {
        case .link: return "link"
        case .file: return "doc.fill"
        case .manual: return "pencil.line"
        case .ocr: return "camera.fill"
        case .clipboard: return "list.clipboard"
        case .voice: return "waveform"
        case nil: return "questionmark"
        }
    }

    private var categoryColor: Color {
        switch ImportCategory(rawValue: record.category) {
        case .link: return .blue
        case .file: return .orange
        case .manual: return .green
        case .ocr: return .purple
        case .clipboard: return .gray
        case .voice: return .pink
        case nil: return .secondary
        }
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Sources/Features/Knowledge/Ingest/View/Components/ImportRecordCard.swift
git commit -m "feat: ImportRecordCard 卡片组件"
```

---

### Task 6: 导入原始内容区域（分段 Tab + 卡片列表）

**Files:**
- Create: `Sources/Features/Knowledge/Ingest/View/Components/ImportRecordSection.swift`
- Modify: `Sources/Features/Knowledge/Ingest/View/IngestView.swift:30-37`
- Modify: `Sources/Localization/Extensions/L10n+Ingest.swift`

- [ ] **Step 1: 添加 L10n 键值**

```swift
// L10n+Ingest.swift 的 Ingest 枚举中添加：
public static var importRecords: String { tr("ingest.importRecords") }
public static var importAll: String { tr("ingest.importAll") }
```

- [ ] **Step 2: 创建 ImportRecordSection**

```swift
// Sources/Features/Knowledge/Ingest/View/Components/ImportRecordSection.swift
import SwiftUI

struct ImportRecordSection: View {
    @State private var selectedCategory: String = "all"
    @State private var records: [ImportRecord] = []
    @Environment(IngestStore.self) var ingestStore

    private let repo = ServiceContainer.shared.resolve((any ImportRecordRepository).self)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            // 标题
            Label(L10n.Ingest.importRecords, systemImage: "archivebox")
                .font(.headline)

            // 分段 Tab
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.small) {
                    categoryTab("all", L10n.Ingest.importAll)
                    ForEach(ImportCategory.allCases, id: \.rawValue) { cat in
                        categoryTab(cat.rawValue, cat.displayName)
                    }
                }
            }

            // 卡片列表
            if records.isEmpty {
                Text("暂无导入记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.large)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: DesignSystem.small) {
                    ForEach(records, id: \.id) { record in
                        ImportRecordCard(record: record)
                    }
                }
            }
        }
        .task { await loadRecords() }
        .onChange(of: selectedCategory) { _, _ in Task { await loadRecords() } }
    }

    private func categoryTab(_ key: String, _ label: String) -> some View {
        Button(action: { selectedCategory = key }) {
            Text(label)
                .font(.caption.weight(selectedCategory == key ? .semibold : .regular))
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.tightPadding)
                .background(selectedCategory == key ? Capsule().fill(Color.appAccent) : Capsule().fill(Color.appCard))
                .foregroundStyle(selectedCategory == key ? .white : .secondary)
        }
    }

    private func loadRecords() async {
        let cat: String? = selectedCategory == "all" ? nil : selectedCategory
        records = (try? await repo.fetchAll(category: cat, limit: 50)) ?? []
    }
}
```

- [ ] **Step 3: IngestView 中集成 ImportRecordSection**

在 IngestView 的 ScrollView 中，`importSourcesSection` 之后添加：

```swift
ImportRecordSection()
    .padding(.top, DesignSystem.small)
```

- [ ] **Step 4: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Sources/Features/Knowledge/Ingest/View/Components/ImportRecordSection.swift Sources/Features/Knowledge/Ingest/View/IngestView.swift Sources/Localization/Extensions/L10n+Ingest.swift
git commit -m "feat: ImportRecordSection 分段 Tab + 卡片列表"
```

---

### Task 7: 存储统计增强

**Files:**
- Modify: `Sources/Features/System/Settings/Coordinator/SystemStatsCoordinator.swift:100-135`

- [ ] **Step 1: 在 SystemStatsCoordinator 中注入 ImportRecordRepository**

```swift
@ObservationIgnored @Inject private var importRecordRepo: any ImportRecordRepository
```

- [ ] **Step 2: 增强 storageCategories**

在 `loadStorageStats()` 的 categories 数组中，替换原有的 `storageImport` 条目为：

```swift
StorageCategory(
    label: L10n.Dashboard.stats.storageImport,
    value: (try? await importRecordRepo.totalStorageSize()) ?? 0,
    count: (try? await importRecordRepo.fetchAll(category: nil, limit: 1000).count) ?? 0,
    color: .green
),
```

同时保留知识页内容条目但改名为 `storageKnowledge`。

- [ ] **Step 3: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep "BUILD" | tail -1`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Sources/Features/System/Settings/Coordinator/SystemStatsCoordinator.swift
git commit -m "feat: 存储统计增加导入原始内容占用"
```

---

### Task 8: 单元测试

**Files:**
- Create: `Tests/Unit/Storage/ImportRecordRepositoryTests.swift`

- [ ] **Step 1: 创建测试**

```swift
// Tests/Unit/Storage/ImportRecordRepositoryTests.swift
import XCTest
import GRDB
@testable import ZhiYu

@MainActor
final class ImportRecordRepositoryTests: XCTestCase {
    private var dbQueue: DatabaseQueue!
    private var repo: SQLiteImportRecordRepository!

    override func setUp() async throws {
        try await super.setUp()
        dbQueue = try DatabaseQueue()
        repo = SQLiteImportRecordRepository(dbWriter: dbQueue)
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v7") { db in
            try db.create(table: "import_records") { t in
                t.column("id", .text).primaryKey()
                t.column("category", .text).notNull()
                t.column("title", .text).notNull()
                t.column("status", .text).notNull().defaults(to: "pending")
                t.column("raw_text", .text)
                t.column("source_url", .text)
                t.column("file_path", .text)
                t.column("file_size", .integer)
                t.column("page_id", .text)
                t.column("vault_id", .text)
                t.column("task_id", .text)
                t.column("created_at", .datetime).notNull()
                t.column("completed_at", .datetime)
            }
        }
        try migrator.migrate(dbQueue)
    }

    func testSaveAndFetch() async throws {
        let record = ImportRecord(category: "link", title: "Test", sourceURL: "https://example.com")
        try await repo.save(record)
        let all = try await repo.fetchAll(category: nil, limit: 10)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].title, "Test")
    }

    func testFetchByCategory() async throws {
        try await repo.save(ImportRecord(category: "link", title: "Link1"))
        try await repo.save(ImportRecord(category: "file", title: "File1"))
        let links = try await repo.fetchAll(category: "link", limit: 10)
        XCTAssertEqual(links.count, 1)
    }

    func testUpdateStatus() async throws {
        let record = ImportRecord(category: "manual", title: "M", status: "processing")
        try await repo.save(record)
        try await repo.updateStatus(id: record.id, status: "done", completedAt: Date())
        let fetched = try await repo.fetchByID(record.id)
        XCTAssertEqual(fetched?.status, "done")
        XCTAssertNotNil(fetched?.completedAt)
    }

    func testFetchInProgress() async throws {
        try await repo.save(ImportRecord(category: "link", title: "P", status: "processing"))
        try await repo.save(ImportRecord(category: "link", title: "D", status: "done"))
        let inProgress = try await repo.fetchInProgress()
        XCTAssertEqual(inProgress.count, 1)
    }
}
```

- [ ] **Step 2: 运行测试**

Run: `xcodegen generate && xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/DerivedData-test -clonedSourcePackagesDirPath ~/.cache/zhiyu-spm CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -only-testing:ZhiYuTests/ImportRecordRepositoryTests`
Expected: 4 tests passed

- [ ] **Step 3: Commit**

```bash
git add Tests/Unit/Storage/ImportRecordRepositoryTests.swift
git commit -m "test: ImportRecordRepository 单元测试 4 用例"
```

---

### Task 9: 全量测试 + 三平台编译

- [ ] **Step 1: 三平台编译**

```bash
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

- [ ] **Step 2: 全量测试**

```bash
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -only-testing:ZhiYuTests/ImportRecordRepositoryTests
```

- [ ] **Step 3: Commit & Push**

```bash
git commit --allow-empty -m "ci: 验证三平台编译 + 全量测试"
git push gitea main
```

---

### 自检

1. **ImportCategory.displayName** — Task 6 中 ImportRecordSection 使用了 `cat.displayName`，需要在 Task 1 的 ImportCategory 枚举中添加：

```swift
public var displayName: String {
    switch self {
    case .link: return "链接"
    case .file: return "文件"
    case .manual: return "手工"
    case .ocr: return "OCR"
    case .clipboard: return "剪贴板"
    case .voice: return "语音"
    }
}
```

在 Task 6 的 step 1 补充这个 L10n。

2. **L10n 完整覆盖** — Task 6 需要完整的 xcstrings 条目，包括 `ingest.importRecords` 和分类名称。

3. **IngestView 中的 ImportRecordSection 环境传递** — IngestView 已有 `@Environment(IngestStore.self)`，Section 内部使用即可。
