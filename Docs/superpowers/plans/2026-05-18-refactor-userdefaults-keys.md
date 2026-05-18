# UserDefaults Key Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded `UserDefaults` key strings with constants from `AppConstants.Keys.Storage` across the project.

**Architecture:** Utilize the existing central `AppConstants` structure to eliminate magic strings in `UserDefaults` access.

**Tech Stack:** Swift 6, SwiftUI.

---

### Task 1: Refactor Localized.swift

**Files:**
- Modify: `Sources/Core/Base/Utils/Localized.swift`

- [ ] **Step 1: Replace hardcoded language mode key**

```swift
// Sources/Core/Base/Utils/Localized.swift

// In L10n class
static var mode: LanguageMode {
    get { LanguageMode(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.languageMode) ?? "auto") ?? .auto }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: AppConstants.Keys.Storage.languageMode) }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/Core/Base/Utils/Localized.swift
git commit -m "refactor: use AppConstants for language mode UserDefaults key"
```

### Task 2: Refactor AIWorkflowStore.swift

**Files:**
- Modify: `Sources/Features/AI/Chat/Model/AIWorkflowStore.swift`

- [ ] **Step 1: Replace hardcoded lint issues key**

```swift
// Sources/Features/AI/Chat/Model/AIWorkflowStore.swift

// In AIWorkflowStore class, _lintIssues property
@ObservationIgnored private var _lintIssues: [LintIssue] = {
    if let data = UserDefaults.standard.data(forKey: AppConstants.Keys.Storage.lastLintIssues),
       let decoded = try? JSONDecoder().decode([LintIssue].self, from: data) {
        return decoded
    }
    return []
}()

// In lintIssues setter
set {
    withMutation(keyPath: \.lintIssues) {
        _lintIssues = newValue
        if let data = try? JSONEncoder().encode(newValue) {
            UserDefaults.standard.set(data, forKey: AppConstants.Keys.Storage.lastLintIssues)
        }
    }
}

// In clearAll() method
UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.lastLintIssues)
```

- [ ] **Step 2: Commit**

```bash
git add Sources/Features/AI/Chat/Model/AIWorkflowStore.swift
git commit -m "refactor: use AppConstants for lastLintIssues UserDefaults key"
```

### Task 3: Refactor AuthService.swift

**Files:**
- Modify: `Sources/Features/System/Auth/Service/AuthService.swift`

- [ ] **Step 1: Replace hardcoded auth keys in commented code**

```swift
// Sources/Features/System/Auth/Service/AuthService.swift

// In init()
/*
let isAuthenticated = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.authIsAuthenticated)
if isAuthenticated {
    AuthSession.shared.update(user: User(name: "User", email: "user@example.com"))
}
let isGuest = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.authIsGuest)
AuthSession.shared.isGuest = isGuest
*/
```

- [ ] **Step 2: Commit**

```bash
git add Sources/Features/System/Auth/Service/AuthService.swift
git commit -m "refactor: use AppConstants for auth keys in commented code"
```

### Task 4: Refactor OnboardingService.swift

**Files:**
- Modify: `Sources/Core/System/Onboarding/OnboardingService.swift`

- [ ] **Step 1: Standardize on AppConstants and simplify init**

```swift
// Sources/Core/System/Onboarding/OnboardingService.swift

// In init()
init() {
    // Standardize on the constant key. 
    // If the legacy key exists, it will be handled by reading from the new key if they match,
    // or by accepting that we are standardizing on the new constant-defined key.
    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.hasCompletedOnboarding)
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/Core/System/Onboarding/OnboardingService.swift
git commit -m "refactor: standardize OnboardingService on AppConstants and remove redundant migration"
```

### Task 5: Refactor SettingsStore.swift

**Files:**
- Modify: `Sources/Features/System/Settings/Model/SettingsStore.swift`

- [ ] **Step 1: Refactor privacy and biometric keys**

```swift
// Sources/Features/System/Settings/Model/SettingsStore.swift

// In _isPrivacyModeEnabled property
@ObservationIgnored private var _isPrivacyModeEnabled: Bool = {
    return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled) as? Bool ?? true
}()

// In _isBiometricEnabled property
@ObservationIgnored private var _isBiometricEnabled: Bool = {
    return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isBiometricEnabled) as? Bool ?? true
}()
```

- [ ] **Step 2: Refactor coach mark property**

```swift
// Sources/Features/System/Settings/Model/SettingsStore.swift

// In hasShownGraphCoachMark property getter
get {
    return UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark)
}
```

- [ ] **Step 3: Commit**

```bash
git add Sources/Features/System/Settings/Model/SettingsStore.swift
git commit -m "refactor: standardize SettingsStore on AppConstants and remove redundant migrations"
```

### Task 6: Final Verification

- [ ] **Step 1: Clean build the project**

Run: `xcodegen generate && xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' > build/test_results.log 2>&1`
