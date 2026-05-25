# 智宇 (ZhiYu) 遗留问题清单

> **生成日期**: 2026-05-24
> **数据来源**: ROADMAP.md / FULL_PROJECT_AUDIT_REPORT_2026_05_16.md / DETAILED_DESIGN.md / global-code-audit-and-refactor-plan.md / p1-tech-debt-resolution.md / PRODUCT_REQUIREMENTS.md / 会话诊断记录
> **优先级定义**: P0 = 闪退/死锁/安全漏洞 / P1 = 架构违规/规范化 / P2 = 性能优化/远期规划

---

## P0 — 必须立即修复（闪退/死锁/安全漏洞）

| # | 问题 | 状态 | 影响范围 | 详情 |
|---|------|------|---------|------|
| **P0-1** | Shared 层越界导致 Watch/Widget 闪退 | ✅ 已修复 | watchOS / WidgetExtension | `WidgetAndWatchViews.swift` 已不依赖 `AppStore`，Watch 端有独立 `WatchModuleRegistrar`，Widget 通过 UserDefaults 获取数据。此问题在 2026-05-23 的代码审计重构中已解决。 |
| **P0-2** | L1-L2 循环依赖 | ✅ 已修复 | 全局编译/架构 | `DocumentProcessorFactory` 不存在，`DocumentFormat` 已在 L0，`DocumentExtractionServiceProtocol` 已在 L0，`IngestService` 通过 `@Inject` 注入协议。此问题在 2026-05-23 的代码审计重构中已解决。 |
| **P0-3** | 信号量同步阻塞死锁隐患 | ✅ 已修复 | watchOS / 低配设备 | `DatabaseManager.setup()` 改为异步 HMAC 校验（`scheduleIntegrityVerification`），`switchDatabase()` 改为 `async throws`，消除所有 `semaphore.wait()` 和 `Thread.sleep()`。同步更新 `VaultDatabaseSwitcher` 协议和 `VaultService` 调用方。 |
| **P0-4** | ServiceContainer 并发竞态 | ✅ 已修复 | macOS 多窗口 / App Extension | `resolve()` 中将两次加锁合并为单次加锁操作，同时读取实例和诊断 keys，消除两次加锁间的竞态窗口。 |
| **P0-5** | ChatCoordinator 并发状态污染 | ✅ 已修复 | macOS 多窗口 / 并发 Chat | 引入 `currentStreamTask: Task<Void, Never>?` 支持显式取消，`cancelCurrentRequest()` 调用 `Task.cancel()` 终止底层 `AsyncThrowingStream`，清理 `streamingContent` 残留，error 路径也清理状态。 |
| **P0-6** | Keychain 签名降级安全漏洞 | ✅ 已修复 | 安全 | `SecurityManager.saveSignature()` 降级到 UserDefaults 现在受 `#if DEBUG` 保护，Release 下签名持久化失败仅记录日志，不允许明文降级。 |
| **P0-7** | iPad 性能监控 Sheet 无法弹出 | ✅ 已修复 | iPad | ① 将 `.sheet(isPresented: $store.showPerfDashboard)` 从三个互斥视图分支统一提取到 `mainContent()` 最外层 ZStack ② 在 `DeveloperSettingsView` 添加"性能监控面板"按钮入口（`store.showPerfDashboard = true`）③ 移除 `adaptiveSplitView`/`modernTabView`/`legacyTabView` 中的重复 sheet 绑定。 |

---

## P1 — 架构治理与规范化

### 1.1 架构违规

| # | 问题 | 状态 | 详情 |
|---|------|------|------|
| **P1-1** | 领域契约穿透（DIP 违规） | ✅ 已修复 | `KnowledgeStore` 改为注入 L1.5 `KnowledgeRepository`（替代 L1 `AnyPageStoreCapabilities`）；`AIWorkflowStore` 改为注入 `KnowledgeRepository` + L0 `VectorIndexableStore`；`ModuleRegistrar` 新增 `VectorIndexableStore` 协议注册。 |
| **P1-2** | Repository 协议位置违规 | ✅ 已修复 | Repository 协议已正确位于 `Sources/Domain/Protocols/`（L1.5），实现类在 `Sources/Infrastructure/Storage/Repositories/`（L1）。符合 DIP 原则。实际问题是 L2 层未使用这些协议（见 P1-1）。 |
| **P1-3** | AppStore 过载 | 🔴 未修复 | `AppStore` 承担全应用 Facade，聚合过多跨领域逻辑（PDF/OCR/演示数据），需按领域拆解。 |
| **P1-4** | LiveActivity 宏污染 | ✅ 已修复 | `TaskCenter` 已通过 `LiveActivityProtocol` 协议解耦，`#if os(iOS)` 仅在平台实现层 (`ActivityService.swift`) 和 UI 适配层，未污染业务逻辑。 |
| **P1-5** | JSC 沙箱动态执行未限制 | 🔴 未修复 | 插件 `JSContext` 需禁用 `eval`/`Function` 等动态代码执行，只暴露值类型 Copy 桥接对象。 |
| **P1-6** | GRDB 连接池非确定性关闭 | 🔴 未修复 | `DatabasePool` 释放前需显式 `close()` 关闭连接并写入 WAL，避免 `vnode unlinked while in use` 警告。 |

### 1.2 代码规范化

| # | 问题 | 状态 | 详情 |
|---|------|------|------|
| **P1-7** | 魔鬼值硬编码（1188 处） | 🟡 部分完成 | UI 间距尺寸（8/12/16）未走 `DesignSystem` 令牌；硬编码错误码（405/501）未归入强类型 Error 枚举。UserDefaults Key 已部分常量化（2026-05-18）。 |
| **P1-8** | 图标常量中心化 | 🔴 未修复 | SF Symbol 名称散落各视图文件，需集中到 `DesignSystem.Icons`。 |
| **P1-9** | 视图组件拆分 | 🟡 部分完成 | `NotebookHubView.swift`（216行）核心组件（NotebookCard/CreateNotebookButton/NotebookFormSheet/NotebookListRow）已提取至 Components 目录。剩余 searchBar/sortMenu 等 5 个内联子组件可进一步提取。 |
| **P1-10** | 路由优化 | 🔴 未修复 | `Router.updateSelection` 的大型 switch 语句需重构为更具扩展性的映射模式。 |
| **P1-11** | 中文注释补全 | 🟡 部分完成 | 文件头注释 100% 覆盖；公开函数 48.3%（102个）缺失 `///` 文档注释；4.5% 纯英文注释需补充中文。 |

---

## P2 — 性能优化与产品体验

### 2.1 性能

| # | 问题 | 状态 | 详情 |
|---|------|------|------|
| **P2-1** | 标签存储查询优化 | 🔴 未修复 | `KnowledgePageRepository` 标签查询用 `LIKE` 子句，大数据量下索引失效，需引入标签中间表。 |
| **P2-2** | 死代码清理 | 🔴 未修复 | `OnDeviceLLMService` 中存在未使用的调试辅助函数。 |
| **P2-3** | 十万节点压测 | 📋 计划中 | 当前压测覆盖 50K 节点，需增至 100K 级别验证 FTS5 性能收敛性。 |
| **P2-4** | Graph 视图按钮布局修复 | 🟡 已知 | 图标颜色一致性 + 触控区域优化。 |
| **P2-5** | Ingest 模块响应式布局 | 🟡 已知 | 需采用 LazyVGrid 实现卡片 2 列/自适应排布。 |

### 2.2 产品体验

| # | 问题 | 状态 | 详情 |
|---|------|------|------|
| **P2-6** | BYOK 引导不够直观 | 🔴 未修复 | Lite 额度耗尽后需设计渐进式指引面板，允许一键导入 API 密钥。 |
| **P2-7** | 游客升级提醒缺失 | 🔴 未修复 | 游客节点数达 90 临界值时需显示渐进式蒙层提醒。 |
| **P2-8** | 冷启动引导单一 | 🔴 未修复 | "欢迎金库"仅 Markdown 文章展示，缺少 3D 图谱核心亮点呈现。 |
| **P2-9** | 安全气泡降级 Banner 美化 | 🔴 未修复 | 需利用 Glassmorphism 半透明磨砂玻璃卡片美化降级 UI。 |
| **P2-10** | Notebook Hub 视觉优化 | 🟡 已知 | 支持笔记本封面自定义。 |
| **P2-11** | iCloud 集成真机测试 | 🟡 已知 | iCloud 功能需在真机上验证。 |

### 2.3 文档待补

| # | 问题 | 状态 | 详情 |
|---|------|------|------|
| **P2-12** | 插件沙箱池化时序图 | 📋 待补 | 需在 DETAILED_DESIGN.md 第3章补充并发池化机制与 CPU 熔断的并发安全时序图。 |
| **P2-13** | HMAC 动态签名算法流程 | 📋 待补 | 需在 DETAILED_DESIGN.md 第6章补充 WAL 离线同步期间 HMAC 动态签名的详细算法流程。 |

---

## 远期演进功能（非紧迫）

| # | 功能 | 状态 |
|---|------|------|
| **F-1** | 加密知识分片（端到端加密传输） | 未开始 |
| **F-2** | 级联式防爬多源捕获引擎 (CaptureCascadeEngine) | 规划中 |
| **F-3** | 端侧双人播客生成 (Audio Overview Native) | 规划中 |
| **F-4** | 外置 Agent 自动化开放总线 | 规划中 |
| **F-5** | 弹性混合云端代理 RAG 模式 | 规划中 |
| **F-6** | 主动联想代理 (Active Agent) | 远期愿景 |
| **F-7** | 零知识证明同步 (ZKP Sync) | 远期愿景 |
| **F-8** | 知识库贸易网络 (Vault Commerce) | 远期愿景 |
| **F-9** | 图谱渲染引擎 2.0（10万级节点） | 远期愿景 |
| **F-10** | 开发者激励协议 (Creator Economy) | 远期愿景 |
| **F-11** | 插件化生态社区市场 Alpha | 部分完成（SDK 已就绪） |

---

## 已完成的重构计划（供参考）

| 日期 | 计划 | 状态 |
|------|------|------|
| 2026-05-03 | rename-wiki-to-knowledge | ✅ 已完成 |
| 2026-05-04 | aiworkflowstore-split | ✅ 已完成 |
| 2026-05-04 | swiftui-cleanup | ✅ 已完成 |
| 2026-05-04 | viewmodel-migration | ✅ 已完成 |
| 2026-05-04 | pptxgenerator-relocation | ✅ 已完成 |
| 2026-05-04 | large-view-splitting | ✅ 已完成 |
| 2026-05-08 | architecture-refactor-implementation | ✅ 已完成 |
| 2026-05-10 | refactor-ui-components | ✅ 已完成 |
| 2026-05-10 | rename-wiki-terminology | ✅ 已完成 |
| 2026-05-10 | update-anypagestore-calls | ✅ 已完成 |
| 2026-05-12 | refactor-notebook-hub | ✅ 已完成 |
| 2026-05-12 | structural-reform | ✅ 已完成 |
| 2026-05-13 | notebookcard-visual-enhancement | ✅ 已完成 |
| 2026-05-14 | rename-approuter-to-router | ✅ 已完成 |
| 2026-05-15 | macro-sanitization | ✅ 已完成 |
| 2026-05-15 | platform-macro-cleanup | ✅ 已完成 |
| 2026-05-16 | architectural-alignment | ✅ 已完成 |
| 2026-05-17 | p1-tech-debt-resolution | 🟡 部分完成（UserDefaults Key 已常量化，其余未完成） |
| 2026-05-18 | refactor-userdefaults-keys | ✅ 已完成 |
| 2026-05-18 | localization-audit-upgrade | ✅ 已完成 |
| 2026-05-15 | magic-cleanup | 🟡 进行中 |
| 2026-05-23 | global-code-audit-and-refactor-plan | 📋 未开始 |
| — | refactor-to-feature-architecture | 📋 未开始 |

---

## 修复优先级建议

**第一波（消除闪退/死锁）✅ 已完成**：
1. ✅ P0-1 Watch/Widget 闪退 — 已在之前重构中解决
2. ✅ P0-2 L1-L2 循环依赖 — 已在之前重构中解决
3. ✅ P0-3 信号量死锁 — async/await 重构
4. ✅ P0-7 iPad Sheet 弹出修复

**第二波（并发安全 + 安全硬化）✅ 已完成**：
5. ✅ P0-4 ServiceContainer 竞态修复
6. ✅ P0-5 ChatCoordinator 状态下沉
7. ✅ P0-6 Keychain 签名降级强化

**第三波（架构治理）— 下一步**：
8. P1-1 领域契约穿透重构
9. P1-2 Repository 协议迁移
10. P1-3 AppStore 瘦身
11. P1-4 LiveActivity 抽象

**第四波（规范化）**：
14. P1-7 ~ P1-11 常量中心化/视图拆分/注释补全

**第五波（性能与体验）**：
15. P2-1 ~ P2-11 性能优化/产品体验/文档补全
