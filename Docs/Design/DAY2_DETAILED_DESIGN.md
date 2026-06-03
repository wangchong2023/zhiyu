# 智宇 (ZhiYu) 进阶技术架构与实现设计 (Day 2)

本文档针对 Day 2 规划中的三项高优核心任务（watchOS 语音简报、SPM 物理模块化、CI 覆盖率转储修复）进行深度技术方案细化与设计。

---

## 1. P0: watchOS “第二大脑”体验闭环 (语音简报 Audio Overview)

### 1.1 业务目标
将 watchOS 端的定位从“单纯的信息采集器”升级为“主动的知识输出终端”。通过 Apple Watch，用户可以在通勤、运动等脱屏场景下，收听由 iOS 端 RAG 引擎智能合成的每日知识简报。

### 1.2 架构设计与数据流向
采用 **“胖 iOS (Host) + 瘦 Watch (Client)”** 的非对称计算架构：
1. **iOS 宿主端 (计算大脑)**：
   - 触发时机：通过 `BackgroundTasks` (BGAppRefreshTask) 每天凌晨触发，或手表端主动发起 `WCSession` 请求。
   - 数据聚合：`WatchBriefingService` (L1.5) 提取最近 24 小时的知识增量，以及遗忘曲线到达复习临界点的历史卡片。
   - LLM 摘要合成：调用 `LLMServiceProtocol` 生成适合语音播报的结构化流媒体文本（去除复杂 Markdown 标记，增加自然语言转折词）。
2. **端到端传输 (WCSession)**：
   - 将合成的文案（Text）与元数据（如 Topic, Duration）封装为 `BriefingPayload`，通过 `WatchSyncProtocol` 的 `.transferUserInfo` 或 `.sendMessage` 推送至手表。
3. **watchOS 展现端 (播放终端)**：
   - UI 层：新增 `WatchBriefingView`，提供沉浸式的播客播放界面（大播放/暂停按钮，环形进度条）。
   - 物理发声：集成 `AVFoundation` 中的 `AVSpeechSynthesizer`，接管 watchOS 系统的音频会话 (`AVAudioSession.sharedInstance().setCategory(.playback)`），实现后台离线锁屏发声播报。

### 1.3 核心实现步骤
- **Step 1**: 扩充 `Sources/Domain/Protocols/WatchSyncProtocol.swift`，增加 `requestDailyBriefing()` 和 `receiveBriefingPayload()` 接口。
- **Step 2**: 在 iOS 端的 `iOSWatchSyncService` 中实现 RAG 调度逻辑，接入 `LLMService`。
- **Step 3**: 在 watchOS 端新增 `Sources/Platforms/watchOS/WatchBriefingView.swift`，封装 `AVSpeechSynthesizer` 的生命周期，并挂载至 `TabView` 首页。

---

## 2. P1: 物理模块化与 SPM 拆分 (Swift Package Manager)

### 2.1 业务目标
消除目前仅靠目录划分 (Folder-based) 和开发者自觉维持的伪分层。将 L0 基座层与 Shared 共享 UI 层彻底抽取为 Swift Packages，从编译器层面阻断反向依赖与跨层越权访问，同时显著提升增量编译速度。

### 2.2 模块划分方案
在项目根目录新建 `Packages/` 文件夹，包含以下两大 SPM 库：

1. **`ZhiYuBase` (L0 基础协议与常量子库)**
   - **内容**: `ServiceContainer`, `AppConstants`, 所有抽象协议 (`Protocols/`), `Localized`, `Extensions`。
   - **依赖**: 无外部业务依赖。仅依赖 `Foundation`。
2. **`ZhiYuUI` (Shared 视觉库)**
   - **内容**: `DesignSystem`, `UIComponents` (按钮, 卡片, 标签等)。
   - **依赖**: `SwiftUI`, `ZhiYuBase` (用于读取常量与 L10n)。

### 2.3 工程化重构步骤
- **Step 1: 物理隔离**
  - 执行目录迁移：`mv Sources/Core/Base Packages/ZhiYuBase/Sources/`
  - 执行目录迁移：`mv Sources/Shared Packages/ZhiYuUI/Sources/`
- **Step 2: 包描述清单 (`Package.swift`)**
  - 为两个库分别创建 `Package.swift`，声明 products 和 targets。
- **Step 3: 修改 `project.yml` (XcodeGen)**
  - 移除原有的 `Sources/Core/Base` 和 `Sources/Shared` 源路径。
  - 在 `dependencies` 节点中通过 `package` 引入 `ZhiYuBase` 和 `ZhiYuUI`。
- **Step 4: 访问权限适配**
  - 将抽取代码中原 `internal` 级别的类、属性、初始化方法（`init`）全部显式变更为 `public`。
  - 在全量主工程业务代码（`L1`, `L1.5`, `L2`, `L3`）的头部注入 `import ZhiYuBase` 和 `import ZhiYuUI`。

---

## 3. P1: CI 流水线覆盖率转储修复

### 3.1 故障根本原因分析
在之前的流水线执行中，`Tools/check_coverage.py` 脚本报出 `Failed to load coverage report... no such file or directory action.xccovreport` 的致命错误。
这是由于 `xcodebuild` 默认生成的 `.xcresult` 包在不同版本的 Xcode (15 vs 16+) 中，对临时转储文件的相对路径挂载点存在漂移，且动态使用 `glob` 扫描 `DerivedData` 容易定位到缓存碎片或未完整写入的残次结果包。

### 3.2 治理与修复方案
将覆盖率生成的链路从“黑盒动态扫描”改为“白盒显式指定”。

- **Step 1: 显式锁定结果包路径 (`run_tests.sh`)**
  在测试脚本中，不要让 xcodebuild 自由散落数据，通过 `-resultBundlePath` 强行指定输出物路径。
  ```bash
  RESULT_PATH="build/TestResult.xcresult"
  rm -rf "${RESULT_PATH}" # 每次跑测前强制清理旧数据
  xcodebuild test ... -enableCodeCoverage YES -resultBundlePath "${RESULT_PATH}"
  ```
- **Step 2: 改造覆盖率哨兵脚本 (`check_coverage.py`)**
  移除脚本中容易出错的 `find_latest_xcresult` 逻辑，直接硬编码读取由测试脚本抛出的锁定文件。
  ```python
  latest_result = "build/TestResult.xcresult"
  if not os.path.exists(latest_result):
      log_error("未找到明确输出的 TestResult.xcresult")
  ```
- **Step 3: 规避 `action.xccovreport` 找不到的沙盒 Bug**
  在部分 CI 环境（或特定 Simulator）中，覆盖率文件未被正确刷写到磁盘。确保在 `run_tests.sh` 的 `xcodebuild` 命令执行前，执行一次完整的 `xcodebuild clean`，并赋予 CI 工具组对 `build/` 目录的最高读写权限，从而确保 `xccov` 可以稳定解包。
