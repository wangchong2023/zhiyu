# ZhiYu Refactoring & Notebook Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the project into a clean layered architecture and implement the "Notebook Hub" (Login -> Hub -> Notebook Context).

**Architecture:** 
- **L0 (Infrastructure):** Core technical services (Storage, Network, Logger).
- **L1 (Service):** Domain-specific services (LLM, Embedding, Search).
- **L2 (Domain/Feature):** Business logic and Features (Chat, Synthesis, Ingest).
- **L3 (Presentation):** SwiftUI Views and ViewModels.
- **DI:** Protocol-based dependency injection via `ServiceContainer`.

**Tech Stack:** Swift 6, SwiftUI, GRDB (SQLite), ServiceContainer (DI).

---

## Phase 1: Directory Restructuring (Physical Alignment)

### Task 1: Initialize New Folder Structure
**Files:**
- Create: `Sources/Core/`
- Create: `Sources/Infrastructure/`
- Create: `Sources/Features/Auth/`
- Create: `Sources/Features/NotebookHub/`

- [ ] **Step 1: Create directories**
Run: `mkdir -p Sources/Core Sources/Infrastructure Sources/Features/Auth Sources/Features/NotebookHub`
- [ ] **Step 2: Commit**
`git commit -m "refactor: initialize new layered directory structure"`

### Task 2: Move Shared Core to L0 (Core)
**Files:**
- Move: `Sources/Shared/Core/*` -> `Sources/Core/`
- Move: `Sources/Shared/Models/Core/*` -> `Sources/Core/Models/`

- [ ] **Step 1: Move files**
Run: `mv Sources/Shared/Core/* Sources/Core/`
- [ ] **Step 2: Update project.yml**
Edit `project.yml` to reflect new paths if necessary (XcodeGen usually handles globbing but check targets).
- [ ] **Step 3: Fix imports and compile**
Run: `xcodegen generate && xcodebuild build ...`
- [ ] **Step 4: Commit**
`git commit -m "refactor: move core utilities to Sources/Core"`

### Task 3: Move Persistent Data & Sync to Infrastructure
**Files:**
- Move: `Sources/Shared/Data/*` -> `Sources/Infrastructure/Storage/`
- Move: `Sources/Shared/Domain/Processors/Network/*` -> `Sources/Infrastructure/Network/`

- [ ] **Step 1: Move files**
Run: `mkdir -p Sources/Infrastructure/Storage Sources/Infrastructure/Network && mv Sources/Shared/Data/* Sources/Infrastructure/Storage/ && mv Sources/Shared/Domain/Processors/Network/* Sources/Infrastructure/Network/`
- [ ] **Step 2: Fix imports and compile**
- [ ] **Step 3: Commit**
`git commit -m "refactor: move storage and network to Infrastructure layer"`

---

## Phase 2: Notebook Hub Implementation

### Task 4: Define AuthSession and User Models
**Files:**
- Create: `Sources/Features/Auth/Models/AuthSession.swift`
- Create: `Sources/Features/Auth/Models/User.swift`

- [ ] **Step 1: Implement Models**
```swift
struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    var avatarURL: URL?
}

@Observable
class AuthSession {
    var currentUser: User?
    var isLoggedIn: Bool { currentUser != nil }
    
    static let shared = AuthSession()
    private init() {}
}
```
- [ ] **Step 2: Commit**
`git commit -m "feat: add AuthSession and User models"`

### Task 3: Implement NotebookHub View
**Files:**
- Create: `Sources/Features/NotebookHub/Views/NotebookHubView.swift`
- Create: `Sources/Features/NotebookHub/ViewModels/NotebookHubViewModel.swift`

- [ ] **Step 1: Create ViewModel**
Implement logic to fetch and manage notebooks.
- [ ] **Step 2: Create View**
Implement 2-column grid layout (NotebookLM style).
- [ ] **Step 3: Commit**
`git commit -m "feat: implement NotebookHubView with grid layout"`

### Task 4: Refactor ContentView Root Routing
**Files:**
- Modify: `Sources/Shared/Views/Core/ContentView.swift`

- [ ] **Step 1: Update Root Logic**
Change `body` to check `AuthSession.isLoggedIn`.
- [ ] **Step 2: Add Hub/Notebook Transition**
When a notebook is selected, enter the existing TabView context.
- [ ] **Step 3: Commit**
`git commit -m "refactor: update ContentView to support Auth and Hub routing"`

---

## Phase 3: Protocol-based DI & Cleanup

### Task 5: Extract Protocols for Features
**Files:**
- Create: `Sources/Shared/Protocols/FeatureProtocols.swift`

- [ ] **Step 1: Define Protocols**
Define protocols for `ChatService`, `SynthesisService`, etc., to decouple features.
- [ ] **Step 2: Update Implementations**
Make services conform to protocols.
- [ ] **Step 3: Update Injection**
Update `ServiceContainer` to register by protocol.
- [ ] **Step 4: Commit**
`git commit -m "refactor: implement protocol-based dependency injection"`

### Task 6: Final Verification & Health Check Fix
**Files:**
- Modify: `Sources/Shared/Data/Persistence/AppStore.swift`
- Modify: `Sources/Shared/Views/Core/ContentView.swift`

- [ ] **Step 1: Add 'healthCheck' to ToolItem**
```swift
enum ToolItem: String, CaseIterable, Hashable {
    case index, chat, log, lint, tagCloud, collab, taskCenter, weeklyReport, dashboard, pluginMarket, synthesis, healthCheck
}
```
- [ ] **Step 2: Fix iPad Performance Sheet**
Add `.sheet(isPresented: $store.showPerfDashboard)` to `adaptiveSplitView`.
- [ ] **Step 3: Final Compile and Test**
Run: `xcodebuild build` and `xcodebuild test`.
- [ ] **Step 4: Commit**
`git commit -m "fix: resolve ToolItem missing member and iPad UI bug"`
