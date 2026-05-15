# 魔鬼数字与字符串深度优化计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 消除 ZhiYu 项目中的硬编码数值、SF Symbols 字符串、通知名称和存储键名，提升代码的可维护性与类型安全性。

**Architecture:** 采用“集中定义 -> 语义化引用”的模式。通过扩展 `DesignSystem`、`AppConstants`、`Notification.Name` 和 `L10n`，为 Feature 层提供强类型的 DSL。

**Tech Stack:** Swift 6, SwiftUI, Combine.

---

### Task 1: 基础令牌扩展 (Opacity & Shadow)

**Files:**
- Modify: `Sources/Shared/DesignSystem/DesignSystem.swift`

- [x] **Step 1: 在 DesignSystem 中添加 Opacity 枚举**
- [x] **Step 2: 在 DesignSystem 中添加 Shadow 令牌**

### Task 2: SF Symbols 标准化

**Files:**
- Modify: `Sources/Shared/DesignSystem/DesignSystem.swift`

- [x] **Step 1: 补全 Icons 枚举中缺失的符号**

### Task 3: 通知名称与存储键名集中化

**Files:**
- Modify: `Sources/Core/Notifications/AppNotifications.swift`
- Modify: `Sources/Core/Constants/AppConstants.swift`

- [x] **Step 1: 补全所有系统级通知名称**
- [x] **Step 2: 在 AppConstants 中定义 Keys 结构体**

### Task 4: 统一日期格式化

**Files:**
- Create: `Sources/Core/Extensions/Date+App.swift`

- [x] **Step 1: 实现 AppDateFormatter**

### Task 5: L10n DSL 增强

**Files:**
- Modify: `Sources/Core/Utils/Localized.swift`

- [x] **Step 1: 为主要模块添加静态文案访问器**

### Task 6: Feature 层 application 优化 (以 Chat 为例)

**Files:**
- Modify: `Sources/Features/Chat/View/ChatView.swift`

- [x] **Step 1: 替换硬编码数值与字符串**
    - [x] 使用 `DesignSystem.Opacity.glass` 替换 `0.15`
    - [x] 使用 `DesignSystem.Icons.thinking` 替换 `"sparkles"`
    - [x] 使用 `L10n.Chat.inputPlaceholder` 替换字符串 key
    - [x] 使用 `Notification.Name.toggleSidebar` 替换硬编码字符串

---
**Verification Plan:**
1. [x] 编译工程，确保无语法错误。
2. [ ] 运行 Unit Tests，确保本地化和常量读取逻辑正确。（用户取消，但已通过构建验证）
3. [x] 手动测试 UI：检查 Chat 透明度是否一致，图谱缩放是否正常。
