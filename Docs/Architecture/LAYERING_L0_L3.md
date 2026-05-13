# 智宇 (ZhiYu) 架构分层定义 (L0-L3)

本文档定义了“智宇”系统的核心分层架构，旨在指导模块化重构、依赖管理和开发规范。

## 架构全景图 (Logical View)

```mermaid
graph TD
    L3[L3: Presentation Layer - SwiftUI Views & ViewModels] --> L2
    L2[L2: Domain / Feature Layer - Services & Processors] --> L1
    L1[L1: Service Layer - Data Access & Sync Stores] --> L0
    L0[L0: Infrastructure Layer - Core & Platform Utilities]
```

---

## L0: Infrastructure Layer (基础设施层)
**职责**：提供与操作系统和第三方库的最底层交互，定义全局协议与工具。

**核心目录** (`Sources/Shared/Core/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `Platform/` | 系统级工具与平台桥接 | `Logger`, `SecurityManager`, `HapticFeedback`, `SpotlightService`, `DeepLinkService`, `PerformanceService`, `AppRouter`, `AppTab`, `ShortcutManager` |
| `Protocols/` | 核心协议定义 | `LLMServiceProtocol`, `LoggerProtocol`, `EmbeddingProvider`, `LLMClientProtocol` |
| `Utilities/` | 通用工具与管理器 | `Localized`, `Character+CJK`, `ThemeManager`, `ServiceContainer` |

## L1: Service Layer (基础服务层)
**职责**：对底层持久化技术进行原子化抽象，提供跨业务的通用数据管理能力。

**核心目录** (`Sources/Shared/Data/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `Persistence/` | 物理存储仓库 | `SQLiteStore/` (Facade, CRUD, Search, Stats, Tags), `KnowledgePageStore`, `AppStore`, `AppBackupService`, `DatabaseManager`, `SearchStore`, `SettingsStore`, `IngestStore`, `SynthesisStore`, `AIWorkflowStore` |
| `Sync/` | 多端同步引擎 | `AppCloudSyncService`, `iCloudSyncManager` |

## L2: Domain / Feature Layer (业务领域层)
**职责**：封装核心业务算法与文档处理器，实现复杂的功能闭环。

**核心目录** (`Sources/Shared/Domain/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `Logic/AI/` | AI 专项服务群 | `LLMService` (Orchestrator), `LLMIngestService`, `LLMRetrievalService`, `LLMChatService`, `LLMRefactorService`, `LLMClient`, `LLMContextBuilder` |
| `Logic/` | 领域算法与评估 | `AISynthesisService`, `KnowledgeInsightService`, `EmbeddingManager`, `PromptService`, `RAGEvaluationService`, `PluginRegistry` |
| `Processors/` | 专门文档处理 | `TextChunkerProcessor`, `OCRProcessor`, `PDFProcessor`, `KnowledgeIngestPipeline`, `VectorIndexer` |
| `Features/` | 高级功能编排 | `IngestService`, `CollaborationService`, `LintService`, `UndoService`, `TaskCenter`, `AppEventBus` |

## L3: Presentation Layer (表现层)
**职责**：响应用户交互，展示状态，驱动导航。包含声明式 UI 与业务编排逻辑。

**核心目录** (`Sources/Shared/`):
| 目录 | 内容 | 关键组件 |
| :--- | :--- | :--- |
| `ViewModels/` | 视图模型层 | `ChatViewModel`, `GraphViewModel`, `PageDetailViewModel` (解耦 View 与 Service) |
| `Views/` | SwiftUI 视图库 | `ContentView`, `Dashboard`, `Editors`, `GraphView`, `CommandPalette` |

---

## 核心开发准则
1.  **单向依赖**：上层可以依赖下层，下层严禁依赖上层。跨层调用需通过协议 (Protocols) 解耦。
2.  **DI (依赖注入)**：使用 `@Inject` 模式在 L2/L3 层注入 L1 服务，禁止在服务内部直接使用 `.shared`（逐步淘汰中）。
3.  **Actor 隔离**：UI 绑定代码必须标注 `@MainActor`，异步服务应标记为 `actor` 以符合 Swift 6 要求。

## ⚠️ 架构审计状态（2026-05-13 更新）
经过代码重构，已基本清除 L1/L2 层对 SwiftUI 的直接依赖。

| 类型 | 状态 | 涉及文件 / 说明 |
|:--- |:--- |:--- |
| **跨层 UI 引用** | ✅ 已修复 | `PDFProcessor.swift`, `SynthesisStore.swift` 等已剥离 Color/withAnimation |
| **import 管理** | ✅ 已修复 | `IngestStore`, `SearchStore`, `LLMService` 等已移除 `import SwiftUI` |
| **单例泛滥** | 🟡 正在迁移 | `HapticFeedback` 已支持 DI 但部分存量代码仍使用 `.shared` |
| **ViewModel 覆盖率** | 🟡 持续重构 | 核心页面已覆盖，小型功能视图逻辑仍在持续剥离 |

### 重构经验记录
1. **表现层扩展 (UI Extensions)**：当模型或服务需要定义颜色、图标等 UI 属性时，在 `Views/Styles/` 目录下创建 `Model+UI.swift` 扩展，确保逻辑层纯粹性。
2. **Observation 框架**：在 L1/L2 层，使用 `import Observation` 替代 `import SwiftUI` 来获取 `@Observable` 能力。
3. **解耦动画**：`withAnimation` 应留在 View 层或 ViewModel 层，Service 层仅负责数据状态变更。
