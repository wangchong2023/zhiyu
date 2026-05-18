# P1 技术债解决计划 (P1 Tech Debt Resolution)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 解决 `FULL_PROJECT_AUDIT_REPORT_2026_05_16.md` 中标识的 P1 级别规范化与代码坏味道问题，主要集中在常量中心化（消除魔法字符串）和进一步的视图组件拆分。

---

### Task 1: 视图组件拆分 (View Splitting)

**Files:**
- Create: `Sources/Features/Knowledge/NotebookHub/View/Components/CreateNotebookButton.swift`
- Modify: `Sources/Features/Knowledge/NotebookHub/View/NotebookHubView.swift`

- [ ] **Step 1: 提取创建按钮组件**
  - 将 `NotebookHubView.swift` 中的 `createNotebookCard` 和 `createNotebookListRow` 提取到新文件 `CreateNotebookButton.swift` 中，封装为一个支持 `displayMode` 参数的通用组件。
- [ ] **Step 2: 重构 NotebookHubView**
  - 移除原有的私有属性，在网格和列表布局中使用新的 `CreateNotebookButton` 组件，并传入绑定的 `viewModel` 以触发创建动作。

### Task 2: 图标常量中心化 (Icon Centralization)

**Files:**
- Modify: `Sources/Shared/DesignSystem/Tokens/Typography.swift`
- Modify: `Sources/Shared/DesignSystem/DesignSystem.swift`
- Modify: `Sources/Features/**/*.swift` (涉及包含硬编码 `systemImage` 的所有视图文件)

- [ ] **Step 1: 扩充 Typography.Icons**
  - 将目前散落在各个 Feature 视图中的未定义系统图标 (SF Symbols) 添加到 `Typography.Icons` 结构体中（例如 `trash.slash.fill`, `doc.text`, `photo.on.rectangle` 等）。
- [ ] **Step 2: 映射至 DesignSystem.Icons**
  - 在 `DesignSystem.Icons` 中添加对应的映射，保持设计系统的统一访问入口。
- [ ] **Step 3: 视图层替换**
  - 遍历 `Sources/Features/` 目录，将所有形如 `systemImage: "..."` 的硬编码调用替换为 `systemImage: DesignSystem.Icons.xxx`。

### Task 3: 存储键名常量中心化 (Storage Key Centralization)

**Files:**
- Modify: `Sources/Core/Base/Constants/AppConstants.swift`
- Modify: 各个使用硬编码 `UserDefaults` 键的文件 (如 `OnboardingService.swift`, `AuthService.swift`, `SettingsStore.swift`, `SecurityManager.swift` 等)。

- [ ] **Step 1: 扩充 AppConstants.Keys.Storage**
  - 将各个模块中隐式使用的 `UserDefaults` 键名（如 `"auth.isAuthenticated"`, `"hasCompletedOnboarding"`, `"vaults.selectedID"` 等）集中定义到 `AppConstants.Keys.Storage`（或为其创建如 `Auth`, `Vault`, `Security` 等子结构体进行分类）。
- [ ] **Step 2: 替换调用点的硬编码键名**
  - 将所有使用 `UserDefaults.standard` 的地方，其 `forKey:` 参数替换为 `AppConstants.Keys.Storage` 中对应的新常量。

---
**Verification Plan:**
1. [ ] 编译全平台 Target，确保 **BUILD SUCCEEDED**。
2. [ ] 验证包含新建图标和存储键名的视图是否渲染正常。
3. [ ] 验证用户设置、登录状态等 `UserDefaults` 读写操作未被破坏。
4. [ ] 确认 `NotebookHubView` 的“新建笔记本”按钮在列表和网格模式下均正常工作。