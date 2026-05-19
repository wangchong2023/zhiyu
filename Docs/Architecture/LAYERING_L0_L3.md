# 智宇 (ZhiYu) 架构分层定义 (L0-L3)

本文档定义了“智宇”系统的核心分层架构，旨在指导模块化重构、依赖管理和开发规范。

## 架构全景图 (Logical View)

```mermaid
graph TD
    L3[L3: Presentation Layer - SwiftUI Views & ViewModels] --> L2
    L2[L2: Feature Layer - Vertical Slices] --> L1_5
    L1_5[L1.5: Domain Layer - Business Rules & Orchestration] --> L1
    L1[L1: Infrastructure Layer - LLM, Storage & Processors] --> L0_5
    L0_5[L0.5: System Layer - OS Integration: Logger, Haptic] --> L0
    L0[L0: Base Layer - Kernel: DI, Protocols, Utils]
```

---

## L0: Base Layer (底层基座层)
**职责**：提供应用运行的最底层支撑，严禁包含任何业务逻辑或对系统服务的直接调用。

**核心目录** (`Sources/Core/Base/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `ServiceContainer.swift` | 依赖注入容器 | `@Inject`, `ServiceContainer` |
| `Protocols/` | 全局抽象协议 | `ReminderServiceProtocol`, `LoggerProtocol` |
| `Constants/` | 基础常量定义 | `AppConstants`, `Keys` |
| `Extensions/` | 基础类型扩展 | `Date+App`, `String+Utils` |

## L0.5: System Layer (系统集成层)
**职责**：封装 OS 级能力，抹平硬件与系统 API 差异。

**核心目录** (`Sources/Core/System/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `Logger/` | 结构化日志服务 | `Logger` |
| `Haptic/` | 触感反馈系统 | `HapticFeedback` |
| `Security/` | 生物识别与加密 | `SecurityManager` |
| `Routing/` | 物理导航与 DeepLink | `DeepLinkService` |

## L1: Infrastructure Layer (基础设施层)
**职责**：实现具体的技术能力，如 LLM 通信、数据库持久化和物理文档解析。本层在多笔记本模式下承担物理连接的多连接池动态断联与挂载（Dynamic Mount）重构职责。

**核心目录** (`Sources/Infrastructure/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `LLM/` | 模型客户端实现 | `LLMClient`, `DeepSeekProvider` |
| `Storage/` | 持久化引擎实现 | `SQLiteStore`, `Repository`, `DatabaseManager`（管理单例 `global.sqlite3` 全局主库及各 `vault.sqlite3` 专属子库的动态热插拔与迁移） |
| `Processors/` | 物理文档处理器 | `PDFProcessor`, `OCRProcessor` |

## L1.5: Domain Layer (领域中心层)
**职责**：承载核心业务大脑，定义跨模块的业务规则、领域行为及合成策略。

**核心目录** (`Sources/Domain/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `Models/` | 核心领域模型 | `KnowledgePage`, `PageLink` |
| `RAG/` | 检索增强生成策略 | `AIContentEnricher`, `LinkService` |
| `Protocols/` | 业务模块契约 | `AuthServiceProtocol`, `VaultServiceProtocol` |

## L2: Features Layer (业务功能层)
**职责**：垂直功能切片。按业务域分组（Knowledge, AI, Insight, System），负责 UI 呈现与本地交互状态管理（通过 `KnowledgeStore` 等专用 Feature Store 实现）。

**核心目录** (`Sources/Features/`):
| 领域 (Sub-Domain) | 包含模块 | 核心职责 |
| :--- | :--- | :--- |
| **Knowledge** | `Ingest`, `Graph`, `Search`, `Vault`, `NotebookHub` | 核心知识流：数据采集、图谱演化、语义搜索与存储。 |
| **AI** | `Chat`, `Synthesis`, `TaskCenter`, `VoiceNote`, `Quiz` | AI 实验室：对话交互、合成润色、任务调度与多模态。 |
| **Insight** | `Dashboard`, `Log`, `Lint`, `MedalWall` | 洞察与质量：数据可视化、系统日志、质量检查与成就系统。 |
| **System** | `Auth`, `Settings`, `Collaboration` | 通用系统：身份认证、应用配置、跨端实时协作。 |


## L3: App Layer (应用层)
**职责**：负责应用的生命周期管理、全局环境初始化以及模块间的导航路由。

**核心目录** (`Sources/App/`):
| 组件 | 职责 |
| :--- | :--- |
| `ZhiYuApp` | 应用入口，执行 L0/L1 层服务的注册与启动 |
| `AppEnvironment` | 管理全局依赖的状态与并发环境配置 |
| `Router` | 跨 Features 模块的全局导航调度中心 |
| `ViewFactory` | 依据业务逻辑动态构建视图实例 |

---

## Shared: 共享层 (非功能分层)
**职责**：定义应用级的共享标准，确保多模块间的视觉与交互一致性。

**核心目录** (`Sources/Shared/`):
- `DesignSystem/`: 原子设计令牌 (Spacing, Typography, Colors, Animations)。
- `UIComponents/`: 跨模块通用的 SwiftUI 视图、布局模板与玻璃拟态修饰符。

---

## 核心开发准则
1.  **单向依赖**：上层可以依赖下层，下层严禁依赖上层。跨层调用需通过协议 (Protocols) 解耦。
2.  **DI (依赖注入)**：使用 `@Inject` 模式在 L2/L3 层注入 L1 服务，禁止在服务内部直接使用 `.shared`（逐步淘汰中）。
3.  **Actor 隔离**：UI 绑定代码必须标注 `@MainActor`，异步服务应标记为 `actor` 以符合 Swift 6 要求。

## ⚠️ 架构审计与重构状态（2026-05-18 全深度审查更新）

经过 2026-05-18 的全生命周期工程体检与对标 Google NotebookLM、Obsidian，智宇项目对“多租户/多笔记本物理沙盒隔离”与“安全层/常量 Clean Code 治理”发起了底盘级革命重构。

| 类型 | 状态 | 涉及文件 / 说明 |
|:--- |:--- |:--- |
| **存储层重构** | ✅ 已修复 | 已完成 Repository 模式迁移，且存储协议已全部异步化适配 Actor。 |
| **物理多库隔离** | ✅ 已修复 | 重构 `DatabaseManager` 支持动态 `switchDatabase(to:)` 物理切换，解除单库强寄生。 |
| **全局库化下沉** | ✅ 已修复 | 建立全局配置库 `global.sqlite3` 结构化托管笔记本卡片列表、防篡改签名表等全局数据。 |
| **依赖倒置 (DIP)** | ✅ 已修复 | 所有的仓储协议已物理下沉至 L1.5 (Domain) 层，实现彻底解耦。 |
| **AppStore 治理** | ✅ 已修复 | `AppStore` 已完成瘦身，页面管理 (`KnowledgeStore`)、标签、统计、PDF 等逻辑已迁移至专有领域 Store。 |
| **安全与常量治理**| ✅ 已修复 | 补全 `SecurityManager` 核心 API 三斜杠中文注释，消除短字 `4` 等魔鬼数字并收拢全局盐值。 |
| **跨层 UI 引用** | ✅ 已修复 | 逻辑层已完全剥离 SwiftUI 依赖。 |
| **平台宏泄漏** | ✅ 已修复 | 已通过 `LiveActivityProtocol` 抽象硬件能力，业务层无宏。 |
| **常量治理** | ✅ 已修复 | 业务常量已从 AppConstants 迁移至 BusinessConstants。 |

### 2026-05-18 深度审查核心结论与物理多库蓝图 (已批准)
1. **彻底物理隔离**：为了对标 Obsidian 与 Google NotebookLM，实现每一个笔记本（Vault）对应沙盒文件夹下的专属子目录。`vault.sqlite3` 物理承载知识数据及 RAG 向量缓存，实现真正的物理隔离，防止不同笔记本间的知识产权和隐私污染。
2. **全局数据库单例职责**：独立划分 `global.sqlite3` 物理库，用于跨笔记本共享的元数据存储（如笔记本索引、文件 HMAC 防篡改指纹表 `file_signatures`、跨 Vault 可观测性日志及全局设置），摆脱对轻量 `UserDefaults` 的强寄生。

### 重构经验记录
1. **Repository 模式 (仓储模式)**：在 L1 层通过 `Repository` 封装具体的 GRDB SQL 逻辑，业务层通过协议与之交互。这实现了业务模型与物理数据库表的解耦，并极大地提升了单元测试的便利性。
2. **表现层扩展 (UI Extensions)**：当模型或服务需要定义颜色、图标等 UI 属性时，在 `Views/Styles/` 目录下创建 `Model+UI.swift` 扩展，确保逻辑层纯粹性。
3. **Observation 框架**：在 L1/L2 层，使用 `import Observation` 替代 `import SwiftUI` 来获取 `@Observable` 能力。
3. **解耦动画**：`withAnimation` 应留在 View 层或 ViewModel 层，Service 层仅负责数据状态变更。

---

## 补充：视图耦合与平台差异化治理规范 (2026-05-13)

### 1. 视图与业务耦合问题
尽管本次重构极极大地提升了系统的层级清晰度，但在部分小型功能代码中，依然可能存在“视图与业务偶尔耦合”的历史债务。为了彻底消除这一隐患，必须遵循以下准则：
- **全面推进 ViewModel (MVVM)**：UI 视图应彻底转变为纯粹的状态呈现层 (State Reflection)。所有的业务逻辑、API 发起和状态变更计算，必须下沉到独立的 ViewModel 中。
- **视图侧严禁耗时操作**：例如数据库直接访问、网络请求或文件 IO，这些逻辑应当交由 Service 层封装，View 仅通过 `@Environment` 或 `@Inject` 与之交互。

### 2. 多端差异化与平台预编译宏的使用
由于智宇支持 iOS、macOS 和 watchOS 跨平台，代码库中会存在平台预编译宏（如 `#if os(iOS)`）。为了防止代码变得碎片化和难以阅读，制定以下“差异化控制”策略：
1. **协议层屏蔽 (Protocol-based Injection)**：严禁在核心业务逻辑中堆砌 `#if` 分支。应提取跨平台协议（例如 `HapticFeedbackProtocol` 或 `PDFServiceProtocol`），然后分别实现如 `iOSHapticService` 等具体类.
2. **依赖注入容器 (DI Container) 路由**：使用 `#if` 的唯一合法非 UI 场所是 `ModuleRegistrar.swift` 这样的 DI 注册入口，以此来决定向容器中注入哪个平台的具体实现。业务调用方只应面对协议。
3. **特有 UI 的优雅隔离**：仅在极少数不可避免的视图表现差异（例如 NavigationSplitView 与现代 TabView 切换）时，允许在 SwiftUI 文件中使用条件编译，但必须将该部分的分支提炼为独立的 `@ViewBuilder` 组件或独立的局部 View 结构，确保主 View 文件的干净整洁。

---

## ⚡️ 2026-05-18 终极全生命周期治理重大突破与重构圣经

为了实现系统的长治久安，智宇项目在本轮深度审计中正式沉淀了以下最高工程设计圣经，全团队在后续开发中必须无条件贯彻执行：

### 1. 依赖倒置（DIP）平台特有能力注入时序
所有平台特有服务（如 OCR、语音合成、安全沙盒存储书签）均应符合 L0 层协议描述。平台实现必须物理下沉在 `Sources/Platforms/{iOS,macOS,watchOS}/` 子目标中。
在应用冷启动时，DI 容器通过 `#if os` 仅在 L3-App 层的 `ModuleRegistrar.swift` 这一合法边界执行单次条件编译路由并向 `ServiceContainer` 动态绑定。高层业务层（Domain/Features）在调用时仅需使用 `@Inject` 面向协议交互，实现逻辑流的彻底平台无关性。

```mermaid
sequenceDiagram
    autonumber
    participant App as App Launch (ModuleRegistrar)
    participant DI as ServiceContainer
    participant Domain as Domain / Features (Business Core)
    participant iOS as iOSPlatformAdapter (Under Platforms/iOS)
    participant Watch as WatchPlatformAdapter (Under Platforms/watchOS)

    Note over App, DI: App init starts
    rect rgb(30, 40, 50)
        Note over App: Router platform compilation
        App->{DI}: Register (any OCRServiceProtocol)
        alt is iOS
            App-->>DI: Bind iOSOCRService
        else is watchOS
            App-->>DI: Bind WatchOCRService
        end
    end
    Note over Domain: Business logic triggers OCR
    Domain->>DI: Request injected service
    DI-->>Domain: Resolve & inject matching platform instance
    Domain->>Domain: Execute platform-independent OCR workflow
```

### 2. 超大文件与圈复杂度治理方针 (KISS & SRP 原则)
*   **物理文件限额**：
    *   单一 Swift 源文件（包含布局）的物理代码行数**不应超过 600 行**。
    *   单一函数/方法的物理行数**不应超过 50 行**，其嵌套圈复杂度（Cyclomatic Complexity）**强制控制在 10 以内**。
*   **治理重构方向**：
    1. **子视图组件化 (View Componentization)**：如 `IngestViewComponents.swift` 等超大 UI 视图，必须提炼出细粒度的子组件结构，或将长视图内容抽离至独立的 `extension` 或专有的局部 SwiftUI 结构体中。
    2. **MVVM 逻辑物理剥离**：视图层严禁包含繁琐的状态转换和异常判断（如 `LintView.swift`）。复杂的交互及校验结果集必须抽取到专有的 `ViewModel` 或者是业务层 `Store` 中，让 SwiftUI 文件回归极简。
    3. **算法状态机化**：对于文本解析（如 `MarkdownProcessor.swift`）和同步冲突比对（如 `AppCloudSyncService.swift`），必须把冗长而复杂的正则流程解耦到高内聚的静态 Helper 或者段落匹配器子类（SRP）中，以降低单一主类的认知负载。

### 3. 100% 结构化中文注释标准
所有 Swift 源文件必须严格采用简体中文书写标准注释，具体规范如下：
*   **文件头文档**：每个 `.swift` 物理文件顶部必须拥有作者、功能说明、所属架构层（L0-L3）、版权说明的标准文件头。
*   **标准三斜杠 Markdown 说明 (`///`)**：所有的公开/内部接口、关键类、枚举及其成员，必须补齐三斜杠 Markdown 说明。必须包含对参数的解释（`- Parameter`）、返回值的解释（`- Returns`）以及抛出异常的场景说明（`- Throws`）。核心在于解释 **“为什么设计该接口（Why）”**。
*   **行内过程注释 (`//`)**：在复杂的业务算法链、事务块、正则迭代和网络状态机中，必须逐一标记细致的三级行内注释，解释 **“这段代码是如何实现功能的（How）”**。
