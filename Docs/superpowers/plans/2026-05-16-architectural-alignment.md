# 智宇架构深度对齐计划 (Kernel & Domain Alignment)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 通过物理拆分 L0 核心层为 Base 与 System，提取 L1.5 领域层，并进化表现层 ViewFactory 为插件化分发模式，实现“基座纯净、大脑中台化、业务垂直化、表现插件化”的最终架构目标。

---

### Task 1: L0 核心层“基座化”拆分 (Base vs System)

- [x] **Step 1: 物理移动 L0 目录** (Base: 纯定义/协议; System: OS 能力封装)

### Task 2: 提取 L1.5 领域层 (Domain Layer)

- [x] **Step 1: 物理移动业务编排逻辑** (RAG, 核心模型, 特性契约)
- [x] **Step 2: project.yml 同步**

### Task 3: 表现层 ViewFactory 进化 (L3 插件化)

**Files:**
- Create: `Sources/Core/Base/Protocols/ViewProvider.swift`
- Modify: `Sources/App/Router.swift`
- Create: `Sources/Features/*/ViewProvider.swift`
- Modify: `Sources/App/ViewFactory.swift`
- Modify: `Sources/App/ModuleRegistrar.swift`

- [x] **Step 1: 定义 ViewProvider 协议** (L0 Base 层)
- [x] **Step 2: AppRoute 领域感知化** (添加 `public var domain` 属性)
- [x] **Step 3: 实现领域视图提供者** (Knowledge, AI, Insight, System)
- [x] **Step 4: ViewFactory 注册表化重构** (移除巨大的 switch-case)
- [x] **Step 5: 在 ModuleRegistrar 中动态注册**

---
**Verification Plan:**
1. [x] 编译全平台 Target，确保 **BUILD SUCCEEDED**。
2. [x] 验证跨模块导航（如侧边栏切换）是否正常工作。
3. [x] 确认 `ViewFactory` 中不再包含具体的 `case` 分发，完全依赖注册表。
