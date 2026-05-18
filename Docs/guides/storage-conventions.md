# 智宇 (ZhiYu) - 数据库存取与多库隔离规范指南 (storage-conventions.md)

本指南旨在规范“智宇”项目在 L1（持久化基础设施层）、L1.5（领域仓储契约层）以及 L2/L3 业务层中的数据库存取机制，确立开发约定，完全杜绝 SQL 硬编码，并确保物理多库（Multi-Vault）隔离的高内聚与高健壮性。

---

## 1. 核心架构：双路数据库（Double-Pool）设计

“智宇”采用**双路数据库并发挂载**架构，严格区分“系统级全局数据”与“笔记本级私有数据”，物理文件存放在不同的沙盒路径下。

### 1.1 全局数据库 (`global.sqlite3`)
* **物理路径**：`Application Support/ZhiYu/global.sqlite3`
* **职责范畴**：
  * `global_vaults`: 所有笔记本的元数据卡片列表（ID、名称、沙盒绝对路径、图标、时间戳等）。
  * `file_signatures`: 物理文件 HMAC 防篡改签名指纹，用于安全完整性审计。
  * `global_settings`: 跨笔记本的全局通用参数设置。
  * `audit_logs`: 全局安全审计日志。
* **生命周期**：随应用冷启动初始化并挂载，直至应用进程销毁，期间连接池始终驻留。

### 1.2 专属笔记本数据库 (`vault.sqlite3`)
* **物理路径**：`Application Support/ZhiYu/Vaults/{Vault_UUID}/vault.sqlite3`
* **职责范畴**：
  * `pages`: 页面实体，包含标题、内容、私密标记、各类时间戳等核心知识。
  * `page_links`: 页面间双向链接及图谱结构（Graph）。
  * `page_tags` / `tags`: 知识标签多对多关系。
  * `page_chunks`: 面向 RAG (检索增强生成) 的语义分块数据。
  * `page_embeddings`: 知识页面与语义分块的本地/远程向量向量映射。
  * `srs_metadata`: SRS 间隔重复记忆算法元数据。
* **生命周期**：**热插拔（Hot-Switchable）**。当用户在 UI 侧切换不同的笔记本时，底层旧库连接池会被优雅销毁（释放文件锁），重新创建连接池挂载新选中的笔记本库，实现 100% 物理隔离。

---

## 2. 仓储模式与依赖倒置（DIP）规范

为了确保“领域层纯净化”与“Cleancode 解耦”，全工程严禁业务层（Features）直接依赖、调用底层的 SQLite 连接池或 GRDB 具体类。

### 2.1 依赖倒置四部曲约定
1. **定义能力契约**：在 `Domain/Protocols/`（L1.5 领域层）中声明纯 Swift 协议（如 `VaultRepository`、`FileSignatureRepository`、`KnowledgeRepository`），协议必须满足 Swift 6 并发安全（`Sendable`）。
2. **实现持久化**：在 `Infrastructure/Storage/Repositories/`（L1 基础设施层）中实现上述协议，负责 GRDB 的具体读写与事务逻辑。
3. **DI 注入绑定**：在 `StorageModuleRegistrar.swift` 中将协议与实现进行依赖绑定注册。
4. **业务层注入**：在业务服务层（如 `VaultService`、`SecurityManager`）通过 `@Inject` 包装器引入对应的抽象协议：
   ```swift
   @ObservationIgnored
   @Inject private var vaultRepository: any VaultRepository
   ```

### 2.2 宏冲突变通方案
在遵循 `@Observable` 的服务类中，如果使用 Property Wrapper（如 `@Inject`）进行依赖注入，由于 Swift 宏自动合成机制的限制，会导致属性包装器与 Observation 自动合成的底层存储冲突，产生编译错误。
* **强制约束**：必须在此类注入属性上显式添加 **`@ObservationIgnored`**，指示宏避开对该注入服务的属性改写。

---

## 3. GRDB 最佳实践：禁止手写 SQL 细则

除了数据库初始化 DDL 与数据迁移脚本（Trigger 等）外，**全工程禁止手写原始 DML SQL 语句（如 "SELECT", "INSERT", "UPDATE", "DELETE" 等纯文本拼装）**。必须全面使用 GRDB 提供的类型安全 **Query Interface**。

### 3.1 实体模型定义规范
所有对应数据库表的结构体（Record），必须遵循 GRDB 的 Record 系列协议（如 `Codable`, `FetchableRecord`, `MutablePersistableRecord`, `TableRecord`），并明确定义 CodingKeys 枚举：
```swift
struct VaultRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "global_vaults"
    
    var id: String
    var name: String
    var path: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey, ColumnExpression {
        case id
        case name
        case path
        case createdAt = "created_at" // 映射蛇形命名
    }
}
```

### 3.2 强类型 CRUD 示例

#### 🟢 正确的类型安全查询 (Query Interface)
```swift
// 1. 根据主键/唯一标识查询
let record = try VaultRecord.fetchOne(db, key: id.uuidString)

// 2. 复杂过滤与排序
let records = try VaultRecord
    .filter(Column("created_at") >= dateThreshold)
    .order(Column("last_accessed_at").desc)
    .fetchAll(db)

// 3. 多表级联或子查询
let pages = KnowledgePage.select(KnowledgePage.Columns.id)
let deletedCount = try PageChunk
    .filter(!pages.contains(PageChunk.Columns.pageID))
    .deleteAll(db)
```

#### 🔴 错误的硬写 SQL 查询 (禁止使用)
```swift
// ❌ 严禁使用手写 SQL 字符串拼装进行增删改查
let records = try Row.fetchAll(db, sql: "SELECT * FROM global_vaults WHERE created_at >= ? ORDER BY last_accessed_at DESC", arguments: [dateThreshold])
```

### 3.3 SQLite 内置函数特殊场景
如果确实需要使用 SQLite 的复杂内置函数（如日期转换、聚合等），允许在 Query Interface 中配合 `SQL` 结构体进行局部表达式拼装，但仍需避免直接手写整句 `SELECT`：
```swift
// 🟢 允许的 SQLite 聚合格式化片段写法
let dayExpr = SQL("strftime('%Y-%m-%d', \(TokenUsage.Columns.createdAt))")
let request = TokenUsage
    .select(dayExpr.forKey("day"), sum(TokenUsage.Columns.totalTokens).forKey("tokens"))
    .group(dayExpr)
```

---

## 4. 多笔记本隔离（WAL）热插拔约定

由于智宇 (ZhiYu) 支持多笔记本沙盒物理隔离，我们在切换笔记本时必须保障底层的并发安全性与锁隔离度。

### 4.1 优雅切换三步走
1. **释放旧锁**：每次切换前，必须显式调用旧 `dbWriter` 的关闭销毁逻辑，断开所有长连接，释放底层 SQLite 的物理文件锁。
2. **挂载新连接**：使用新 UUID 计算对应的专属沙盒路径，并在 `WAL (Write-Ahead Logging)` 并发安全写入模式下初始化新的 `DatabasePool` 连接池。
3. **重置上层内存状态**：热插拔挂载成功后，**必须物理触发广播 `.databaseDidSwitch` 全局通知**。
   * AI 向量服务（`EmbeddingManager`）在监听到通知后，必须**瞬间清除**当前的向量内存缓存，并异步重载当前新笔记本专属库的向量索引，杜绝多库内存交叉污染。
   * 应用状态层（`AppStore`）在监听到通知后，必须**清空当前内存中的 Pages 实体缓存**，并触发 `refresh()` 从新库中拉取最新页面向 UI 层发布重绘广播。

---

## 5. 安全防护：数据存储级加固 (Encryption)

为了保护用户隐私，在特定的私密笔记本/页面中，我们必须强制在物理持久化层进行拦截加密。
* **加密编排**：由 Repository 层的 `upsert` / `save` 接口统一进行物理加密。在数据即将写入 SQLite 物理磁盘前，拦截需要加密的字段（如 `content`，`rawTextSnippet`），调用 `SecurityManager.shared.encrypt(_:)` 执行高强度的本地 AES-GCM 加密后，再落盘。
* **解密编排**：由 Repository 的 `fetchAll` / `fetch(id:)` 统一在返回给业务层前，调用解密逻辑：
  ```swift
  private func decryptIfPrivate(_ page: KnowledgePage) -> KnowledgePage {
      guard page.isPrivate else { return page }
      var p = page
      p.content = (try? SecurityManager.shared.decrypt(p.content)) ?? ""
      return p
  }
  ```
* **架构增益**：将加密和解密无感地切片在 L1 持久化基础设施层（Repository 实现内部），使上层 UI 和 RAG 检索在逻辑编写时完全无感，维持了极佳的 Clean Architecture 关注点分离（SoC）。
