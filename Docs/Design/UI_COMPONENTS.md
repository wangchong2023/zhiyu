# UI 组件与布局系统设计

本文档定义了“智宇”系统中 UI 组件的划分策略与布局规范，确保跨平台 (iOS/iPadOS/macOS) 的视觉一致性。

## 1. DesignSystem (设计系统)

核心设计资产（Token）和基础视觉定义，位于 `Sources/Shared/DesignSystem/`。

- `Tokens/Colors.swift`: 全局语义化色彩定义，必须支持 Dark/Light Mode 切换。
- `Tokens/Spacing.swift`: 间距与圆角常量定义。严禁在视图中使用散落的硬编码数字（魔鬼数字）。
- `Tokens/Typography.swift`: 排版与字号层级，映射为逻辑缩放大小。
- `Tokens/Animations.swift`: 系统级物理动效定义。

## 2. UIComponents (公共 UI 组件)

通用且无业务状态（Stateless）的视觉积木，位于 `Sources/Shared/UIComponents/`。

- `Buttons/`: 各种应用级别按钮。
- `Cards/`: 数据展示卡片（如 `AppCard`, `StatCard`）。
- `Feedback/`: 轻提示、加载浮层（如 `AppToast`, `AppEmptyState`）。
- `Modifiers/`: 视觉修饰符封装，例如 `GlassStyle` 玻璃拟态。

## 3. Layouts (布局模板)

用于界面的骨架约束结构，位于 `Sources/Shared/UIComponents/Layouts/`。

- `StandardSection.swift`: 标准区块布局，提供一致的内边距和流式排列。
- `FlowLayout.swift`: 流式自适应包裹布局，多用于标签云等可换行内容。
- **业务定制要求**：在重构过程中，需要保持既有布局效果不被破坏。遇到特定业务界面的定制布局需求时，禁止在 View 层直接硬编码堆叠，而是应提炼模板并存放到 `Layouts` 下（或对应模块的特定 Layout 子目录中）。

---

*参考文档：*
* - `SOFTWARE_REQUIREMENTS_SPECIFICATION.md`*
* - `swift-coding-style.md`*
