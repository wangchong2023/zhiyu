# 智宇 (ZhiYu) 详细设计文档 (Detailed Design)

本文件深入解析 智宇 (ZhiYu) 核心引擎的内部实现细节。

## 1. 混合检索引擎 (Hybrid Search Engine)

### 1.1 数据流向与 RAG 模块化管道 (Modular Ingest Pipeline)
智宇 (ZhiYu) 实现了端到端的 RAG 摄入管道，通过 `KnowledgeIngestPipeline` (位于 `Domain/RAG`) 进行编排：
1. **Parser (解析器)**: 抽取纯文本，支持 Markdown, PDF, OCR 图像识别。
2. **Chunker (分块器)**: 基于语义长度（Semantic Splitting）将长文划分为分块。
3. **Embedding (向量化)**: 异步调用 LLM 生成向量，由 `EmbeddingManager` 同步至向量数据库。
4. **Linker (关联器)**: 自动发现页面间的 Wiki-Link，构建知识图谱 (Graph)。

### 1.2 检索策略 (Retrieval Strategy)
系统采用 **FTS5 (全文搜索)** + **Vector Search (向量检索)** 的混合模式：
- **关键词匹配**: 用于精确查找特定术语。
- **语义相似度**: 用于模糊意图识别，支持跨语境关联。
- **Reranking (重排序)**: 召回后的结果由 AI 进一步根据 Query 语义进行权重重排，确保最相关的知识排在首位。

## 2. 存储与状态引擎 (Storage & State Engine)

### 2.1 物理存储与 Repository 模式 (DIP 实现)
智宇 (ZhiYu) 采用基于 **GRDB.swift** 的 Repository 模式，并严格遵循 **依赖倒置原则 (DIP)**：
- **契约下沉**: 所有的仓储协议（如 `KnowledgeRepository`, `VectorRepository`）物理位置位于 `Sources/Domain/Protocols/`，由领域层定义业务契约。
- **解耦实现**: 具体的 SQL 实现类（如 `KnowledgePageRepository`）位于 `Sources/Infrastructure/` 层，通过 DI 容器注入到领域服务中。这种模式确保了核心业务逻辑不直接依赖于 GRDB 或任何特定的持久化框架。

### 2.2 全局状态 Facade (AppStore 治理)
`AppStore` 作为全应用的状态入口，通过 `@Observable` 驱动 UI 刷新。为了符合 **单向数据流 (UDF)** 原则，系统执行了重构：
- **核心聚合**: `AppStore` 仅负责页面元数据同步、全局路由协调与基础操作封装。
- **显式调度**: 移除了子 Store (Search, Settings, Workflow) 对 EventBus 的被动监听。所有的重置与全局同步动作由 `AppStore` 通过方法调用显式驱动。这种设计确立了严谨的父子 Store 调用链路，极大降低了复杂业务流下的调试难度。
- **业务下沉**: 垂直领域特有的复杂状态已下沉至领域专有的 `Store`（如 `IngestStore`, `AIWorkflowStore`），通过环境对象 (`.environment()`) 按需注入视图。

## 3. 插件系统架构与加固 (Plugin System & Hardening)

### 3.1 扩展点设计 (Extension Points)
智宇参考 Obsidian 架构，为插件开放了深度 UI 扩展点：
- **Command Palette**: 插件可注册全局指令至 `Cmd+K` 中枢。
- **Ribbon & Sidebar**: 插件可在侧边栏注册图标入口或独立的自定义视图。
- **Lifecycle Events**: 插件可监听 `onFileOpen`, `onPageSave` 等系统级事件。

### 3.2 Watchdog 2.0 性能监控
为了防止僵尸插件拖慢宿主 App，`PluginRegistry` 集成了 Watchdog 2.0 机制：
- **执行竞速**: 每个插件拦截 Hook 的执行上限为 **500ms**。
- **物理封禁**: 超时插件会被立即卸载、物理回收 `JSContext` 内存，并将其 ID 写入 `UserDefaults` 黑名单。重启 App 后封禁依然有效，彻底杜绝循环性能崩溃。
- **资源监控**: 系统实时统计每个插件的调用次数与平均耗时，并在“系统监控”面板中提供可视化排行。

### 3.3 插件存储加密
每个插件拥有独立的持久化空间：
- **AES-GCM 加密**: 存储文件（`.json`）在写入磁盘前均通过 AES-256-GCM 进行全盘加密，密钥派生自系统 Keychain。
- **双向绑定**: 插件的声明式 UI 组件与加密存储实现了自动双向绑定，开发者无需编写 IO 代码即可实现配置记忆。
## 3. 多平台适配与能力隔离 (Platform Adaptation)

### 3.1 跨平台协议抽象
为了实现“业务代码零宏”的目标，系统在 `Sources/Core/Base/Protocols/` 定义了一系列能力协议：
- **PlatformCapabilities**: 抽象触感反馈、状态栏高度、底部安全区等 UI 差异。
- **LiveActivityProtocol**: 抽象灵动岛 (Dynamic Island) 实时活动。在 iOS 下由 `ActivityService` 实现，在非支持平台由 `DummyActivityService` 提供空操作。
- **OCRServiceProtocol**: 抽象文字识别。

### 3.2 系统级解耦
所有的平台具体实现均被物理隔离在 `Sources/Platforms/` 目录下。主 App 仅通过 `ModuleRegistrar` 完成各平台的 DI 注册。

## 4. 视觉算法：力导向图谱布局 (Force-Directed Graph)

### 4.1 核心算法
图谱视图 (`GraphView`) 采用力导向布局 (Force-Directed Layout)，通过模拟物理作用力计算节点坐标：
- **排斥力 (Repulsion)**: 防止节点重叠。
- **吸引力 (Attraction)**: 将具备双向链接的节点拉近。
- **摩擦力 (Damping)**: 随迭代次数增加逐渐降低动能，使布局趋于平稳。

### 4.2 空间分布 (Spatial Distribution)
针对 3D 图谱，采用 **Fibonacci Sphere (斐波那契球)** 分布算法：
- **动态半径**: 球体半径 $R = \max(40, \min(150, \sqrt{N} \times 12))$。该公式确保节点间的平均弧长在不同节点规模 ($N$) 下保持视觉舒适。
- **层级深度**: 选中节点及其一阶邻居会通过 `SCNTransaction` 进行平滑的“向前推移”，利用 Z 轴深度突出展示上下文。
