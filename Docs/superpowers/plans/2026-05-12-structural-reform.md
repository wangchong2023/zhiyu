# 智宇 (ZhiYu) 工程架构重构与卓越工程实施计划

> **执行说明：** 要求使用 `superpowers:subagent-driven-development` (推荐) 或 `superpowers:executing-plans` 技能按任务逐步实施。每项任务需包含检查点，使用复选框 (`- [ ]`) 跟踪进度。

**核心目标：** 将项目转换为垂直化的 "MyAIApp" 架构，强制执行严苛的工程标准（圈复杂度 < 15，NBNC < 100 行），实现全量 SRS 需求溯源及 DFX（日志/指标）增强。

**架构分层设计：**
- **App 层**：全局入口、环境配置与路由调度。
- **Core (L0) 层**：技术基座（网络、存储、底层日志、工具类）。
- **Infrastructure (L1) 层**：AI/RAG 领域实现（LLM 适配、向量库、OCR、分析）。
- **Features (L2) 层**：垂直业务模块（对话、搜索、知识库、设置），内部按 V-VM-M-S 组织。
- **Shared 层**：业务共性标准（设计系统、通用 UI 组件、布局模板）。

**工程卓越性标准：**
- **复杂度控制**：函数圈复杂度必须小于 15。
- **代码行数**：单个函数 NBNC（非空非注释行）严禁超过 100 行。
- **需求溯源**：代码中必须通过 `// MARK: @SR-03` 或 `/// @Docs/Requirements/...` 标注 SRS 编号。
- **DFX 增强**：在 RAG 和关键路径植入结构化日志与时延度量指标。
- **中文注释**：所有文件头、函数、枚举及关键逻辑必须具备高质量中文注释。

---

## 第一阶段：共享标准与设计系统 (DesignSystem) 重构

### 任务 1：拆分 AppUI 为原子设计令牌 (Tokens)
**涉及文件：**
- 创建：`Sources/Shared/DesignSystem/Tokens/Spacing.swift` (间距与圆角)
- 创建：`Sources/Shared/DesignSystem/Tokens/Typography.swift` (排版与字号)
- 创建：`Sources/Shared/DesignSystem/Tokens/Colors.swift` (颜色与语义色)
- 创建：`Sources/Shared/DesignSystem/Tokens/Animations.swift` (动效令牌)
- 删除：`Sources/Shared/Core/Constants/AppUI.swift` (迁移完成后删除)

- [ ] **步骤 1：实施间距令牌**
将 `AppUI` 中的间距、圆角常数提取至 `Spacing.swift`，并添加中文注释。
- [ ] **步骤 2：实施排版令牌**
将字号、`HeadingLevel` 提取至 `Typography.swift`，确保满足 KISS 原则。
- [ ] **步骤 3：实施颜色令牌**
将 `Color` 扩展及十六进制转换逻辑移至 `Colors.swift`。
- [ ] **步骤 4：实施动效令牌**
将 `Animation` 结构体及物理常数移至 `Animations.swift`。
- [ ] **步骤 5：提交代码**
`git commit -m "refactor: 拆分 AppUI 为原子设计系统令牌"`

### 任务 2：重构通用 UI 组件与布局模板 (Layouts)
**涉及文件：**
- 创建：`Sources/Shared/UIComponents/Backgrounds/PageBackground.swift`
- 创建：`Sources/Shared/UIComponents/Layouts/StandardSection.swift`
- 创建：`Sources/Shared/UIComponents/Modifiers/GlassStyle.swift`

- [ ] **步骤 1：迁移页面背景**
在 `PageBackground.swift` 中实现 `MeshGradientView` 和 `PageBackgroundView`。
- [ ] **步骤 2：迁移标准布局**
在 `Layouts` 目录下实现 `StandardSection`（原 `AppSection`）。
- [ ] **步骤 3：迁移视觉修饰符**
在 `GlassStyle.swift` 中实现玻璃拟态修饰符，确保 DFX 易用性。
- [ ] **步骤 4：提交代码**
`git commit -m "refactor: 迁移布局模式与视觉修饰符至 UIComponents"`

---

## 第二阶段：核心层与基础设施层 (物理归位与标准化)

### 任务 3：迁移核心服务至 L0 (Core)
**涉及文件：**
- 移动：`Sources/Shared/Core/Logger/Logger.swift` -> `Sources/Core/Logger/Logger.swift`
- 移动：`Sources/Shared/Core/Network/*` -> `Sources/Core/Network/`
- 移动：`Sources/Shared/Core/Utilities/*` -> `Sources/Core/Utils/`

- [ ] **步骤 1：执行物理移动**
- [ ] **步骤 2：应用卓越工程标准**
补全中文头注释，检查 NBNC 行数，标注 SRS 需求 ID（如 SR-03）。
- [ ] **步骤 3：提交代码**
`git commit -m "refactor: 迁移并标准化 L0 Core 核心层"`

### 4. 迁移 RAG 组件至基础设施层 (L1)
**涉及文件：**
- 移动：`Sources/Shared/Domain/Logic/LLM*` -> `Sources/Infrastructure/LLM/`
- 移动：`Sources/Shared/Domain/Processors/AI/VectorIndexer.swift` -> `Sources/Infrastructure/VectorDB/VectorIndexer.swift`

- [ ] **步骤 1：物理移动与代码合规**
在 LLM 和向量库代码中植入 PR-01, PR-02 性能指标溯源标注。
- [ ] **步骤 2：提交代码**
`git commit -m "refactor: 迁移并标准化 L1 Infrastructure 基础设施层"`

---

## 第三阶段：业务模块垂直化 (Features L2)

### 任务 5：重构对话模块 (垂直切片示例)
**涉及文件：**
- 移动：`Sources/Shared/Views/Features/ChatView.swift` -> `Sources/Features/Chat/View/ChatView.swift`
- 移动：`Sources/Shared/ViewModels/ChatViewModel.swift` -> `Sources/Features/Chat/ViewModel/ChatViewModel.swift`
- 创建：`Sources/Features/Chat/Service/ChatService.swift` (从 Domain 提取)

- [x] **步骤 1：建立垂直目录结构并移动文件**
- [x] **步骤 2：实施基于协议的依赖注入**
  定义 `ChatServiceProtocol`，通过 `ServiceContainer` 实现解耦。
- [x] **步骤 3：增强 DFX 日志**
  为对话响应链路添加结构化延迟追踪日志。
- [x] **步骤 4：提交代码**`git commit -m "refactor: 垂直化 Chat 模块，补全 DFX 与 SRS 溯源"`

---

## 第四阶段：应用层与全局路由 (L3)

### 任务 6：实现全局路由与应用环境
**涉及文件：**
- 创建：`Sources/App/Router.swift`
- 创建：`Sources/App/AppEnvironment.swift`

- [x] **步骤 1：实施 AppEnvironment**
  管理 Core 与 Infrastructure 层的初始化顺序。
- [x] **步骤 2：实施 Router**
  集中管理所有跨模块导航逻辑。
- [x] **步骤 3：提交代码**
`git commit -m "feat: 实现 App 层路由调度与全局环境管理"`

---

## 第五阶段：测试同步与质量验收

### 任务 7：同步测试用例与 SRS 编号
**涉及文件：**
- 创建：`Tests/Features/ChatTests.swift`
- 创建：`Tests/Infrastructure/LLMTests.swift`

- [ ] **步骤 1：更新测试用例**
确保每个重构后的模块都有对应的单元测试，且测试描述中包含 SRS ID。
- [ ] **步骤 2：修复遗留 Bug 并验证**
修复 `AppStore.ToolItem` 成员缺失问题，验证 iPad 性能监控 Sheet。
- [ ] **步骤 3：提交代码**
`git commit -m "test: 同步重构模块的测试用例与质量指标"`
