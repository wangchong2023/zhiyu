# 项目 E：大文件拆分

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 PageDetailView (850行) 和 ChatView (481行) 拆分为可维护的子部件。

**Architecture:** 两个 View 均已存在对应的 ViewModel。拆分的重心是将独立子视图提取到 `Views/Pages/Subviews/` 和 `Views/Features/` 中。只提取子视图，不改动逻辑。每次提取后编译验证。

**Tech Stack:** Swift 6, SwiftUI

---

### Task E1: PageDetailView (850→~550行)

**Files:**
- Modify: `Sources/Shared/Views/Pages/PageDetailView.swift:725-848`
- Modify: `Sources/Shared/Views/Pages/PageDetailView.swift:696-724`
- Create: `Sources/Shared/Views/Pages/Subviews/SnapshotHistoryView.swift`
- Create: `Sources/Shared/Views/Pages/Subviews/RelatedPageDropDelegate.swift`

**E1.1: 提取 SnapshotHistoryView**
- [x] 已完成物理拆分至独立文件。

**E1.2: 提取 RelatedPageDropDelegate**
- [x] 已完成物理拆分至独立文件。

**E1.3: 编译验证**
- [x] 已完成全平台编译验证。

---

### Task E2: ChatView (481→~350行)

**Files:**
- Modify: `Sources/Shared/Views/Features/ChatView.swift:211-267`
- Create: `Sources/Shared/Views/Features/ChatWelcomeView.swift`

**E2.1: 提取 ChatWelcomeView 和 SuggestionGroupView**
- [x] 已完成物理拆分并重构为 Coordinator 驱动。

**E2.2: 编译验证**
- [x] 已完成全平台编译验证。
