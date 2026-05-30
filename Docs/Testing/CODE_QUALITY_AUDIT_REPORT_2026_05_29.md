# 智宇 (ZhiYu) 全量代码深度审计报告 (2026-05-29)

## 1. 总体评估 (Executive Summary)
经过自动化工具扫描及核心代码精读，智宇项目在架构分层上表现优秀，垂直切片逻辑清晰，DIP（依赖倒置）原则在 Domain 与 Infrastructure 层之间得到了较好的贯彻。然而，在 **App 层注册逻辑**、**持久化层职责划分**以及**部分跨平台适配实现**上存在明显的优化空间。

## 2. 核心审计发现 (Key Findings)

### 2.1 架构与解耦 (Architecture & Decoupling)
- **[问题] ModuleRegistrar 宏膨胀**：`ModuleRegistrar.swift` 中存在大量 `#if os` 分支。虽然实现了功能，但导致注册逻辑与平台环境强耦合，且难以测试。
- **[问题] DatabaseManager 职责过载**：`DatabaseManager` 承担了连接池管理、迁移逻辑（V1-V4）、安全性校验、多金库切换等多种职责，违反了单一职责原则 (SRP)。
- **[问题] AppStore 门面臃肿**：`AppStore` 作为 Facade 模式实现，存在过多的透传方法（Forwarding Methods），且在 `init` 中自我注册到 DI 容器的设计虽然方便，但增加了启动时序风险。

### 2.2 代码质量与设计模式 (Code Quality & Design Patterns)
- **[热点] 巨型函数**：
  - `SidebarRowComponents.asRoute`: 392 行。该函数内部通过庞大的 `switch` 处理路由跳转，应重构为路由表或策略模式。
  - `KnowledgePageListView.triggerSearch`: 382 行。复杂的搜索闭包嵌套。
  - `KnowledgeStatsWidget.calculateTimeline`: 210 行。Widget 端逻辑过重。
- **[优点] DIP 落实**：`ServiceContainer` 与 `@Inject` 的结合使用非常成熟，各层级均能通过协议进行通讯。
- **[改进] 跨平台解耦**：UI 层已开始使用 `AppEnvironmentProtocol` 进行自适应判定，这是一个良好的趋势，应推广至全量 UI 组件。

### 2.3 规范与文档 (Conventions & Docs)
- **[问题] 机械化注释**：部分文档注释由工具自动生成，仅重复了函数名，未解释业务逻辑。
- **[问题] 魔法值残留**：`AppStore.swift` 和 `SidebarView.swift` 中仍存在硬编码的字符串 Key（如 `"graph_discovery"`）。

## 3. 重构建议方案 (Refactoring Roadmap)

### 3.1 拆分 DatabaseManager 迁移逻辑 (SRP 优化)
将 `DatabaseMigrator` 逻辑抽离至独立的 `VaultMigrator` 与 `GlobalMigrator` 结构体中。
```swift
// 建议重构方向
struct VaultMigrator {
    static func apply(to db: DatabaseWriter) throws { ... }
    private static func v1_initial(db: Database) throws { ... }
}
```

### 3.2 路由策略化 (Strategy Pattern)
将 `SidebarRowComponents.asRoute` 的巨型 `switch` 拆分为独立的 `RouteHandler` 策略类。

### 3.3 平台注册器分块 (Modularization)
将 `CoreModuleRegistrar` 拆分为 `iOSCoreRegistrar`, `macOSCoreRegistrar` 等，利用 Swift 的物理文件隔离代替内部宏。

## 4. 后续任务 (Next Steps)
1. [x] 物理拆分 `DatabaseManager.swift` 中的迁移代码。
2. [x] 重构 `SidebarRowComponents.swift` 的路由跳转逻辑。
3. [x] 手工精修核心 API 的中文文档注释。
4. [ ] 消除审计报告中识别出的 Top 50 魔法字符串。

---

## 5. 追加行动：Domain 层全量手动审计 (2026-05-29 后续)
在完成自动化检查与热点治理后，我们启动了针对 `Sources/Domain` (L1.5) 下总计 42 个 Swift 文件的全量逐一精读。主要达成了以下指标：
- **消灭“无业务语义”的机械代码生成注释**：将批量生成的 `"属于 Models 模块，提供相关的结构体或工具支撑"` 等全部替换为真实的业务描述（例如 `KnowledgePageFTS.swift` 被重新定义为 `"定义基于 SQLite FTS5 (全文搜索) 的知识页面虚拟表结构映射模型"`）。
- **层级越界修正**：发现了 `LintIssue.swift` 等模型错误标示为 `[L2] 业务功能层` 的情况，并修正为正确的 `[L1.5] 领域层` 标识。
- **贫血模型向充血模型转移校验**：确认了如 `KnowledgePage.swift` 携带了 `wordCount` 和 `merge(with:)` (LWW 并发冲突解决) 逻辑，充当了合格的充血领域模型。
- **纯净性担保**：再次通过逐文件验证，确认 Domain 内部无 `#if os(iOS)` 等系统宏、无 `SwiftUI` 导入，严格遵守了 DIP 依赖倒置。
