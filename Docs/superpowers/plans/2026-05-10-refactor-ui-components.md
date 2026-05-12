# 重构通用 UI 组件与布局模板 (Layouts) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking tracking.

**Goal:** 将 `AppUI.swift` 中的高层 UI 组件、视图装饰器和布局模板迁移到 `Sources/Shared/UIComponents/` 目录下，并进行标准化重构，使用最新的 `Spacing` 和 `Colors` 令牌。

**Architecture:** 
- `Backgrounds/`: 存放页面背景相关的视图组件。
- `Layouts/`: 存放标准化的容器组件。
- `Modifiers/`: 存放 ViewModifier 及其 View 扩展。
- 遵循单向依赖：组件层依赖令牌层，应用层依赖组件层。

**Tech Stack:** Swift 6, SwiftUI

---

### Task 1: 创建背景组件 (Backgrounds)

**Files:**
- Create: `Sources/Shared/UIComponents/Backgrounds/PageBackground.swift`

- [ ] **Step 1: 创建 `PageBackground.swift` 并实现相关视图**

```swift
import SwiftUI

// MARK: @PR-03: 工业级页面背景系统，优化了渐变渲染性能
// MARK: @PR-04: AI 思考指示器背景

/// 动态网格背景渲染器
public struct MeshGradientView: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Color.appBackground
                
                if size.width > 1 && size.height > 1 {
                    if #available(iOS 18.0, macOS 15.0, *) {
                        #if os(watchOS)
                        watchOSCanvasBackground(size: size)
                        #else
                        MeshGradient(
                            width: 3,
                            height: 3,
                            points: [
                                [0, 0], [0.5, 0], [1, 0],
                                [0, 0.5], [0.5, 0.5], [1, 0.5],
                                [0, 1], [0.5, 1], [1, 1]
                            ],
                            colors: [
                                .appBackground, .appBackground, .appBackground,
                                .appAccent.opacity(0.2), .appConcept.opacity(0.15), .appSource.opacity(0.18),
                                .appBackground, .appBackground, .appBackground
                            ],
                            smoothsColors: true
                        )
                        #endif
                    } else {
                        legacyCanvasBackground(size: size)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func watchOSCanvasBackground(size: CGSize) -> some View {
        Canvas { context, size in
            let gridPadding: CGFloat = 40
            let rows = Int(size.height / gridPadding)
            let cols = Int(size.width / gridPadding)
            
            for row in 0...rows {
                let y = CGFloat(row) * gridPadding
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
            }
            
            for col in 0...cols {
                let x = CGFloat(col) * gridPadding
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
            }
        }
    }
    
    @ViewBuilder
    private func legacyCanvasBackground(size: CGSize) -> some View {
        Canvas { context, size in
            let gridPadding: CGFloat = 40
            let rows = Int(size.height / gridPadding)
            let cols = Int(size.width / gridPadding)
            
            for row in 0...rows {
                let y = CGFloat(row) * gridPadding
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
            }
            
            for col in 0...cols {
                let x = CGFloat(col) * gridPadding
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
            }
        }
    }
}

/// 氛围光渐变背景
public struct AmbientGlowView: View {
    public let color: Color
    
    public init(color: Color) {
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            if size.width > 1 && size.height > 1 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 500, height: 500)
                    .blur(radius: 80)
                    .position(x: size.width / 2, y: size.height / 2)
            }
        }
    }
}

/// 统一的工业级页面背景
public struct PageBackgroundView: View {
    public let accentColor: Color
    
    public init(accentColor: Color) {
        self.accentColor = accentColor
    }
    
    public var body: some View {
        ZStack {
            MeshGradientView()
            VStack {
                AmbientGlowView(color: accentColor)
                    .frame(height: 300)
                    .offset(y: -150)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .background(Color.appBackground)
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

---

### Task 2: 创建玻璃拟态修饰符 (Modifiers)

**Files:**
- Create: `Sources/Shared/UIComponents/Modifiers/GlassStyle.swift`

- [ ] **Step 1: 创建 `GlassStyle.swift` 并实现相关修饰符**

```swift
import SwiftUI

// MARK: @PR-03: 玻璃拟态视觉效果重构，使用了 ultraThinMaterial 材质

/// 统一的玻璃卡片修饰符
public struct GlassCardModifier: ViewModifier {
    public let opacity: Double
    public let cornerRadius: CGFloat
    
    public init(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View 扩展
public extension View {
    /// 应用玻璃拟态卡片样式
    func appGlassCardStyle(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        self.modifier(GlassCardModifier(opacity: opacity, cornerRadius: cornerRadius))
    }
    
    /// 标准卡片容器样式
    func appCardStyle(cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        self.padding(Spacing.large)
            .background(.ultraThinMaterial)
            .background(Color.appCard.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder.opacity(0.4), lineWidth: Spacing.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    /// 通用容器样式
    func appContainer(
        background: Color = .appCard.opacity(0.7),
        borderColor: Color = .appBorder,
        cornerRadius: CGFloat = Spacing.cardRadius,
        padding: Bool = true
    ) -> some View {
        self.padding(padding ? Spacing.standardPadding : 0)
            .background(.ultraThinMaterial)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.4), lineWidth: Spacing.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    /// 仪表盘指标卡片风格 (Metric Card Style)
    func appMetricCardStyle(color: Color = .appAccent, cornerRadius: CGFloat = Spacing.Metrics.dashboardRadius) -> some View {
        self.background(.ultraThinMaterial)
            .background(
                ZStack {
                    Color.appCard.opacity(0.7)
                    LinearGradient(
                        colors: [color.opacity(0.12), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.appBorder.opacity(0.5), .appBorder.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

---

### Task 3: 创建布局容器 (Layouts)

**Files:**
- Create: `Sources/Shared/UIComponents/Layouts/StandardSection.swift`

- [ ] **Step 1: 创建 `StandardSection.swift`**

```swift
import SwiftUI

// MARK: @PR-03: 标准化容器组件，用于列表分组

/// 标准卡片容器
public struct StandardSection<Content: View>: View {
    public let title: String?
    public let footer: String?
    public let content: Content
    
    public init(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .padding(.leading, Spacing.medium)
                    .textCase(.uppercase)
            }
            
            VStack(spacing: 0) {
                content
            }
            .appGlassCardStyle(opacity: 1.0, cornerRadius: Spacing.cardRadius)
            
            if let footer = footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, Spacing.medium)
            }
        }
        .padding(.horizontal, Spacing.standardPadding)
        .padding(.vertical, Spacing.small)
    }
}

public extension View {
    /// 应用列表行样式 (用于 StandardSection 内部)
    func appListRowStyle(showDivider: Bool = true) -> some View {
        VStack(spacing: 0) {
            self
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .contentShape(Rectangle())
            
            if showDivider {
                Divider()
                    .padding(.leading, Spacing.medium)
                    .opacity(0.5)
            }
        }
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

---

### Task 4: 更新 `AppUI.swift` 并处理遗留代码

**Files:**
- Modify: `Sources/Shared/Core/Constants/AppUI.swift`

- [ ] **Step 1: 从 `AppUI.swift` 中删除已迁移的代码**

从 `AppUI.swift` 中删除以下内容：
- `struct MeshGradientView`
- `struct AmbientGlowView`
- `struct PageBackgroundView`
- `static func pageBackground`
- `struct GlassCardModifier`
- `struct AppSection` (rename references if any)
- `View` 扩展中的 `appGlassCardStyle`, `appListRowStyle`, `appCardStyle`, `appContainer`, `appMetricCardStyle`

- [ ] **Step 2: 添加类型别名或保持向后兼容（可选，按需）**

如果其他地方引用了 `AppUI.AppSection`，可以添加：
```swift
@available(*, deprecated, renamed: "StandardSection")
typealias AppSection = StandardSection
```
在 `AppUI` 枚举内（如果需要）。

- [ ] **Step 3: 全局搜索并替换 `AppSection` 为 `StandardSection`**

- [ ] **Step 4: 最终编译验证**

Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

- [ ] **Step 5: 提交更改**
