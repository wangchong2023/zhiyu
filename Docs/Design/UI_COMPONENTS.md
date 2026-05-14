# UI 组件与架构设计规范

本文档定义了“智宇”系统中 UI 组件的划分策略与布局规范，确保跨平台 (iOS/iPadOS/macOS) 的视觉一致性，并落实全链路溯源与 DFX (Design for X) 标准。

## 1. DesignSystem (设计系统)

核心设计资产（Token）和基础视觉定义，位于 `Sources/Shared/DesignSystem/`。最终 DesignSystem 存放公共统一标准。

- `Tokens/Colors.swift`: 全局语义化色彩定义，必须支持 Dark/Light Mode 切换。
- `Tokens/Spacing.swift`: 间距与圆角常量定义。严禁在视图中使用散落的硬编码数字（魔鬼数字）。
- `Tokens/Typography.swift`: 排版与字号层级，映射为逻辑缩放大小。
- `Tokens/Animations.swift`: 系统级物理动效定义。

## 2. UIComponents (公共 UI 组件)

通用且无业务状态（Stateless）的视觉积木，位于 `Sources/Shared/UIComponents/`。

- `Buttons/`: 各种应用级别按钮。
- `Cards/`: 数据展示卡片（如 `AppCard`, `StatCard`）。
- `Feedback/`: 轻提示、加载浮层（如 `AppToast`, `AppEmptyState`）。
- `Modifiers/`: 视觉修饰符封装，例如 `GlassStyle` 玻璃拟态。

## 3. Layouts (布局模板)

用于界面的骨架约束结构，位于 `Sources/Shared/UIComponents/Layouts/`。用于存放本界面的特殊定制标准。

- `StandardSection.swift`: 标准区块布局，提供一致的内边距和流式排列。
- `FlowLayout.swift`: 流式自适应包裹布局，多用于标签云等可换行内容。
- `VaultLayout.swift`: 特定于金库模块的专属布局模板。
- **业务定制要求**：在重构过程中，需要保持既有布局效果不被破坏。遇到特定业务界面的定制布局需求时，禁止在 View 层直接硬编码堆叠，而是应提炼模板并存放到 `Layouts` 下（或对应模块的特定 Layout 子目录中）。所有特定的约束、间距应映射至 `DesignSystem` 常量。

---

## 4. 全链路溯源矩阵 (Traceability Matrix)

为实现卓越工程，确保所有的需求（SRS）、架构设计（Architecture）、源代码（Code）和测试用例（Tests）均能精准对齐。

### 4.1 溯源关系映射

| SRS 编号 | 需求名称 | 架构 / 设计文档映射 | 代码模块映射 (Sources) | 测试用例映射 (Tests) |
| :--- | :--- | :--- | :--- | :--- |
| **SR-01/02** | 数据隔离与沙盒 | `SECURITY_DESIGN.md` | `VaultStorageSecurityService.swift`, `SQLiteStore.swift` | `VaultSecurityTests.swift` |
| **SR-03/04** | 身份鉴权与插件沙盒 | `AuthArchitecture.md`, `PLUGIN_SDK.md` | `AuthService.swift`, `PluginRegistry.swift` | `AuthTests.swift`, `PluginSandboxTests.swift` |
| **PR-01/02** | FTS5 与 RAG 性能 | `DETAILED_DESIGN.md`, `RAG_GOVERNANCE.md` | `KnowledgePageStore.swift`, `VectorIndexer.swift` | `SearchPerformanceTests.swift`, `RAGPipelineTests.swift` |
| **PR-05** | 数据库冷启动加载 | `ARCHITECTURE_4PLUS1.md` | `AppEnvironment.swift`, `SQLiteStore.swift` | `DatabaseStartupTests.swift` |
| **RR-01/03** | ACID 与 内存管控 | `DETAILED_DESIGN.md` | `SQLiteStore.swift`, `PerformanceBenchmarker.swift` | `TransactionTests.swift`, `MemoryFootprintTests.swift` |

### 4.2 代码中的强制溯源
代码中必须以注释的形式显式标注其对应的需求编号，以实现最强的可回溯性。
示例：
```swift
// MARK: @SR-03 (金库级锁定实现)
/// 遵循 @Docs/Requirements/SOFTWARE_REQUIREMENTS_SPECIFICATION.md
```

## 5. DFX 与可观测性 (Log/Tracing/Metric)

系统在 `Sources/Core/Logger/Logger.swift` 和 `Sources/Core/Performance/PerformanceBenchmarker.swift` 中集中落实 DFX 要求：

1. **功能单一性 (SOLID)**：`Logger` 仅负责操作日志的内存聚合与磁盘原子写入；`PerformanceBenchmarker` 仅负责耗时指标的计算与分析。两者通过 `AppEventBus` 松耦合交互。
2. **追踪与度量 (Tracing & Metric)**：
   - 核心耗时路径（如向量查询、图谱布局）使用 `logTimed` 高阶函数包裹，自动采集并写入带有时序标记的 `LogEntry`。
   - 所有操作日志（包括执行耗时、成功/失败状态）会持久化到磁盘，支持通过 `LogView` 在开发者菜单中可视化追溯。
3. **命名原则 (KISS & Clean Code)**：
   - 文件与类名必须做到“见名知意”，如 `DataCoordinator` (数据协调)、`SQLiteStore` (SQL存储)。
   - 绝不出现如 `Utils.swift` 或 `Manager.swift` 这种指代不明的巨型神仙类。

## 6. xcstrings (本地化) 模块化划分
随着代码目录迁移至按功能领域 (Features L2) 划分，`.xcstrings` 的模块化必须与 Features 一一对应。
- `Dashboard.xcstrings` -> `Sources/Features/Dashboard`
- `Chat.xcstrings` -> `Sources/Features/Chat`
- `Vault.xcstrings` -> `Sources/Features/Vault`
- `Common.xcstrings` -> `Sources/Shared/UIComponents`

确保所有的字符串均从上述字典表中通过类型安全的 `Localized.tr()` 动态加载，严禁 UI 视图中出现硬编码中文或魔鬼字符串。
