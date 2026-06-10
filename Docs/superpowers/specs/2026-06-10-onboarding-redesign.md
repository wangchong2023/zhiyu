# 引导体系优化 Design Spec

**Goal:** 优化空状态引导 + 渐进式功能发现 + 里程碑提示，提升新用户上手体验

**Scope:** 3 个模块，统一实施

---

## 模块一：空状态引导场景化

### 替代现有 WelcomeQuickStartGuideSection

**当前:** 2 步文字 + 演示数据按钮
**优化:** 3 个场景卡片让用户选择路径

### 数据模型

```swift
enum OnboardingPath: String, CaseIterable {
    case quickStart  // 快速体验（注入演示数据）
    case importData  // 导入数据（跳转到导入Tab）
    case explore     // 自己探索（关闭引导）
}
```

### UI 结构

```
WelcomeHeroSection         ← 保留
WelcomeStatsSection        ← 保留
┌─ 开始使用 ──────────────────────────────┐
│  选择一种方式开始：                         │
│                                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │ 🚀 快速   │ │ 📥 导入   │ │ 🔍 探索   │ │
│  │ 体验     │ │ 数据     │ │ 自己      │ │
│  └──────────┘ └──────────┘ └──────────┘ │
│                                           │
│  [选择快速体验后展示演示数据预览卡片]        │
└───────────────────────────────────────────┘
WelcomeQuickActionsSection  ← 保留
```

### L10n keys

| Key | zh-Hans | en |
|-----|---------|-----|
| `onboarding.path.quickStart` | 快速体验 | Quick Start |
| `onboarding.path.import` | 导入数据 | Import Data |
| `onboarding.path.explore` | 自己探索 | Explore |
| `onboarding.path.quickStart.desc` | 一键注入演示数据，立即感受完整功能 | Instantly see what ZhiYu can do |
| `onboarding.path.import.desc` | 从文件、链接或剪贴板迁移现有笔记 | Migrate from files, links, clipboard |
| `onboarding.path.explore.desc` | 从空白画布开始，用到哪学到哪 | Start fresh, learn as you go |

---

## 模块二：渐进式功能发现

### 每个功能 Tab 的空状态 + 首次进入引导

**实现方式:** 使用现有的 `OnboardingOverlay` 组件，增加各 Tab 的引导卡片

### 各 Tab 引导内容

| Tab | 条件 | 引导内容 |
|-----|------|---------|
| 知识库 | pages.isEmpty | 创建第一页 or 导入 |
| AI 对话 | pages.count ≥ 1, 首次进入 | 快捷提问建议 |
| AI 对话 | pages.isEmpty | 提示先去添加知识 |
| 图谱 | pages.count ≥ 3, 首次进入 | 图谱交互说明 |
| 图谱 | pages.count < 3 | 提示需要更多页面 |
| 综合 | pages.count ≥ 5, 首次进入 | 综合功能介绍 |
| 综合 | pages.count < 5 | 提示需要更多页面 |

### 首次进入状态存储

```swift
// UserDefaults keys
"onboarding.didShowChatTip" → Bool
"onboarding.didShowGraphTip" → Bool
"onboarding.didShowSynthesisTip" → Bool
```

---

## 模块三：里程碑提示

### 实现方式

`AppEventBus` 事件驱动，`KnowledgeStore` 或 `AppStore` 在关键动作后发布里程碑事件，`ToastManager` 展示轻量提示

### 里程碑定义

```swift
enum OnboardingMilestone {
    case firstPageCreated      // 第 1 页 → "第一页！"
    case firstAIChat           // 首次对话 → "AI 已就绪"
    case firstGraphView        // 首次图谱 → "知识关联已就绪"
    case knowledgeScale(Int)   // 第 10/50/100 页 → "初具规模"
    case firstSynthesis        // 首次综合 → "洞察已生成"
}
```

| 触发条件 | Toast |
|---------|-------|
| pageCount == 1（首次创建后） | 🎉 第一页！已加入知识库 |
| 首次 AI 对话完成 | 💡 AI 正在基于你的知识回答 |
| 首次进入图谱（≥3页） | 🕸️ 知识关联已就绪，拖拽探索连接 |
| pageCount == 10 | ⭐ 已有 10 页，试试 AI 综合 |
| 首次综合完成 | 🧠 洞察已生成 |
```
