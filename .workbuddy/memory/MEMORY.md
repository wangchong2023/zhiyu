# MEMORY.md - 长期记忆

## 项目背景
- **项目**: ZhiYu (智宇) - AI 原生知识管理应用，类似 Google NotebookLM
- **方法论**: 基于 Karpathy LLM Wiki 方法论的 RAG 闭环系统
- **技术栈**: SwiftUI + Swift 6 (严格并发) + GRDB (SQLite/FTS5) + 向量存储
- **多平台**: iOS 17+ / macOS 14+ (Catalyst) / watchOS 10+ / Widget + Live Activities
- **工程管理**: XcodeGen (project.yml)，2 个外部依赖 (GRDB, swift-snapshot-testing)
- **代码规模**: 420 个 Swift 文件 / ~56,238 行源码 / 44 个测试文件 / 58 个文档
- **代码路径**: /Users/constantine/Documents/work/code/projects/ZhiYu/

## 架构全景 (L0-L3 严格分层)
- **L0 (Base)**: ServiceContainer DI + @Inject + 全局协议 + 常量 + 工具类
- **L0.5 (System)**: Logger、Haptic、Security、Routing、Analytics 等 OS 能力封装
- **L1 (Infrastructure)**: LLM 适配器、SQLiteStore + Repository、Processors(文档/图谱/合成)、VectorDB、Plugins、Sync
- **L1.5 (Domain)**: 核心模型(KnowledgePage, PageLink)、RAG 编排(AIContentEnricher, RAGOrchestrator)、领域协议
- **L2 (Features)**: 4 大业务域 — Knowledge(Ingest/Graph/Search/Vault/NotebookHub) / AI(Chat/Synthesis/TaskCenter/VoiceNote/Quiz) / Insight(Dashboard/Lint/Log/MedalWall) / System(Auth/Settings/Collaboration)
- **L3 (App)**: ZhiYuApp + AppEnvironment + Router + ViewFactory + AppStore
- **Shared**: DesignSystem 令牌 + UIComponents 通用组件库

## 核心架构模式
1. **模块化 DI**: 4 个 ModuleRegistrar (Core→Storage→Domain→App) 按序注册
2. **启动分流**: AppLauncher 检测 XCTest 启动空壳 TestApp，隔离测试环境
3. **Repository 模式**: KnowledgeRepository/VectorRepository/GovernanceRepository/VaultRepository 协议化
4. **多库物理隔离**: global.sqlite3 (全局配置) + vault.sqlite3 (专属笔记本) 动态热插拔
5. **ViewFactory + ViewProvider**: 按 FeatureDomain (knowledge/ai/insight/system) 注册视图
6. **Router 单例**: NavigationPath + AppRoute 枚举全局导航，SidebarSelection 同步
7. **AppStore Facade**: 聚合 KnowledgeStore/SearchStore/AIWorkflowStore/TagStore 子 Store
8. **协议屏蔽**: 平台宏(#if os) 仅允许在 ModuleRegistrar.swift 中使用

## 测试体系
- **框架**: XCTest (必选) + Swift Testing (@Test 宏，推荐新模块)
- **分层**: Unit(27) / Integration(1) / Boundary(1) / Performance(1) / SnapshotTests(2) / UI(7)
- **Mock**: 通过 ServiceContainer DI 注入，TestMocks.swift 提供通用 Mock
- **快照测试**: pointfreeco/swift-snapshot-testing
- **最新全量结果**: 359 tests passed (2026-05-18)

## 文档体系
- **架构**: ARCHITECTURE_4PLUS1.md, LAYERING_L0_L3.md, HIGH_LEVEL_DESIGN.md
- **设计**: DETAILED_DESIGN.md, DATABASE_SCHEMA.md, SECURITY_DESIGN.md, PLUGIN_SDK.md, RAG_GOVERNANCE.md
- **需求**: PRODUCT_REQUIREMENTS.md, SOFTWARE_REQUIREMENTS_SPECIFICATION.md, FEATURE_LIST.md, ROADMAP.md
- **测试**: SYSTEM_TEST_PLAN.md, PERFORMANCE_BENCHMARK.md, TEST_CASES.md, UNIT_TEST_GUIDE.md
- **编码指南**: swift-coding-style.md, config-conventions.md, implementation-patterns.md, storage-conventions.md
- **重构记录**: Docs/superpowers/plans/ (20+ 历史重构计划)

## 用户偏好
- **语言**: 中文交流，技术术语中英混用
- **输出格式**: 结构化（表格、步骤列表、计划文档）
- **工作流**: 发现问题 → 给出详细执行计划(带优先级+估时) → 逐步实施 → 验证测试
- **代码偏好**: 使用编译宏(#if)禁用代码而非注释符号

## 当前关注迭代
1. **P0 已全部修复** (2026-05-24): Watch/Widget闪退(已验证) / L1-L2循环依赖(已验证) / 信号量死锁 / ServiceContainer竞态 / ChatCoordinator状态污染 / Keychain签名降级 / iPad Sheet弹出
2. **P1 架构治理**: 领域契约穿透重构 / Repository 协议迁移 / AppStore 瘦身 / 常量中心化(1188处魔法值)
3. **P1 安全硬化**: JSC 沙箱限制 / GRDB 连接池关闭
4. **P2 体验优化**: iCloud 真机测试 / Notebook Hub 封面自定义 / 测试覆盖率提升

## 认证与导航系统（2026-05-13 更新）
- **Notebook Hub**: 已实施笔记本工作台，支持 2 列卡片布局。
- **AuthSession**: 引入了全局 `@Observable` 认证会话。
- **个人中心**: 个人设置已集成至右上角头像菜单，取代了底部的 Settings Tab。
- **协议驱动 DI**: AuthService 和 VaultService 已重构为基于协议的注入。
- **架构对齐 (2026-05-16)**: 完成了物理归位重构后的全量编译修复，包括：
    - 同步了 `VectorRepository`, `GovernanceRepository`, `LoggerProtocol` 的异步化协议。
    - 在 `AppStore` 中补全了 PDF、标签管理、OCR 及演示数据生成的业务封装。
    - 修复了 `SettingsView` 等 UI 层的 SwiftUI 绑定与编译性能问题。
    - 恢复了丢失的 `KnowledgePageRepresentable` 核心协议。

## UserDefaults 规范化与本地化治理 (2026-05-18)
- **键名规范化**: 将全工程硬编码字符串替换为 `AppConstants.Keys.Storage` 统一管理。
- **冗余清理**: 移除了 `SettingsStore` 和 `OnboardingService` 中的旧版本数据迁移逻辑，简化了初始化流程。
- **本地化修复**: 
    - 修复了因本地化目录重构（从 `.xcstrings` 到 Catalog 分片）导致的 `L10n.Common` 成员缺失报错。
    - 在 `Localized.swift` 中实现了动态表路由算法，确保旧的表名请求（如 `AITasks`）能自动重定向到新的 Catalog。
- **验证**: 全量单元测试通过 (359 tests)，iOS 模拟器构建成功。

## 待处理
- **遗留问题完整清单**: `Docs/Testing/REMAINING_ISSUES.md` (2026-05-24 生成)
- **P0 全部修复** (2026-05-24): P0-1~P0-7 均已修复并验证（iOS+macOS BUILD SUCCEEDED）
- P1（11项）: 架构违规(DIP穿透/Repository位置/AppStore过载/LiveActivity宏/JSC沙箱/GRDB关闭) + 规范化(魔法值/图标/视图拆分/路由/注释)
- P2（13项）: 性能(标签查询/死代码/压测/Graph布局/Ingest布局) + 体验(BYOK/游客升级/冷启动/降级UI/Hub封面/iCloud) + 文档(时序图/HMAC流程)

## macOS 编译错误修复 (2026-05-24)
- **根因**: `MacOSPlatformCapabilities.swift` 中 `MacOSSecurityScopedStorage` 缺少 `#if os(macOS)` 条件编译保护，iOS Simulator 下 `.withSecurityScope` 不可用
- **关联问题**: `ModuleRegistrar.swift` 中 `MacFileArchiver`/`MacAccessibilityService` 的注册条件 `#if os(macOS)` 与定义条件 `#if os(macOS) && !targetEnvironment(macCatalyst)` 不一致，Catalyst 下引用不存在的类型
- **修复**: 添加条件编译保护 + 统一注册条件，Catalyst fallback 到 iOS 实现
- **验证**: ZhiYuMac (Simulator/Catalyst) + ZhiYu (iOS) 三个目标均 BUILD SUCCEEDED