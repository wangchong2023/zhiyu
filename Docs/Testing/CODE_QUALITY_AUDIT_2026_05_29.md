# ZhiYu 代码质量与架构深度审计报告
> **审计日期**: 2026-05-29

**代码规模**: 467 文件 / 64775 行 Swift 源码

## 一、模块与文件划分 (SRP & File Size)
发现 **58** 个大文件(>300行)。超大文件通常违反单一职责原则(SRP)，建议拆分。
| 文件路径 | 行数 |
| :--- | :---: |
| `Shared/DesignSystem/DesignSystem.swift` | 878 |
| `Features/Knowledge/Ingest/View/Components/IngestViewComponents.swift` | 660 |
| `Infrastructure/Storage/Persistence/DatabaseManager.swift` | 656 |
| `Features/Insight/Lint/View/LintView.swift` | 630 |
| `Features/System/Settings/View/SystemStatsView.swift` | 628 |
| `Infrastructure/Processors/Document/MarkdownProcessor.swift` | 627 |
| `Features/AI/Synthesis/View/SynthesisView.swift` | 626 |
| `Features/Knowledge/Graph/View/Components/GraphComponents.swift` | 592 |
| `Infrastructure/Storage/Sync/AppCloudSyncService.swift` | 568 |
| `App/Store/AppStore.swift` | 549 |
| `Features/Knowledge/Graph/View/Components/Graph3DComponents.swift` | 549 |
| `Features/Knowledge/Graph/View/Graph3DView.swift` | 545 |
| `Features/Knowledge/Search/View/SearchView.swift` | 504 |
| `Features/Insight/Dashboard/View/KnowledgeDashboardView.swift` | 496 |
| `App/Views/SidebarRowComponents.swift` | 478 |


## 二、架构合规性与层级解耦 (Architecture & SOLID)
### 1. Domain 层纯净化 (L1.5)
- ✅ Domain 层未发现 UI 或数据库框架硬依赖。

### 2. 上帝对象引用 (AppStore / Router)
发现 **65** 处跨层直接引用 `AppStore`，**31** 处引用 `Router`。
前 5 处 AppStore 跨层调用：
- `Platforms/watchOS/WatchDictationView.swift:45`
- `Features/Insight/Lint/View/LintView.swift:28`
- `Features/Insight/Lint/View/LintView.swift:442`
- `Features/Insight/Lint/View/LintView.swift:499`
- `Features/Insight/Lint/View/LintView.swift:531`

### 3. Shared 层越界依赖
- ✅ Shared 层未直接 import 业务层。

## 三、多端适配层与宏治理 (#if os)
全工程仍散落 **147** 处 `#if os()` 宏。理想状态下业务层不应包含平台宏，应通过注入或 Coordinator 屏蔽差异。
| 包含平台宏的文件 | 数量 |
| :--- | :---: |
| `App/ModuleRegistrar.swift` | 15 |
| `Platforms/iOS/ActivityService.swift` | 5 |
| `Platforms/iOS/PencilManager.swift` | 5 |
| `Shared/UIComponents/Editors/MermaidWebView.swift` | 5 |
| `Features/Knowledge/Ingest/View/PDFReaderView.swift` | 4 |
| `App/Views/AppLayoutComponents.swift` | 3 |
| `Features/Insight/Log/View/LogView.swift` | 3 |
| `Features/Knowledge/Ingest/View/Components/PDFComponents.swift` | 3 |
| `Shared/UIComponents/Overlays/LockOverlayView.swift` | 3 |
| `Shared/UIComponents/Editors/MarkdownTextView.swift` | 3 |

## 四、中文注释覆盖率 (Documentation)
发现 **2** 个文件缺失中文文件头注释。
- `Features/System/Auth/Strategy/GitHubAuthStrategy.swift`
- `Localization/Extensions/L10n+Network.swift`

## 五、清理与坏味道 (Clean Code)
### 1. 魔法字符串与硬编码
- **SF Symbols**: 发现 21 处直接使用 `systemName:`。
  - `Platforms/iOS/Widgets/AIProcessingActivityWidget.swift:22` -> `Image(systemName: "sparkles")`
  - `Platforms/iOS/Widgets/AIProcessingActivityWidget.swift:52` -> `Image(systemName: "sparkles")`
  - `Platforms/iOS/Widgets/AIProcessingActivityWidget.swift:106` -> `Image(systemName: "sparkles")`
  - `Platforms/iOS/Widgets/AIProcessingActivityWidget.swift:122` -> `Image(systemName: "sparkles")`
  - `Platforms/iOS/Widgets/KnowledgeStatsWidget.swift:130` -> `Image(systemName: "books.vertical.fill")`
- **UserDefaults Magic Keys**: 发现 2 处硬编码。
  - `Core/Base/Utils/Localized.swift:76` -> `get { LanguageMode(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.languageMode) ?? "auto") ?? .auto }`
  - `App/Router.swift:208` -> `var selectedTab: AppTab = AppTab(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.selectedTab) ?? "") ?? .knowledge {`

### 2. 调试残留
- 发现 **104** 处 `print()` 调用，应替换为标准日志库(Logger)。

## 六、总结与重构建议

1. **清理废弃代码**：移除所有的 `print` 和多余的测试残留。
2. **消灭上帝对象**：当前 Features 对 `AppStore` 和 `Router` 存在大量跨层引用，建议在 Core 层声明 `AppStoreProtocol` 以解耦。
3. **治理大文件**：拆分 `DesignSystem.swift` 和 600行以上的 `View` 或 `Manager`。
4. **消除宏和魔法字符串**：将 `systemName` 收敛至 `DesignSystem`，`UserDefaults` 收敛至专用 Storage 组件。
