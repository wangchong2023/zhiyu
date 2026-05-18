# MEMORY.md - 长期记忆

## 项目背景
- **项目**: ZhiYu (知予) - 知识管理应用，类似 Google NotebookLM
- **技术栈**: SwiftUI 多平台 (iPhone/iPad/Mac)，XcodeGen 管理项目
- **代码路径**: /Users/constantine/Documents/work/code/projects/ZhiYu/

## 用户偏好
- **语言**: 中文交流，技术术语中英混用
- **输出格式**: 结构化（表格、步骤列表、计划文档）
- **工作流**: 发现问题 → 给出详细执行计划(带优先级+估时) → 逐步实施 → 验证测试
- **代码偏好**: 使用编译宏(#if)禁用代码而非注释符号

## 当前关注迭代
1. Graph 视图按钮布局修复（图标颜色一致性+触控区域）
2. Ingest 模块 LazyVGrid 响应式布局（2列自适应）
3. iCloud 功能集成与真机测试
4. 测试覆盖率提升
5. KMStore.ToolItem 缺失 'healthCheck' 成员编译错误
6. iPad 性能监控卡片无法弹出 sheet 的根因排查

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
- Notebook Hub 页面视觉优化（支持笔记本封面自定义）
- iCloud 集成真机测试
- Graph 视图按钮布局修复
- 自动化单元测试覆盖率提升