# 智宇 (ZhiYu) Day 2 进阶完善与更新规划任务清单

基于 2026-06-01 的全量代码深度审计与架构重构成果，以下是针对系统迈向卓越（Next-Level）所制定的进阶开发任务清单。这些任务涵盖了用户体验、底层架构隔离、网络安全及空间计算的未来演进。

## 🔴 P0 核心体验补齐 (High Priority)
- [ ] **watchOS “第二大脑”体验闭环 (Audio Overview)**
  - **描述**：手表端目前仅有基础的录音（Dictation）功能，缺乏 PRD 规划中的“语音简报”闭环。
  - **行动**：结合 iOS 端的 RAG 检索结果与系统原生 TTS（Text-to-Speech）引擎，实现跨端的每日知识摘要生成与手表端的离线/在线语音播报。

## 🟡 P1 架构演进与容灾加固 (Medium Priority)
- [ ] **物理模块化与 SPM 拆分 (Swift Package Manager)**
  - **描述**：目前的 L0-L3 架构仅依靠文件夹结构和代码规范约束，依然存在跨层物理访问的风险。
  - **行动**：将底层基座（Core/Base）和共享 UI 设计系统（Shared）抽取为完全独立的 Swift Packages，实现 100% 的物理编译隔离。
- [ ] **完全气隙隔离金库 (Air-gapped Vault) 安全机制**
  - **描述**：目前的安全机制主要针对云端同步和插件沙盒。针对高密级用户，需要纯粹的物理隔离。
  - **行动**：增加一种高密级的本地金库类型，强制切断该金库的 CloudKit 同步开关，屏蔽任何外部 API (如第三方 LLM) 的请求，强制仅限端侧模型 (On-Device LLM) 读取。
- [ ] **混沌工程 (Chaos Engineering) 极端弱网测试**
  - **描述**：缺乏针对 CloudKit 极端网络环境的容灾测试。
  - **行动**：补充 `CloudChaosTests` 用例集，使用 Mock 注入模拟高丢包、网络瞬断、云端服务器 503 等边缘场景，验证 LWW 合并算法与本地 SQLite 的双重健壮性。
- [ ] **Apple 生态连续性互通 (Handoff)**
  - **描述**：多端协同目前依赖后台数据同步，缺乏即时的场景接力。
  - **行动**：集成 `NSUserActivity`，使用户在 iPhone 查阅的知识点（如特定 Note ID），在靠近 Mac 时能通过 Handoff 在 Dock 栏无缝接力打开。
- [ ] **CI 流水线覆盖率转储修复**
  - **描述**：由于 Xcode DerivedData 路径变化与本地 `xccov` 的解析限制，部分环境下 `.woodpecker.yml` 和 `ci.yml` 中的覆盖率探针可能失效。
  - **行动**：重构 `Tools/check_coverage.py`，增强对 `.xcresult` 包文件缺失或 Action 拆分的兼容解析，确保 85% 代码覆盖率红线精准拦截。

## 🟢 P2 用户体验与架构探索 (Low Priority)
- [ ] **并发插件调度总线 (Plugin Message Bus)**
  - **描述**：插件沙盒目前是依靠单一 JSContext 的串行执行与 0.5s 熔断。
  - **行动**：引入基于 Swift Actor 的并发插件调度总线，支持多个插件的异步协同工作与跨插件通信（类似微服务架构）。
- [ ] **空间计算视觉预研 (visionOS 适配准备)**
  - **描述**：当前的 SwiftUI 视图体系缺乏 3D 深度（Z轴）的定义。
  - **行动**：为 `GraphView` (知识图谱) 引入 RealityKit 或 SceneKit 的基础几何抽象，为未来的 visionOS 版本打下 3D 悬浮视窗和空间交互的技术基础。
