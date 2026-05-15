# 智宇 (ZhiYu) 详细设计文档 (Detailed Design)

本文件深入解析 智宇 (ZhiYu) 核心引擎的内部实现细节。

## 1. 混合检索引擎 (Hybrid Search Engine)

### 1.1 数据流向与 RAG 模块化管道 (Modular Ingest Pipeline)
智宇 (ZhiYu) 实现了端到端的 RAG 摄入管道，通过 `KnowledgeIngestPipeline` 编排以下核心阶段：
1. **语义增强 (AIContentEnricher)**: 自动识别并转义 Markdown 中的图表、公式为文本描述。
2. **递归分块 (TextChunkerProcessor)**: 层级感知切分。
3. **向量索引 (VectorIndexer)**: 解耦的向量计算与存储同步。

系统采用 **倒数排名融合 (Reciprocal Rank Fusion, RRF)** 算法来消除不同搜索引擎（FTS5 与 Vector）结果量纲不统一的问题。

**数学定义**:
对于召回结果集中的任意文档 $d$，其最终评分 $Score(d)$ 计算如下：
$$Score(d) = \sum_{r \in R} \frac{1}{k + r(d)}$$
其中：
- $R$: 检索源集合（此处为 $\{FTS, Vector\}$）。
- $r(d)$: 文档 $d$ 在该检索源中的排名索引（1-indexed）。
- $k$: 平滑常数，系统默认取值为 **60**。该值能有效平衡关键词的精确性与语义的模糊性。

### 1.3 AI 智能重排 (Rerank)
在 RRF 召回后，系统对 Top 10 候选文档执行 **AI Rerank**:
- **模型验证**: 调用 LLM 接口，根据查询词与候选文档的相关性进行二次打分。
- **排序修正**: 修正 RRF 在处理同义词或隐式关系时的排名偏差，大幅提升首位检索精度。

### 1.2 递归语义分块 (Recursive Chunking)
为了解决 RAG 中的“语义切断”问题，`TextChunkerProcessor` 实施了层级感知策略：
1. **优先级 1**: 查找标题分隔符 (`#`, `##`)，确保逻辑主题完整。
2. **优先级 2**: 查找段落分隔符 (`\n\n`)。
3. **窗口重叠**: 块大小固定为 $N$ (800 字符)，重叠窗口 $O = 150$ 字符（约 18.75%）。

## 2. 链接管理服务 (Link Service)

### 2.1 引用解析算法
*   **正则表达式**: `\[\[(.*?)\]\]`
*   **反向链接缓存**: 系统在内存中维护一个 `Map<PageID, [BacklinkID]>`。每当页面保存时，异步触发 `LinkRefresher` 更新该缓存，确保 UI 响应不阻塞。

## 3. 插件执行引擎 (Plugin Runtime)

### 3.1 拦截链 (Interceptor Chain)
插件执行遵循 **“管道模式 (Pipeline Pattern)”**。
*   **输入**: 原始 Markdown 字符串。
*   **变换**: `Reduce(plugins) { content, plugin in plugin.preProcess(content) }`
*   **异常隔离**: 使用 `do-catch` 包裹每个插件的执行，单个插件崩溃会自动被熔断，不影响主链路存储。

## 4. API 版本化路由 (Version Routing)

为了确保插件生态的长效兼容性，智宇 (ZhiYu) 实施 **“双重版本控制”**：
1. **内核版本 (Host Version)**: 随 App 更新。
2. **能力版本 (Feature API Version)**: 独立于内核演进。
   * **路由策略**: 当内核升级至 2.0 且重构了拦截接口时，系统会维护一个 `v1_Adapter`。它将 1.0 插件的调用桥接到 2.0 实现上，确保旧插件无需重写即可运行。

## 5. 多设备冲突解铃 (Distributed LWW)

系统采用 **兰伯特时间戳 (Lamport Timestamps)** 实现分布式最终一致性：
*   **物理层逻辑**:
    ```swift
    final_version = (remote.lamport > local.lamport) ? remote : local
    ```
*   **物理模式**: 每次页面更新，`lamportTimestamp` 自动递增。在同步冲突时，通过 `WikiPage.merge(with:)` 算法自动收敛数据，避免产生重复文件或内容丢失。

## 6. 向量库同步一致性协议 (Vector DB Consistency Protocol)

为了确保核心 SQLite 数据与向量索引（Vector Index）之间的最终一致性，系统实施了以下协议：

### 6.1 事务边界与触发机制
*   **WAL (Write-Ahead Logging)**: 数据库启用 WAL 模式，确保读写不冲突。
*   **同步钩子 (Sync Hook)**: 在 `SQLiteStore` 的 `savePage` 事务提交成功后，触发 `EmbeddingManager.updateEmbedding(for:)`。
*   **ID 对齐策略**: 向量库主键必须与 SQLite 记录的 `UUID` 严格一致。

### 6.2 脏数据修复 (Reconciliation)
*   **全量核对**: App 启动时执行 `CheckConsistencyTask`。
    1. 提取 SQLite 中所有已更新但 `vector_version < page.updated_at` 的 ID。
    2. 将缺失向量的页面压入 `SyncQueue` 重新计算。
*   **重试机制**: 若向量化（NLEmbedding 调用）失败，系统会在 `last_error_log` 记录失败次数，并在 5 分钟后进行指数退避重试。

---

## 7. 数据库 Schema 设计 (Database Schema)

系统的底层存储设计已独立维护，详细描述了从 V1 到 V6 的演进过程、表结构、索引策略及迁移日志。

详见：[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)


# 附录：专题设计补充

## A. iCloud 同步编排 (Sync Coordinator)

为消除 View 层直接编排 iCloud 业务逻辑的问题，引入 `iCloudSyncCoordinator`：

### 设计模式：View → Coordinator → Service

```
iCloudSyncView (L3, 瘦 View)
  └─ @Bindable var coordinator: iCloudSyncCoordinator
       └─ (L3-ViewModel) 管理 UI 状态(10个属性)、Timer、冲突解决
            └─ iCloudSyncService (L1) 执行实际同步 IO
```

- `iCloudSyncView` 从 290 行精简到 128 行，仅保留 UI 布局
- `iCloudSyncCoordinator` 是 `@Observable` class，180 行，在 `@MainActor` 上运行
- 所有同步编排逻辑（push、pull、bidirectional、autoSync）集中在 Coordinator 中
- **下一步**：ChatView、IngestView、PDFReaderView 等大型 View 应逐步采用同样模式

## B. 已知架构缺陷与修复路线图 (2026-05)

来自全工程深度审计：

| 优先级 | 问题 | 目标文件 | 方案 | 状态 |
|--------|------|---------|------|------|
| P0 | PluginRegistry 重复属性声明 | PluginRegistry.swift | 删除重复行 | **已修复** |
| P0 | LogService 递归崩溃 | LogService.swift | 修复 extension 递归调用或重构 | **已修复** |
| P0 | 核心逻辑平台宏污染 | 多文件 | 引入平台能力协议 (DI) | **已修复** |
| P0 | API Key 明文存储 | LLMModels.swift | 迁移至 Keychain (支持分提供商独立存储) | **已修复** |
| P0 | SecurityManager 硬编码 salt | SecurityManager.swift | 迁移至 Keychain 动态生成与存储 | **已修复** |
| P0 | DataExportService fatalError | DataExportService.swift | 已改为抛出 DataExportError | **已修复** |
| P1 | LLMService 上帝类 (精简至332行) | LLMService.swift | 拆分为 Chat/Ingest/Refactor | **已修复** |
| P1 | AIWorkflowStore (精简至355行) | AIWorkflowStore.swift | 按合成/扫描/洞察/建议拆分 | **已修复** |
| P1 | 两套 LLM 协议并存 | LLMService | 清理旧版协议实现 | **已修复** |
| P2 | parseJSONArray 重复实现 | 多文件 | 提取至 LLMUtils 工具类 | **已修复** |

---

## 8. 图谱布局引擎 (Graph Layout Engine)

### 8.1 2D 力导向算法优化 (Force-Directed Layout)
为了解决节点重叠与布局拥挤，系统在 `GraphLayoutProcessor` 中实施了以下物理改进：
- **碰撞避免 (Collision Avoidance)**: 引入了基于距离的非线性斥力。当节点间距小于 20 像素时，斥力系数呈指数级增长，形成“硬碰撞”效果。
- **动态斥力感应范围**: 感应范围从 120 像素提升至 200 像素，确保高密度节点群能更均匀地分散。
- **自适应阻尼**: 引入 `damping` 系数随迭代次数衰减，加速布局收敛并减少后期震荡。

### 8.2 3D 空间分布策略 (3D Spatial Distribution)
针对 3D 图谱，采用 **Fibonacci Sphere (斐波那契球)** 分布算法：
- **动态半径**: 球体半径 $R = \max(40, \min(150, \sqrt{N} \times 12))$。该公式确保节点间的平均弧长在不同节点规模 ($N$) 下保持视觉舒适。
- **层级深度**: 选中节点及其一阶邻居会通过 `SCNTransaction` 进行平滑的“向前推移”，利用 Z 轴深度突出展示上下文。
