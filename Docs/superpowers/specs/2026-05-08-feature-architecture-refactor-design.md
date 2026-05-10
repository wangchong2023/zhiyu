# 智宇 (ZhiYu) 架构重构设计文档：走向 Feature 核心模块化

- **日期**：2026-05-08
- **目标**：将当前的 L0-L3 水平分层架构重构为以 Feature 为核心、物理归类清晰的垂直架构。
- **核心准则：视觉无损 (Visual Integrity)**：重构过程仅为物理结构与逻辑层级的优化，严禁改变既有的 UI 布局效果与交互表现。

## 0. 模块划分原则 (Module Partitioning Principles)

为了确保组件归属明确且易于维护，遵循以下四个决策准则：

1. **业务垂直原则 (Verticality) -> Features/**
    - 针对独立的功能闭环（如 Chat, Search）。
    - 包含实现该功能所需的 UI (Views)、交互 (ViewModels) 和独有逻辑 (Services)。
2. **领域能力原则 (Domain Capability) -> Infrastructure/**
    - 针对通用的技术领域实现（如 LLM, VectorDB, OCR）。
    - 逻辑纯粹，不关心 UI 表现，仅作为 Feature 的能力支撑。
3. **公共公约原则 (Commonality) -> Shared/**
    - 针对跨功能的业务本质（Models）或视觉标准（DesignSystem, Layouts）。
    - 只有当一个组件被 2 个或更多 Feature 同时依赖时方可进入。
4. **纯粹技术原则 (Purity) -> Core/**
    - 针对业务无关的技术底层（Network, Storage, Logger, Extension）。
    - 理论上可以拿去给任何其他 App 独立使用。

## 1. 目标架构概览

重构后的代码根目录将按照以下结构组织：

```text
Sources/
├── App/                # 应用入口、环境配置、全局路由
├── Core/               # 基础技术能力（与业务无关）
│   ├── Network/        # API 客户端、网络监听
│   ├── Storage/        # 文件系统、UserDefaults
│   ├── Logger/         # 统一日志
│   ├── Database/       # SQLite/GRDB 核心引擎
│   ├── Extension/      # Swift 语言基础扩展
│   └── Utils/          # 通用工具类
├── Features/           # 垂直业务功能块
│   ├── Chat/           
│   │   ├── Views/
│   │   │   └── Layouts/ # 本界面专属的定制布局标准（从 AppUI 拆分而来）
│   │   ├── ViewModels/
│   │   └── Services/
│   ├── KnowledgeBase/  
│   ├── Search/         
│   └── Settings/       
├── Shared/             # 跨功能共享资源
│   ├── Models/         # 核心领域模型（如 KnowledgePage）
│   ├── UIComponents/   # 基础 UI 组件、WikiUI
│   │   └── Layouts/    # 全局公共布局标准与模版
│   ├── Theme/          # 颜色、字体设计系统
│   ├── DesignSystem/   # 全局公共视觉原子标准（颜色、间距、字号）
│   └── Protocols/      # 跨模块通信契约协议
├── Infrastructure/     # 技术领域实现（AI/RAG 基础设施）
│   ├── LLM/            # 大模型客户端与适配器
│   ├── VectorDB/       # 向量存储与检索实现
│   ├── OCR/            # 图像识别能力
│   └── Analytics/      # 数据分析与统计
└── Resources/          # 资源文件（xcassets, l10n）
```

## 2. 详细映射关系表

### 2.1 基础设施与核心层 (Core & Infrastructure)
| 原路径 (Sources/Shared/...) | 目标路径 (Sources/...) | 关键文件/组件 |
| :--- | :--- | :--- |
| `Core/Platform/Logger.swift` | `Core/Logger/` | `Logger` |
| `Data/Persistence/SQLiteStore.swift` | `Core/Database/` | `SQLiteStore` |
| `Domain/Logic/LLM*` | `Infrastructure/LLM/` | `LLMClient`, `LLMService` |
| `Domain/Logic/EmbeddingManager` | `Infrastructure/VectorDB/` | `EmbeddingManager` |
| `Domain/Processors/OCRProcessor` | `Infrastructure/OCR/` | `OCRProcessor` |
| `Core/Utilities/` | `Core/Utils/` & `Core/Extension/` | `Localized`, `Character+CJK` |

### 2.2 业务功能层 (Features)
| 功能模块 | 包含的原组件 | 目标路径 |
| :--- | :--- | :--- |
| **Chat** | `Views/Chat`, `ViewModels/ChatViewModel`, `AISynthesisService` | `Features/Chat/` |
| **Knowledge** | `Views/Dashboard`, `IngestService`, `TextChunker`, `PDFProcessor` | `Features/KnowledgeBase/` |
| **Search** | `Views/CommandPalette`, `SearchStore`, `KnowledgeInsightService` | `Features/Search/` |

### 2.3 共享与应用层 (Shared & App)
| 组件类型 | 原路径 | 目标路径 |
| :--- | :--- | :--- |
| **应用入口** | `ZhiYuApp.swift` | `App/ZhiYuApp.swift` |
| **全局路由** | `Core/Platform/AppRouter.swift` | `App/Router.swift` |
| **核心模型** | `Models/*.swift` | `Shared/Models/` |
| **UI 基础** | `Core/Utilities/WikiUI`, `Views/Components` | `Shared/UIComponents/` |

### 2.4 UI 系统专项拆分 (AppUI.swift 重构)
现有的 `AppUI.swift` 承担了过多职责，需按照以下逻辑拆分：

- **Shared/DesignSystem**：原子令牌（Spacing, Radius, IconSize, Typography, Colors）。
- **Shared/UIComponents/Layouts**：通用装饰器（appCardStyle, appContainer, MeshGradient）与全局容器。
- **Features/XXX/Views/Layouts**：特定业务布局指标（从 AppUI.Graph 等提取）。

## 3. 实施计划 (方案一：原子结构先行)

### 阶段 1：目录骨架创建与核心迁移
1. 创建目标文件夹结构。
2. 迁移 `Core` 与 `Infrastructure` 下的底层组件。
3. 迁移 `Shared/Models`。
4. **执行 AppUI.swift 拆分**：将原子令牌先移入 `Shared/DesignSystem`。
5. **验证**：确保底层基础引用修复。

### 阶段 2：垂直功能聚合
1. 迁移 `Features/Chat`、`KnowledgeBase`、`Search`。
2. 将各功能专属的 `Views`, `ViewModels`, `Services` 归位。
3. 迁移对应的布局定制标准至 `Features/XXX/Views/Layouts`。

### 阶段 3：依赖清理与 DI 调整
1. 更新 `project.yml` 并刷新项目。
2. **逻辑整改**：执行冗余逻辑平替（见 3.4）。
3. 更新 `ServiceContainer` 注册逻辑。

### 3.4 冗余逻辑整改守则
- **提炼 (Lift)**：识别 Feature 内部的重复公共逻辑，提炼至 Shared 或 Core。
- **平替 (Smooth Replacement)**：在 Feature 内部暂时使用 Alias (别名) 包装标准版，确保数值 1:1 映射。
- **保留差异**：若逻辑存在业务特定性，将其保留在 Feature Service 中，仅剥离通用部分。

## 4. 风险评估与对策
- **引用冲突**：由于是逻辑隔离（单 Target），大部分 `import` 路径不受影响。
- **对策**：使用 `git mv` 保持历史记录，迁移后立即运行 `xcodegen`。
- **DI 注册失效**：Service 可能因为重命名或位置变动导致注入失败。
- **对策**：在启动时统一验证所有 `@Inject` 依赖。

## 5. UI 布局原则：规范复用与特性定制
- **全局原子标准 (`Shared/DesignSystem`)**：通用“视觉基因”。
- **全局布局模板 (`Shared/UIComponents/Layouts`)**：通用页面容器。
- **功能定制标准 (`Features/XXX/Views/Layouts`)**：特定功能布局常量，确保**视觉无损**。

## 6. 模块间通信与依赖准则
- **依赖解耦**：所有跨模块调用服务协议存放在 `Sources/Shared/Protocols/`。禁止直接引用具体实现。
- **导航解耦**：通过 `Sources/App/Router.swift` 集中分发跳转。
- **异步解耦**：使用 `Core/AppEventBus` 进行跨模块消息广播。
- **状态管理**：业务状态严格限定在 Feature ViewModels 内部。

## 7. 工程卓越准则 (Engineering Excellence)
在重构过程中，不仅要完成物理移动，还需执行以下代码质量清洗，确保系统符合 **SOLID**（面向对象设计五原则）与 **KISS**（简单至上原则）：

### 7.1 单一职责原则 (SRP) 与规模控制
- **文件级**：一个文件原则上仅包含一个主类型（Class/Struct/Actor）。关联的 Extension 若超过 100 行应考虑拆分。
- **函数级**：一个函数仅执行一个逻辑任务。
    - **长度限制**：单函数长度严禁超过 **100 行**（以 NBNC，即非空非注释行计）。
    - **复杂度控制**：单函数圈复杂度 (Cyclomatic Complexity) 严禁超过 **15**。若逻辑过深，必须提炼子函数或采用状态模式优化。

### 7.2 注释规范 (Documentation)
- **全量中文注释**：所有新增或重构的代码必须具备完备的简体中文注释：
    - **文件头**：包含文件名、作者、功能简述、版权声明。
    - **类型定义**：Class, Struct, Enum, Actor 及其属性必须有文档注释。
    - **函数头**：说明函数功能、参数含义、返回值、抛出异常。
    - **逻辑过程**：函数内部关键步骤、复杂算法、边缘情况处理必须有行内注释。

### 7.3 魔鬼数字与字符串治理
- **UI 常量**：严禁在 View 中出现硬编码数值。所有间距、尺寸必须溯源至 `DesignSystem` 或功能的 `Layouts`。
- **业务常量**：逻辑中的 magic numbers 必须定义为私有 `Constants` 枚举或常量结构。
- **字符串硬编码**：所有面向用户的字符串必须通过 `Localized.tr` 走 String Catalog。内部使用的 Key 应定义为 `RawRepresentable` 枚举。

### 7.4 高内聚与低耦合
- **物理内聚**：与该 Feature 相关的 Processor、Helper 必须放在 Feature 目录下，除非被 2 个以上模块共享。
- **逻辑解耦**：通过 `Protocol` 隐藏内部实现。如果修改 Feature A 的内部逻辑导致 Feature B 需要编译报错，则说明解耦不彻底。

### 7.5 命名准则 (Naming Conventions)
- **描述性优先**：变量名应清晰表达意图，避免 `data`, `info`, `manager` 等模糊词汇。
- **动宾结构**：函数名必须使用“动词 + 宾语”结构（如 `fetchKnowledgePages()`, `updateUIVisibility()`），严禁使用单动词或纯名词。
- **类型语义**：严格遵循 `Docs/guides/swift-coding-style.md` 中的后缀规范（Service, Store, Provider 等）。

### 7.6 设计哲学
- **SOLID**：通过接口隔离（ISP）和依赖倒置（DIP）确保模块可扩展、易替换。
- **KISS**：优先选择最直接、简单的实现方案。避免过度设计，除非业务复杂度确实需要。

## 8. 全链路测试策略 (Testing Strategy)
架构重构必须伴随测试体系的同步演进，确保每一个物理移动和逻辑调整都有据可查。

### 8.1 单元测试 (Unit Tests) - 模块内隔离测试
- **存放路径**：`Tests/Unit/` 下对应 `Core`, `Infrastructure`, `Features` 的子目录。
- **职责**：验证单个 Service, ViewModel 或 Utils 的逻辑正确性。
- **重构要求**：迁移代码后，必须同步移动对应的测试文件。确保单函数重构后的覆盖率不下降。

### 8.2 集成测试 (Integration Tests) - 协议契约测试
- **存放路径**：`Tests/Integration/`。
- **职责**：验证 Feature 与 Infrastructure 之间通过协议进行的协作是否正常。
- **重构要求**：重点测试 `ServiceContainer` 重新注册后的依赖解析是否正确。

### 8.3 系统测试 (System Tests) - 业务闭环测试
- **存放路径**：`Tests/UI/` & `Tests/Shared/`。
- **职责**：验证 RAG 全链路（摄取 -> 存储 -> 检索 -> 合成）在架构调整后依然闭环。
- **重构要求**：在重构的每个阶段结束时，必须运行一次全量系统测试。

### 8.4 自动化验证准则
...
- **持续集成**：重构后的 `project.yml` 必须保证 `ZhiYuTests` target 能够一键运行。

## 10. 跨平台适配策略 (Platform Adaptation)
...
- **能力桩测试 (Mocking Capabilities)**：对于 watchOS 等受限平台，通过 Mock 协议确保业务逻辑在缺少硬件支持时依然能优雅降级。

## 11. 工程追踪矩阵与可回溯性规范 (Traceability)
为了实现从“需求”到“代码”再到“测试”的全链路追踪，重构需遵循以下规范：

### 11.1 追踪链条定义
- **Feature (F-xxx)** -> **Spec (ID)** -> **Implementation (Code)** -> **TestCase (TC-xxx)**。

### 11.2 代码标注要求 (@Spec Annotation)
- **硬性标注**：所有实现特定规格要求的核心逻辑、类、方法，必须在代码中显式标注对应的 SRS 编号。
- **标注格式**：
    - **文档注释**：`/// @Spec(SR-03): 实现金库级锁定逻辑`
    - **MARK 标签**：`// MARK: - @Spec(PR-01) 全文搜索性能优化点`
- **目的**：确保开发者在不离开编辑器的情况下，能够瞬间回溯到该代码对应的业务标准与验收准则。

### 11.3 测试追溯
- **测试方法命名**：推荐采用 `test_TC_XXX_Scenario` 格式。
- **测试关联**：在测试用例的文档注释中，必须注明其验证的 `@Spec(ID)`。



