# ZhiYu 架构重构实施计划 (ZhiYu Architecture Refactor)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 ZhiYu 工程从 L0-L3 水平分层架构迁移到以 Feature 为核心的模块化架构，实现物理归类清晰、逻辑高度解耦、资源配置合理且视觉无损的工程结构，并保持 100% 的跨平台构建成功率。

**Architecture:** 垂直 Feature 架构，划分为 App (入口), Core (技术底座), Infrastructure (AI 能力), Features (业务闭环), Shared (全局共享) 五大顶层模块。

**Tech Stack:** Swift 6, SwiftUI, XcodeGen, GRDB.

---

## 阶段 1：基础设施与核心层迁移 (Foundation)

### 任务 1.1：创建目标目录骨架
- [ ] **Step 1: 执行目录创建命令**
```bash
mkdir -p Sources/App/Resources Sources/Core/Network Sources/Core/Storage Sources/Core/Logger Sources/Core/Database Sources/Core/Extension Sources/Core/Utils Sources/Core/Resources Sources/Infrastructure/LLM Sources/Infrastructure/VectorDB Sources/Infrastructure/OCR Sources/Infrastructure/Analytics Sources/Features/Chat/Resources Sources/Features/KnowledgeBase/Resources Sources/Features/Search/Resources Sources/Features/Settings/Resources Sources/Shared/Models Sources/Shared/UIComponents/Layouts Sources/Shared/Theme Sources/Shared/DesignSystem Sources/Shared/Protocols Sources/Shared/Resources
mkdir -p Tests/Unit/Core Tests/Unit/Infrastructure Tests/Unit/Features Tests/Platforms
```

### 任务 1.2：迁移核心原子组件与单元测试
- [ ] **Step 1: 移动 Logger 及其测试**
    - 移动代码至 `Sources/Core/Logger/Logger.swift`。
    - **同步**：移动或更新 `Tests/Unit/LoggerTests.swift` 路径。
    - **验证**：运行 iOS/macOS 双端测试。

---

## 阶段 2：UI 系统规范化 (UI System Refactoring)

### 任务 2.1：拆分 AppUI.swift 并更新 UI 测试
- [ ] **Step 1: 提取原子常量到 DesignSystem.swift**
- [ ] **Step 2: 验证 UI 渲染一致性**
    - 运行 `ZhiYuTests/SnapshotTests` 确保布局无偏差。

---

## 阶段 3：业务功能聚合与资源同步 (Feature Migration)

### 任务 3.1：迁移 Chat 功能模块与本地化资源
- [ ] **Step 1: 聚合 Chat 物理组件**
- [ ] **Step 2: 治理代码质量 (NBNC < 100, Complexity < 15, 中文注释)**
- [ ] **Step 3: 检查平台宏滥用**
    - 将业务逻辑中的 `#if os()` 封装进协议或环境扩展。

---

## 阶段 4：收尾与跨平台质量验收 (Final Cleanup & Cross-Platform QA)

### 任務 4.1：全平台构建与验证
- [ ] **Step 1: 更新 project.yml**
- [ ] **Step 2: 执行全量跨平台验证**
    - Build iOS: `xcodebuild build -scheme ZhiYu -destination 'generic/platform=iOS Simulator'`
    - Build macOS: `xcodebuild build -scheme ZhiYuMac -destination 'platform=macOS'`
- [ ] **Step 3: 运行跨平台 Snapshot 测试对比**
- [ ] **Step 4: 提交**
```bash
git commit -m "refactor: architecture restructuring complete with cross-platform validation"
```
