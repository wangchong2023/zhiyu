# 智宇 (ZhiYu) 架构规范：L0-L3 垂直层级反向调用禁止约束表

## 1. 架构设计原则 (Architecture Principles)

智宇 (ZhiYu) 采用**垂直化功能架构 (Vertical Slices)**，将代码按物理职责与业务域执行深层隔离。为防止系统在迭代过程中发生“架构退化”、“编译瓶颈（循环依赖）”、“多平台交叉偶合（watchOS Target 引入 iOS UI 导致编译失败）”以及“单测隔离性崩溃”，特制定本**禁止反向调用约束表**。

系统强制遵循 **正向单向依赖流 (Strict One-Way Dependency Flow)**，即：
> **上层可依赖下层，下层绝不允许以任何显式形式（如 direct import 或直接类名引用）调用上层。**

---

## 2. L0-L3 物理层级依赖边界约束矩阵

本矩阵定义了各物理目录的职责边界、正向依赖权限、以及**红线级禁止项**：

| 层级 (Layer) | 物理路径 (Path) | 核心职责描述 | 允许依赖的下层 (Allowed) | 🚨 绝对禁止引入/调用 (Forbidden) |
| :--- | :--- | :--- | :--- | :--- |
| **L3 应用层** | `Sources/App/` | 应用启动、全局路由与导航编排、DI 服务集中注册、UI 视窗根容器。 | L2, L1.5, L1, L0.5, L0, Shared | **无**（作为顶层容器持有全局） |
| **L2 业务功能层** | `Sources/Features/` | 垂直业务域 UI 视图、ViewModel、本地界面导航协调器（Coordinator）。 | L1.5, L1, L0.5, L0, Shared | 🚨 **禁止** 依赖 L3（如 `AppEnvironment`, `ZhiYuApp`）。<br>🚨 **禁止** 跨垂直业务模块强耦合（例如 AI Feature 严禁导入 Knowledge Feature 的内部 View）。 |
| **L1.5 领域层** | `Sources/Domain/` | **核心大脑**：纯净业务规则、RAG 编排、数据同步协调器。 | L1, L0.5, L0, Shared | 🚨 **禁止** 导入 `UIKit` / `AppKit` / `SwiftUI` 库。<br>🚨 **禁止** 使用 `#if os` 处理平台特定逻辑。<br>🚨 **绝对禁止** 引用 L2 / L3 层的任何类和状态。 |
| **L1 基础设施层** | `Sources/Infrastructure/` | 技术栈具体实现：GRDB 数据库操作、向量存储、LLM 本地/远程通信客户端。 | L0.5, L0, Shared | 🚨 **禁止** 引用 L1.5 的领域业务实现（必须只依赖 L0/L1.5 定义的协议，如 `FileSignatureRepository`）。<br>🚨 **绝对禁止** 调用 L2 / L3。 |
| **L0.5 系统集成层** | `Sources/Core/System/` | 针对特定 OS / 硬件的物理能力封装：指纹/人脸识别、后台任务注册、剪贴板读写、触感驱动。 | L0, Shared | 🚨 **绝对禁止** 导入任何业务域逻辑（如 `KnowledgePage`、`ChatMessage`）。<br>🚨 **绝对禁止** 向上调用 L1 及以上级别。 |
| **L0 底层基座层** | `Sources/Core/Base/` | 内核：DIP 依赖注入容器、系统级常量定义、基础 DTO 结构、跨平台纯净协议。 | Shared | 🚨 **绝对分子级纯净**：除 `Foundation` 外禁止导入任何系统框架（无 SwiftUI/GRDB 依赖）。<br>🚨 **绝对禁止** 引用上层任何具体实现。 |
| **Shared 共享层** | `Sources/Shared/` | 视觉标准定义、调色板、无业务状态的原子 UI 组件（Buttons, Skeletons）。 | L0 | 🚨 **禁止** 持有 any 业务 Store 状态。<br>🚨 **禁止** 调用 L0.5 及以上任何系统/基础设施能力。 |

---

## 3. 反向调用的灾难性后果

1. **冷启动循环依赖闪退 (DI Dependency Cycle Panic)**：
   若 L1.5 领域层或 L2 功能层在初始化时反向解析 L3 的 `AppEnvironment`，将导致 `ServiceContainer` 在冷启动时发生死锁或“Service not registered”的崩溃，破坏整个 DI 链路的鲁棒性。
2. **三端（iOS / macOS Catalyst / watchOS）编译雪崩**：
   在 `project.yml` 中，`ZhiYuWatch` 排除了所有重型视图和 iOS 特定的 Framework。如果底层 `Domain` 或 `Infrastructure` 反向调用了 L2 的重型 UI，将导致 `watchOS` Target 出现编译期致命错误（如 `Cannot find 'AdaptiveSidebarView' in scope`）。
3. **单元测试沙盒失效 (Test Isolation Ruined)**：
   测试环境下，我们通过分流拉起空壳 `TestApp`，要求对底层进行干净的 Mock 替换。若底层存在反向调用，将直接拉起整个宿主 App 的重型后台数据同步和 iCloud 连接，导致单元测试运行极其缓慢且结果不可预测。

---

## 4. 依赖倒置原则 (DIP) 规避反向引用的规范示范

当低层级组件（如 L1 基础设施的 `SecurityManager`）需要向高层级（如 L1.5 领域层的数据库仓储）读取或写入数据时，**严禁直接调用具体类**。必须采用 **DIP (Dependency Inversion Principle)**，即在 L0 或 L1.5 定义抽象协议，由高层实现协议，并通过 DI 容器注入：

### ❌ 错误示范 (Anti-Pattern: 反向调用具体类)
```swift
// 位于 Sources/Core/System/Security/SecurityManager.swift [L0.5]
import Foundation

class SecurityManager {
    func verifyDatabaseIntegrity() {
        // ❌ 严重错误：L0.5 系统层直接调用了 L1 基础设施层的具体类，导致严重的跨层反向耦合！
        let repo = SQLiteFileSignatureRepository.shared 
        let isOK = repo.validate(file: "db.sqlite")
        ...
    }
}
```

###  正确示范 (DIP: 依赖抽象协议)

```swift
// 1. 协议定义：在低层或标准契约层定义协议
// 位于 Sources/Domain/Protocols/FileSignatureRepository.swift [L1.5]
import Foundation

/// 文件签名指纹仓储契约
public protocol FileSignatureRepository: Sendable {
    /// 校验指定物理文件的完整性指纹
    /// - Parameter filePath: 文件的绝对或相对物理路径
    /// - Returns: 是否通过 HMAC 签名校验
    func validateSignature(for filePath: String) async -> Bool
}

// 2. 消费协议：调用方仅依赖抽象协议，通过 DI 容器自动注入
// 位于 Sources/Core/System/Security/SecurityManager.swift [L0.5]
import Foundation

public final class SecurityManager: @unchecked Sendable {
    public static let shared = SecurityManager()
    
    /// 🛡️ DIP 原则：注入契约协议而非具体实现类，根除反向耦合
    @Inject private var signatureRepository: any FileSignatureRepository
    
    private init() {}
    
    /// 执行核心数据库文件完整性审计
    public func performDatabaseAudit() async -> Bool {
        // 正确：仅通过注入的协议发起调用，SecurityManager 在物理上完全不知道 SQLiteFileSignatureRepository 的存在
        let isSecure = await signatureRepository.validateSignature(for: "zhiyu.sqlite")
        return isSecure
    }
}

// 3. 依赖注入注册：统一在应用顶层容器中装配，低层级完全无感知
// 位于 Sources/App/ModuleRegistrar.swift [L3]
struct StorageModuleRegistrar: ModuleRegistrar {
    static func register(in container: ServiceContainer) {
        let writer = DatabaseManager.shared.dbWriter!
        // 注册具体实现类绑定到它的协议契约上
        let fileSigRepo = SQLiteFileSignatureRepository(dbWriter: writer)
        container.register(fileSigRepo as any FileSignatureRepository, for: (any FileSignatureRepository).self)
    }
}
```

## 5. 持续自动监测机制

本工程在 `Tools/` 目录下部署了 `lint_layer_markers.sh` 脚本。任何新提交或修改的 `.swift` 文件必须在头部 20 行内声明物理层级标记（如 `[L1]`），CI 流水线将结合静态依赖图工具（如 `swift-dependency-graph`）自动对反向调用行为进行无情阻断，对于违规代码直接拒绝并阻断 Commit。
