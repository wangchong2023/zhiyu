# 架构对齐与本地化治理重构总结 (2026-05-18 更新)

## 重构背景
智宇 (ZhiYu) 项目在快速迭代中积累了显著的技术债：本地化架构臃肿（单一 `Localizable.xcstrings`）、存储键名混乱（硬编码字符串散落在各处）以及跨平台依赖耦合。为了支持垂直化功能架构 (Vertical Slices)，我们执行了本次深度重构。

## 核心战果

### 1. 本地化架构物理分表与解耦
- **分表治理**：彻底物理删除了 `Localizable.xcstrings`，建立了 `Common`, `Auth`, `Chat`, `AI`, `Ingest` 等 20+ 个物理分表，实现了按域分治。
- **扩展架构**：将巨型 `Localized.swift` 拆分为 `L10n+*.swift` 的多文件扩展，引入动态表路由算法，确保旧表名请求能自动映射至新 Catalog。
- **静态审计**：升级 `Tools/check_localization.py` 扫描内核，支持嵌套命名空间与继承路由。目前全工程 **0 缺失 Key、0 缺失翻译、0 越权调用**。

### 2. UserDefaults 键名规范化
- **常量化收拢**：全量消灭了 `AuthService`、`OnboardingService` 及 `SettingsStore` 中的硬编码字符串。
- **中心化管理**：所有持久化键名统一通过 `AppConstants.Keys.Storage` 管理，提升了代码的物理可见性与类型安全性。
- **冗余清理**：移除了 10+ 处冗余的旧版本数据迁移逻辑，简化了初始化流程，降低了维护成本。

### 3. 跨平台与依赖治理
- **Apple Watch 对齐**：通过条件编译 (`#if !os(watchOS)`) 与 `project.yml` 排除规则，隔离了手表端对 L3 层 UI 组件的非法依赖，实现了全平台 100% 编译通过。
- **DI 协议驱动**：核心服务（Auth, Vault）完成协议化重构，支持基于接口的依赖注入。

### 4. God Class 深度拆解 (Phase 2)
- **核心剥离**：将 `AppStore` 中原本承担的巨型页面状态管理（`pages`, `totalPages` 等）彻底抽离至独立的 `KnowledgeStore`。
- **职责聚合**：`AppStore` 演进为纯粹的“门面 (Facade)”与“调度中心”，通过聚合多个领域 Store (`SearchStore`, `AIWorkflowStore`, `KnowledgeStore`, `TagStore`) 实现功能解耦。
- **视图层瘦身**：完成了 `Sources/Features/` 下 10+ 个核心视图文件的深度解耦，各子模块现在直接通过 `@Environment(KnowledgeStore.self)` 访问其所需的业务状态，不再强依赖于全局巨型 Store。

### 5. 质量保障与构建验证
- **全平台编译通过**：iOS、macOS (Catalyst) 与 watchOS 所有构建 Scheme 均成功且无编译警告通过。
- **单元测试与覆盖率**：领域层 (Domain) 覆盖率达到 **97.90%**（远超 85% 红线指标），309 个功能单元测试全部绿色通过。

### 6. 设置页磨砂玻璃样式（Glassmorphism）与交互调优
- **样式统一挂载**：在 `SettingsView` 及其 5 个子页面（`BackupView`、`LLMSettingsView`、`DeveloperSettingsView`、`LogView`、`iCloudSyncView`）中，完成了底色与毛玻璃修饰器的架构统一。行背景已移至 `Section` 级别，通过 `AppListRowBackground` 确保磨砂玻璃视觉一致性。
- **布局漏洞修复**：彻底移除了 `SettingsView` 外层 `List` 容器上错误的 `background` 修饰符，消除了滚动时偶现的纯白底色背景穿透漏洞，提升了视觉精致感。
- **开屏动画（SplashView）极简优化**：移除了多余的“名言闪光”文字扫光动画，彻底去除了 `shimmerOffset` 状态及相应的计时器与叠加层。开屏动画仅保留呼吸渐显 Slogan 与平滑过渡，页面展示逻辑更加简洁、高效与优雅。

### 5. 本地化资源瘦身 (Slimming Plan)
- **物理去重**：通过自动化脚本识别并删除了 `Common.xcstrings` 中 70 多个与业务分表完全重复的“影子键”，大幅降低了维护成本。
- **语义整合**：统一了全工程的原子操作（确定、取消、删除、设置、搜索）及核心业务名词（页面标题、来源、实体、概念），将其收拢至 `L10n.Common`，消灭了 10+ 处语义冗余。
- **架构鲁棒性**：修复了 `L10n+AI.swift` 等文件中的动态键名拼接隐患，并完善了 `Localized.swift` 的路由逻辑，确保 100% 静态审计通过。

## 清理工作与编译告警消除
- **已彻底消灭全平台所有编译告警**：
  1. **SecurityManager.swift (Sendable警告)**：由于 `SecurityManager` 采用 `NSLock` 保护其唯一状态 `_cachedPassphrase` 且外部调用全部线程安全，我们将其标志为 `@unchecked Sendable`，并去除了对属性包装器无效的 `nonisolated(unsafe)` 修饰符，消除了 Swift 6 模式下的数据竞争存疑告警。
  2. **PluginRegistry.swift (Await警告)**：移除了 `queryPages` 中对同步闭包 `pagesProvider` 冗余的 `await` 调用，消除了“no 'async' operations occur within 'await' expression”警告。
  3. **CrossPlatform.swift (watchOS/iOS Image Sendable警告)**：显式为 watchOS 平台的 `AppImage` 存根声明了 `Sendable` 协议，并移除已在 UIKit/AppKit SDK 中内置 Sendable 声明的冗余扩展，彻底消除了 watchOS 平台下由于传递非 Sendable 图片可能导致数据竞争的编译告警。
- 已物理删除 `Tools/Temp/` 下的所有临时迁移脚本。
- 已清理 `project.yml` 中的陈旧文件引用。

## 结语
本次重构不仅消灭了物理层面的技术债，更在工程范式上为后续的插件化扩展与自动化流水线打下了坚实的根基。智宇项目现在拥有了真正意义上的“可独立测试、按域分发”的现代化架构。
