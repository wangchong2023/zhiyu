# 智宇 (KM) 未来进化路线图 (Evolution Roadmap)

## 1. 短期目标 (Next 3 Months): 工程精细化
*   [x] **嵌入式 AI 引擎**: 集成 `Llama.cpp` 实现进程内模型推断 — `OnDeviceLLMService` 已实现。
*   [x] **语义缩放图谱**: 3D 图谱的 LOD 自动切换 — `GraphLOD.swift` 已实现。
*   [x] **多端实时同步**: iCloud 同步 — `iCloudSyncManager` / `AppCloudSyncService` 已实现。

## 2. 中期目标 (Next 6-12 Months): 开放生态与协同
*   [~] **插件化生态 (Plugin 1.0)**: `PluginRegistry` / `PluginMarketService` / `PLUGIN_SDK.md` 已就绪；社区插件市场 Alpha 待上线。
*   [ ] **加密知识分片**: 允许用户导出”思维切片”分享给他人，支持端到端加密传输。
*   [x] **空间计算适配 (Spatial Computing)**: `VisionProSpatialView` 已实现基础空间视图。

## 3. 远期愿景 (2 Years+): 真正的第二大脑

*状态标记: [x] 已完成 [~] 部分完成 [ ] 未开始*
*   **主动联想代理 (Active Agent)**: AI 自动在后台扫描互联网或本地文档，主动提示：“你刚才写的这段话，似乎与 2023 年的一篇论文存在互补关系”。
*   **完全零知识证明同步 (ZKP Sync)**: 在不泄露任何明文内容的情况下，实现多机协同计算。
*   **知识库贸易网络 (Vault Commerce)**: 建立全球化的金库分发市场，支持高质量、垂直领域知识金库的“按需挂载”与交易。
*   **图谱渲染引擎 2.0 (Massive Graph)**: 引入分片加载与 GPU 视口裁剪技术，支持 10 万级节点下的 120Hz 丝滑交互。
*   **开发者激励协议 (Creator Economy)**: 实装插件内购、订阅及打赏系统，让知识与工具的创作者获得真正的商业回报。

## 4. 遗留问题与微调建议 (Pending Issues & Fine-tuning Suggestions)

基于资深开发与架构审计，以及 Google NotebookLM、llm_wiki 和 qiaomu 等竞品对比，整理出系统在未来版本迭代中必须解决的技术债务与增强方向：

### 4.1 架构与并发债务
- [ ] **彻底消除信号量同步阻塞**：将数据层的 `switchDatabase` 与 `setup` 方法重构为 `async throws` 异步机制，移除所有 `semaphore.wait`，消除单核或 watchOS 上的死锁隐患。
- [ ] **DI 容器全局 Actor 化**：将 `ServiceContainer` 改造为全局 Actor 或以细粒度锁保护，保证多端并发和 App Extension 桌面小组件读取时的依赖安全。
- [ ] **领域契约穿透重构**：将 L2 `KnowledgeStore` 的数据操作彻底解耦，使其仅依赖 L1.5 定义的 Repository 契约，杜绝 L2 直接拉起 L1 `SQLiteStore` 的隐式越权。

### 4.2 安全与底层硬化
- [ ] **Keychain 生产降级强隔离**：通过 `#if DEBUG` 严格限制 `UserDefaults` 的兜底明文存储，在生产发布包中绝对禁止降级，若 Keychain 写入失败直接闪退，保证金库安全。
- [ ] **JSC 沙箱动态执行限制**：在插件的 `JSContext` 虚拟机中禁用 `eval`、`Function` 等动态代码执行，只暴露 Value Type Copy 桥接对象。
- [ ] **GRDB 连接池确定性关闭**：在 `DatabasePool` 释放前，显式调用 GRDB 的 `close()` 关闭数据库连接并写入 WAL，避免产生 SQLite 驱动警告。

### 4.3 UI与体验缺陷
- [ ] **安全气泡降级 Banner 美化**：利用 Glassmorphism 半透明磨砂玻璃卡片美化降级 UI，并为重新验证的加载状态引入平滑收缩动画。
- [ ] **全景引导欢迎金库 (Welcome Vault)**：将初次启动的欢迎金库改造为拥有 15+ 节点、错落有致的“知识星团”3D 引导图谱，提升冷启动的“Aha Moment”。

### 4.4 竞品启发之杀手级功能规划
- [ ] **级联式反防爬多源捕获引擎**：内置微信文章、音视频转录（端侧 Whisper）以及 6 级抓取反爬（直连、UA、代理池、Reader API、Headless、OCR）的智能导入引擎。
- [ ] **端侧双人播客 (Audio Overview Native) 生成**：通过本地 SLM 提炼 RAG 检索上下文并重写为对话剧本，利用系统 TTS 或轻量模型在本地渲染出双声道音频。
- [ ] **外置 Agent 自动化总线**：利用 App Intents 将智宇的混合检索与向量归档能力对第三方 CLI/SDK 工具链（如 Cursor/Claude Code）开放。
- [ ] **弹性混合云端代理 RAG 模式**：通过本地脱敏（匿名化敏感词）加云端中转大模型的双重架构，安全处理超大长文本综述。
