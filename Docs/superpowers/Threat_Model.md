# 智宇 (ZhiYu) - 威胁模型安全分析 (Threat Model)

本文档旨在识别并缓解智宇 (ZhiYu) 在客户端侧、网络侧以及 AI 生成过程中的潜在安全风险。本应用作为一个 AI 原生知识管理应用，安全核心在于**防止恶意的 Prompt 注入**、**保护本地向量数据库的机密性**以及**防范不受信任的插件沙盒越权**。

## 1. 核心资产 (Assets)

1. **用户知识库数据**：存放在本地 SQLite (`KnowledgeStore`) 和向量数据库 (`SearchStore`) 中的个人笔记与摘录。
2. **API 密钥**：用户填写的用于连接远程大模型 (如 OpenAI, Anthropic, DeepSeek) 的 Token (`llm_api_key`)。
3. **iCloud 同步数据**：存放于 `NSUbiquitousKeyValueStore` 或 CloudKit 的用户私人配置与文档。

## 2. 威胁向量识别 (STRIDE 模型)

### 2.1 身份伪装 (Spoofing)
- **描述**：恶意应用可能会试图伪装成 ZhiYu 来窃取用户的 URL Scheme 请求或剪贴板内容。
- **缓解措施**：
  - URL Scheme 的 DeepLink 处理采用严格的参数校验。
  - 所有跨应用数据传输限定在 Apple 官方支持的安全框架内 (如 `PasteboardService`, `Share Extension`)。

### 2.2 篡改数据 (Tampering)
- **描述**：本地 SQLite 数据库或向量数据库文件被恶意程序篡改（如 SQL 注入）。
- **缓解措施**：
  - GRDB 底层使用参数化查询，绝不拼接裸字符串，彻底杜绝 **SQL 注入 (SQLi)** 风险。
  - 文件系统受 Apple OS 沙盒 (Sandbox) 保护，ZhiYu 只能访问其 App Container 内部的文件。

### 2.3 抵赖 (Repudiation)
- **描述**：发生同步冲突或操作意外删除时，用户无法追溯。
- **缓解措施**：
  - 应用内置了一套完整的日志审计框架 `AuditLogger`。所有的核心 RAG 修改、配置覆盖均会在本地记录 Log 供追溯，确保所有数据变化具有可观察性。

### 2.4 信息泄露 (Information Disclosure)
- **描述**：第三方插件越权读取用户的知识库，或者用户的 LLM API Key 被明文打印或拦截。
- **缓解措施**：
  - **插件沙盒化**：`PluginRegistry` 严格限制了外部插件的运行权限。必须声明 `readContent` 或 `writeContent` 等权限，否则 `applyPreProcess` 会直接拦截（拦截案例可见测试 `testPluginRegistrySecurityInterception`）。
  - **凭证安全**：`llm_api_key` 在可能的情况下存放于 Keychain 中，绝不可明文打入日志。
  - `iCloudSyncManager` 同步过程中采用端到端加密通道，保证数据在传输过程中的安全。

### 2.5 拒绝服务 (Denial of Service - DoS)
- **描述**：恶意脚本或超大规模的 RAG 请求引发应用内存溢出 (OOM) 或无响应 (Hang)。
- **缓解措施**：
  - **插件 Watchdog**：运行的任何插件如果超出阈值时间，将被 `Watchdog 2.0` 物理隔离并强制回收内存资源（测试已覆盖 `testWatchdogTimeoutSuspension`）。
  - **请求降级机制 (Throttling)**：若 AI API 请求频率过高，系统将自动降级。对于无效的 JSON 响应，系统将优雅降级为兜底值 (Error 0.0) 而非崩溃崩溃（参考 `RAGEvaluationServiceTests`）。

### 2.6 提权 (Elevation of Privilege)
- **描述**：ZhiYu 作为一个知识管理器，不可信输入可能通过 **Prompt Injection (提示词注入)** 绕过 AI 的防御机制，使 AI 违背指令甚至泄露用户的其他文档块。
- **缓解措施**：
  - 核心 RAG 管道内置了 `PromptSanitizer`，使用正则过滤如 `(?i)ignore\s+all\s+prior\s+instructions` 等高风险的注入短语。
  - 利用系统提示词 (System Prompt) 为大模型施加了严格的身份约束 (Boundaries)，确保大模型不会在 `RAGEvaluation` (评判模式) 中被诱导修改打分。

## 3. 结论

智宇通过 **GRDB 安全参数化**、**Plugin Sandbox (插件沙盒与隔离)** 和 **PromptSanitizer 防火墙** 三道核心防线，有效地降低了作为一个 AI 原生客户端应用所面临的安全风险。未来将引入更细粒度的 Keychain 配置管理以及更复杂的 LLM 输出过滤策略，进一步收敛风险表面。
