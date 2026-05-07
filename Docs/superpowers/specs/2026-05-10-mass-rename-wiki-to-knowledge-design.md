# 批量重命名 "Wiki" 术语设计文档

## 1. 目标
系统性地将代码库中所有的 "Wiki" 相关术语替换为指定的 "Knowledge"、"App" 或 "Page" 术语，以符合新的品牌和功能命名规范。

## 2. 术语映射表
| 原术语 | 新术语 |
| :--- | :--- |
| `WikiPage` | `KnowledgePage` |
| `WikiPageStore` | `KnowledgePageStore` |
| `WikiPageFTS` | `KnowledgePageFTS` |
| `WikiEventBus` | `AppEventBus` |
| `WikiEvent` | `AppEvent` |
| `WikiLinkProcessor` | `AppLinkProcessor` |
| `WikiLink` | `PageLink` |
| `WikiPasteboard` | `AppPasteboard` |
| `WikiImage` | `AppImage` |
| `shimmerWiki()` | `shimmerApp()` |
| `wikiCard()` | `appCard()` |
| `wikiToast()` | `appToast()` |
| `wikiSecondary` | `appSecondary` |
| `wikiAccent` | `appAccent` |
| `wikiBackground` | `appBackground` |
| `WikiGlow` | `AppGlow` |
| `WikiGlassCard` | `AppGlassCard` |
| `WikiShimmer` | `AppShimmer` |
| `WikiBadge` | `AppBadge` |
| `WikiToast` | `AppToast` |
| `WikiToastType` | `AppToastType` |
| `WikiDivider` | `AppDivider` |
| `WikiAccentLine` | `AppAccentLine` |
| `WikiGradientBG` | `AppGradientBG` |
| `WikiDotPattern` | `AppDotPattern` |
| `WikiCardAccent` | `AppCardAccent` |
| `WikiIconBox` | `AppIconBox` |
| `WikiSkeleton` | `AppSkeleton` |
| `WikiPulseDot` | `AppPulseDot` |
| `WikiEmptyState` | `AppEmptyState` |
| `WikiLoadingOverlay` | `AppLoadingOverlay` |
| `WikiTooltip` | `AppTooltip` |
| `WikiCardModifier` | `AppCardModifier` |
| `WikiBorderedCard` | `AppBorderedCard` |
| `WikiSectionHeader` | `AppSectionHeader` |
| `WikiLabeledRow` | `AppLabeledRow` |
| `WikiStepRow` | `AppStepRow` |
| `WikiChip` | `AppChip` |
| `WikiIconChip` | `AppIconChip` |
| `WikiPrimaryButton` | `AppPrimaryButton` |
| `WikiCapsuleButton` | `AppCapsuleButton` |
| `WikiSuccessBanner` | `AppSuccessBanner` |
| `WikiTextField` | `AppTextField` |
| `WikiTagField` | `AppTagField` |
| `WikiMonospacedEditor` | `AppMonospacedEditor` |
| `WikiScrollableChips` | `AppScrollableChips` |
| `WikiInlineProgress` | `AppInlineProgress` |
| `WikiToastModifier` | `AppToastModifier` |
| `WikiToastView` | `AppToastView` |
| `WikilinkPickerSheet` | `PageLinkPickerSheet` |
| `wiki_link` | `page_link` |

## 3. 实施策略

### 3.1 核心文件更新
首先更新定义这些符号的核心文件，确保它们的内部逻辑一致。
- `Sources/Shared/Models/KnowledgePage.swift`
- `Sources/Shared/Services/Storage/KnowledgePageStore.swift`
- `Sources/Shared/Services/System/AppEventBus.swift`
- 各种 UI 组件文件 (`Sources/Shared/Views/Components/App*.swift`)

### 3.2 全局批量替换
使用脚本在 `Sources/` 和 `Tests/` 目录下进行全局搜索和替换。特别注意：
- 区分大小写。
- 处理标识符（如 `wiki_link`）。
- 更新注释和文件头部。

### 3.3 构建与测试
- 运行 `xcodegen generate` 确保项目配置同步。
- 编译项目，修复由于重命名引起的编译错误（如有）。
- 运行单元测试和集成测试。

## 4. 风险评估
- **编译错误**：重命名可能影响到部分硬编码字符串或反射调用。
- **文件重命名**：如果还有文件未更名，需要同步进行（目前大部分已完成）。

## 5. 验证标准
- 代码库中不再存在上述 "Wiki" 相关的导出符号。
- 所有相关文件头已更新为正确的文件名和描述。
- 项目编译通过且所有测试通过。
