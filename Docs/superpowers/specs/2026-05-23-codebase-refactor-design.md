# 智宇 (ZhiYu) 全局工程重构与 Clean Code 设计规约

## 1. 问题背景与目的
本 Spec 针对智宇 (ZhiYu) 知识管理应用（全工程 435 个 Swift 文件，共计 57,041 行代码）进行深度模块化清洗与注释合规化设计。
在快速迭代中，工程累积了部分违反 SOLID 依赖倒置原则、硬编码中文（L10n Leak）引发静态编译门禁错误、多平台宏污染以及中文注释率偏低（45.67%）等架构隐患。
本设计将明确重构标准与子代理分工，确保项目架构的高内聚、低耦合与可读性。

---

## 2. 详细重构方案设计

### 2.1 依赖倒置原则 (DIP) 解耦设计
*   **目标文件**：[VaultService.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Features/Knowledge/Vault/Service/VaultService.swift) 与 [DatabaseManager.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Infrastructure/Storage/Persistence/DatabaseManager.swift)。
*   **问题**：业务功能层 `VaultService` 直接调用持久化层具体单例 `DatabaseManager.shared`。
*   **重构方案**：
    1. 在 `DatabaseManagerProtocol.swift` 中定义抽象协议：
       ```swift
       import Foundation

       /// 数据库热切换与连接生命周期隔离契约
       @MainActor
       public protocol VaultDatabaseSwitcher: Sendable {
           /// 进行多数据库实例的安全切换与 WAL 锁重置
           func switchDatabase(to vaultID: UUID, at url: URL) throws
           /// 彻底断开专属物理库写入池，清空文件锁
           func releaseDatabaseConnection()
       }
       ```
    2. `DatabaseManager` 遵循并实现该协议。
    3. 在 `ModuleRegistrar.swift` 的 `StorageModuleRegistrar` 中注册：
       ```swift
       container.register(DatabaseManager.shared as any VaultDatabaseSwitcher, for: (any VaultDatabaseSwitcher).self)
       ```
    4. 在 `VaultService` 内部，通过依赖注入解析使用：
       ```swift
       @ObservationIgnored
       @Inject private var databaseSwitcher: any VaultDatabaseSwitcher
       ```

### 2.2 硬编码中文字符串 (L10n Leak) 消除设计
本设计遵循【分类精细化治理】原则，确保在源码文件中无直接中文硬编码，从而通过静态编译门禁：
1.  **开发与调试日志**：
    *   将 `ActivityService.swift`、`iOSWatchSyncService.swift`、`SecurityManager.swift`、`WorkflowService.swift` 等系统服务的底层打印和错误日志改写为英文（例：`Logger.shared.debug("Dynamic Island starting activity for task \(id)")`）。
2.  **大模型提示词 (Prompts)**：
    *   在 `Sources/Localization/Extensions/` 下新建 `L10n+AI.swift`，使用静态只读属性向业务层注入中文 Prompts（不在原业务逻辑文件内暴露中文汉字字面量）。
3.  **UI 界面字符**：
    *   `WatchWidgets.swift`、`ZhiYuWatchView.swift` 等 UI 里的硬编码中文剥离，改用 `LocalizedStringResource("watch.widget.title", table: "Watch")` 等无中文字面量的方式加载。

### 2.3 平台宏分支解耦 (View & Domain Purity)
*   **重构点**：`PDFComponents.swift` 和 `MermaidWebView.swift` 等 UI 组件中频繁出现的 `#if os` 分支。
*   **重构方案**：
    *   在 `Sources/Platforms/` 目录下为各平台定义专门的桥接视图包装，统一输出跨平台视图。
    *   业务层 View 直接消费该桥接视图，消灭其内的平台宏编译分支，保证视图与领域逻辑的纯净度。

### 2.4 中文注释覆盖率补足规范
1.  **文件头注释**：对 `JailbreakDetector.swift`、`DatabaseManagerProtocol.swift` 等 12 个关键协议和基座类文件，补充符合项目规范的文件头中文注释。
2.  **方法与逻辑注释**：
    *   所有修改过的方法必须附带规范的 Swift 三斜杠 (`///`) DocC 中文文档注释，明确参数及返回值。
    *   核心代码执行逻辑中，必须在关键分支上补充中文双斜杠 (`//`) 过程说明。

---

## 3. 执行阶段子代理 (Subagents) 分工规划
在进入执行阶段时，我们将启动 3 个并发的 Subagents 处理各自的任务域：

1.  **Subagent-A (DIP 与架构解耦)**：
    *   负责 `DatabaseManagerProtocol.swift` 协议补齐、`DatabaseManager` 与 `VaultService` 重构，并更新 `ModuleRegistrar.swift` 注册。
2.  **Subagent-B (L10n 门禁净化)**：
    *   负责创建 `L10n+AI.swift`；将 `ActivityService`、`WatchWidgets` 等 46 个文件中的中文硬编码日志/Prompt 剥离清理。
3.  **Subagent-C (注释与规范化)**：
    *   负责补齐 12 个关键文件的头部注释与重构区域的 DocC 函数中文注释，规范命名与 KISS 原则调整。

---

## 4. 验证与测试规约 (Systematic Debugging)
- 重构过程中，如遇任何编译、链接或测试错误，严禁盲目试错，必须首先记录堆栈与分析根因，在 [task.md](file:///Users/constantine/.gemini/antigravity-cli/brain/75a6a7b0-0a08-4da1-8dfe-fc66ca7dd71b/task.md) 记录 Root Cause 后方可实施微量修复。
- 自动化运行完整测试套件：
  ```bash
  xcodegen generate
  xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
  ```
