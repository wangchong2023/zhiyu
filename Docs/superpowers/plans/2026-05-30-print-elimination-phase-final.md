# Phase 4: Print Elimination and Log Translation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all `print` calls with `Logger.shared` (info/error/warning/debug) and convert Chinese log messages to English in the remaining 16 files.

**Architecture:** Utilize the existing `Logger.shared` singleton in the system layer for unified logging.

**Tech Stack:** Swift 6, Logger module.

---

### Task 1: Platforms and Core System Files

**Files:**
- Modify: `Sources/Platforms/macOS/MacOSPlatformCapabilities.swift`
- Modify: `Sources/Platforms/iOS/iOSExportService.swift`
- Modify: `Sources/Core/System/Analytics/LocalAnalyticsService.swift`
- Modify: `Sources/Core/Base/ServiceContainer.swift`

- [ ] **Step 1: Replace prints in MacOSPlatformCapabilities.swift**
    - Replace 2 error prints with `Logger.shared.error`.
- [ ] **Step 2: Replace print in iOSExportService.swift**
    - Replace 1 error print with `Logger.shared.error`.
- [ ] **Step 3: Replace prints in LocalAnalyticsService.swift**
    - Replace info print with `Logger.shared.info`.
    - Replace error print with `Logger.shared.error`.
- [ ] **Step 4: Replace prints in ServiceContainer.swift**
    - Replace debug print with `Logger.shared.debug`.
    - Replace error print with `Logger.shared.error`.
- [ ] **Step 5: Verify compilation**
    - Run `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

### Task 2: App and Features Files (Part 1)

**Files:**
- Modify: `Sources/App/ContentView.swift`
- Modify: `Sources/Features/System/Settings/View/DeveloperSettingsView.swift`
- Modify: `Sources/Features/Knowledge/Ingest/Service/IngestService.swift`
- Modify: `Sources/Features/Knowledge/System/Model/MediaStore.swift`

- [ ] **Step 1: Replace prints in ContentView.swift**
    - Replace info and error prints in `triggerReverification`.
    - Translate messages to English.
- [ ] **Step 2: Replace print in DeveloperSettingsView.swift**
    - Replace error print in `loadStats`.
- [ ] **Step 3: Replace prints in IngestService.swift**
    - Replace warning and error prints in `ingestDocument`.
- [ ] **Step 4: Replace print in MediaStore.swift**
    - Replace error print in `ensureAttachmentsDirectoryExists`.
    - Translate message to English.
- [ ] **Step 5: Verify compilation**

### Task 3: Features Files (Part 2)

**Files:**
- Modify: `Sources/Features/Knowledge/System/Model/KnowledgeStore.swift`
- Modify: `Sources/Features/Knowledge/Vault/Service/VaultService.swift`

- [ ] **Step 1: Replace prints in KnowledgeStore.swift**
    - Replace 3 info prints.
    - Translate messages to English.
- [ ] **Step 2: Replace prints in VaultService.swift**
    - Replace 7 error prints and 1 info print.
    - Translate the info print message to English.
- [ ] **Step 3: Verify compilation**

### Task 4: Infrastructure and Domain Files

**Files:**
- Modify: `Sources/Shared/UIComponents/Editors/MarkdownEditorView.swift`
- Modify: `Sources/Infrastructure/LLM/PromptService.swift`
- Modify: `Sources/Infrastructure/VectorDB/EmbeddingManager.swift`
- Modify: `Sources/Infrastructure/Processors/Network/WebScraperProcessor.swift`
- Modify: `Sources/Infrastructure/Performance/PerformanceBenchmarker.swift`
- Modify: `Sources/Domain/RAG/RAGEvaluationService.swift`

- [ ] **Step 1: Replace print in MarkdownEditorView.swift**
    - Replace error print in `OCRPickerModifier`.
- [ ] **Step 2: Replace prints in PromptService.swift**
    - Replace 2 info prints.
- [ ] **Step 3: Replace prints in EmbeddingManager.swift**
    - Replace 2 info prints in `clearCacheAndReload`.
    - Translate messages to English.
- [ ] **Step 4: Replace print in WebScraperProcessor.swift**
    - Replace 1 error print.
- [ ] **Step 5: Replace prints in PerformanceBenchmarker.swift**
    - Replace 9 prints with `Logger.shared.info` and `Logger.shared.warning`.
    - Translate messages to English.
- [ ] **Step 6: Replace print in RAGEvaluationService.swift**
    - Replace 1 error print.
- [ ] **Step 7: Final verification**
    - Full build and ensure no prints remain in target files.
