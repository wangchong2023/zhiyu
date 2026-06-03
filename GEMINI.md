# 智宇 (ZhiYu) - AI 原生知识管理应用

智宇 (ZhiYu) 是一款面向 iOS、macOS 和 watchOS 的 AI 原生知识管理应用，基于 Andrej Karpathy 的 LLM Wiki 方法论构建。它不仅仅是一个 Markdown 编辑器，更是一个完整的 RAG (Retrieval-Augmented Generation) 闭环系统。

## 项目概览

- **核心目标**：语义分块 → 混合 FTS5+向量存储 → AI 合成实验室（深度引用）。
- **主要技术栈**：
  - **语言**：Swift 6 (开启严格并发检查)
  - **UI 框架**：SwiftUI (全平台统一代码库)
  - **存储**：SQLite (GRDB.swift) + 向量存储
  - **AI**：本地/远程 LLM 适配，RAG 管道
  - **工程化**：XcodeGen (`project.yml`), SwiftLint, String Catalog (`.xcstrings`)

## 构建与开发

所有构建日志应存放在 `build/` 目录下。

```bash
# 从 project.yml 生成 Xcode 项目（配置变更后必须执行）
xcodegen generate

# 构建 iOS (iPhone/iPad)
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/ios_build.log 2>&1

# 构建 macOS (Catalyst)
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/mac_build.log 2>&1

# 构建 watchOS
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/watch_build.log 2>&1

# 运行单元测试
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' > build/test_results.log 2>&1
```

## 架构规范 (垂直化功能架构)

项目遵循垂直化功能架构 (Vertical Slices)，将代码按职责深度分层，并在业务逻辑层执行垂直切片，以最大化模块内聚并减少跨层耦合。

| 层级 | 名称 | 物理路径 | 核心职责 |
| :--- | :--- | :--- | :--- |
| **L3** | 应用层 (App) | `Sources/App/` | 全局入口、环境配置、路由中心 |
| **L2** | 业务功能层 (Features) | `Sources/Features/` | 业务域分组的垂直切片，包含 UI 及本地状态 |
| **L1.5** | 领域层 (Domain) | `Sources/Domain/` | **核心业务大脑**：业务规则、RAG 编排、跨模块契约 |
| **L1** | 基础设施层 (Infra) | `Sources/Infrastructure/` | 技术实现：LLM 适配、数据库持久化、文档解析 |
| **L0.5** | 系统集成层 (System) | `Sources/Core/System/` | 系统能力封装：日志、触感、安全、硬件集成 |
| **L0** | 底层基座层 (Base) | `Sources/Core/Base/` | 内核：DI 容器、全局协议定义、基础常量与工具 |
| **Shared** | 共享标准层 | `Sources/Shared/` | 视觉标准：设计系统、通用 UI 原子组件 |

## 目录结构 (物理归位)

- `Sources/App`: 应用启动逻辑与全局路由调度。
- `Sources/Core/Base`: 极简内核，无业务逻辑，无系统依赖。
- `Sources/Core/System`: 封装 Apple 系统框架能力。
- `Sources/Domain`: 核心业务逻辑、领域模型与中台化服务。
- `Sources/Infrastructure`: AI 客户端、存储引擎的具体实现。
- `Sources/Features`: 业务功能模块，按领域分组。
- `Sources/Shared`: 设计令牌与跨业务通用 UI 组件。
- `Sources/Localization`: 全局 String Catalog 资源。
- `Sources/Platforms`: 平台特有的桥接实现（iOS, macOS, watchOS）。
- `Docs/superpowers`: 存储工程重构计划与设计文档。


## 开发约定

### 1. 依赖注入 (DI) 与依赖倒置 (DIP)
- 使用 `ServiceContainer` 模式和 `@Inject` 属性包装器。
- **强制约束**：业务功能层 (Features) 严禁直接依赖基础设施的具体实现类（如 `SQLiteStore`）。必须通过定义在 `Core/Base` 或 `Domain/Protocols` 中的协议（如 `any AnyPageStoreCapabilities`）进行注入。所有服务必须在 `ZhiYuApp.init()` 中注册。

### 2. 领域层纯净化 (Domain Purity)
- **强制约束**：L1.5 领域层必须保持平台无关。严禁在 Domain 层导入 `ActivityKit`, `UIKit`, `AppKit` 或使用 `#if os` 宏进行业务分支。平台相关的能力必须抽象为协议并下沉至 `Platforms/` 或 `Core/System/` 实现。

### 3. 并发模型 (Swift 6)
- 启用 `SWIFT_STRICT_CONCURRENCY: complete`。
- 优先使用 `async/await` 和 `actor`；避免使用传统锁。
- UI 绑定代码必须标注 `@MainActor`。
- 非 `Sendable` 的单例常量需标注 `nonisolated(unsafe)`。

### 3. 注释与文档
- **统一使用简体中文**书写所有注释。
- **文档注释 (`///`)**：解释“为什么”，用于公开 API。
- **实现注释 (`//`)**：解释“怎么做”，用于内部逻辑。
- **MARK 标签**：`// MARK: - 中文标题`。

### 4. 本地化 (L10n) 强约束规范
- **禁止硬编码**：UI 层严禁出现硬编码字符串。所有展示文本必须通过 `L10n.模块.属性` 访问。
- **禁止直连 tr()**：严禁在业务视图或服务层直接调用 `.tr()`。
- **禁止假国际化**：在 `L10n+XXX.swift` 扩展中，禁止直接赋值硬编码中文，必须映射至 `.xcstrings`。
- **强校验网关**：项目已集成 `check_localization.py` 编译网关。任何硬编码非 ASCII 字符或非法 `.tr()` 调用将**阻断编译**。开发者必须先在 `L10n` 扩展中定义属性并在 `.xcstrings` 中配置翻译，方可通行。

### 5. 编码风格
- 遵循 `Docs/guides/swift-coding-style.md`。
- `import` 管理：Model/Service 层 `import Foundation`（严禁导入 `SwiftUI`）；View 层 `import SwiftUI`。
- 协议遵循放在独立 `extension` 中。

### 6. 脚本管理规范
- **长期工具**：存放在 `Tools/` 目录下。
- **临时脚本**：存放在 `Tools/Temp/` 目录下，使用后需及时清理。
- **文档维护**：新增或移动脚本后，必须同步更新 `Tools/README.md`。

### 7. 数据库 Model 字段绑定规范
- **禁止物理硬编码**：在编写数据库 Schema 迁移、建表与 SQL 数据处理时，严禁直接使用硬编码的裸物理表名或物理字段名字面量（例如 `"created_at"`、`t.column("created_at")`）。
- **必须通过 Model 字段**：必须使用各数据库 Model 实体自带的 `databaseTableName` 静态常量及 `Columns` / `CodingKeys` 常量作为表名和字段的映射插值，以保证编译期类型安全与模型解耦。
- **强校验网关**：项目已集成 `check_storage_constants.py` 守卫网关，检测到任何硬编码物理字段或未进行常量插值的硬编码 SQL 均会**阻断编译**。

## 提交规范
使用 Conventional Commits 格式：
- `feat:` (新功能), `fix:` (缺陷修复), `docs:` (文档), `refactor:` (重构), `perf:` (优化)。

## 关键文件路径
- `Sources/ZhiYuApp.swift`: 应用入口与服务注册中心。
- `Sources/Core/Base/ServiceContainer.swift`: DI 容器实现。
- `Sources/Domain/Models/`: 核心领域模型。
- `Sources/Shared/UIComponents/`: 跨平台 SwiftUI 通用视图。
- `Tools/`: 开发者辅助工具（同步、模拟器、MockServer）。
- `project.yml`: XcodeGen 项目定义。
