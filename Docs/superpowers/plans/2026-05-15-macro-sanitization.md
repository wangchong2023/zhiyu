# 平台预编译宏规范化与架构对齐计划 (Macro Sanitization)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 贯彻 `LAYERING_L0_L3.md` 中关于平台预编译宏的规范，彻底消除业务逻辑层 (L0-L2) 中的 `#if os()` 嵌套，通过协议注入和职责分离实现优雅的跨平台适配。

**Architecture Principles:**
1. **协议层屏蔽**: 将底层设备信息提取至 `AppEnvironmentProtocol`。
2. **统一门面 (Facade)**: 消除多余的系统能力封装（如 AccessibilityService 里的触感），统一收口。
3. **职责单一**: 将索引逻辑与路由逻辑解耦。

---

### Task 1: 设备环境能力抽象 (AppEnvironment)

**Files:**
- Modify: `Sources/Core/Protocols/AppEnvironmentProtocol.swift`
- Modify: `Sources/App/Environment/iOSAppEnvironment.swift`
- Modify: `Sources/App/Environment/MacAppEnvironment.swift`
- Modify: `Sources/App/Environment/WatchAppEnvironment.swift`
- Modify: `Sources/Features/Collaboration/Service/CollaborationService.swift`

- [x] **Step 1: 扩展 AppEnvironmentProtocol**
    - 添加 `var deviceName: String { get }` 属性。
- [x] **Step 2: 实现各平台环境类**
    - iOS: 返回 `UIDevice.current.name`
    - macOS: 返回 `Host.current().localizedName ?? "Mac"` (如果无法获取使用 "Apple Device")
    - watchOS: 返回 `WKInterfaceDevice.current().name`
- [x] **Step 3: 重构 CollaborationService**
    - 移除 `#if os(iOS)` 获取设备的逻辑。
    - 使用 `@Inject private var appEnv: any AppEnvironmentProtocol`。
    - 在 `userName` 获取时回退到 `appEnv.deviceName`。

### Task 2: 收束触感反馈逻辑 (Haptic)

**Files:**
- Modify: `Sources/Core/Accessibility/AccessibilityService.swift`

- [x] **Step 1: 移除冗余的触感代码**
    - 删除 `AccessibilityService` 中包含 `#if os(iOS)` 的 `playHaptic` 和 `playNotificationHaptic` 静态方法。
    - (注：工程中已有 `HapticFeedbackProtocol` 和基于 DI 的 `HapticFeedback.shared.trigger()`，任何视图需要震动都应使用标准的 `HapticFeedback.shared`)

### Task 3: 解耦 Spotlight 索引与深度链接 (Routing vs Indexing)

**Files:**
- Modify: `Sources/Core/Routing/DeepLinkService.swift`
- Modify: `Sources/Infrastructure/Storage/Search/SpotlightService.swift`
- Modify: `Sources/Infrastructure/Storage/Sync/DataCoordinator.swift`

- [x] **Step 1: 将 Spotlight 逻辑移出 DeepLinkService**
    - 移除 `DeepLinkService` 中的 `indexPages`, `deindexPage`, `deindexAllPages` 方法及其对 `CoreSpotlight` 的导入。
- [x] **Step 2: 完善 SpotlightService**
    - 确保 `SpotlightService` 具有 `indexPage(s:)`, `removeIndex(for:)`, `reindexAll(pages:)` 等方法，并在内部封装好 `#if canImport(CoreSpotlight)`。
- [x] **Step 3: 更新调用方**
    - 将 Spotlight 索引逻辑集成到 `DataCoordinator` 中，确保数据同步时自动更新索引。

---
**Verification Plan:**
1. [x] 编译工程（iOS, macOS, watchOS），确保在各平台下均无编译错误。
2. [x] 检查 `CollaborationService` 和 `AccessibilityService`，确认文件内不再包含 `#if os()` 宏。
3. [x] 验证功能隔离是否清晰。
