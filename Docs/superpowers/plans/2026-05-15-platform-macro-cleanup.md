# 100% 架构达标：平台预编译宏深度清理计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 彻底清除业务逻辑层 (L0-L2) 中的所有散落的 `#if os()` 宏，将平台差异化逻辑完全下沉至 `Platforms/` 层，实现“逻辑层平台无关，表现层平台透明”的目标。

**Architecture Principles:**
1. **彻底解耦**: L0-L2 层只允许存在逻辑，严禁引用平台 SDK (UIKit/AppKit/WatchKit)。
2. **物理隔离**: 平台特有代码必须存放在 `Sources/Platforms/<Platform>/` 目录下。
3. **协议驱动**: 任何跨平台能力差异必须通过协议注入解决。

---

### Task 1: 工作流能力协议化 (Reminders)

**Files:**
- Create: `Sources/Core/Protocols/ReminderServiceProtocol.swift`
- Create: `Sources/Platforms/iOS/iOSReminderService.swift`
- Modify: `Sources/Core/Workflow/WorkflowService.swift`
- Modify: `Sources/App/ModuleRegistrar.swift`

- [x] **Step 1: 定义 ReminderServiceProtocol**
- [x] **Step 2: 实现 iOSReminderService**
- [x] **Step 3: 重构 WorkflowService**
- [x] **Step 4: 在 ModuleRegistrar 中注册**

### Task 2: 工具类物理归位与宏清理

**Files:**
- Move: `Sources/Core/Utils/UINavigationController+PopGesture.swift` -> `Sources/Platforms/iOS/Extensions/UINavigationController+PopGesture.swift`
- Modify: `Sources/Features/Collaboration/Service/CollaborationService.swift`

- [x] **Step 1: 物理移动 iOS 特有工具类**
- [x] **Step 2: 清理 CollaborationService 头部**

### Task 3: 导出服务架构对齐 (WebViewExport)

**Files:**
- Create: `Sources/Core/Protocols/ExportServiceProtocol.swift`
- Modify: `Sources/Infrastructure/Storage/Export/WebViewExportService.swift`
- Modify: `Sources/App/ModuleRegistrar.swift`

- [x] **Step 1: 提取 ExportServiceProtocol**
- [x] **Step 2: 拆分实现** (已迁移至 `iOSExportService.swift`)

### Task 4: 彻底隔离 PDFKit

**Files:**
- Modify: `Sources/Infrastructure/Storage/Persistence/AppStore.swift`
- Modify: `Sources/Features/Ingest/View/PDFReaderView.swift`

- [x] **Step 1: 清理 AppStore 中的 PDFKit 残留**
- [x] **Step 2: 提取 PDF 视图逻辑** (已迁移至 `Platforms/iOS/Views/PDFKitRepresentedView.swift`)

### Task 5: 额外清理与归档优化

- [x] **Step 1: 提取 FileArchiverProtocol** (消除 `PPTXProcessor` 中的平台依赖)
- [x] **Step 2: 提取 SearchIndexerProtocol** (消除 `SpotlightService` 中的平台依赖)
- [x] **Step 3: 移除全工程逻辑层中剩余的 #if 宏** (通过 grep 验证 L0-L2 逻辑层已完全纯净)

---
**Verification Plan:**
1. [x] 编译全平台 Target。
2. [x] 使用 `grep` 验证 `Sources/Core`, `Sources/Infrastructure`, `Sources/Features` 下不再存在违反规范的 `#if os()`。
3. [x] 验证提醒事项、协作名展示、PDF 预览、文档导出等功能是否正常。
