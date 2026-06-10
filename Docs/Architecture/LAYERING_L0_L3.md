# 智宇 (ZhiYu) L0-L3 跨层依赖与调用限制规范

本规范定义了智宇 (ZhiYu) 项目中垂直化功能架构 (Vertical Slices) 各层级之间的物理依赖与调用约束。旨在杜绝反向依赖、削减组件耦合、确保 L1.5 领域层的纯净化，并对齐 Swift 6 严格并发标准。

---

## 1. 架构层级拓扑与核心职责

项目遵循垂直化功能架构，将代码物理划分为以下层级：

| 层级 | 名称 | 物理路径 | 核心职责 | 依赖限制说明 |
| :--- | :--- | :--- | :--- | :--- |
| **L3** | 应用层 (App) | `Sources/App/` | 全局入口、环境配置、路由中心 | 可依赖所有下层组件 |
| **L2** | 业务功能层 (Features) | `Sources/Features/` | 业务域分组的垂直切片，包含 UI 及本地状态 | 仅可依赖 L1.5 及以下，严禁同层级循环依赖 |
| **L1.5** | 领域层 (Domain) | `Sources/Domain/` | **核心业务大脑**：业务规则、RAG 编排、跨模块契约 | **平台无关**！严禁导入 UI 框架或具体基础设施实现 |
| **L1** | 基础设施层 (Infra) | `Sources/Infrastructure/` | 技术实现：LLM 适配、数据库持久化、文档解析 | 严禁依赖 L2/L3，通过协议向上注入服务 |
| **L0.5** | 系统集成层 (System) | `Sources/Core/System/` | 系统能力封装：日志、触感、安全、硬件集成 | 严禁依赖 L1 及以上任何业务层组件 |
| **L0** | 底层基座层 (Base) | `Sources/Core/Base/` | 内核：DI 容器、全局协议定义、基础常量与工具 | 极简内核，无业务逻辑，绝对零外部/上层依赖 |
| **Shared** | 共享标准层 | `Sources/Shared/` | 视觉标准：设计系统、通用 UI 原子组件 | 仅供 UI 视图引用，严禁包含任何业务逻辑 |

---

## 2. 跨层依赖禁用矩阵 (Dependency Matrix)

以下矩阵详细定义了各物理层级之间的引用可行性。**行**代表调用源（Source Layer），**列**代表调用目标（Target Layer）。

| ↘️ 目标 \ ↙️ 源 | L3 (App) | L2 (Features) | L1.5 (Domain) | L1 (Infra) | L0.5 (System) | L0 (Base) | Shared |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **L3 (App)** | - | ✅ 允许 | ✅ 允许 | ✅ 允许 | ✅ 允许 | ✅ 允许 | ✅ 允许 |
| **L2 (Features)** | 🚫 禁用 | ⚠️ 限制<sup>1</sup> | ✅ 允许 | 🚫 禁用<sup>2</sup> | ✅ 允许 | ✅ 允许 | ✅ 允许 |
| **L1.5 (Domain)** | 🚫 禁用 | 🚫 禁用 | - | 🚫 禁用<sup>3</sup> | ✅ 允许 | ✅ 允许 | 🚫 禁用 |
| **L1 (Infra)** | 🚫 禁用 | 🚫 禁用 | ✅ 允许<sup>4</sup> | - | ✅ 允许 | ✅ 允许 | 🚫 禁用 |
| **L0.5 (System)** | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | - | ✅ 允许 | 🚫 禁用 |
| **L0 (Base)** | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | - | 🚫 禁用 |
| **Shared** | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | 🚫 禁用 | ✅ 允许 | - |

> **注解说明**：
> 1. **L2 ↔ L2 同层限制**：不同 Feature 切片（如 PageList 和 Chat）之间严禁强耦合，必须通过 L3 路由中转或 L1.5 领域中介进行解耦通讯。
> 2. **L2 🚫 L1 直接穿透禁用**：UI 视图层严禁直接引用或硬编码具体基础设施实现类（如 `SQLiteStore`）。必须通过 `ServiceContainer` 注入定义在 Base/Domain 中的抽象协议。
> 3. **L1.5 🚫 L1 物理硬编码禁用**：领域层定义规则与接口契约，严禁依赖具体物理实现。
> 4. **L1 ⚠️ L1.5 纯净通信**：L1 只允许导入 L1.5 定义的实体模型 (Domain Models) 和服务契约协议，用以实现协议的具体细节。

---

## 3. 反向依赖与跨层越权红线 (Architectural Violations)

### 红线 1：L1.5 领域层非纯净化 (Domain Purity Violation)
*   **违规行为**：在 `Sources/Domain/` 的任何文件中出现 `import UIKit`、`import AppKit`、`import SwiftUI` 或 `import ActivityKit`。
*   **惩罚机制**：CI 静态检查直接阻断，触发编译熔断。
*   **最佳实践**：如果领域层需要感知系统状态或执行 UI 触发，必须在 `Sources/Core/Base/` 或 `Sources/Domain/Protocols/` 定义协议（例如 `any NotificationDispatcherCapabilities`），并在 App 层或 System 层实现，通过依赖注入机制传入。

### 红线 2：底层（L0/L0.5/L1）反向导入上层（L2/L3）
*   **违规行为**：基础设施、系统封装或基座组件中，直接 `import Features` 或直接引用具体的上层 Store/View（如 `AppStore`、`ChatViewModel`）。
*   **危害**：这将导致严重的循环依赖，导致无法生成独立的静态库，且 Swift 6 严格并发会报数据竞争警告。
*   **最佳实践**：采用**依赖倒置原则 (DIP)**，下层只声明接口，由上层负责实现，并将具体实现注册至 `ServiceContainer` 中。

### 红线 3：UI 视图穿透依赖物理存储引擎
*   **违规行为**：在 SwiftUI 的 View 中直接声明 `let db = DatabaseManager.shared`。
*   **危害**：使 UI 与 SQLite/CloudKit 物理引擎强绑定，无法进行无数据 Mock 的快照测试 (Snapshot Tests) 和单元测试。
*   **最佳实践**：通过 `@Inject var pageStore: any AnyPageStoreCapabilities` 进行协议注入。

---

## 4. 依赖注入与解耦标准模式

为了确保各层级松耦合，推荐使用以下标准解耦模式：

### 4.1 协议定义在下层 (或 L1.5 Domain)
```swift
/// 物理路径: Sources/Domain/Protocols/AI/ChatServiceType.swift
/// 核心业务大脑定义的 AI 对话服务契约
public protocol ChatServiceType: Sendable {
    func sendMessage(_ content: String) async throws -> String
}
```

### 4.2 具体实现在物理下沉层 (L1 Infra)
```swift
/// 物理路径: Sources/Infrastructure/AI/OpenAIChatService.swift
/// 具体的 OpenAI 接入实现
import Foundation

public final class OpenAIChatService: ChatServiceType {
    private let client: any AnyLLMClientCapabilities
    
    public init(client: any AnyLLMClientCapabilities) {
        self.client = client
    }
    
    public func sendMessage(_ content: String) async throws -> String {
        // 具体请求逻辑...
        return "AI Response"
    }
}
```

### 4.3 全局入口注册 (L3 App)
```swift
/// 物理路径: Sources/App/ZhiYuApp.swift
import Foundation

extension ServiceContainer {
    func registerServices() {
        // 注册具体的基础设施实现给对应的抽象服务协议
        register(type: ChatServiceType.self) {
            OpenAIChatService(client: resolve(AnyLLMClientCapabilities.self))
        }
    }
}
```

### 4.4 业务视图解耦引用 (L2 Feature)
```swift
/// 物理路径: Sources/Features/Chat/ChatViewModel.swift
import SwiftUI

@MainActor
public final class ChatViewModel: ObservableObject {
    // 强制只依赖协议，通过 DI 容器自动注入，免除具体类依赖
    @Inject private var chatService: ChatServiceType
    
    @Published public var messages: [String] = []
    
    public func send(text: String) async {
        do {
            let reply = try await chatService.sendMessage(text)
            self.messages.append(reply)
        } catch {
            // 优雅错误处理
        }
    }
}
```

---

## 5. 已知违例案例与修复指引

### 红线 4：L0 基座层引用 L3 应用层类型
*   **违例文件**：`Sources/Core/Base/Protocols/RouterProtocol.swift` (L0)
*   **具体问题**：引用了 `ToolItem` (定义于 `Sources/App/Store/AppModels.swift`, L3) 和 `AppTab` (定义于 `Sources/App/AppTab.swift`, L3)
*   **示例代码**：
    ```swift
    // RouterProtocol.swift (L0) — 不应引用 L3 类型
    func navigateToTool(_ tool: ToolItem)  // ToolItem ∈ L3
    var selectedTab: AppTab { get set }    // AppTab ∈ L3
    var path: NavigationPath               // NavigationPath ∈ SwiftUI
    ```
*   **修复指引**：
    1. 将 `AppTab`、`ToolItem` 等导航相关类型定义迁移至 `Core/Base/Constants/` (L0)
    2. 或将 `RouterProtocol` 泛型化：`protocol RouterProtocol<Tab, Tool>`
    3. 使用 `AnyNavigationPath` 包装器隔离 SwiftUI 依赖

### 红线 5：L1-L2 领域/业务层直接 import 框架实现
*   **违例文件** (共 6 处)：

| 文件 | 层级 | 违规框架 | 修复指引 |
|------|------|----------|----------|
| `Domain/Models/RAGModels.swift:12` | L1.5 | `import GRDB` | 抽取 Record 封装至 L1 |
| `Domain/Models/PluginRecord.swift:12` | L1.5 | `import GRDB` | 同上 |
| `Domain/Models/PluginRecordFTS.swift:12` | L1.5 | `import GRDB` | 同上 |
| `Features/Vault/VaultService.swift:13-14` | L2 | `import GRDB` + `import SwiftUI` | 移除 SwiftUI；GRDB 移至 Repository |
| `Features/Knowledge/System/Model/KnowledgeStore.swift:11` | L2 | `import SwiftUI` | 改用 `import Observation` |
| `Features/Knowledge/NotebookHub/Model/NotebookThemeFactory.swift:12` | L2 | `import SwiftUI` | 移除 (仅需 Foundation) |

*   **危害**：领域模型与 GRDB 绑定则无法在不同持久化方案间切换；业务层引入 SwiftUI 则无法在非 UI 上下文中复用。
*   **最佳实践**：
    - Domain Models 保持纯 Swift struct，GRDB 映射在 L1 Repository 中通过 `extension Model: FetchableRecord` 实现
    - 非 View 文件使用 `import Observation` 而非 `import SwiftUI`
    - 所有数据访问通过 Repository 协议 (`Domain/Protocols/*Repository.swift`)

### 红线 6：使用 `NSLock` 而非 actor (Swift 6 严格并发禁止)
*   **违例文件**：`Sources/Infrastructure/Storage/Engine/DatabaseManager.swift:31` — 使用 `NSLock` 保护数据库连接
*   **其他受影响的 @unchecked Sendable 文件** (需审计)：

| 文件 | 声明 | 建议替代 |
|------|------|----------|
| `Core/Base/ServiceContainer.swift` | `@unchecked Sendable` + `os_unfair_lock` | `actor` |
| `Core/System/Security/SecurityManager.swift` | `@unchecked Sendable` + `NSLock` | `actor` 或 `os_unfair_lock` |
| `Core/System/Events/IntentRateLimiter.swift` | `@unchecked Sendable` | `actor` |
| `Core/System/Analytics/LocalAnalyticsService.swift` | `@unchecked Sendable` | `actor` |
| `Infrastructure/LLM/LLMService.swift` 系列 | `@unchecked Sendable` (14+ 类) | 逐类审计改为 actor |
| `PluginEnginePool.swift` | `os_unfair_lock` | 已符合安全，可保留 |

*   **危害**：Swift 6 严格并发模式下 `NSLock` 是非 Sendable 类型，会导致数据竞争警告。`@unchecked Sendable` 将安全检查责任转移给开发者，在大型团队中容易遗漏。
*   **最佳实践**：
    - 有可变状态的单例 → 改为 `actor`
    - 需要 `@MainActor` 隔离的类型 → 标注 `@MainActor final class`
    - 不可变值类型 → 标注 `struct: Sendable`
    - 真正需要 `os_unfair_lock` 的场景 → 封装到独立的 `Locked<T>` 包装器中

---

## 6. 架构门禁自动扫描规范

为了确保规范在团队协作中不被突破，配置以下构建门禁：
1. **XcodeGen 配置**：在 `project.yml` 中将各个子 Slice 划分为独立的 Target。通过限制 `dependencies`，强制实现在编译期拦截不合规依赖。
2. **SwiftLint 脚本拦截**：在 `.swiftlint.yml` 中配置 `custom_rules`，限制物理路径下的非法 `import` 语句。
3. **自定义扫描**：集成 `Tools/Gatekeeper/check_magic_numbers_v2.py` 到 CI，新增 Python 文件扫描。
4. **CodeGraph 集成**：初始化 `.codegraph/` 知识图谱以支持自动化架构违规检测。
