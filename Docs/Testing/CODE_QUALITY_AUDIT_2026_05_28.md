# 智宇 (ZhiYu) 代码质量深度审计报告

> **审计日期**: 2026-05-28
> **代码规模**: 457 文件 / 64,124 行 Swift 源码
> **审计范围**: 全层级 (L0-L3 + Shared + Platforms)

---

## 一、总体评分

| 维度 | 评分 | 趋势 | 核心结论 |
|:---|:---:|:---:|:---|
| **架构分层** | 6.5/10 | → | 分层拓扑设计优秀，但依赖方向合规性仅 4/10：ShortcutManager 跨三层反代、Domain→Features 违规、Infrastructure→Features 违规、Features 系统性依赖 AppStore |
| **代码整洁** | 7.0/10 | ↑ | 中文注释覆盖 100%，但 103 处硬编码 SF Symbol、30+ 处 UserDefaults 魔法 Key、超大文件需拆分 |
| **多端解耦** | 6.5/10 | ↑ | Platforms 适配层架构正确，但 Features 层散布 49 处 `#if os()` 宏，Core 层残留 4 处 |
| **SOLID/KISS** | 7.0/10 | → | DI 模式成熟，但 AppStore 仍为上帝 Facade、DesignSystem.swift 878 行严重违反 SRP |
| **废弃代码** | 8.5/10 | ↑ | 零 TODO/FIXME 标记，P0 全部修复，仅少量死代码残留 |

**综合评分: 6.8/10** — 成熟稳定期项目，但依赖方向合规性严重不足（4/10），需在架构穿透、宏治理、魔法值三个方向集中攻坚。

---

## 二、架构违规 (Critical)

### 2.1 反向依赖 — L0.5 → L3 / L2

| 文件 | 违规 | 严重度 |
|:---|:---|:---:|
| `Core/System/Shortcuts/ShortcutManager.swift:91-92` | `resolve(AppStore.self)` + `resolve(Router.self)` — L0.5 直接引用 L3 类型 | 🔴 |
| `Core/System/Shortcuts/ShortcutManager.swift:54,115` | 直接引用 `KnowledgeStore`(L2) — L0.5 跨三层跳至 L2 | 🔴 |

**修复方案**: 将 ShortcutManager 物理迁移至 `App/` 层，或通过协议注入 L0 定义的 `ShortcutActionProtocol`。

### 2.2 Domain 层对 GRDB 的硬耦合 — L1.5 → L1

| 文件 | 违规 |
|:---|:---|
| `Domain/Models/KnowledgePage.swift` | `import GRDB` + `FetchableRecord, PersistableRecord` |
| `Domain/Models/PageLink.swift` | `import GRDB` |
| `Domain/Models/PageType.swift` | `import GRDB` |
| `Domain/Models/RAGModels.swift` | `import GRDB` |
| `Domain/Models/KnowledgePageFTS.swift` | `import GRDB` |

**修复方案**: Domain 模型剥离 GRDB 协议，在 Infrastructure/Storage 层用 Extension 遵循 `FetchableRecord`/`PersistableRecord`。

### 2.3 Domain 层直接引用 L1 具体类 + L2 类型 — L1.5 → L1 / L2

| 文件 | 违规 |
|:---|:---|
| `Domain/RAG/KnowledgeIngestPipeline.swift:30` | 参数类型 `EmbeddingManager` (L1 具体类) |
| `Domain/RAG/LinkService.swift:106` | 参数类型 `EmbeddingManager` |
| `Domain/Knowledge/KnowledgePageManager.swift:152,160` | `PluginRegistry.shared.emitEvent` (L1 单例直接调用) |
| `Domain/Knowledge/KnowledgePageManager.swift:24` | 直接引用 `IngestService`(L2) — **反向依赖** |
| `Domain/RAG/RAGOrchestrator.swift:31-82` | 直接调用 `TaskCenter.shared`(L2) — **反向依赖** |

**修复方案**: 抽取 `EmbeddingProvider` 和 `PluginEventBus` 协议至 Domain/Protocols/；IngestService/TaskCenter 抽取协议至 Core/Protocols/，通过 DI 注入。

### 2.4 Infrastructure 层反向引用 — L1 → L2 / L3

| 文件 | 违规 | 严重度 |
|:---|:---|:---:|
| `Infrastructure/Plugins/PluginRegistry.swift:260,330` | 直接引用 `KnowledgeStore`(L2) | 🔴 |
| `Infrastructure/LLM/ChatRunner.swift:88-131` | 直接调用 `TaskCenter.shared`(L2) | 🔴 |
| `Infrastructure/Storage/Sync/iCloudSyncCoordinator.swift:21` | 持有 `AppStore?` 引用(L3) | 🔴 |

**修复方案**: KnowledgeStore/TaskCenter 的协议接口下沉至 Core/Protocols/；iCloudSyncCoordinator 通过 `SyncCoordinatorDelegate` 协议解耦 AppStore。

### 2.5 Features 层系统性依赖 AppStore — L2 → L3

| 类型 | 涉及文件数 | 说明 |
|:---|:---:|:---|
| `AppStore` 引用 | **30+** | 几乎所有 View/Coordinator 通过 `@Environment(AppStore.self)` 注入 |
| `Router` 引用 | 2 | `ChatView.swift:27`, `TaskCenterView.swift:20` |

**根因分析**: AppStore 是架构污染的根源——定义为 L3 (App) 层类型，但被 L2 (Features)、L1 (Infrastructure)、L0.5 (Core/System) 直接引用。AppStore 应当下沉核心接口至 Domain 层或通过协议解耦。

**修复方案**: 
1. 在 Core/Protocols/ 定义 `AppStoreProtocol`，AppStore 遵循协议
2. 各层通过 `@Inject var appStore: any AppStoreProtocol` 引用，消除直接类型依赖
3. Router 抽象接口 `RouterProtocol` 定义在 Core 层
4. 长期目标：Features 层 View 通过 ViewModel/Coordinator 间接访问 AppStore

### 2.6 Shared 层越界引用业务类型 — Shared → L2/L3

| 被引用类型 | 引用次数 | 代表文件 |
|:---|:---:|:---|
| `AppStore` | 7 | `LockOverlayView`, `MarkdownRendererView`, `EditorComponents`, `AdaptiveSidebarView`, `KeyboardShortcutsView`, `UserProfileMenu` |
| `Router` | 3 | `AdaptiveSidebarView`, `UserProfileMenu` |
| `VaultService` | 2 | `FloatingContextCapsule`, `VaultBadge` |
| `CollaborationService` | 1 | `HostingSetupSheet` |
| `TaskCenter` | 2 | `AIProcessingStatusBanner`, `MarkdownRendererView` |
| `SynthesisStore` | 1 | `SynthesisStore+UI.swift` (extension) |
| `KnowledgePage` | 10+ | `PageRowView`, `EditorComponents`, `BreadcrumbView` 等 |

**修复方案**: Shared 层组件改为泛型或通过协议注入（如 `@Environment(\.pageStore)`），消除对具体业务类型的直接依赖。

---

## 三、#if os() 宏散布分析

### 3.1 宏分布统计

| 位置 | `#if os()` 数量 | 合规性 |
|:---|:---:|:---|
| `Platforms/` | ~30 | ✅ 完全合规 |
| `App/ModuleRegistrar.swift` | 15 | ✅ 合规 (唯一合法 DI 路由) |
| `App/` (其余) | ~10 | ⚠️ 部分合规 (UI 层隔离) |
| `Features/` | **~40** | 🔴 大量违规 |
| `Shared/UIComponents/` | ~25 | ⚠️ 部分合理 (跨平台 UI 适配)，但部分嵌套过深 |
| `Core/` | **~6** | 🔴 严重违规 (Haptic/JailbreakDetector) |
| `Infrastructure/` | **~3** | ✅ 合理 (Plugin JavaScriptCore/PluginRegistry) |
| **总计** | **~130+** | — |

### 3.2 Core 层宏违规明细

| 文件 | 行号 | 宏 | 问题 |
|:---|:---:|:---|:---|
| `ShortcutManager.swift` | 11 | `#if os(iOS) \|\| os(macOS)` | 整个文件被宏包裹，应迁移至 Platforms/ |
| `JailbreakDetector.swift` | 77 | `#if os(iOS)` | 应通过协议抽象 |
| `iOSHapticService.swift` | 11 | `#if os(iOS)` | 已在 Platforms/ 有对应实现，此文件应迁移 |
| `MacHapticService.swift` | 11 | `#if os(macOS)` | 同上 |

### 3.3 Features 层宏违规 TOP 10

| 文件 | 宏数量 | 典型违规 |
|:---|:---:|:---|
| `LogView.swift` | 3 | `#if os(iOS)` 包裹 UIActivityViewController |
| `IngestViewComponents.swift` | 2 | `#if os(watchOS)` / `#if os(iOS)` |
| `PDFReaderView.swift` | 4 | PDF 功能平台差异 |
| `CollaborationView.swift` | 2 | `#if os(iOS)` 包裹 ShareLink |
| `SettingsView.swift` | 1 | `#if targetEnvironment(macCatalyst)` |
| `ConflictDiffView.swift` | 1 | `#if os(iOS)` 包裹文档交互 |
| `OnDeviceLLMSettingsView.swift` | 1 | `#if os(iOS)` |
| `PluginCenterView.swift` | 1 | `#if os(iOS)` |
| `PerformanceDashboardView.swift` | 1 | `#if os(iOS)` ActivityKit |
| `CreatePageView.swift` | 2 | `#if os(watchOS)` / `#if os(iOS)` |

**修复策略**: 按 swift-coding-style.md 的三原则（协议屏蔽 → DI 路由 → UI 隔离），将功能差异提炼为 `@ViewBuilder` 或独立平台适配器。

---

## 四、魔法值/硬编码

### 4.1 SF Symbol 硬编码

- **总计 103 处** `systemName:` 未走 `DesignSystem.Icons` 集中管理
- **重点散布**: Settings (15+), Dashboard (10+), Ingest (8+)

### 4.2 UserDefaults 非常量化 Key

- **30+ 处** `UserDefaults.standard` 直接使用非 `AppConstants.Keys.Storage` 的字符串 Key
- **重点散布**: LLM/ (8处), Security/ (5处), Insight/ (2处)

### 4.3 业务魔法数字

| 文件 | 行号 | 魔法值 | 建议常量 |
|:---|:---:|:---|:---|
| `LintService.swift` | 42 | `stalePageThresholdDays = 30` | ✅ 已常量化 |
| `LintService.swift` | 199-201 | `10/5/2` 扣分权重 | 需提取 `ScoringWeight` 枚举 |
| `LintService.swift` | 204 | `90/75/50` 健康等级阈值 | 需提取 `HealthThreshold` 常量集 |
| `ShortcutManager.swift` | 55 | `15` 标题截断长度 | 需提取 `Constants.maxSiriTitleLength` |
| `ShortcutManager.swift` | 62 | `["Siri", "QuickCapture"]` 硬编码标签 | 需提取至常量 |
| `AIContentEnricher.swift` | 143-177 | 中文 prompt 字符串硬编码 | 需迁移至 PromptRegistry |
| `KnowledgeIngestPipeline.swift` | 46 | `2000` 预览长度 | 需提取 `Constants.previewLength` |
| `KnowledgeIngestPipeline.swift` | 66,101 | `chunkSize: 1000/300, chunkOverlap: 200/50` | 需提取 `ChunkConfig` |
| `KnowledgeIngestPipeline.swift` | 49,100,123,145 | `"sum_", "p_", "qa_"` chunk ID 前缀 | 需提取 `ChunkIDFormat` 枚举 |
| `RAGEvaluationService.swift` | 53-59 | `0.5, 0.7` 评估阈值 | 需提取 `EvaluationThreshold` |
| `KnowledgePage.swift` | 215 | `100` stub 阈值 | 需提取常量 |
| `PluginRegistry.swift` | 56,59,63,64 | `"2.0.0"`, `0.5`, `50`, `60.0` 插件配置 | 需提取 `PluginDefaults` |
| `AppCloudSyncService.swift` | 91,172,342,446 | `"AppData"`, `"knowledge-management_main"` iCloud 常量 | 需提取 `iCloudConstants` |
| `AppCloudSyncService.swift` | 536 | `200` 日志保留阈值 | 需提取常量 |
| `OnDeviceLLMService.swift` | 58-73 | 6 个分散常量 (maxTokens, temperature 等) | 需集中为 `LLMDefaults` |
| `EmbeddingManager.swift` | 105-106,129,146 | `512` 维向量, `1000` 字符截断 | 需提取 `EmbeddingConfig` |
| `DatabaseManager.swift` | 232,306,317-322 | PRAGMA SQL 参数硬编码 | 需提取 `DatabaseConfig` |
| `BusinessConstants.swift` | 95 | 微信 AppId 和 UniversalLink 硬编码 | 需迁移至 Keychain/Info.plist |

### 4.4 print() 调试输出泛滥

| 文件 | print() 数量 | 说明 |
|:---|:---:|:---|
| `EmbeddingManager.swift` | 4+ | 应统一迁移至 Logger |
| `DatabaseManager.swift` | 16+ | 广泛使用 print() 调试输出 |
| `PerformanceBenchmarker.swift` | 9 | 应迁移至 Logger |
| `RAGEvaluationService.swift` | 1 | 应迁移至 Logger |

### 4.5 重复代码

| 模式 | 文件 1 | 文件 2 | 说明 |
|:---|:---|:---|:---|
| 标签正则 `#(\\w+)` | `KnowledgePage.swift:239-240` | `OnDeviceLLMService.swift:331` | 需提取为共享工具函数 |
| RRF 算法 | `LinkService.swift` | `EmbeddingManager.swift` | 需提取为独立算法 |

---

## 五、文件过大 / SRP 违规

### 5.1 超大文件清单 (>300行)

| 文件 | 行数 | 建议拆分 |
|:---|:---:|:---|
| **DesignSystem.swift** | **878** | 🔴 按 Spacing/Radius/Typography/Color/Animation 拆为 5+ 独立文件 |
| **IngestViewComponents.swift** | **660** | 🔴 按组件类型拆分 (IngestCard/SourcePicker/ImportProgress) |
| **DatabaseManager.swift** | **656** | ⚠️ 按职责拆分 (SchemaMigration/ConnectionPool/IntegrityCheck) |
| **LintView.swift** | **630** | ⚠️ 按子页面拆分 (HealthCheckView/AISuggestionView) |
| **SystemStatsView.swift** | **628** | ⚠️ 按统计域拆分 (StorageStats/ModelStats/AppStats) |
| **MarkdownProcessor.swift** | **627** | ⚠️ 按处理阶段拆分 (FrontMatterParser/BlockProcessor/InlineProcessor) |
| **SynthesisView.swift** | **626** | ⚠️ 按合成类型拆分 (SummaryView/OutlineView/QuizLaunchView) |
| **AppCloudSyncService.swift** | **568** | ⚠️ 按同步方向拆分 (PushService/PullService/ConflictResolver) |
| **GraphComponents.swift** | **592** | ⚠️ 按组件拆分 (NodeView/EdgeView/ToolbarView) |
| **AppStore.swift** | **537** | 🔴 仍过重，需按域拆分 PDF/OCR/DemoData 到对应 Feature Store |
| **Graph3DComponents.swift** | **549** | ⚠️ 按 3D 元素拆分 |
| **Graph3DView.swift** | **545** | ⚠️ 按交互模式拆分 |
| **SearchView.swift** | **504** | ⚠️ 按搜索模式拆分 |
| **KnowledgeDashboardView.swift** | **496** | ⚠️ 按面板区域拆分 |
| **MarkdownRendererView.swift** | **449** | ⚠️ 按渲染模式拆分 |
| **PluginRegistry.swift** | **453** | ⚠️ 按生命周期拆分 (RegistryCore/Watchdog/Sandbox) |
| **OnDeviceLLMService.swift** | **434** | ⚠️ 按能力拆分 (ModelManager/InferenceEngine/DownloadService) |
| **Spacing.swift** | **407** | ⚠️ 令牌定义过长，可按类别分组拆分 |
| **TagCloudView.swift** | **418** | ⚠️ 按子视图拆分 |
| **Logger.swift** | **387** | ⚠️ 按日志域拆分 (CoreLogger/PerformanceLogger/SecurityLogger) |
| **SettingsView.swift** | **385** | ⚠️ 按设置域拆分 |
| **PDFReaderView.swift** | **378** | ⚠️ 按功能拆分 |
| **EmbeddingManager.swift** | **376** | ⚠️ 按职责拆分 |
| **AppConstants.swift** | **342** | ⚠️ 已分类但总量大，可考虑拆为 Keys/Storage/Network 子文件 |

### 5.2 关键 SRP 违规

| 文件 | 违规 | 影响 |
|:---|:---|:---|
| `DesignSystem.swift` (878行) | 将 Spacing/Radius/Typography/Color/Animation/Metrics 全部塞入单个 enum | 修改任一令牌需重新编译整个 DesignSystem |
| `AppStore.swift` (537行) | 仍聚合 PDF 管理、OCR 提取、演示数据生成等跨域逻辑 | 违反 L3-Facade 原则，应仅做路由编排 |
| `KnowledgePageManager.swift` | 管理页面 CRUD + 处理器链 + 插件事件 + 撤销栈 | 职责过多，可拆分 PageCRUDService + ProcessorChain |

---

## 六、中文注释评估

| 维度 | 覆盖率 | 说明 |
|:---|:---:|:---|
| 文件头注释 | **100%** | 全部 457 文件含系统层级、核心职责描述 |
| 函数头 `///` | ~52% | 102 个公开函数缺失文档注释 (P1-11 遗留) |
| 关键流程注释 | ~85% | 核心管道 (RAG/Ingest/Sync) 有完整的步骤注释 |
| 枚举值注释 | ~90% | 大部分枚举有中文说明 |
| MARK 标签 | ~95% | 绝大多数文件使用 `// MARK: - 中文标题` |
| 注释格式一致性 | **75%** | 多处 `/// ///` 双注释格式（KnowledgeRepository、KnowledgePageManager、LinkService、PluginRegistry 等），需统一为标准 `/// - Parameter` 格式 |

### 6.1 注释格式问题明细

| 文件 | 问题 |
|:---|:---|
| `KnowledgeRepository.swift:22-47` | 多处参数使用双 `/// ///` 格式 |
| `SourceStore.swift:28-29` | 双注释格式 |
| `KnowledgePageManager.swift:85-248` | 6 处双注释 |
| `LinkService.swift:58-68, 207-235` | 双注释 + JavaScript DocStyle `/** */` 残留 |
| `PluginRegistry.swift:169-314` | 15+ 处双注释 |
| `OnDeviceLLMService.swift:370` | 双注释 |

### 6.2 层级标注不一致

| 文件 | 问题 |
|:---|:---|
| `RAGEvaluationService.swift:14` | 注释写 `[L2] 领域服务` 但文件头是 `[L1.5]` |
| `LinkService.swift:14` | 注释写 `[L1] 领域层` 但头文件是 `[L1.5]` |

---

## 七、依赖方向合规性评估 (4/10)

### 7.1 各层依赖合规评分

| 层级 | 评分 | 说明 |
|:---|:---:|:---|
| L0 (Core/Base) | **9/10** | 仅引用 Foundation/系统框架，无跨层引用，高内聚低耦合 |
| L0.5 (Core/System) | **3/10** | ShortcutManager 严重违规，直接依赖 App(L3) 和 Features(L2) |
| L1 (Infrastructure) | **5/10** | 大部分合规，但 PluginRegistry/ChatRunner 引用 Features 类型，iCloudSyncCoordinator 引用 AppStore |
| L1.5 (Domain) | **6/10** | KnowledgePageManager 引用 IngestService(L2)，RAGOrchestrator 调用 TaskCenter(L2) |
| L2 (Features) | **2/10** | 系统性依赖 AppStore/Router，30+ 文件直接注入 App 层类型 |
| Shared | **4/10** | 6 个 UI 组件文件直接依赖 Features 层的 VaultService、TaskCenter、CollaborationService |

### 7.2 跳层访问清单

| 跳层路径 | 严重度 | 说明 |
|:---|:---:|:---|
| L0.5 → L3 | 🔴 严重 | ShortcutManager 直接注入 AppStore、Router，跳过 L1/L1.5/L2 三层 |
| L0.5 → L2 | 🔴 严重 | ShortcutManager 直接注入 KnowledgeStore，跳过 L1/L1.5 |
| L1 → L3 | ⚠️ 中等 | iCloudSyncCoordinator 持有 AppStore 引用，跳过 L2 |
| L1 → L2 | ⚠️ 中等 | PluginRegistry、ChatRunner 直接使用 KnowledgeStore、TaskCenter |

### 7.3 架构污染根源分析

| 污染源 | 影响范围 | 根因 |
|:---|:---|:---|
| **AppStore** | L2(30+) → L1(1) → L0.5(1) | 定义在 L3 但被全层引用，应下沉核心接口至 Core 协议 |
| **Router** | L2(2) → L0.5(1) | 定义在 App 层但被 Core/Features 引用，应抽取 RouterProtocol 至 Core |
| **TaskCenter** | L1(1) → L1.5(1) | 被跨层调用 `.shared` 单例，应抽取 TaskCenterProtocol 至 Core |
| **ServiceContainer** | 全层 | 运行时 DI 容器无编译期层级边界检查 |

---

## 八、SOLID 违规详解

### 8.1 单一职责 (SRP) 违规
- `AppStore` 仍承载跨域业务逻辑
- `DesignSystem.swift` 878 行，承载全部设计令牌
- `KnowledgePageManager` 混合 CRUD + 处理器链 + 事件

### 8.2 开闭原则 (OCP) 违规
- `Router.updateSelection` 的大型 switch 语句，新增路由需修改现有代码
- `LintService` 的健康评分算法硬编码阈值，无法外部配置

### 8.3 里氏替换 (LSP)
- 无明显违规，协议抽象基本到位

### 8.4 接口隔离 (ISP)
- `AnyPageStoreCapabilities` 仍然偏大（包含 CRUD + 搜索 + 标签 + PDF），可按能力拆分

### 8.5 依赖倒置 (DIP) 违规
- Domain 模型直接 `import GRDB`（见 2.2）
- `ShortcutManager` 直接 resolve AppStore/Router（见 2.1）
- `KnowledgePageManager` 直接调用 `PluginRegistry.shared`（见 2.3）

---

## 九、分域问题清单

### 9.1 AI 域 (22文件, 4,797行)

| 问题 | 严重度 | 文件 |
|:---|:---:|:---|
| SynthesisView 626行过大 | ⚠️ | SynthesisView.swift |
| TaskCenterView 456行过大 | ⚠️ | TaskCenterView.swift |
| ChatView 332行接近阈值 | 🟡 | ChatView.swift |
| SynthesisStore 325行 | 🟡 | SynthesisStore.swift |

### 9.2 Insight 域 (27文件, 5,333行)

| 问题 | 严重度 | 文件 |
|:---|:---:|:---|
| LintView 630行过大 + 1处宏 | 🔴 | LintView.swift |
| TagCloudView 418行 + 2处宏 | ⚠️ | TagCloudView.swift |
| KnowledgeDashboardView 496行 | ⚠️ | KnowledgeDashboardView.swift |
| BacklinksView 2处宏 | ⚠️ | BacklinksView.swift |
| LogView 3处宏 | 🔴 | LogView.swift |
| LintService 魔法数字 | 🟡 | LintService.swift |

### 9.3 Knowledge 域 (48文件, 8,644行)

| 问题 | 严重度 | 文件 |
|:---|:---:|:---|
| IngestViewComponents 660行 | 🔴 | IngestViewComponents.swift |
| GraphComponents 592行 | ⚠️ | GraphComponents.swift |
| Graph3DComponents 549行 | ⚠️ | Graph3DComponents.swift |
| Graph3DView 545行 | ⚠️ | Graph3DView.swift |
| SearchView 504行 | ⚠️ | SearchView.swift |
| PDFReaderView 378行 + 4处宏 | ⚠️ | PDFReaderView.swift |
| VaultService 325行 | 🟡 | VaultService.swift |

### 9.4 System 域 (34文件, 6,958行)

| 问题 | 严重度 | 文件 |
|:---|:---:|:---|
| SystemStatsView 628行 | ⚠️ | SystemStatsView.swift |
| OnDeviceLLMSettingsView 393行 + 1处宏 | ⚠️ | OnDeviceLLMSettingsView.swift |
| SettingsView 385行 | ⚠️ | SettingsView.swift |
| ConflictDiffView 360行 + 1处宏 | ⚠️ | ConflictDiffView.swift |
| CollaborationView 353行 + 2处宏 | ⚠️ | CollaborationView.swift |
| DeveloperSettingsView 317行 + 1处宏 | 🟡 | DeveloperSettingsView.swift |
| CollaborationService 305行 + 2处模拟器宏 | 🟡 | CollaborationService.swift |

---

## 十、改进优先级 (P0-P2)

### P0: 架构红线 (必须修复)

| # | 问题 | 预估影响文件 |
|:---|:---|:---|
| **P0-1** | ShortcutManager 迁移至 App/ 或 Platforms/，消除 L0.5→L3/L2 反向依赖 | 1 |
| **P0-2** | Domain 模型剥离 GRDB，Extension 下沉至 Infrastructure | 5 |
| **P0-3** | KnowledgePageManager 的 EmbeddingManager/PluginRegistry/IngestService 引用改为协议注入 | 3 |
| **P0-4** | RAGOrchestrator 对 TaskCenter.shared 的直接调用改为协议注入 | 1 |
| **P0-5** | Infrastructure 层反向引用：PluginRegistry→KnowledgeStore, ChatRunner→TaskCenter, iCloudSync→AppStore | 3 |

### P1: 架构治理

| # | 问题 | 预估影响文件 |
|:---|:---|:---|
| **P1-1** | Shared 层 AppStore/Router/VaultService/TaskCenter 引用改为协议/泛型注入 | 15 |
| **P1-2** | DesignSystem.swift 878 行拆分为 5+ 独立文件 | 5 |
| **P1-3** | Features 层 ~40 处 `#if os()` 宏提炼为 ViewBuilder 或平台适配器 | 40 |
| **P1-4** | 103 处硬编码 systemName 集中到 DesignSystem.Icons | 103 |
| **P1-5** | AppStore 瘦身，PDF/OCR/DemoData 下沉至 Feature Store；核心接口下沉 Core/Protocols/ | 30+ |
| **P1-6** | 30+ 处 UserDefaults 非常量化 Key 归入 AppConstants.Keys.Storage | 30 |

### P2: 质量提升

| # | 问题 | 预估影响文件 |
|:---|:---|:---|
| **P2-1** | 20+ 个超大文件 (>300行) 按职责拆分 | 20 |
| **P2-2** | Router.updateSelection switch 重构为映射模式 | 1 |
| **P2-3** | LintService 健康评分阈值提取为配置化常量 | 1 |
| **P2-4** | 公开函数 `///` 文档注释补全至 80%+ | ~50 |
| **P2-5** | Core 层 Haptic/JailbreakDetector 宏包裹文件迁移至 Platforms/ | 3 |

---

## 十一、与上次审计 (2026-05-16) 的对比

| 维度 | 5/16 评分 | 5/28 评分 | 变化 | 说明 |
|:---|:---:|:---:|:---:|:---|
| 架构分层 | 8.0 | 6.5 | ↓ | 发现依赖方向合规性仅 4/10：Domain→Features、Infrastructure→Features、Features 系统性依赖 AppStore |
| 代码整洁 | 7.5 | 7.0 | ↓ | 更精确地量化了魔法值(103处 SF Symbol)和宏散布(49处) |
| 多端解耦 | 8.5 | 6.5 | ↓ | 实际扫描发现 Features 层宏数量远超预期 |
| 文档注释 | 9.0 | 8.5 | ↓ | 量化发现 48% 公开函数仍缺 `///` |

**说明**: 评分下调非代码质量退步，而是本次审计维度更深、扫描更精确，发现了之前未覆盖的问题。

---

## 十二、修复路线图 — 任务清单

### 阶段 1: P0 架构红线 (1 周)

| # | 任务 | 违规类型 | 涉及文件 | 修复方案 | 预估工时 |
|:---|:---|:---|:---|:---|:---|
| **T01** | ShortcutManager 迁移 | L0.5→L3/L2 反向依赖 | `Core/System/Shortcuts/ShortcutManager.swift` | 物理迁移至 `App/Shortcuts/` 或 `Platforms/Shortcuts/`，消除 Core 层对 AppStore/Router/KnowledgeStore 的直接引用 | 2h |
| **T02** | Domain 模型剥离 GRDB | L1.5→L1 DIP 违规 | `Domain/Models/` 下 5 文件 (KnowledgePage/PageLink/PageType/RAGModels/KnowledgePageFTS) | 移除 `import GRDB` + `FetchableRecord/PersistableRecord` 遵循，在 `Infrastructure/Storage/Extensions/` 新建 GRDB 协议 Extension | 4h |
| **T03** | KnowledgePageManager 协议注入 | L1.5→L1/L2 DIP 违规 | `Domain/Knowledge/KnowledgePageManager.swift` | 1. 抽取 `PluginEventBus` 协议至 `Domain/Protocols/`，替代 `PluginRegistry.shared`<br>2. 抽取 `IngestServiceProtocol` 至 `Core/Protocols/`，替代直接引用<br>3. `EmbeddingManager` 改为 `EmbeddingProvider` 协议注入 | 3h |
| **T04** | RAGOrchestrator 协议注入 | L1.5→L2 反向依赖 | `Domain/RAG/RAGOrchestrator.swift` | 抽取 `TaskCenterProtocol` 至 `Core/Protocols/`，替代 `TaskCenter.shared` 直接调用 | 2h |
| **T05** | Infrastructure 反向引用修复 | L1→L2/L3 反向依赖 | `PluginRegistry.swift`, `ChatRunner.swift`, `iCloudSyncCoordinator.swift` | 1. PluginRegistry: 抽取 `KnowledgeStoreProtocol` 替代直接引用<br>2. ChatRunner: 同 T04 用 TaskCenterProtocol<br>3. iCloudSync: 抽取 `SyncDelegate` 协议替代 AppStore 引用 | 4h |

### 阶段 2: P1 架构治理 (2 周)

| # | 任务 | 违规类型 | 涉及文件 | 修复方案 | 预估工时 |
|:---|:---|:---|:---|:---|:---|
| **T06** | Shared 层业务类型解耦 | Shared→L2/L3 越界 | 15 文件 (VaultBadge, FloatingContextCapsule, AIProcessingStatusBanner, MarkdownRendererView, HostingSetupSheet, SynthesisStore+UI, LockOverlayView, EditorComponents, AdaptiveSidebarView, KeyboardShortcutsView, UserProfileMenu 等) | 1. AppStore/Router 引用改为 `@Environment(\.appStoreProtocol)` / `@Environment(\.routerProtocol)`<br>2. VaultService/TaskCenter/CollaborationService 同理协议化<br>3. KnowledgePage 引用改为泛型或协议 `PageRepresentable` | 8h |
| **T07** | AppStore 接口下沉 + 瘦身 | L3→L2 系统性污染 | `AppStore.swift` (537行) + 30+ 引用文件 | 1. Core/Protocols/ 定义 `AppStoreProtocol`<br>2. AppStore 遵循协议，各层通过 `any AppStoreProtocol` 引用<br>3. PDF/OCR/DemoData 逻辑下沉至对应 Feature Store | 8h |
| **T08** | DesignSystem.swift 拆分 | SRP 违规 (878行) | `Shared/DesignSystem/DesignSystem.swift` | 拆分为: DesignSystemSpacing.swift / DesignSystemRadius.swift / DesignSystemTypography.swift / DesignSystemColor.swift / DesignSystemAnimation.swift | 4h |
| **T09** | Features 层宏治理 | 宏散布 (~40处) | Features/ 下 ~20 文件 | 按 swift-coding-style.md 三原则: 协议屏蔽 → DI 路由 → UI 隔离。提炼为 `@ViewBuilder` 或独立平台适配器 | 8h |
| **T10** | Core 层宏迁移 | 宏散布 (4处) | `iOSHapticService.swift`, `MacHapticService.swift`, `JailbreakDetector.swift` | 物理迁移至 `Platforms/` 对应目录 | 2h |
| **T11** | SF Symbol 中心化 | 魔法值 (103处) | Features/Shared 下 ~50 文件 | 集中到 `DesignSystem.Icons` 枚举，逐一替换硬编码 `systemName:` | 6h |
| **T12** | UserDefaults Key 常量化 | 魔法值 (30+处) | Infrastructure/Security/Insight/LLM 下 ~15 文件 | 归入 `AppConstants.Keys.Storage`，逐一替换 | 3h |
| **T13** | 业务魔法数字集中化 | 魔法值 (20+处) | AIContentEnricher/KnowledgeIngestPipeline/PluginRegistry/AppCloudSyncService/OnDeviceLLMService/EmbeddingManager/DatabaseManager/BusinessConstants | 提取 ChunkConfig/EvaluationThreshold/PluginDefaults/iCloudConstants/LLMDefaults/EmbeddingConfig/DatabaseConfig/ScoringWeight/HealthThreshold 等常量集 | 6h |

### 阶段 3: P2 质量提升 (持续)

| # | 任务 | 违规类型 | 涉及文件 | 修复方案 | 预估工时 |
|:---|:---|:---|:---|:---|:---|
| **T14** | 超大文件拆分 (>300行) | SRP 违规 | Top 5 优先: DatabaseManager(656)/MarkdownProcessor(627)/AppCloudSyncService(568)/PluginRegistry(453)/OnDeviceLLMService(434) | 按审计报告 §5.1 建议逐一拆分 | 16h |
| **T15** | print() → Logger 迁移 | 日志规范 | DatabaseManager(16+)/PerformanceBenchmarker(9)/EmbeddingManager(4+)/RAGEvaluationService(1) | 全量替换为 `Logger.service.log()` | 2h |
| **T16** | 注释格式统一 | 文档规范 | KnowledgeRepository/KnowledgePageManager/LinkService/PluginRegistry/OnDeviceLLMService 等 6+ 文件 | 修复 `/// ///` 双注释为标准 `/// - Parameter`；修复层级标注不一致 | 3h |
| **T17** | RRF 算法去重 | 重复代码 | `LinkService.swift` + `EmbeddingManager.swift` | 提取为 `RRFCombiner` 工具类至 Core/Utils/ | 1h |
| **T18** | 标签正则去重 | 重复代码 | `KnowledgePage.swift:239` + `OnDeviceLLMService.swift:331` | 提取为 `TagRegex` 共享工具 | 0.5h |
| **T19** | Router.updateSelection 重构 | OCP 违规 | `App/Router/Router.swift` | 重构 switch 为路由映射表模式 | 2h |
| **T20** | LintService 健康评分配置化 | OCP 违规 | `Features/Insight/Lint/LintService.swift` | 提取 ScoringWeight/HealthThreshold 为可配置常量集 | 1h |
| **T21** | 公开函数 `///` 补全 | 文档规范 | ~50 文件 / 102 个函数 | 补全缺失的 SwiftDoc 注释至 80%+ | 8h |
| **T22** | LLMUtils 字典透传改造 | 类型安全 | `Domain/RAG/LLMUtils.swift:40-48` | `[String: Any]` 改为 Codable 结构体 | 1h |
| **T23** | FeatureProtocols 按域拆分 | ISP 违规 | `Domain/Protocols/FeatureProtocols.swift` | 按 AI/Knowledge/Insight/System 拆分为独立协议文件 | 1h |

### 工时汇总

| 阶段 | 任务数 | 预估总工时 | 关键指标 |
|:---|:---:|:---:|:---|
| 阶段 1 (P0) | 5 | **15h** | 消除全部反向依赖，依赖合规评分 4→6 |
| 阶段 2 (P1) | 8 | **45h** | 依赖合规 6→7.5，宏/SF Symbol/魔法值归零 |
| 阶段 3 (P2) | 10 | **35.5h** | 超大文件清零，注释覆盖 80%+ |
| **总计** | **23** | **95.5h** | 综合评分 6.8→8.5+ |

---

**审计人**: 齐活林 (Qi) · 交付总监
**工具**: 自动化 grep/扫描 + 分层深度审查
**下次审计建议**: 阶段 1 完成后重新评估架构分层评分
