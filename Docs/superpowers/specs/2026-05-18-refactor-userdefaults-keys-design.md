# Design Doc: Refactor UserDefaults Keys to Constants

## 1. Goal
Replace all hardcoded `UserDefaults` key strings in the `Sources/` directory with their corresponding constants from `AppConstants.Keys.Storage` to improve maintainability and type safety.

## 2. Scope
- **Directory**: `Sources/`
- **Files identified**:
    - `Sources/Core/Base/Utils/Localized.swift`
    - `Sources/Core/System/Onboarding/OnboardingService.swift`
    - `Sources/Features/AI/Chat/Model/AIWorkflowStore.swift`
    - `Sources/Features/System/Auth/Service/AuthService.swift`
    - `Sources/Features/System/Settings/Model/SettingsStore.swift`
- **Mapping Table**:
    - "auth.isAuthenticated" -> AppConstants.Keys.Storage.authIsAuthenticated
    - "auth.isGuest" -> AppConstants.Keys.Storage.authIsGuest
    - "vaults.list" -> AppConstants.Keys.Storage.vaultsList
    - "vaults.selectedID" -> AppConstants.Keys.Storage.vaultsSelectedID
    - "lastLintIssues" -> AppConstants.Keys.Storage.lastLintIssues
    - "earned_medals" -> AppConstants.Keys.Storage.earnedMedals
    - "app_language_mode" -> AppConstants.Keys.Storage.languageMode
    - "hasCompletedOnboarding" -> AppConstants.Keys.Storage.hasCompletedOnboarding
    - "isPrivacyModeEnabled" -> AppConstants.Keys.Storage.isPrivacyModeEnabled
    - "isBiometricEnabled" -> AppConstants.Keys.Storage.isBiometricEnabled
    - "hasShownGraphCoachMark" -> AppConstants.Keys.Storage.hasShownGraphCoachMark
    - "app_selected_tab" -> AppConstants.Keys.Storage.selectedTab

## 3. Implementation Details

### 3.1 Direct Replacements
For files where the hardcoded string value matches the constant value, a simple search and replace will be performed.
- `Localized.swift`: `"app_language_mode"` -> `AppConstants.Keys.Storage.languageMode`
- `AIWorkflowStore.swift`: `"lastLintIssues"` -> `AppConstants.Keys.Storage.lastLintIssues`
- `AuthService.swift`: `"auth.isAuthenticated"` -> `AppConstants.Keys.Storage.authIsAuthenticated` (in comments)

### 3.2 Migration Logic Handling
In `OnboardingService.swift` and `SettingsStore.swift`, the hardcoded strings (e.g., `"hasCompletedOnboarding"`) are used as *old* keys to migrate data to *new* keys (e.g., `AppConstants.Keys.Storage.hasCompletedOnboarding` which is `"app_has_completed_onboarding"`).

**Strategy**:
1. Following the literal instruction to replace these strings with the constants.
2. Since using the same constant for both the *source* and *destination* of a migration makes the migration logic redundant or harmful (it would delete the new key), the migration blocks will be simplified to just use the constant directly.
3. This assumes the user wants to standardize on the constants and is aware that this effectively "finishes" the migration phase by no longer checking for the old literal keys.

## 4. Verification Plan
- **Static Analysis**: Ensure all replacements use the correct `AppConstants.Keys.Storage` member.
- **Compilation**: Verify that the project still builds successfully.
- **Unit Tests**: Run relevant tests (if any exist for these services) to ensure no regressions in state management.
