# Update AnyPageStore Calls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `AnyPageStore` method calls to use the new names `anyCreatePage`, `anyUpdatePage`, and `anyDeletePage` in `IngestService`, `SQLiteStore`, and `AppStore`.

**Architecture:** Update call sites and protocol implementations to align with the renamed `AnyPageStore` protocol methods.

**Tech Stack:** Swift 6, SwiftUI

---

### Task 1: Update IngestService.swift

**Files:**
- Modify: `Sources/Features/Knowledge/Ingest/Service/IngestService.swift`

- [ ] **Step 1: Update createPage call**
- [ ] **Step 2: Update updatePage call**

### Task 2: Update SQLiteStore.swift Implementation

**Files:**
- Modify: `Sources/Infrastructure/Storage/Engine/SQLiteStore.swift`

- [ ] **Step 1: Update AnyPageStore extension methods to use anyCreatePage, anyUpdatePage, anyDeletePage**

### Task 3: Update AppStore.swift Implementation

**Files:**
- Modify: `Sources/App/Store/AppStore.swift`

- [ ] **Step 1: Implement AnyPageStore protocol methods in the extension**

### Task 4: Verification

- [ ] **Step 1: Build the project to ensure no compilation errors**
- [ ] **Step 2: Run existing tests**
