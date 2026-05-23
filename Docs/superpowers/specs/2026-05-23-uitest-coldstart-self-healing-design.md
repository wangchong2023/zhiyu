# UI 自动化测试冷启动自愈逻辑设计规格书

- **作者**: Wang Chong / Antigravity AI
- **日期**: 2026-05-23
- **版本**: 1.0
- **项目**: 智宇 (ZhiYu) - AI 原生知识管理应用
- **版权**: 版权所有 © 2026 Wang Chong。保留所有权利。

---

## 1. 背景与痛点

在以 `--uitesting --reset-state` 模式冷启动时，测试数据库是完全被清空的。这意味着应用在启动后，会停留在大厅 `NotebookHubView` 中（无任何笔记本卡片）。在此状态下：
1. **找不到 TabBar**：应用的底部 Tab 栏属于主界面的一部分，在尚未进入任何一个具体笔记本之前，整个 TabBar 是不存在的。
2. **测试级联崩溃**：现有的 UI 测试基类 `setUp()` 因为在空状态下找不到卡片，退化为盲点 `element(boundBy: 0)`。这会意外弹出“新建笔记本”的 Sheet，但却没有对其进行输入与保存提交，导致后续测试用例运行时 UI 完全被表单 Sheet 覆盖，找不到 TabBar，造成所有用例级联报错崩溃。

为了解决这一问题，我们需要建立一套**基于精准标识符的可测试性架构与自愈流式引导机制**。

---

## 2. 方案设计

我们决定采用 **方案 A：精准可访问性标识符（Accessibility Identifiers）与 UI 层流式自愈相结合** 的设计。

### 2.1 业务视图层可测试性改造

我们需要在业务视图中增加专用于 UI 测试定位的 `accessibilityIdentifier`：
1. **空状态引导按钮**
   - **文件**: `Sources/Shared/UIComponents/Feedback/AppEmptyState.swift`
   - **标识符**: `empty_state_action_button`
   - **可访问容器优化**: 在非测试状态下，为了 VoiceOver 读屏器用户体验，容器会采用 `.combine` 合并子元素；但若在 `--uitesting` 测试模式下，则动态调整为 `.contain`，以确保 XCUITest 能够向下穿透并定位到具体的 action Button。
2. **新建笔记本表单**
   - **文件**: `Sources/Features/Knowledge/NotebookHub/View/Components/NotebookFormSheet.swift`
   - **名称输入框**: `notebook_name_textfield`
   - **保存确认按钮**: `notebook_submit_button`

### 2.2 测试框架自愈跳转流程

修改 UI 自动化测试基类 `KnowledgeBaseUITests.swift` 与 `ZhiYuPlatformUITests.swift` 中的 `setUp()` 自愈保护逻辑：

1. **第一阶段：状态判定**
   - 检查 `app.tabBars.firstMatch.exists` 是否为假。若为假，表明当前尚未进入笔记本主界面，需要启动自愈引导。
2. **第二阶段：尝试寻找已有卡片**
   - 检查是否已经存在代表笔记本的 Button 元素（`NotebookCard_Item` 或 label 包含“的笔记本”的按钮）。若存在，直接点击该卡片以进入主页。
3. **第三阶段：流式模拟创建（自愈核心）**
   - 若数据库中确实不存在任何卡片，触发流式创建：
     - 点击空状态的引导按钮 `empty_state_action_button` 弹出创建表单。
     - 等待表单 Sheet 弹出，并精确定位输入框 `notebook_name_textfield`。
     - 激活输入框并键入 `"测试笔记本"`。
     - 点击保存按钮 `notebook_submit_button` 提交保存。
     - 表单关闭后，等待新笔记本卡片刷新出来并点击进入。
4. **第四阶段：异常熔断与等待时长**
   - 在每一步的 UI 模拟动作中，设置 3.0 秒的 `waitForExistence` 超时，防范模拟器启动缓慢或由于设备类型差异导致的永久阻塞。

---

## 3. 详细设计与代码接口

### 3.1 业务层代码修改细节

#### `AppEmptyState.swift`
```swift
// 修改后：
VStack(spacing: Spacing.giant) {
    ...
    if let action = action {
        Button(action: action.handler) {
            ...
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("empty_state_action_button")
    }
}
.accessibilityElement(children: ProcessInfo.processInfo.arguments.contains("--uitesting") ? .contain : .combine)
```

#### `NotebookFormSheet.swift`
```swift
// 修改后：
TextField(L10n.Vault.namePlaceholder, text: $name)
    .font(.title3.bold())
    .padding()
    .background(Color.appCard)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .accessibilityIdentifier("notebook_name_textfield")

...

ToolbarItem(placement: .confirmationAction) {
    Button(submitLabel) {
        onSubmit()
        dismiss()
    }
    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    .accessibilityIdentifier("notebook_submit_button")
}
```

### 3.2 测试基层自愈代码细节

在 `setUp()` 中，将原跳转保护块替换为以下逻辑（两份测试文件对齐）：

```swift
if !app.tabBars.firstMatch.exists {
    let firstVaultCard = app.buttons.containing(NSPredicate(format: "label CONTAINS '的笔记本'")).element(boundBy: 0)
    let anyCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
    
    if firstVaultCard.waitForExistence(timeout: 2.0) && firstVaultCard.exists {
        firstVaultCard.tap()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    } else if anyCard.exists {
        anyCard.tap()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    } else {
        // 全新数据库，触发流式创建
        let createBtn = app.buttons["empty_state_action_button"]
        if createBtn.waitForExistence(timeout: 3.0) && createBtn.exists {
            createBtn.tap()
            
            let nameField = app.textFields["notebook_name_textfield"]
            if nameField.waitForExistence(timeout: 3.0) {
                nameField.tap()
                nameField.typeText("测试笔记本")
                
                let submitBtn = app.buttons["notebook_submit_button"]
                if submitBtn.exists {
                    submitBtn.tap()
                    
                    // 提交后，等待主列表刷新出新卡片并点击进入
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    let newCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
                    if newCard.waitForExistence(timeout: 3.0) {
                        newCard.tap()
                        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    }
                }
            }
        }
    }
}
```

---

## 4. 验证计划

1. **宿主 App 编译**：确保改动后 iOS 模拟器及 macOS 平台均能顺利编译成功。
2. **测试套件运行**：在 iPhone 17 Pro 模拟器或 iPad 模拟器上，对 `ZhiYuPlatformUITests` 和 `KnowledgePageUITests` 进行冷启动拉起，观察整个创建笔记本并点击进入的过程是否流畅。
3. **回归验证**：验证完毕后，查看生成的单元测试和 UI 测试运行报告，确保没有产生级联失败的误触发。
