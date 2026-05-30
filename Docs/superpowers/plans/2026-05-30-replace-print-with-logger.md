# 替换 print() 为 Logger 实施计划

> **面向 Agent 助手：** 必须使用规范的步骤进行跟踪。步骤使用复选框（`- [x]`）语法进行进度标记。

**目标：** 在指定的 18 个文件中，将所有的 `print()` 调用替换为 `Logger.shared` 调用，使用适当的日志级别（`.info`，`.warning`，`.error`）并移除表情符号（emoji）。

**架构设计：** 这是对日志基础设施的系统性更新，旨在确保多端日志的一致性，并充分利用集中化的 `Logger` actor 统一管理。

**技术栈：** Swift 6，自定义高并发 Logger系统。

---

### 任务 1: Infrastructure/Network/ModelDownloadManager.swift

**待修改文件：**
- 修改：`Sources/Infrastructure/Network/ModelDownloadManager.swift`

- [x] **步骤 1：替换 L116 的 print**
  原代码：`print("⚠️ [ModelDownloadManager] No resume data for \(modelId), restarting from scratch is not implemented.")`
  替换为：`Logger.shared.warning("[ModelDownloadManager] No resume data for \(modelId), restarting from scratch is not implemented.")`

---

### 任务 2: Infrastructure/Processors/Network/WebScraperProcessor.swift

**待修改文件：**
- 修改：`Sources/Infrastructure/Processors/Network/WebScraperProcessor.swift`

- [x] **步骤 1：替换 L52 的 print**
  原代码：`print("Scraper HTTP Error \(httpResponse.statusCode): \(body)")`
  替换为：`Logger.shared.error("Scraper HTTP Error \(httpResponse.statusCode): \(body)")`

---

### 任务 3: Infrastructure/LLM/PromptService.swift

**待修改文件：**
- 修改：`Sources/Infrastructure/LLM/PromptService.swift`

- [x] **步骤 1：替换 L118 的 print**
  原代码：`print("Prompt configurations saved to UserDefaults.")`
  替换为：`Logger.shared.info("Prompt configurations saved to UserDefaults.")`

- [x] **步骤 2：替换 L135 的 print**
  原代码：`print("Prompt configurations reset to default.")`
  替换为：`Logger.shared.info("Prompt configurations reset to default.")`

---

### 任务 4: Domain/Services/PromptTemplateEngine.swift

**待修改文件：**
- 修改：`Sources/Domain/Services/PromptTemplateEngine.swift`

- [x] **步骤 1：替换 L93 的 print**
  原代码：`print("⚠️ [PromptTemplateEngine] 远程拉取技能 \(skill.skillId) (v\(skill.version)) 失败，已降级至本地预置: \(error.localizedDescription)")`
  替换为：`Logger.shared.warning("[PromptTemplateEngine] 远程拉取技能 \(skill.skillId) (v\(skill.version)) 失败，已降级至本地预置: \(error.localizedDescription)")`

---

### 任务 5: Shared/UIComponents/Editors/MarkdownEditorView.swift

**待修改文件：**
- 修改：`Sources/Shared/UIComponents/Editors/MarkdownEditorView.swift`

- [x] **步骤 1：替换 L89 的 print**
  原代码：`print("❌ [OCR] Failed: \(error.localizedDescription)")`
  替换为：`Logger.shared.error("[OCR] Failed", error: error)`

---

### 任务 6: Infrastructure/VectorDB/EmbeddingManager.swift

**待修改文件：**
- 修改：`Sources/Infrastructure/VectorDB/EmbeddingManager.swift`

- [x] **步骤 1：替换 L61 的 print**
  原代码：`print("🧹 [EmbeddingManager] 物理驱逐内存向量缓存并开始从新库重载...")`
  替换为：`Logger.shared.info("[EmbeddingManager] 物理驱逐内存向量缓存并开始从新库重载...")`

- [x] **步骤 2：替换 L67 的 print**
  原代码：`print("🚀 [EmbeddingManager] 向量缓存重载载入完毕")`
  替换为：`Logger.shared.info("[EmbeddingManager] 向量缓存重载载入完毕")`

---

### 任务 7: Domain/RAG/RAGEvaluationService.swift

**待修改文件：**
- 修改：`Sources/Domain/RAG/RAGEvaluationService.swift`

- [x] **步骤 1：替换 L75 的 print**
  原代码：`print("Evaluation failed: \(error)")`
  替换为：`Logger.shared.error("Evaluation failed", error: error)`

---

### 任务 8: App/ContentView.swift

**待修改文件：**
- 修改：`Sources/App/ContentView.swift`

- [x] **步骤 1：替换 L299 的 print**
  原代码：`print("✅ [DatabaseCorruptedBanner] Reverification succeeded! Remounted physical database.")`
  替换为：`Logger.shared.info("[DatabaseCorruptedBanner] Reverification succeeded! Remounted physical database.")`

- [x] **步骤 2：替换 L301 的 print**
  原代码：`print("❌ [DatabaseCorruptedBanner] Reverification failed: \(error)")`
  替换为：`Logger.shared.error("[DatabaseCorruptedBanner] Reverification failed", error: error)`

---

### 任务 9: App/ZhiYuApp.swift

**待修改文件：**
- 修改：`Sources/App/ZhiYuApp.swift`

- [x] **步骤 1：替换 L55 的 print**
  原代码：`print("🎬 [Splash] 执行退出动画...")`
  替换为：`Logger.shared.info("[Splash] 执行退出动画...")`

- [x] **步骤 2：替换 L122 的 print**
  原代码：`print("🧹 [AppLauncher] Found -ResetUserDefaults launch argument. Successfully sanitized and reset all seeded_vault_* keys.")`
  替换为：`Logger.shared.info("[AppLauncher] Found -ResetUserDefaults launch argument. Successfully sanitized and reset all seeded_vault_* keys.")`

---

### 任务 10: Features/System/ModelManager/GlobalModelManager.swift

**待修改文件：**
- 修改：`Sources/Features/System/ModelManager/GlobalModelManager.swift`

- [x] **步骤 1：替换 L111 的 print**
  原代码：`print("⚠️ [GlobalModelManager] 加载大模型商店白名单失败: \(error.localizedDescription)")`
  替换为：`Logger.shared.warning("[GlobalModelManager] 加载大模型商店白名单失败: \(error.localizedDescription)")`

- [x] **步骤 2：替换 L150 的 print**
  原代码：`print("❌ [GlobalModelManager] 硬件运存不足，强力拦截模型 \(modelId) 下载。")`
  替换为：`Logger.shared.error("[GlobalModelManager] 硬件运存不足，强力拦截模型 \(modelId) 下载。")`

---

### 任务 11: Core/Base/Utils/Localized.swift

**待修改文件：**
- 修改：`Sources/Core/Base/Utils/Localized.swift`

- [x] **步骤 1：替换 L186 的 print**
  原代码：`print("❌ [L10n Error] Missing Key: \(key)@\(resolvedTable)")`
  替换为：`Logger.shared.error("[L10n Error] Missing Key: \(key)@\(resolvedTable)")`

---

### 任务 12: Features/System/Settings/View/DeveloperSettingsView.swift

**待修改文件：**
- 修改：`Sources/Features/System/Settings/View/DeveloperSettingsView.swift`

- [x] **步骤 1：替换 L271 的 print**
  原代码：`print("Failed to load developer stats: \(error)")`
  替换为：`Logger.shared.error("Failed to load developer stats", error: error)`

---

### 任务 13: Features/Knowledge/System/Model/MediaStore.swift

**待修改文件：**
- 修改：`Sources/Features/Knowledge/System/Model/MediaStore.swift`

- [x] **步骤 1：替换 L43 的 print**
  原代码：`print("[MediaStore] 物理创建附件目录失败: \(error.localizedDescription)")`
  替换为：`Logger.shared.error("[MediaStore] 物理创建附件目录失败", error: error)`

---

### 任务 14: Core/Base/ServiceContainer.swift

**待修改文件：**
- 修改：`Sources/Core/Base/ServiceContainer.swift`

- [x] **步骤 1：替换 L46 的 print**
  原代码：`print("DI: Registered [\(key)] with instance \(String(describing: service))")`
  替换为：`Logger.shared.info("DI: Registered [\(key)] with instance \(String(describing: service))")`

- [x] **步骤 2：替换 L75 的 print**
  原代码：`print(errorMessage)`
  替换为：`Logger.shared.error(errorMessage)`

---

### 任务 15: Core/System/Analytics/LocalAnalyticsService.swift

**待修改文件：**
- 修改：`Sources/Core/System/Analytics/LocalAnalyticsService.swift`

- [x] **步骤 1：替换 L32 的 print**
  原代码：`print("📊 [Analytics] \(timestamp) | \(name) | \(properties?.description ?? "")")`
  替换为：`Logger.shared.info("[Analytics] \(timestamp) | \(name) | \(properties?.description ?? "")")`

- [x] **步骤 2：替换 L70 的 print**
  原代码：`print("❌ [Analytics] \(timestamp) | Error: \(error.localizedDescription) | Details: \(details ?? "")")`
  替换为：`Logger.shared.error("[Analytics] \(timestamp) | Details: \(details ?? "")", error: error)`

---

### 任务 16: Core/System/Security/SecurityManager.swift

**待修改文件：**
- 修改：`Sources/Core/System/Security/SecurityManager.swift`

- [x] **步骤 1：替换 L182 的 print**
  原代码：`print("⚠️ [SecurityManager] DEBUG: HMAC 签名持久化降级到 UserDefaults: \(error)")`
  替换为：`Logger.shared.warning("[SecurityManager] DEBUG: HMAC 签名持久化降级到 UserDefaults: \(error.localizedDescription)")`

---

### 任务 17: Platforms/iOS/iOSExportService.swift

**待修改文件：**
- 修改：`Sources/Platforms/iOS/iOSExportService.swift`

- [x] **步骤 1：替换 L281 的 print**
  原代码：`print("Export WebView failed to load: \(error)")`
  替换为：`Logger.shared.error("Export WebView failed to load", error: error)`

---

### 任务 18: Platforms/macOS/MacOSPlatformCapabilities.swift

**待修改文件：**
- 修改：`Sources/Platforms/macOS/MacOSPlatformCapabilities.swift`

- [x] **步骤 1：替换 L55 的 print**
  原代码：`print("❌ [macOS] Failed to create bookmark: \(error.localizedDescription)")`
  替换为：`Logger.shared.error("[macOS] Failed to create bookmark", error: error)`

- [x] **步骤 2：替换 L69 的 print**
  原代码：`print("❌ [macOS] Failed to resolve bookmark: \(error.localizedDescription)")`
  替换为：`Logger.shared.error("[macOS] Failed to resolve bookmark", error: error)`
