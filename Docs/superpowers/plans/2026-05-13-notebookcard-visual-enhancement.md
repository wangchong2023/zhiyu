# NotebookCard Visual Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a theme-driven background system for `NotebookCard` supporting Linear and Mesh gradients.

**Architecture:** Extend the `Vault` model with a JSON payload, create a `NotebookThemeFactory` for automatic generation, and implement a reusable `NotebookThemeBackgroundView`.

**Tech Stack:** Swift 6, SwiftUI, Observation.

---

## File Mapping
- `Sources/Features/NotebookHub/Model/NotebookThemeConfig.swift`: Defines the theme data structure.
- `Sources/Features/NotebookHub/Model/NotebookThemeFactory.swift`: Logic for generating themes from metadata.
- `Sources/Shared/Domain/Services/VaultService.swift`: Extends the Vault model.
- `Sources/Features/NotebookHub/View/NotebookThemeBackgroundView.swift`: The background rendering component.
- `Sources/Features/NotebookHub/View/NotebookHubView.swift`: Integrates the new background into the card.

---

### Task 1: Define NotebookThemeConfig Model

**Files:**
- Create: `Sources/Features/NotebookHub/Model/NotebookThemeConfig.swift`

- [ ] **Step 1: Create the config struct**
```swift
import Foundation

public struct NotebookThemeConfig: Codable, Equatable, Sendable {
    public enum ThemeType: String, Codable {
        case linear
        case mesh
    }
    
    public var type: ThemeType
    public var colors: [String] // Hex strings
    public var seed: Int
    
    public init(type: ThemeType = .linear, colors: [String], seed: Int = 0) {
        self.type = type
        self.colors = colors
        self.seed = seed
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add Sources/Features/NotebookHub/Model/NotebookThemeConfig.swift
git commit -m "feat: add NotebookThemeConfig model"
```

---

### Task 2: Implement NotebookThemeFactory

**Files:**
- Create: `Sources/Features/NotebookHub/Model/NotebookThemeFactory.swift`

- [ ] **Step 1: Create the factory with generation logic**
```swift
import Foundation
import SwiftUI

public struct NotebookThemeFactory {
    private static let palettes: [[String]] = [
        ["#4A90E2", "#50E3C2"], // Blue-Teal
        ["#FF9A9E", "#FECFEF"], // Pink-Soft
        ["#A18CD1", "#FBC2EB"], // Purple-Lavender
        ["#84FAB0", "#8FD3F4"], // Green-Blue
        ["#F6D365", "#FDA085"], // Yellow-Orange
        ["#667EEA", "#764BA2"]  // Indigo-Violet
    ]
    
    public static func generate(from name: String, id: UUID) -> NotebookThemeConfig {
        let hash = abs(name.hashValue)
        let palette = palettes[hash % palettes.count]
        let seed = abs(id.hashValue)
        
        return NotebookThemeConfig(
            type: .linear, // Default type
            colors: palette,
            seed: seed
        )
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add Sources/Features/NotebookHub/Model/NotebookThemeFactory.swift
git commit -m "feat: add NotebookThemeFactory for auto-generating themes"
```

---

### Task 3: Extend Vault Model

**Files:**
- Modify: `Sources/Shared/Domain/Services/VaultService.swift`

- [ ] **Step 1: Add themePayload property**
```swift
public struct Vault: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var createdAt: Date
    public var pageCount: Int
    public var themePayload: String? // Added field
}
```

- [ ] **Step 2: Commit**
```bash
git add Sources/Shared/Domain/Services/VaultService.swift
git commit -m "feat: extend Vault model with themePayload"
```

---

### Task 4: Implement NotebookThemeBackgroundView

**Files:**
- Create: `Sources/Features/NotebookHub/View/NotebookThemeBackgroundView.swift`

- [ ] **Step 1: Create the rendering view**
```swift
import SwiftUI

struct NotebookThemeBackgroundView: View {
    let config: NotebookThemeConfig
    
    var body: some View {
        ZStack {
            switch config.type {
            case .linear:
                LinearGradient(
                    colors: config.colors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                if #available(iOS 18.0, macOS 15.0, *) {
                    // Placeholder for MeshGradient implementation
                    // For now, fallback to linear until specific mesh parameters are refined
                    LinearGradient(
                        colors: config.colors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: config.colors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}

// Extension to support Hex colors in SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add Sources/Features/NotebookHub/View/NotebookThemeBackgroundView.swift
git commit -m "feat: implement NotebookThemeBackgroundView"
```

---

### Task 5: Integrate Theme into NotebookCard

**Files:**
- Modify: `Sources/Features/NotebookHub/View/NotebookHubView.swift`

- [ ] **Step 1: Update NotebookCard to use the new background**
Modify `NotebookCard` to resolve theme from `vault.themePayload` or generate it.
```swift
struct NotebookCard: View {
    let notebook: VaultService.Vault
    let action: () -> Void
    
    private var themeConfig: NotebookThemeConfig {
        if let payload = notebook.themePayload,
           let data = payload.data(using: .utf8),
           let config = try? JSONDecoder().decode(NotebookThemeConfig.self, from: data) {
            return config
        }
        return NotebookThemeFactory.generate(from: notebook.name, id: notebook.id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                ZStack(alignment: .bottomLeading) {
                    // Replace the old hardcoded gradient
                    NotebookThemeBackgroundView(config: themeConfig)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
                        .frame(height: DesignSystem.Vault.coverHeight)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(DesignSystem.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notebook.name)
                        .font(.headline.bold())
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    Text("\(notebook.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Clean up legacy colorForName method**
Remove the `colorForName` private method from `NotebookCard`.

- [ ] **Step 3: Run final build verification**
Run: `xcodegen generate && xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**
```bash
git add Sources/Features/NotebookHub/View/NotebookHubView.swift
git commit -m "feat: integrate dynamic themes into NotebookCard"
```
