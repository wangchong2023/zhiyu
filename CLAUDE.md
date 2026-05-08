# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导，回复问题和任务规划采用简体中文。

## 参考指南

| 指南 | 内容 |
|------|------|
| [swift-coding-style.md](Docs/guides/swift-coding-style.md) | 命名、Protocol、Localization key、CodingKeys、Boolean 前缀等 Swift 编码约定 |
| [config-conventions.md](Docs/guides/config-conventions.md) | project.yml、AppConfig.json、Asset Catalog、.xcstrings、文档目录规范 |
| [implementation-patterns.md](Docs/guides/implementation-patterns.md) | Swift 6 变通方案、图谱模式、合成文档、缓存策略、Mermaid、UI 框架等 |

## 项目概览

智宇 (ZhiYu) — 面向 iOS/macOS/watchOS 的 AI 原生知识管理应用，基于 Karpathy 的 LLM Wiki 方法论构建。不仅是一个 Markdown 编辑器，更是一个 RAG 闭环系统：语义分块 → 混合 FTS5+向量存储 → AI 合成实验室（含深度引用）。

## 构建与开发

```bash
# 从 project.yml 生成 Xcode 项目（配置变更后必须执行）
xcodegen generate

# 同步本地化词条（分表合并到主表）
python3 Tools/update_localization.py

# 构建 iOS
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS'

# 构建 macOS (Catalyst)
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS'

# 构建 watchOS
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuWatch -destination 'generic/platform=watchOS'

# 列出可用模拟器
xcodebuild -project ZhiYu.xcodeproj -scheme ZhiYu -showdestinations | grep simulator

# 运行单元测试
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -enableCodeCoverage YES

# 运行单个测试类
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZhiYuTests/AppStoreTests

# 代码检查（需安装 SwiftLint）
swiftlint --strict
```

## 架构：L0–L3 严格分层

依赖规则：**上层依赖下层，绝不可反向。** 跨层访问必须通过协议。

| 层级 | 名称 | 内容 |
|-------|------|-----------------|
| **L3** | 表现层 | SwiftUI Views、`@Observable` ViewModels、导航 |
| **L2** | 领域/功能层 | 业务逻辑服务 — `KnowledgeInsightService`、`AISynthesisService`、`IngestService` |
| **L1** | 服务层 | 数据访问与 AI 适配器 — `AppStore`、`LLMClient`、`EmbeddingManager` |
| **L0** | 基础设施层 | 存储引擎 (SQLite)、网络、Keychain、Logger、OS 工具 |

## 关键模式

### 依赖注入 — `@Inject` 属性包装器

服务通过 `ServiceContainer`（服务定位器模式）在 `ZhiYuApp.init()` 中注册。在任何 View、ViewModel 或其他服务中使用：

```swift
@Inject var store: AppStore
```

`@Inject` 包装器从 `ServiceContainer.shared` 解析。服务必须在使用前注册——未注册会导致 `fatalError`。

### 并发

- 严格并发检查**已启用**（`SWIFT_STRICT_CONCURRENCY: complete` — Swift 6 模式）
- 优先使用 `async/await` 和 `actor`；绝不使用锁或信号量
- UI 绑定代码必须标注 `@MainActor`
- 非 `Sendable` 单例类，将 `static let shared` 标记为 `nonisolated(unsafe)`。

## 项目结构（关键路径）

```
Sources/
├── ZhiYuApp.swift                # @main 入口点，服务注册中心
├── Shared/
│   ├── Core/                  # ServiceContainer (DI)、协议定义、平台适配、工具类
│   ├── Data/                  # SQLiteStore、AppStore、VaultService、同步引擎 (iCloud/FS)
│   ├── Domain/                # LLMService、AISynthesisService、IngestService、处理器 (OCR/PDF/Chunker)
│   ├── Models/                # Entity、Concept、Page 模型定义
│   ├── ViewModels/            # 基于 @Observable 的业务逻辑编排层 (ChatViewModel, GraphViewModel)
│   ├── Views/                 # 跨平台 SwiftUI 视图组件
│   └── Resources/             # 跨平台静态资源
├── Platforms/                 # 平台特定实现 (iOS, macOS, watchOS)
└── Resources/                 # App 资源 (Assets, Info.plist)
Tests/                         # 单元测试、集成测试、快照测试、性能测试
Tools/                         # 开发者辅助工具 (MockServer, Scripts)
```

## Targets

- **ZhiYu** — iOS 应用（iPhone/iPad），主 target
- **ZhiYuMac** — Mac Catalyst 应用
- **ZhiYuWatch** — 独立 watchOS 应用
- **ZhiYuTests** — 单元测试 bundle

## 提交规范

使用 Conventional Commits 格式：

- `feat:` — 新功能
- `fix:` — 缺陷修复
- `docs:` — 文档更新
- `refactor:` — 代码重构
- `perf:` — 性能优化

## 注释规范

统一使用**简体中文**书写所有注释：

- **文档注释（`///`）**：解释“为什么”，用于公开 API。
- **实现注释（`//`）**：解释“怎么做”，用于内部逻辑。
- **MARK 标签**：使用 `// MARK: - 中文标题` 格式。
