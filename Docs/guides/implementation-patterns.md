# 实现模式参考

> 本文档是 CLAUDE.md 中 `## 关键模式` 的详细展开。

## Swift 6 编译器变通方案

- **`static let` 配合自定义 `Color(light:dark:)` 初始化器会失败**：Swift 6 在使用带嵌套闭包的自定义初始化器的 `static let` 属性时可能产生 "failed to produce diagnostic for expression" 错误。**变通方案**：改用 `static var` 计算属性：
  ```swift
  static var wikiCard: Color { Color(light: Color(hex: "ffffff"), dark: Color(hex: "202031")) }
  ```
- **`nonisolated(unsafe)` 用于单例**：非 `Sendable` 类中的 `static let shared` 需要该属性才能在 Swift 6 严格并发下编译通过。

## 架构解耦模式

### 1. 模块化 DI (Modular Dependency Injection)
避免在 `ZhiYuApp.init()` 中平铺数百行注册逻辑。使用 `ModuleRegistrar`：
- 每个层级（Core, Storage, Domain）定义自己的 `Registrar`。
- `ZhiYuApp` 仅负责按顺序调用 `register(in:)`。
- **优点**：启动代码整洁，支持在测试环境中一键替换整组 Mock。

### 2. 能力协议 (Capability Protocols)
当 L2 服务需要访问 L1 Store 的特定高级功能（如向量索引）时，不要使用类型强转（`as? SQLiteStore`）。
- 定义 `VectorIndexableStore` 协议。
- Store 遵循协议。
- 服务通过 `if let store = pageStore as? any VectorIndexableStore` 访问。
- **优点**：消除硬编码依赖，维持分层边界。

### 3. Actor 化重型处理器 (Actor-based Processors)
计算密集型服务（OCR、语音识别）应定义为 `actor` 而非 `class`。
- **职责**：确保内部状态（如 Vision 请求队列）的并发安全。
- **规范**：移除 `@unchecked Sendable`，拥抱 Swift 6 的原生数据隔离。

### 4. 表现层扩展 (View Extensions)
模型（Model）层严禁 `import SwiftUI`。
- 图标（icon）、颜色（Color）属性应存放在 `Views/Styles/` 目录下的 Extension 中。
- **优点**：保持 Model 的纯粹性，方便多平台（如无 UI 的 CLI 工具）重用模型。

## SwiftUI 图谱模式

- **浮动控件**：对浮动在内容之上的控件（Picker、缩放按钮、筛选药丸），使用 `.overlay(alignment:)`。避免使用带有 `VStack { Spacer() }` 的 ZStack 子视图——它们会创建透明的全屏层，拦截触摸事件。`.overlay(alignment:)` 仅占据其内容的固有尺寸。
- **节点定位**：仅在最外层视图上使用**单个** `.position()` 修饰符。绝不要嵌套 `.position()`——双重定位会使节点偏移约 2 倍，而 Canvas 绘制的边则保持在正确的坐标，造成视觉错位。

## 合成文档多份存储

`AppStore.synthesisResults` 是 `[SynthesisType: [SynthesisDocument]]`，每种类型最多保留 **5 份**文档（新文档插入数组头部，超出则截断）。通过 `UserDefaults` key `synthesis_docs_<type.rawValue>` 持久化 JSON 数组。

- `renameSynthesisDoc(type:docID:newName:)` — 重命名
- `deleteSynthesisDoc(type:docID:)` — 删除
- `SynthesisView` 中通过 `.contextMenu` 长按触发重命名/删除，`selectedDoc` 驱动输出 sheet

## 每日/每周洞察缓存

- **每日闪念**（`KnowledgeInsightService.generateDailyRecap`）：UserDefaults key `daily_recap_yyyyMMdd`，当天仅生成一次，`forceRefresh: true` 可强制重新生成
- **每周报告**（`AppStore.generateWeeklyInsight`）：UserDefaults key `weekly_insight_<year>_<weekOfYear>`，当周仅生成一次，`forceRefresh: true` 可强制重新生成
- Dashboard 手动下拉刷新传入 `forceRefresh: true`

## 测验生成流程

AI 输出 JSON（匹配 `QuizModel` 结构，`answer` 为 0 起始索引，0=A/1=B/2=C/3=D）→ `AISynthesisService.canDecodeAsQuizModel()` 验证格式 → `PageDetailView` 解码为 `QuizModel` → `QuizView` 交互式展示（选项标签 A/B/C/D，解释文本中数字索引替换为字母）。若 JSON 格式不匹配，回退到 Markdown 渲染。

## Mermaid 渲染模式

**始终使用程序化 `mermaid.render()`**，不要依赖 `startOnLoad: true`（不稳定）。标准模式：

1. HTML 中设置 `startOnLoad: false`，使用 `mermaid.render('id', code)` 异步渲染 SVG
2. 外层 `waitForMermaid()` 轮询 CDN 脚本加载完成
3. `WKWebView.evaluateJavaScript` 会等待 Promise 完成
4. 渲染失败时显示中文错误提示

`MermaidWebView`（展示）和 `exportMindmapToPDF()`（导出 PDF）均遵循此模式。

## WebViewExportService

`WebViewExportService`（L0 层）使用隐藏 `WKWebView` 执行 JavaScript 实现跨平台导出：
- **PDF**：`marked.parse()` 渲染 Markdown → `WKWebView.createPDF()`
- **PPTX**：解析 Markdown 为幻灯片 → `PptxGenJS` 生成 Base64 → 写入文件

## UI 框架

- 100% SwiftUI（除 `LaunchScreen.storyboard` 外无 UIKit storyboard）
- 使用 Swift 5.9 `@Observable` 宏（非 `@ObservableObject` / `@Published`）
- `NavigationSplitView` 自适应布局：iPhone 上为 TabView，iPad 上为三列布局
- 通过 `ZhiYuMac` target 支持 Mac Catalyst，带有键盘快捷键（`CommandGroup`、`.keyboardShortcut`）

## LLM 提示词输入/输出长度控制（三层防御）

业界标准做法：**API 硬限制 + Prompt 软引导 + 客户端兜底截断**，三重保障防止回复失控和费用浪费。

### 架构

```
输入截断                         API 调用                         输出控制
────────                        ────────                         ────────
Chat 用户输入                    max_tokens = 1000               API 硬限制
  .prefix(1000)         ──→      (ChatRunner.generate)    ──→    绝对不超

合成功能 content                 Prompt 注入                      Prompt 软引导
  .truncated(500)       ──→      "控制在1000字以内"        ──→    提升质量

所有 generate() 调用             BusinessConstants.AI             客户端兜底
  自动携带 maxTokens 默认值       统一配置入口                     .prefix()
```

### 统一常量 (`BusinessConstants.AI`)

| 常量 | 值 | 作用域 | 说明 |
|------|----|--------|------|
| `maxUserInputLength` | 1000 | Chat 用户输入 | ChatCoordinator 发送前截断 |
| `maxSynthesisInputLength` | 500 | 合成/后台 prompt | AISynthesisService.truncated() |
| `maxOutputTokens` | 1000 | 所有 LLM 调用 | ChatRunner.generate() 的 max_tokens 参数 |

> 所有限制在 `Sources/Domain/Models/BusinessConstants.swift` 的 `BusinessConstants.AI` 中一处调整即可全局生效。

### 流式 Chat 特殊处理

流式 Chat（`LLMChatService.streamChat`）走独立管线：
- **API 层**：`max_tokens: BusinessConstants.AI.maxOutputTokens`
- **Prompt 层**：注入 `lengthHint` → `"Keep response within 1000 characters."`
- **输入层**：`ChatCoordinator` 截断用户输入至 `maxUserInputLength`

### 非流式 generate() 特殊处理

所有通过 `llm.generate()` 的调用（合成、摄取、检索、重构）：
- `ChatRunner.generate()` 接受 `maxTokens` 参数，默认值 = `BusinessConstants.AI.maxOutputTokens`
- 协议 `LLMChatServiceProtocol` 声明 `maxTokens:` 为必选参数
- 所有现有调用方无需修改——默认值自动生效
- 特殊需求（如 `LLMRefactorService`）可显式传参覆盖：
  ```swift
  // 链接发现只需短输出
  try await generate(prompt: ..., systemPrompt: ..., maxTokens: 500)
  ```

### 如何调整

```swift
// Sources/Domain/Models/BusinessConstants.swift
public struct AI {
    public static let maxUserInputLength: Int = 1000     // ← 改这里
    public static let maxSynthesisInputLength: Int = 500 // ← 改这里
    public static let maxOutputTokens: Int = 1000        // ← 改这里
}
```

修改后重新编译即可，无需改动任何其他代码。
