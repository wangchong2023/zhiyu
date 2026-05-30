# 智宇 (ZhiYu) 全方位深度体检与演进任务清单 (Round 2)

基于 2026-05-29 的第二轮多维度专家（PM、架构师、安全专家等）深度体检，现将识别出的深层技术债务、产品痛点及文档缺失整理为以下可执行的任务清单。

## 🔴 P0 级别 (高危阻断 / 核心架构缺陷)
*必须在下一个正式版本发版前予以修复的任务。*

- [ ] **SEC-01: 本地脱敏与隐私越界防御 (Security)**
  - **痛点**：当前标有 `#private` 标签的内容在触发 RAG 或生成摘要时，仍会明文上传至云端大模型。
  - **任务**：在 `LLMContextBuilder` 送入网络请求前，强制串联一层基于本地 NLP（如 `NaturalLanguage` 框架）的 PII（个人身份信息）脱敏管道，将人名、手机号、特定黑话等自动替换为 `[REDACTED]`。
- [ ] **ARCH-01: 肢解 `AppStore` 上帝类 (Architecture)**
  - **痛点**：`AppStore.swift` 存在上帝类 (God Object) 倾向，聚合了超 40 个对外代理转发的方法（如 `anyCreatePage`, `renameTag`），严重违反接口隔离原则 (ISP)，且底部堆砌了大量自动生成的无意义机械注释。
  - **任务**：强力擦除所有无意义模板注释；将 `AppStore` 降级为单纯的 App 生命周期引导与跨模块协调器；UI 层应通过 `@Environment` 分别精准按需获取 `KnowledgeStore` 或 `TagStore`。

## 🟠 P1 级别 (高优特性 / 性能与稳定性瓶颈)
*显著影响用户体验或系统高可用性的任务。*

- [ ] **PERF-01: 插件系统沙盒后台隔离 (Module Design)**
  - **痛点**：`JavaScriptPlugin` 注入的闭包直接使用 `DispatchQueue.main.async` 绑定，若第三方插件执行高频回调，将直接引发宿主 UI 主线程的严重卡顿 (Jank)。
  - **任务**：为 JS 引擎池开辟纯净的串行后台运行队列 (Background Queue)，使得插件从加载、解析到通信全部脱离主线程。
- [ ] **UX-01: 颗粒度任务进度反馈面板 (User Experience)**
  - **痛点**：在执行百 M 级 Markdown 文件夹的导入与 Embedding 向量化时，界面仅有粗糙的 Loading，用户极易产生“死机”错觉。
  - **任务**：监听并利用 `AITaskProgress` 模型，在 UI 底部引入类似于“终端控制台”的细粒度（显示当前处理到了哪个具体的 chunk）实时滚动打字机动画面板。
- [ ] **QA-01: RAG 混沌工程验证 (Quality Assurance)**
  - **痛点**：现有测试覆盖多为 Happy Path，缺乏极端物理中断场景下的保障。
  - **任务**：在 `CloudChaosTests` 中追加混沌断言——模拟当 SQLite WAL 仍在刷写或大模型流式接收中断网时，应用重启后必须自动执行图谱孤岛修剪 (Orphan Cleanup) 及状态幂等恢复。
- [ ] **DOC-01: 补齐缺失的核心文档 (Documentation)**
  - **任务 1**：在 `PLUGIN_SDK.md` 中补充关于 JS 看门狗 (`JSShouldTerminateCallback`) 的 0.5s 超时惩罚及内存隔离限制的架构级说明。
  - **任务 2**：在 CI 流程中集成 Slather 等覆盖率工具，并在 `Docs/Testing/` 目录下物理输出一份 `COVERAGE_REPORT.md`，用于自证 Domain 层 >85% 的红线达成率。

## 🟡 P2 级别 (体验抛光 / 产品留存增长)
*产品商业化及生态闭环相关的体验增强任务。*

- [ ] **GROWTH-01: 间隔重复 (SRS) 主动唤醒 (Product Manager)**
  - **痛点**：重基建轻促活，用户容易形成“白板恐惧”。
  - **任务**：结合数据库中的 `srs_metadata` 表，通过本地计算在设备端生成每日的 Local Push Notification：“你有 3 个关键知识概念正在遗忘曲线边缘，让 AI 帮你温故知新吧”。
- [ ] **ONBOARD-01: 空窗期的沙盒引导库 (Product Manager)**
  - **任务**：在用户首次安装 App 时，默认解压内置的一个轻量级 `Demo Vault`（包含双链和标签演示），让用户开箱即体验到 RAG 的威力。
- [ ] **UI-01: 金库物理热切换的优雅动画 (UI/UX)**
  - **痛点**：调用 `switchDatabase` 时重载连接池引发的界面瞬间硬刷新白屏。
  - **任务**：引入全屏高斯模糊遮罩或渐变骨架屏 (Skeleton View) 过渡，并在底层异步就绪后 (Notification `.databaseDidSwitch` 到达) 以 `.spring` 动画平滑揭开。
- [ ] **ECO-01: 苹果生态跨端连续性 Handoff (User Experience)**
  - **任务**：注入 `NSUserActivity`。例如在 watchOS 手表上记录完一则 VoiceNote 抬起 iPhone 时，iPhone 锁屏能够直接投射无缝接力的图标，点击直达 AI 润色总结界面。
- [ ] **CI-01: UI 快照防回归测试 (Software Engineering)**
  - **任务**：在 `ci.yml` 中激活 `SnapshotTesting` 测试用例环节，在非 Apple Silicon 服务器上引入严格的像素对比容差率设置。