# 2026-06-21 ZhiYu UI Tests Stability Design Spec

本文档定义了解决智宇 (ZhiYu) 全平台核心业务流 UI 自动化测试套件中三个不稳定（Flaky）测试用例的设计方案与规范。通过优化输入缓冲自愈、强制时序转场阻尼以及强类型常量元素匹配，从根本上解决模拟器和慢速构建机环境下的竞态冲突。

## 1. 目标用例与问题诊断

### 1.1 testChatAISkeletonLoadingState
- **问题**：在键盘尚未完全弹起时便开始输入文本，导致文本框输入落空。输入为空时发送按钮置灰不可点击，无法触发 AI 请求流程，因而流式思考骨架屏不可达，等待文案超时。
- **定位关键文件**：[ZhiYuUITests.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Tests/UI/ZhiYuUITests.swift)

### 1.2 testPageLinkNavigation
- **问题**：列表第一项（PageRow_Item[0]）的渲染排序是不确定的，其内容不保证一定含有双向链接 `[[ `。若文档无双链，则直接跳过链接点击并在后面的导航条等待中报错，或发生非预期的转场中断。
- **定位关键文件**：[ZhiYuUITests.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Tests/UI/ZhiYuUITests.swift)

### 1.3 testVaultSwitchingAndSeedingFlow
- **问题**：金库切换时，GRDB 异步加载、表隔离与 InitialNotebookGenerator 重新注入数据开销较大。若视图转场尚未就绪就强行点击 Tab 以及进入列表项，会导致事件丢失与识别超时。
- **定位关键文件**：[ZhiYuUITests.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Tests/UI/ZhiYuUITests.swift)

---

## 2. 详细技术方案

### 2.1 testChatAISkeletonLoadingState 优化设计
1. **键盘弹出缓冲**：在 `chatInput.tap()` 之后，引入 `try? Thread.sleep(forTimeInterval: 0.8)` 强行缓冲系统键盘动效。
2. **打字丢失自愈**：
   - 执行 `chatInput.typeText(...)`。
   - 检查 `sendButton.isEnabled`。若未亮起，说明键盘未激活或输入法干扰，自动重新执行 `chatInput.tap()` 与 `chatInput.typeText(...)` 进行打字自愈。
3. **弹性识别超时**：把 `skeletonText` 的等待超时门槛由原来的 `5` 秒安全放宽至 `12` 秒。
4. **移除 flaky 屏蔽**：删除 `// @flaky` 标注。

### 2.2 testPageLinkNavigation 优化设计
1. **强类型匹配种子页面**：摒弃随机点击，改用播种中绝对含有双链 `[[主题]]` 文本的 `L10n.InitialNotebook.PKM.title1` 页面。
2. **双元素匹配防御**：
   ```swift
   let targetTitle = L10n.InitialNotebook.PKM.title1
   let targetPredicate = NSPredicate(format: "label == %@ OR identifier == %@", targetTitle, targetTitle)
   let targetPage = app.buttons.matching(targetPredicate).element(boundBy: 0)
   let targetPageCell = app.cells.matching(targetPredicate).element(boundBy: 0)
   let targetElement = targetPage.exists ? targetPage : targetPageCell
   XCTAssertTrue(targetElement.waitForExistence(timeout: 20), "未能在列表中找到预置的个人知识图谱指南文档")
   targetElement.tap()
   ```
3. **强校验链接渲染**：使用 `XCTAssertTrue(pageLink.waitForExistence(timeout: 8))` 确保 Wiki 链接渲染出来后再物理点击，并判定 `app.navigationBars.element` 在 `5` 秒内跳转稳定。
4. **移除 flaky 屏蔽**：删除 `// @flaky` 标注。

### 2.3 testVaultSwitchingAndSeedingFlow 优化设计
1. **Hub 转场延迟**：在 `navigateBackToHub()` 的每次点击操作后引入 `0.5~0.8` 秒的阻尼。
2. **切换写库等待**：在金库卡片 `namedCard.tap()` 之后，显式 sleep `1.5` 秒，让异步数据库播种事务在沙盒内安全提交完毕。
3. **Tab 页切换防护**：使用 `knowledgeTab.waitForExistence(timeout: 8)`，并在 tap 之后额外停留 `0.6` 秒。
4. **所有页面等待**：将 `pageListRow` 的等待超时提高到 `10` 秒。
5. **移除 flaky 屏蔽**：删除 `// @flaky` 标注。

---

## 3. 验收与回归标准

- **编译通过**：`xcodebuild` 命令成功编译且无任何静态分析或 Lint 报错。
- **本地稳定性验证**：本地自动化测试环境针对上述 3 个修复的 UI 测试用例，**连续成功运行 5 次**且必须达到 100% 成功率。
- **覆盖率统计**：回归结束后导出 Domain 逻辑层的代码覆盖率汇总。
