# 全项目代码质量综合分析报告

> 生成日期：2026-06-10
> 扫描范围：564 个 Swift 源文件，~92K 行代码 (不含 Tests 17K 行)
> 分析方法：逐文件夹深度扫描，18 项代码质量准则

---

## 目录

1. [整体健康度评分](#1-整体健康度评分)
2. [P0 — 阻塞性问题](#2-p0--阻塞性问题)
3. [P1 — 严重违规](#3-p1--严重违规)
4. [P2 — 中等严重度](#4-p2--中等严重度)
5. [P3 — 建议改进](#5-p3--建议改进)
6. [跨层访问违规](#6-跨层访问违规)
7. [层内违规明细](#7-层内违规明细)
8. [文件/模块健康度矩阵](#8-文件模块健康度矩阵)
9. [SOLID 原则违规汇总](#9-solid-原则违规汇总)
10. [平台适配分析](#10-平台适配分析)
11. [本地化 L10n 审计](#11-本地化-l10n-审计)
12. [测试质量审计](#12-测试质量审计)
13. [响应式架构迁移进度](#13-响应式架构迁移进度)
14. [废弃/死代码清单](#14-废弃死代码清单)
15. [优先修复路线图](#15-优先修复路线图)

---

## 1. 整体健康度评分

| 维度 | 评分 (0-10) | 主要问题 |
|------|-------------|----------|
| 架构分层 | 7.5 / 10 | L0 协议引用 L3 类型、Domain Layer import GRDB |
| SOLID 遵循 | 7.0 / 10 | SRP 违反 (God Class)、DIP 违反 (直接依赖具体实现) |
| 中文注释 | 9.0 / 10 | 一致性极佳，少量模板化注释 |
| 命名规范 | 8.5 / 10 | 基本一致，少量模糊命名 |
| 魔鬼数字/字符串消除 | 7.5 / 10 | 桌面端 Tokens 覆盖 ~85%，但仍有遗留 |
| 本地化 L10n | 8.5 / 10 | 架构合规，少量视图残留硬编码 |
| 并发安全 | 6.5 / 10 | 大量 @unchecked Sendable 需要审计 |
| 平台适配 | 6.0 / 10 | 39 个 #if os 散落，Adaptor 层不完整 |
| 测试质量 | 7.0 / 10 | XCTest-only，无 swift-testing，缺边界测试 |
| 废弃代码消除 | 7.5 / 10 | 少量死代码/空桩/注释残留 |
| **综合** | **7.5 / 10** | **整体良好，需系统性修复** |

---

## 2. P0 — 阻塞性问题

### P0-1: `ServiceContainer` 并发隐患 (Core/Base)

- **文件**: `Sources/Core/Base/ServiceContainer.swift:17`
- **问题**: `@unchecked Sendable` + `os_unfair_lock` 非原子化屏障存在 TOCTOU 窗口
- **建议**: 迁移至 `actor ServiceContainer`

### P0-2: `AppStore` God Class (App/Store)

- **文件**: `Sources/App/Store/AppStore.swift` — 554 行
- **问题**: 持有 10+ `@Inject` 属性，管理 4 个子 Store，实现 3 个协议扩展，SRP 严重违反
- **建议**: 拆分到独立扩展/文件

### P0-3: `SidebarRowComponents.swift` 多个视图 (App/Scenes/Layout)

- **文件**: `Sources/App/Scenes/Layout/Components/SidebarRowComponents.swift` — 453 行
- **问题**: 1 个文件包含 12 个独立视图结构体 + 1 个 ViewModifier
- **建议**: 拆分为 4-5 文件

### P0-4: 模型重复定义 (App/Store)

- **文件**: `AppStore.swift:25-68` + `AppModels.swift:17-61`
- **问题**: `ToolItem`、`CoachMarkType`、`KnowledgeGrowthPoint` 在两个文件中重复定义
- **建议**: 统一至 `AppModels.swift`

### P0-5: `RouterProtocol` 跨层引用 (Core → App)

- **文件**: `Sources/Core/Base/Protocols/RouterProtocol.swift:41,48`
- **问题**: L0 的 `RouterProtocol` 引用了 L3 的 `ToolItem` 和 `AppTab`
- **建议**: 将依赖类型定义下移至 Core 层，或使用泛型抹除

### P0-6: `DatabaseManager` 使用 NSLock (Infrastructure/Storage)

- **文件**: `Sources/Infrastructure/Storage/Engine/DatabaseManager.swift:31`
- **问题**: Swift 6 严格并发模式下 NSLock 被禁止
- **建议**: 替换为 `os_unfair_lock` 或 `actor`

### P0-7: Domain Models 直接 import GRDB (Domain/Models)

- **文件**: `RAGModels.swift:12`、`PluginRecord.swift:12`、`PluginRecordFTS.swift:12`
- **问题**: Domain 层依赖 L0 持久化框架，违反 DIP
- **建议**: 在 L1 层创建独立 GRDB Record 封装

### P0-8: `VaultService` import SwiftUI + GRDB (Features/Knowledge)

- **文件**: `Sources/Features/Knowledge/Vault/Service/VaultService.swift:13-14`
- **问题**: L2 业务服务同时依赖 L0 (GRDB) 和 L3 (SwiftUI)
- **建议**: 移除 `import SwiftUI`；GRDB 操作抽取到 L1 Repository

### P0-9: `SourceView.swift` 硬编码本地化字符串 (Features/Knowledge)

- **文件**: `Sources/Features/Knowledge/SourceView/View/SourceView.swift:43,46,69`
- **问题**: 3 处 `Text("key")` 直接使用 localization key 绕过 L10n 网关
- **建议**: 替换为 `Text(L10n.SourceView.xxx)`

---

## 3. P1 — 严重违规

### 跨层违规 (5 处)

| 文件 | 行号 | 源层 → 目标 | 说明 |
|------|------|-------------|------|
| `Core/Base/Protocols/LLMProtocols.swift` | 29 | L0 → L2 | L0 协议引用 Domain 类型 |
| `Infrastructure/Storage/Sync/iCloudSyncCoordinator.swift` | 21-22 | L1 → L3 | 同步协调器引用 App layer 类型 |

### 中文注释质量问题

| 文件 | 问题 |
|------|------|
| `AppStore.swift:297-300` | 中英混排 `启动Time`、`结束Time` |
| `AppStore.swift:211-258` | 参数中文占位符 `- Parameter title: title` |
| `Logger.swift:79-132` | 协议扩展默认实现存在潜在递归风险 |
| `StubWatchSyncService.swift:19-28` | 无意义自我重复注释 `- Parameter text: text` |

### `@unchecked Sendable` 滥用 (10+ 处)

| 文件 | 说明 |
|------|------|
| `ServiceContainer.swift:17` | 应改为 actor |
| `SecurityManager.swift:16` | 内部使用 NSLock 但声明 @unchecked Sendable |
| `IntentRateLimiter.swift:15` | 同上 |
| `LLMService.swift` 系列 | 14+ 个类使用 @unchecked Sendable |
| `PluginRegistry.swift` | 单文件 654 行 God Class |
| `OnDeviceLLMService.swift` | ~500 行 |

### 魔鬼字符串 (4 处)

| 文件 | 行号 | 字符串 | 建议 |
|------|------|--------|------|
| `ZhiYuApp.swift:121` | 121 | `"refresh_token"` | 使用 `AppConstants` |
| `DeepLinkService.swift:40` | 40 | `"zhiyu"` (URL scheme) | 使用 `AppConstants` |
| `DeepLinkService.swift:93` | 93 | `"com.zhiyu.app.openPage"` | 使用 `AppConstants` |
| `LogAction.swift` | — | rawValue 命名不一致 | 统一前缀 |

### 平台适配 #if os 散落 (39 处)

| 文件 | 数量 | 严重度 |
|------|------|--------|
| `PlatformModifiers.swift` | **13** | P1 |
| `MermaidWebView.swift` | 5 | P2 |
| `DesignModifiers.swift` | 3 | P2 |
| `MarkdownTextView.swift` | 3 | P2 |
| 其他 | 15 | P2-P3 |

### 过大文件 (≥500 行, 排除 Tokens)

| 文件 | 行数 | 模块 |
|------|------|------|
| `SynthesisView.swift` | **626** | Features/AI |
| `AppStore.swift` | **554** | App/Store |
| `PluginRegistry.swift` | **654** | Infrastructure/Plugins |
| `LintView.swift` | **630** | Features/Insight |
| `SidebarRowComponents.swift` | **453** | App/Scenes/Layout |
| `GraphView.swift` | **385** | Features/Knowledge |
| `SearchSheets.swift` | **382** | Features/Knowledge |
| `MarkdownRendererView.swift` | **449** | Shared/UIComponents |
| `Logger.swift` | **388** | Core/System |
| `ChatView.swift` | **324** | Features/AI |

---

## 4. P2 — 中等严重度

### 设计模式问题

| 文件 | 问题 | 建议 |
|------|------|------|
| `KnowledgePageManager.swift` | 7 种职责集于一身 | 拆分为 4-5 个独立服务 |
| `ChatCoordinator.swift` | 14 个状态属性 (导航+业务重叠) | 业务状态迁移至 Store |
| `@Inject` 属性包装器 | 隐式全局 Service Locator | 编译期无法验证依赖 |
| `AppLayoutComponents.swift` | `mainContent` 嵌套 5 层条件分支 | 策略模式 |

### 代码重复

| 位置 | 说明 |
|------|------|
| `resolveOptional` + `optionalResolve` | `ServiceContainer.swift` 中签名相同的 2 个方法 |
| `iOSAppEnvironment.swift:55-59` + `MacAppEnvironment.swift:28-32` | `appVersion` 完全相同 |
| `L10n+Common.swift` | `Stat` (107行) 和 `Stats` (118行) 有重叠属性 |

### 硬编码数值

| 文件 | 行号 | 硬编码值 |
|------|------|----------|
| `AppCard.swift` | 多处 | `.frame(width: 120, height: 120)` |
| `AppEmptyState.swift` | 66,70,83 | 硬编码 frame 尺寸 |
| `AppErrorView.swift` | 47,59,64,82,93 | 系统字号、硬编码圆角 |
| `AppTextEditor.swift` | 48,57,84 | `.system(size: 15)` 等 |
| `NotebookThemeFactory.swift` | 17-27 | 6 组十六进制颜色 |
| `RAGEvaluationView.swift` | 301 | `cornerRadius: 3` |
| `SplashComponents.swift` | 56-60 | `Color(red: 0.04, ...)` |

### 测试问题

| 问题 | 严重度 |
|------|--------|
| 100% XCTest，零 swift-testing 迁移 | P2 |
| `Tests/Boundary/` 目录不存在 (文档提及但缺失) | P2 |
| 5 个测试文件 > 500 行 | P2 |
| UI 测试仅限 iOS | P2 |

### 并发问题

| 文件 | 问题 |
|------|------|
| `LLMService` | 10+ `@Published` 属性共享同一 actor 边界 |
| `ChatLLMService.generate()` | 每次调用创建新的 `LLMClient` |
| `dbWriter` | 4 个 Repository 有重复的动态 `dbWriter` 实现 |
| `AIAnalyticsService` | XCTest 检测 hack |

---

## 5. P3 — 建议改进

### 文件/函数尺寸

| 文件 | 问题 |
|------|------|
| `AppRows.swift` | 10 个组件在 1 个文件 (190 行) |
| `AppToast.swift` | 6 种职责 (model, manager, view, modifier, ext) |
| `AppCard.swift` | 5 个独立 Card 变体 |
| `DesignModifiers.swift` | 3 个不相关 modifier |
| `WorkflowService.syncToReminders` | 72 行函数 (超 40 行阈值) |

### 死代码

| 文件 | 代码 | 说明 |
|------|------|------|
| `Logger.swift:171-176` | `setupSubscriptions()` 空 sink | 订阅了语言变更但不处理 |
| `AppKeyboardShortcuts.swift` | 整个文件 | 只有 Action 枚举未注册快捷键 |
| `AppStore.swift:552` | `clusters { [] }` | 硬编码返回空数组 |
| `OnboardingService.swift:94-97` | `completeOnboarding = finish()` | 冗余转发 |
| `AppWindowSceneDelegate.swift` | 5 个空 scene 回调 | 只存框架要求 |
| `DemoDataGenerator.swift:130` | `generateStressTest` 空内容循环 | 未实现 |
| `iOSSecurityScopedStorage.swift:62-68` | `restoreURL()` 返回 nil | 空实现 |

### 合并建议

| 模块 | 建议 |
|------|------|
| `ModuleRegistrar` + `PlatformRegistrar` | 几乎相同签名的协议，可合并 |
| `AppLayoutComponents.swift` | `#if os` 条件编译迷宫，可策略模式化 |
| `ZipUtility.swift` | 自实现 ZIP 解压，考虑系统库替代 |

---

## 6. 跨层访问违规

### 已确认违规 (影响架构完整性)

| # | 源文件 | 层 | 引用了 | 目标层 | 说明 |
|---|--------|-----|--------|--------|------|
| 1 | `Core/Base/Protocols/RouterProtocol.swift` | **L0** | `ToolItem` (AppStore/AppModels) | **L3** | 路由协议引用 App 层类型 |
| 2 | `Core/Base/Protocols/RouterProtocol.swift` | **L0** | `AppTab` (App/AppTab.swift) | **L3** | 同上 |
| 3 | `Core/Base/Protocols/LLMProtocols.swift:29` | **L0** | Domain 协议 | **L2** | 基础设施协议引用领域类型 |
| 4 | `Infrastructure/Storage/Sync/iCloudSyncCoordinator.swift:21-22` | **L1** | App/Store/AppStore | **L3** | 存储层引用 UI 层 |
| 5 | `Domain/Models/RAGModels.swift:12` | **L1.5** | `import GRDB` | **L0** | 领域模型依赖存储框架 |
| 6 | `Domain/Models/PluginRecord.swift:12` | **L1.5** | `import GRDB` | **L0** | 同上 |
| 7 | `Domain/Models/PluginRecordFTS.swift:12` | **L1.5** | `import GRDB` | **L0** | 同上 |
| 8 | `Features/Knowledge/Vault/Service/VaultService.swift:13-14` | **L2** | `import GRDB` + `import SwiftUI` | **L0+L3** | 业务服务双跨层 |
| 9 | `Features/Knowledge/System/Model/KnowledgeStore.swift:11` | **L2** | `import SwiftUI` | **L3** | 非 View 文件引入 UI 框架 |
| 10 | `Features/Knowledge/NotebookHub/Model/NotebookThemeFactory.swift:12` | **L2** | `import SwiftUI` | **L3** | 同上 |
| 11 | `Features/Knowledge/NotebookHub/ViewModel/NotebookHubViewModel.swift:13` | **L2** | `import SwiftUI` | **L3** | 同上 |
| 12 | `Features/Knowledge/Graph/ViewModel/GraphViewModel.swift:11` | **L2** | `import SwiftUI` | **L3** | 同上 |
| 13 | `Features/Knowledge/Ingest/Coordinator/IngestCoordinator.swift:11` | **L2** | `import SwiftUI` | **L3** | 同上 |

### 边界案例 (策略性权衡)

| 文件 | 引用 | 说明 |
|------|------|------|
| `Domain/Models/PageType.swift` | `L10n.CoreModels.xxx` | Domain 模型自带 displayName，可接受 |
| `Domain/Models/VaultTheme.swift` | `L10n.Shared.themeStandard` | 同上 |
| `KnowledgePageFTS.swift` | `import GRDB` | FTS5 虚拟表映射需要 FetchableRecord |

---

## 7. 层内违规明细

### L0 — Core (75 文件, 5574 行)

| 问题 | 数量 |
|------|------|
| `@unchecked Sendable` | 7 处 |
| `NSLock` 保留 | 1 处 (SecurityManager) |
| 未使用 `import Combine` | 3 文件 |
| 魔鬼字符串 | 3 处 (AppConstants 缺失) |
| 死代码 | 3 处 (Logger subscriptions, AppKeyboardShortcuts, etc.) |
| 文件头注释与内容不符 | 5 文件 |

### L0-L1 — Infrastructure (84 文件, 13831 行)

| 问题 | 数量 |
|------|------|
| God Class | 2 个 (PluginRegistry 654行, OnDeviceLLMService ~500行) |
| NSLock 使用 | 1 处 (DatabaseManager, 违反 Swift 6) |
| `@unchecked Sendable` | 14+ 类 |
| 重复 `dbWriter` 模式 | 4 个 Repository |
| print() 调试日志 | 42 处 |
| JSDoc 风格注释 | 2 文件 (TextChunkerProcessor, 等) |

### L1.5 — Domain (48 文件, 3670 行)

| 问题 | 数量 |
|------|------|
| import GRDB | 3 文件 (健康度 🟡) |
| import Combine (未使用) | 2 文件 |
| God Class | 1 个 (KnowledgePageManager, 7 种职责) |
| L10n 引用 | 2 文件 (策略性可接受) |
| **整体健康度** | 🟢 |

### L2-L3 — Features (150 文件, 29553 行)

| 子模块 | 文件数 | 健康度 | 主要问题 |
|--------|--------|--------|----------|
| Features/AI/Chat | 7 | 🟡 | 协调器臃肿, UserDefaults 直写 |
| Features/AI/Synthesis | 6 | 🟡 | 626 行超大视图 |
| Features/AI/Quiz | 2 | 🟢 | - |
| Features/Knowledge/Graph | 14 | 🟡 | 硬编码字符串, 大型视图 |
| Features/Knowledge/Ingest | 16 | 🟢 | - |
| Features/Knowledge/NotebookHub | 7 | 🟡 | SwiftUI 在非 View 文件, 颜色硬编码 |
| Features/Knowledge/Vault | 2 | 🟠 | P1 双跨层违规 |
| Features/Knowledge/SourceView | 2 | 🟠 | P1 硬编码本地化字符串 |
| Features/Insight | ~20 | 🟡 | LintView 630行 |
| Features/System | ~30 | 🟢 | Auth Strategy 模式良好 |

### L3 — App (20 文件, 3668 行)

| 问题 | 数量 |
|------|------|
| God Class (AppStore) | 1 |
| 文件 > 300 行 | 4 |
| #if os 条件编译 | 5+ 处 (AppLayoutComponents) |
| 中英混排注释 | 3+ 处 |

### L3 — Shared (96 文件, 10105 行)

| 问题 | 数量 |
|------|------|
| #if os 散落 | 39 处 |
| SRP 违反 (多组件文件) | 5 文件 (AppRows, AppToast, AppCard, etc.) |
| 硬编码数值 | 10+ 处 (AppErrorView, AppTextEditor, etc.) |
| 文件 > 300 行 | 5 文件 (Design tokens 可接受) |
| DesignModifiers 重复背景模式 | 3 种相似 RoundedRectangle.stroke |

---

## 8. 文件/模块健康度矩阵

```
模块                  文件数  P0  P1  P2  P3  健康度
─────                 ─────  ──  ──  ──  ──  ─────
Core/                   75   1   4   6   8   🟡
Infrastructure/         84   2   8  10   6   🟡
├── LLM/               21   0   4   3   1   🟡
├── Storage/           30   1   2   3   2   🟡
├── Plugins/            8   0   1   2   1   🟡
├── Processors/        13   0   0   2   2   🟢
└── VectorDB/           2   1   1   0   0   🟡
Domain/                 48   3   1   2   2   🟡
App/                    20   4   3   3   5   🟠
Features/AI/            23   0   2   5   3   🟡
Features/Knowledge/     57   2   5   8   4   🟡
Features/Insight/      ~20   0   2   4   2   🟡
Features/System/       ~30   0   1   3   2   🟢
Shared/                 96   0   3  12  15   🟡
├── DesignSystem/      10   0   0   0   3   🟢
├── UIComponents/      72   0   2  10  10   🟡
└── Platforms/Adaptor/  1   0   1   2   1   🟠
Platforms/              50   0   0   2   3   🟢
Localization/           41   0   0   1   2   🟢
Tests/                  93   0   1   5   3   🟡
────────────────────────────────────────────────
总计                   564   9  26  52  48   🟡
```

---

## 9. SOLID 原则违规汇总

### SRP — 单一职责原则违反

| 严重度 | 文件 | 职责数 | 违规说明 |
|--------|------|--------|----------|
| P0 | `AppStore.swift` (554行) | 10+ | Store + 协议扩展 + 转发方法 |
| P0 | `SidebarRowComponents.swift` (453行) | 12+ | 12 视图结构体 |
| P1 | `PluginRegistry.swift` (654行) | 8+ | 注册 + 查询 + 沙箱 + 验证 |
| P1 | `LLMService` | 10+ | 推理 + 配置 + 状态管理 |
| P2 | `KnowledgePageManager.swift` | 7 | CRUD + 撤销 + 处理器 + 标签 |
| P2 | `ChatCoordinator.swift` | 3 | 导航 + 状态 + 业务 |
| P2 | `AppToast.swift` | 6 | Model + View + Modifier + Manager |
| P3 | `AppRows.swift` | 10 | 10 个不同组件 |

### OCP — 开闭原则违反

| 文件 | 问题 |
|------|------|
| `SidebarRowComponents.swift` | 添加新工具需修改现有文件 |
| `AppLayoutComponents.swift` | 新平台需添加 #if os 分支 |
| `PlatformModifiers.swift` | 每个 modifier 都有 #if os 分支 |

### DIP — 依赖倒置原则违反

| 文件 | 问题 |
|------|------|
| `Domain/Models/RAGModels.swift` | 依赖 GRDB 具体类而非协议 |
| `VaultService.swift` | 依赖 GRDB + SwiftUI 具体框架 |
| `@Inject` 模式 | 全局 Service Locator 反模式 |
| `AIWorkflowStore.swift` | 直接访问 `UserDefaults.standard` |

### ISP — 接口隔离原则违反

| 文件 | 问题 |
|------|------|
| `RouterProtocol.swift` | 包含 NavigationPath 和 SwiftUI 关联类型 |
| `AppStore.swift` | 实现 3 个不相关的协议扩展 |

---

## 10. 平台适配分析

### Adaptor 层状态

- **`Shared/Platforms/Adaptor/`** 仅 1 个文件 (`CrossPlatform.swift`, 59 行)
- `AppPasteboard`: 使用 `PasteboardProtocol` DI (✅ 正确模式)
- `AppImage`: 使用 `#if os` 宏 (❌ 应通过 ViewFactory)
- `AppScreen`: 使用 `#if os(watchOS)` (❌ 未抽象)

### 缺失的适配器

| 当前方式 | 问题 | 建议 |
|----------|------|------|
| `UIImpactFeedbackGenerator` 直用 | iOS-only | `HapticFeedbackProtocol` via @Inject |
| `PlatformModifiers.swift` 13 个 #if os | 散落 | `AppPlatformAdapter` 协议 |
| `MarkdownTextView` 3 个 #if os | 散落 | 环境注入 |

### 跨平台复用率

| 维度 | iOS | macOS (Catalyst) | watchOS |
|------|-----|------------------|---------|
| 平台特有文件 | 27 | 5 | 14 |
| 代码复用 | ~85% | ~95% (复用了 iOS 的 PDF 等服务) | ~60% (大量 stubs) |
| 特有行数 | ~2,900 | ~240 | ~1,000 |
| 独立注册器 | iOSPlatformRegistrar | MacPlatformRegistrar | WatchPlatformRegistrar |

### 关键发现

1. `WatchModuleRegistrar` + `WatchPlatformRegistrar` 可能重复注册 (P2)
2. macOS 仅 5 文件 240 行 — Catalyst 复用了大量 iOS 代码
3. watchOS 的 OCR/PDF/Speech 服务都是空桩

---

## 11. 本地化 L10n 审计

### 整体状态

| 指标 | 值 |
|------|-----|
| .xcstrings 文件数 | 16 |
| L10n 扩展文件数 | 41 |
| 硬编码中文 | **0** (架构规则严格执行) |
| 合规度 | ✅ 98% |
| 纯英文硬编码字符串 | 6 处 (P2 违规) |
| 缺失 Key 的字符串 | 3 处 (SourceView) |

### 违规明细

| 文件 | 字符串 | 正确方式 |
|------|--------|----------|
| `SourceView.swift:43` | `Text("Source_View")` | `Text(L10n.Knowledge.SourceView.title)` |
| `SourceView.swift:46` | `Text("Original_Source_Content")` | `Text(L10n.SourceView.originalContent)` |
| `SourceView.swift:69` | `Text("No_Source_Found")` | `Text(L10n.SourceView.noSourceFound)` |
| `Graph3DView.swift:112` | `Text("FPS: \(Int(fps))")` | 需要本地化模板 |
| `Graph3DComponents.swift:25` | `Text("Not Supported")` | `Text(L10n.Common.notSupported)` |
| `Graph3DComponents.swift:533` | `Text("View_Page")` | `Text(L10n.Graph.viewPage)` |
| `SearchSheets.swift:230,260` | `Text("FTS5 SQLite")`, `Text("HNSW / Vector")` | 技术术语需 L10n |
| `AIViewProvider.swift:31` | `Text("Quiz_View")` | `Text(L10n.AI.quizView)` |

### 设计问题

1. `L10n+Common.swift` 中 `Stat`(107行) 与 `Stats`(118行) 混淆
2. `Common.xcstrings` 10,112 行包含标点符号条目 `" "`, `"— "`, `"·"` 作为本地化 key
3. 旧 `.strings` 文件 (en.lproj, zh-Hans.lproj) 与 `.xcstrings` 并存

---

## 12. 测试质量审计

### 测试分布

| 目录 | 文件 | 行数 | 状态 |
|------|------|------|------|
| Unit/ | 49 | ~8,500 | ✅ 覆盖 8 个子模块 |
| Integration/ | 6 | ~2,200 | ✅ 含 RAG/CloudKit/Sync |
| UI/ | 10 | ~3,500 | ⚠️ iOS-only |
| SnapshotTests/ | 1 | ~250 | ✅ |
| Performance/ | 4 | ~500 | ✅ |
| **Boundary/** | **0** | **0** | **❌ 不存在** |
| Shared/ | 5 | ~950 | ✅ 含 TestMocks |

### 严重问题

1. **100% XCTest**, 零 swift-testing 迁移 (P2)
2. **`Tests/Boundary/` 不存在** — 文档提及但实际缺失 (P2)
3. **5 文件 > 500 行**: ZhiYuPlatformUITests (804), ZhiYuE2ETests (802), ZhiYuServiceTests (703), ZhiYuModelTests (547), RAGEvaluationServiceTests (531)
4. UI 测试仅 iOS (缺 macOS/watchOS)

### Mock/Stub 使用

- `Tests/Shared/TestMocks.swift`: 406 行, 提供 Logger/LLMService/CollaborationProvider mocks
- Mock 使用合理, 但 Integration 测试不足 (6 个文件对于 84 个 Infra 文件不够)

---

## 13. 响应式架构迁移进度

### @Observable 迁移状态

| 状态 | 类型 | 模块 |
|------|------|------|
| ✅ 已迁移 | `AppStore`、`Router`、`IngestStore`、`SynthesisStore`、`SearchStore`、`KnowledgeStore` | App、Features |
| ❌ 遗留 `ObservableObject` | `TaskCenter:13`、`MedalService:20`、`IngestQueue`、`CollaborationService` | Features |
| ❌ 遗留 `@EnvironmentObject` | `themeManager` 在 SynthesisView、ChatView、GraphView、SearchSheets 中 | Features |
| ❌ 遗留 `@StateObject`/`@ObservedObject` | `llmService` 在 ChatView 中 | Features |

### Combine 遗留

`import Combine` 仍存在于 5+ 文件中但未使用 (AIWorkflowStore, KnowledgePageManager, ChatCoordinator, 等)

---

## 14. 废弃/死代码清单

| 文件 | 代码 | 状态 |
|------|------|------|
| `Logger.swift:171-176` | `setupSubscriptions()` 空 sink | 🔴 死代码 |
| `AppKeyboardShortcuts.swift` | 整个文件 | 🔴 死代码 |
| `AppStore.swift:552` | `clusters { [] }` | 🔴 未实现 |
| `OnboardingService.swift:94-97` | `completeOnboarding = finish()` | 🟡 冗余 |
| `AppWindowSceneDelegate.swift:50-58` | 5 个空 scene 回调 | 🟡 冗余 |
| `DemoDataGenerator.swift:130` | `generateStressTest` 空内容 | 🟡 未实现 |
| `iOSSecurityScopedStorage.swift:62-68` | `restoreURL()` 返回 nil | 🟡 空实现 |
| `AppConfig.swift:18` | `nonisolated(unsafe) static var` | 🟡 绕过了并发检查 |
| `AppEnvironment.swift:139` | 奇怪字符串拼接 | 🟡 代码风格 |
| `AdaptiveSidebarView.swift:108` | 注释掉的代码 | 🟢 小残留 |

---

## 15. 优先修复路线图

### 阶段 1: 架构违规修复 (P0, 预计 2-4 天)

| # | 任务 | 文件 | 工作类型 |
|---|------|------|----------|
| 1 | 迁移 ServiceContainer 至 actor | `Core/Base/ServiceContainer.swift` | 🔧 重构 |
| 2 | 修复 RouterProtocol 跨层引用 | `Core/Base/Protocols/RouterProtocol.swift` + `AppTab.swift` | 🔧 重构 |
| 3 | 移除 Domain Models 的 GRDB import | `Domain/Models/RAGModels.swift` 等 3 文件 | 🔧 重构 |
| 4 | 清理 VaultService 的 SwiftUI/GRDB import | `Features/Knowledge/Vault/VaultService.swift` | 🔧 清理 |
| 5 | 修复 SourceView 硬编码本地化 | `Features/Knowledge/SourceView/View/SourceView.swift` | 🐛 修复 |
| 6 | 替换 DatabaseManager 的 NSLock | `Infrastructure/Storage/Engine/DatabaseManager.swift` | 🔧 重构 |

### 阶段 2: Code Smell 修复 (P1, 预计 3-5 天)

| # | 任务 | 文件 | 工作类型 |
|---|------|------|----------|
| 7 | 拆分 AppStore God Class | `App/Store/AppStore.swift` | 🔧 重构 |
| 8 | 拆分 SidebarRowComponents | `App/Scenes/Layout/Components/` | 🔧 重构 |
| 9 | 拆分 SynthesisView (626行) | `Features/AI/Synthesis/View/` | 🔧 重构 |
| 10 | 拆分 PluginRegistry (654行) | `Infrastructure/Plugins/` | 🔧 重构 |
| 11 | 消除 @unchecked Sendable | 全局 10+ 文件 | 🔧 重构 |
| 12 | 设备 PlatformModifiers #if os 策略 | `Shared/UIComponents/Modifiers/PlatformModifiers.swift` | 🔧 重构 |
| 13 | 消除 LLM 层的重复 `dbWriter` | `Infrastructure/Storage/Repositories/` 4 文件 | 🔧 重构 |
| 14 | AIWorkflowStore 注入 Repository | `Features/AI/Chat/Model/AIWorkflowStore.swift` | 🔧 重构 |

### 阶段 3: 代码质量提升 (P2, 预计 5-8 天)

| # | 任务 | 文件 | 工作类型 |
|---|------|------|----------|
| 15 | 统一 @Observable 迁移 (遗留 ObservableObject) | TaskCenter, MedalService, IngestQueue 等 | 🔧 迁移 |
| 16 | 合并 AppModels 重复定义 | `App/Store/AppStore.swift` + `AppModels.swift` | 🧹 清理 |
| 17 | 抽取公共 BorderedCapsule modifier | Shared/UIComponents 全局 | 🔧 重构 |
| 18 | 消除硬编码颜色/尺寸 | AppEmptyState, AppErrorView, AppTextEditor 等 | 🐛 修复 |
| 19 | 启动 swift-testing 迁移 | Tests/ 全局 | 🔧 迁移 |
| 20 | 创建 Boundary 测试目录 | Tests/Boundary/ | 📝 新增 |
| 21 | 消除 6 处纯英文硬编码字符串 | Graph3DView, SearchSheets, AIViewProvider | 🐛 修复 |
| 22 | 拆分 KnowledgePageManager | `Domain/Knowledge/KnowledgePageManager.swift` | 🔧 重构 |

### 阶段 4: 持续改进 (P3, 长期维护)

| # | 任务 | 说明 |
|---|------|------|
| 23 | 拆分 AppRows (10 组件) / AppToast (6 职责) / AppCard (5 变体) | SRP 合规 |
| 24 | 移除废弃代码 (Logger 空订阅, AppKeyboardShortcuts, 等) | 代码整洁 |
| 25 | 消除 #if os 在 Shared/UIComponents 的 39 处使用 | 平台适配 |
| 26 | 补充 Adaptor 层缺失的协议 (Haptic, NavigationBar, etc.) | 跨平台 |
| 27 | 修复中英混排注释 | 注释规范 |
| 28 | 合并 Stat/Stats L10n 枚举 | 本地化整洁 |
| 29 | 移除未使用的 import Combine | 导入整洁 |
| 30 | 统一 LogAction rawValue 命名风格 | 命名规范 |

---

> **总结**: 全项目 564 个源文件分析完毕。**P0 问题 9 个，P1 问题 26 个，P2 问题 52 个，P3 问题 48 个。** 最需优先修复的是跨层访问违规 (6 处) 和 Swift 6 并发适配 (10+ 处 @unchecked Sendable)。整体架构设计优秀，执行层面存在历史债务。

<!-- 版本: 1.0.0 / 2026-06-10 -->
