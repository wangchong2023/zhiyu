# Rename AppRouter to Router Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename all occurrences of `AppRouter` to `Router` across the codebase to maintain consistency with the updated `Router.swift`.

**Architecture:** Systematic replacement of the symbol `AppRouter` with `Router` in all Swift files, ensuring DI registrations and environment object injections are updated.

**Tech Stack:** Swift 6, SwiftUI, ServiceContainer (DI).

---

### Task 1: Update Sources/App Files

**Files:**
- Modify: `Sources/App/ContentView.swift`
- Modify: `Sources/App/NavigationView.swift`
- Modify: `Sources/App/SidebarView.swift`
- Modify: `Sources/App/ViewFactory.swift`
- Modify: `Sources/App/WelcomeView.swift`

- [ ] **Step 1: Replace AppRouter with Router in Sources/App/ContentView.swift**
- [ ] **Step 2: Replace AppRouter with Router in Sources/App/NavigationView.swift**
- [ ] **Step 3: Replace AppRouter with Router in Sources/App/SidebarView.swift**
- [ ] **Step 4: Replace AppRouter with Router in Sources/App/ViewFactory.swift**
- [ ] **Step 5: Replace AppRouter with Router in Sources/App/WelcomeView.swift**

### Task 2: Update Core and Infrastructure

**Files:**
- Modify: `Sources/Core/ModuleRegistrar.swift`

- [ ] **Step 1: Fix AppRouter registration in Sources/Core/ModuleRegistrar.swift**
    - Replace `container.register(AppRouter.shared, for: AppRouter.self)` with `container.register(Router.shared, for: Router.self)`

### Task 3: Update Features

**Files:**
- Modify: `Sources/Features/Dashboard/View/KnowledgeDashboardView.swift`
- Modify: `Sources/Features/Graph/View/GraphView.swift`
- Modify: `Sources/Features/Ingest/View/IngestView.swift`
- Modify: `Sources/Features/Lint/View/LintView.swift`
- Modify: `Sources/Features/NotebookHub/View/NotebookHubView.swift`
- Modify: `Sources/Features/Search/View/SearchView.swift`
- Modify: `Sources/Features/Settings/View/LLMSettingsView.swift`
- Modify: `Sources/Features/Settings/View/PluginCenterView.swift`
- Modify: `Sources/Features/Settings/View/SettingsView.swift`
- Modify: `Sources/Features/Synthesis/View/SynthesisView.swift`
- Modify: `Sources/Features/TaskCenter/View/TaskCenterView.swift`
- Modify: `Sources/Features/Vault/View/VaultHomeView.swift`

- [ ] **Step 1: Replace AppRouter with Router in all feature views**

### Task 4: Update Shared Views

**Files:**
- Modify: `Sources/Shared/Views/Components/AdaptiveSidebarView.swift`
- Modify: `Sources/Shared/Views/Components/ChatComponents.swift`
- Modify: `Sources/Shared/Views/Components/WeeklyInsightCard.swift`
- Modify: `Sources/Shared/Views/Core/UserProfileMenu.swift`
- Modify: `Sources/Shared/Views/Pages/CreatePageView.swift`
- Modify: `Sources/Shared/Views/Pages/PageDetailView.swift`

- [ ] **Step 1: Replace AppRouter with Router in shared views**

### Task 5: Update Tests

**Files:**
- Modify: `Tests/Shared/TestMocks.swift`
- Modify: `Tests/Unit/Services/RouterTests.swift`

- [ ] **Step 1: Replace AppRouter with Router in Tests/Shared/TestMocks.swift**
- [ ] **Step 2: Replace AppRouter with Router and update class name in Tests/Unit/Services/RouterTests.swift**

### Task 6: Verification

- [ ] **Step 1: Run iOS build**
    - Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
- [ ] **Step 2: Run macOS build**
    - Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
- [ ] **Step 3: Run Tests**
    - Run: `xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
