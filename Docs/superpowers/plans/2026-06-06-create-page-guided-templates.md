# CreatePageView 引导式模板重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 替换 CreatePageView 的 markdown 等宽字体模板为自然语言引导式结构化表单，降低用户输入门槛。

**Architecture:** 保留 `content` @State 和 `createPage()` 不变。三个模板函数改为注入结构化自然语言 placeholder，`TextEditor` 字体从 `.monospaced` 改为标准系统字体。模板按钮改为带描述的引导卡片。

**Tech Stack:** SwiftUI, 现有 DesignSystem tokens, 现有 L10n 体系

---

### Task 1: 新增引导式模板的 xcstrings 词条

**Files:**
- Modify: `Sources/Localization/Catalogs/Knowledge.xcstrings`
- Modify: `Sources/Localization/Extensions/L10n+Creation.swift`

- [ ] **Step 1: 在 Knowledge.xcstrings 中添加结构化模板 placeholder 词条**

在 `Sources/Localization/Catalogs/Knowledge.xcstrings` 的 `strings` 字典中加入以下 9 个 key。使用 python3 脚本批量写入：

```python
import json
path = 'Sources/Localization/Catalogs/Knowledge.xcstrings'
with open(path) as f:
    data = json.load(f)

entries = {
    "creation.template.entity.desc":       ("一句话说清楚它是什么——定义、背景、核心特征。", "Describe what it is in one sentence — definition, background, key traits."),
    "creation.template.entity.overview":   ("## 核心贡献与影响\n", "## Core Contributions\n"),
    "creation.template.entity.overviewHint": ("它带来了哪些改变？解决了什么重要问题？每行一个要点。", "What changes did it bring? What problems did it solve? One per line."),
    "creation.template.concept.desc":      ("简要说明它是什么、核心原理是什么。", "Briefly explain what it is and its core principles."),
    "creation.template.concept.definition":("## 分析与洞察\n", "## Analysis & Insights\n"),
    "creation.template.concept.analysisHint": ("它为什么重要？优势和局限是什么？适用什么场景？", "Why is it important? Strengths, limitations, use cases."),
    "creation.template.comparison.desc":   ("对比两个事物的异同——选好维度，逐项分析。", "Compare two things — pick dimensions, analyze each."),
    "creation.template.comparison.table":  ("| 维度 | A | B |\n|------|---|---|\n| | | |\n| | | |\n", "| Dimension | A | B |\n|------|---|---|\n| | | |\n| | | |\n"),
    "creation.template.comparison.conclusionHint": ("基于以上对比，总结各自适用场景与选择建议。", "Summarize use cases and selection advice based on the comparison."),
}

for k, (zh, en) in entries.items():
    data['strings'][k] = {
        "extractionState": "manual",
        "localizations": {
            "zh-Hans": {"stringUnit": {"state": "translated", "value": zh}},
            "en": {"stringUnit": {"state": "translated", "value": en}}
        }
    }

with open(path, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Done")
```

- [ ] **Step 2: 在 L10n+Creation.swift 中加入对应的强类型属性**

在 `Sources/Localization/Extensions/L10n+Creation.swift` 的 `extension L10n.Creation` 中添加 Template 子结构体：

```swift
public struct Template {
    public struct Entity {
        public static var desc: String { Creation.tr("creation.template.entity.desc") }
        public static var overview: String { Creation.tr("creation.template.entity.overview") }
        public static var overviewHint: String { Creation.tr("creation.template.entity.overviewHint") }
    }
    public struct Concept {
        public static var desc: String { Creation.tr("creation.template.concept.desc") }
        public static var definition: String { Creation.tr("creation.template.concept.definition") }
        public static var analysisHint: String { Creation.tr("creation.template.concept.analysisHint") }
    }
    public struct Comparison {
        public static var desc: String { Creation.tr("creation.template.comparison.desc") }
        public static var table: String { Creation.tr("creation.template.comparison.table") }
        public static var conclusionHint: String { Creation.tr("creation.template.comparison.conclusionHint") }
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add Sources/Localization/Catalogs/Knowledge.xcstrings Sources/Localization/Extensions/L10n+Creation.swift
git commit -m "feat: 新增引导式页面模板的 xcstrings 词条"
```

---

### Task 2: 重构 CreatePageView——等宽字体→标准字体 + 引导式模板

**Files:**
- Modify: `Sources/Features/Insight/Dashboard/View/CreatePageView.swift`

- [ ] **Step 1: 替换 TextEditor 字体**

将第 67 行的 `.monospaced` 改为标准字体：

```swift
// 旧
.font(.system(.body, design: .monospaced))
// 新
.font(.body)
```

同时更新第 63 行 watchOS 分支：

```swift
// 旧
.font(.system(.body, design: .monospaced))
// 新
.font(.body)
```

- [ ] **Step 2: 重写三个模板函数——注入结构化自然语言内容**

替换第 137-184 行的模板函数，改为自然语言引导格式：

```swift
// MARK: - 引导式模板

private func applyEntityTemplate() {
    type = .entity
    content = """
    \(L10n.Creation.Template.Entity.overview)
    \(L10n.Creation.Template.Entity.overviewHint)
    
    """
}

private func applyConceptTemplate() {
    type = .concept
    content = """
    \(L10n.Creation.Template.Concept.definition)
    \(L10n.Creation.Template.Concept.analysisHint)
    
    """
}

private func applyComparisonTemplate() {
    type = .comparison
    content = """
    \(L10n.Creation.Template.Comparison.table)
    
    \(L10n.Creation.Template.Comparison.conclusionHint)
    
    """
}
```

删除不再使用的 `entityTemplateContent` computed property。

- [ ] **Step 3: 重构模板按钮——改用带描述的引导卡片**

替换第 80-93 行的 Section 内容：

```swift
// Quick templates
Section {
    VStack(spacing: DesignSystem.small) {
        templateCard(
            icon: DesignSystem.Icons.entity,
            title: L10n.Creation.entityTemplate,
            description: L10n.Creation.Template.Entity.desc,
            action: applyEntityTemplate
        )
        templateCard(
            icon: DesignSystem.Icons.concept,
            title: L10n.Creation.conceptTemplate,
            description: L10n.Creation.Template.Concept.desc,
            action: applyConceptTemplate
        )
        templateCard(
            icon: DesignSystem.Icons.comparison,
            title: L10n.Creation.comparisonTemplate,
            description: L10n.Creation.Template.Comparison.desc,
            action: applyComparisonTemplate
        )
    }
} header: {
    Text(L10n.Creation.quickTemplates)
}
```

- [ ] **Step 4: 添加 templateCard 辅助视图**

在 `CreatePageView` 中添加 private 方法：

```swift
private func templateCard(icon: String, title: String, description: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.appAccent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: DesignSystem.Icons.forward)
                .font(.caption)
                .foregroundStyle(.appSecondary.opacity(0.4))
        }
        .padding(.vertical, DesignSystem.tiny)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 5: 编译验证**

```bash
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"
```

- [ ] **Step 6: 提交**

```bash
git add Sources/Features/Insight/Dashboard/View/CreatePageView.swift
git commit -m "refactor: CreatePageView 引导式模板——自然语言替代markdown等宽字体"
```

---

### Task 3: 更新现有测试

**Files:**
- Check: `Tests/` 目录下是否有 CreatePageView 相关测试

- [ ] **Step 1: 搜索现有测试**

```bash
grep -rn "CreatePageView\|entityTemplate\|conceptTemplate\|comparisonTemplate" Tests/ --include="*.swift"
```

- [ ] **Step 2: 如有测试引用旧的 template L10n key，更新为新 key**

确认 `L10n.Creation.template.entity.overview` 等旧 key 是否仍被引用。如果测试中引用了这些 key 的具体值（如检查 content 包含特定标记），更新为新格式。

- [ ] **Step 3: 运行相关测试**

```bash
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZhiYuTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "passed|failed|TEST SUCCEEDED"
```

- [ ] **Step 4: 提交（如有修改）**

```bash
git add Tests/
git commit -m "test: 更新 CreatePageView 模板相关测试"
```
