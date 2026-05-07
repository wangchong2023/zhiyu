# 移除 "Wiki" 术语重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 系统性地将代码库中所有的 "Wiki" 相关术语替换为 "Knowledge"、"App" 或 "Page" 术语。

**Architecture:** 采用“脚本批量替换 + 核心文件人工精修”的策略。首先通过 Python 脚本处理 90% 的重复性工作，然后手动修复文件头、特定逻辑注释以及复杂的符号关联，最后通过编译和测试验证。

**Tech Stack:** Swift, Python (辅助脚本), xcodegen

---

### Task 1: 批量重命名脚本准备与执行

**Files:**
- Create: `Tools/Temp/mass_rename_wiki.py`
- Modify: `Sources/**/*`, `Tests/**/*`

- [ ] **Step 1: 创建批量重命名脚本**

```python
import os
import re

mapping = {
    "WikiPageStore": "KnowledgePageStore",
    "WikiPageFTS": "KnowledgePageFTS",
    "WikiPage": "KnowledgePage",
    "WikiEventBus": "AppEventBus",
    "WikiEvent": "AppEvent",
    "WikiLinkProcessor": "AppLinkProcessor",
    "WikiLink": "PageLink",
    "WikiPasteboard": "AppPasteboard",
    "WikiImage": "AppImage",
    "shimmerWiki": "shimmerApp",
    "wikiCard": "appCard",
    "wikiToast": "appToast",
    "wikiSecondary": "appSecondary",
    "wikiAccent": "appAccent",
    "wikiBackground": "appBackground",
    "WikiGlow": "AppGlow",
    "WikiGlassCard": "AppGlassCard",
    "WikiShimmer": "AppShimmer",
    "WikiBadge": "AppBadge",
    "WikiToast": "AppToast",
    "WikiToastType": "AppToastType",
    "WikiDivider": "AppDivider",
    "WikiAccentLine": "AppAccentLine",
    "WikiGradientBG": "AppGradientBG",
    "WikiDotPattern": "AppDotPattern",
    "WikiCardAccent": "AppCardAccent",
    "WikiIconBox": "AppIconBox",
    "WikiSkeleton": "AppSkeleton",
    "WikiPulseDot": "AppPulseDot",
    "WikiEmptyState": "AppEmptyState",
    "WikiLoadingOverlay": "AppLoadingOverlay",
    "WikiTooltip": "AppTooltip",
    "WikiCardModifier": "AppCardModifier",
    "WikiBorderedCard": "AppBorderedCard",
    "WikiSectionHeader": "AppSectionHeader",
    "WikiLabeledRow": "AppLabeledRow",
    "WikiStepRow": "AppStepRow",
    "WikiChip": "AppChip",
    "WikiIconChip": "AppIconChip",
    "WikiPrimaryButton": "AppPrimaryButton",
    "WikiCapsuleButton": "AppCapsuleButton",
    "WikiSuccessBanner": "AppSuccessBanner",
    "WikiTextField": "AppTextField",
    "WikiTagField": "AppTagField",
    "WikiMonospacedEditor": "AppMonospacedEditor",
    "WikiScrollableChips": "AppScrollableChips",
    "WikiInlineProgress": "AppInlineProgress",
    "WikiToastModifier": "AppToastModifier",
    "WikiToastView": "AppToastView",
    "WikilinkPickerSheet": "PageLinkPickerSheet",
    "wiki_link": "page_link"
}

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in mapping.items():
        new_content = new_content.replace(old, new)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    targets = ['Sources', 'Tests']
    modified_count = 0
    for target in targets:
        for root, dirs, files in os.walk(target):
            for file in files:
                if file.endswith('.swift'):
                    if process_file(os.path.join(root, file)):
                        modified_count += 1
    print(f"Modified {modified_count} files.")

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: 执行脚本**

Run: `python3 Tools/Temp/mass_rename_wiki.py`
Expected: 打印修改的文件数量。

- [ ] **Step 3: 检查并提交初步修改**

```bash
git add Sources/ Tests/
git commit -m "refactor: mass rename Wiki terminology using script"
```

### Task 2: 核心模型与头部注释精修

**Files:**
- Modify: `Sources/Shared/Models/KnowledgePage.swift`
- Modify: `Sources/Shared/Services/Storage/KnowledgePageStore.swift`
- Modify: `Sources/Shared/Services/System/AppEventBus.swift`

- [ ] **Step 1: 更新 KnowledgePage.swift 头部与注释**
确保文件头部注释中的文件名、描述以及 WikiLinkProcessor 的引用都已更新。

- [ ] **Step 2: 更新 KnowledgePageStore.swift 头部与注释**
同步更新 WikiPageStore -> KnowledgePageStore 的所有注释描述。

- [ ] **Step 3: 更新 AppEventBus.swift 头部与注释**
同步更新 WikiEventBus -> AppEventBus 的所有注释描述。

### Task 3: UI 组件头部精修

**Files:**
- Modify: `Sources/Shared/Views/Components/AppCard.swift`
- Modify: `Sources/Shared/Views/Components/AppDecorators.swift`
- Modify: `Sources/Shared/Views/Components/AppEmptyState.swift`
- Modify: `Sources/Shared/Views/Components/AppLoadingOverlay.swift`
- Modify: `Sources/Shared/Views/Components/AppToast.swift`
- Modify: `Sources/Shared/Views/Components/AppTooltip.swift`
- Modify: `Sources/Shared/Views/Components/AppCardComponents.swift`

- [ ] **Step 1: 逐个检查并更新这些文件的头部注释**
确保所有 "Wiki" 字样都被替换为 "App" 或相应的新名称。

### Task 4: 编译与验证

- [ ] **Step 1: 重新生成 Xcode 项目**

Run: `xcodegen generate`

- [ ] **Step 2: 编译 iOS 目标**

Run: `./env/venv/bin/python3 -c "import os; os.system('xcodebuild build -project KM.xcodeproj -scheme KM -destination \'generic/platform=iOS Simulator\' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/ios_build.log 2>&1')"`

- [ ] **Step 3: 检查编译错误并修复**
如果有编译错误，逐个修复。

- [ ] **Step 4: 运行单元测试**

Run: `./env/venv/bin/python3 -c "import os; os.system('xcodebuild test -project KM.xcodeproj -scheme KM -destination \'platform=iOS Simulator,name=iPhone 17 Pro\' > build/test_results.log 2>&1')"`

- [ ] **Step 5: 清理临时脚本**

Run: `rm Tools/Temp/mass_rename_wiki.py`

- [ ] **Step 6: 最终提交**

```bash
git add .
git commit -m "docs: update file headers and comments for Wiki to Knowledge/App renaming"
```
