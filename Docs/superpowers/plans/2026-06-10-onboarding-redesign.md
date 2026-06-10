# 引导体系优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development

**Goal:** 空状态场景化引导 + 渐进式功能发现 + 里程碑提示

**Tech Stack:** SwiftUI, Observation, UserDefaults

---

### Task 1: OnboardingPath 枚举 + L10n

**Files:**
- Modify: `Sources/Core/System/Onboarding/OnboardingService.swift`
- Modify: `Sources/Localization/Extensions/L10n+Onboarding.swift`
- Modify: `Sources/Localization/Catalogs/Onboarding.xcstrings`

- [ ] **Step 1: 添加 OnboardingPath 枚举**

```swift
// 在 OnboardingService.swift 顶部（或新建文件）添加：
public enum OnboardingPath: String, CaseIterable, Sendable {
    case quickStart
    case importData
    case explore

    public var icon: String {
        switch self {
        case .quickStart: return "rocket.fill"
        case .importData: return "tray.and.arrow.down.fill"
        case .explore: return "safari.fill"
        }
    }

    public var color: Color {
        switch self {
        case .quickStart: return .blue
        case .importData: return .green
        case .explore: return .orange
        }
    }
}
```

- [ ] **Step 2: 添加 L10n**

```swift
// L10n+Onboarding.swift
public enum Path {
    public static var quickStart: String { tr("onboarding.path.quickStart") }
    public static var quickStartDesc: String { tr("onboarding.path.quickStart.desc") }
    public static var importData: String { tr("onboarding.path.import") }
    public static var importDataDesc: String { tr("onboarding.path.import.desc") }
    public static var explore: String { tr("onboarding.path.explore") }
    public static var exploreDesc: String { tr("onboarding.path.explore.desc") }
}
```

- [ ] **Step 3: 添加 xcstrings 条目**（Onboarding.xcstrings 中）

- [ ] **Step 4: 编译验证** → `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

---

### Task 2: WelcomePathSelectionSection 替换 QuickStartGuide

**Files:**
- Modify: `Sources/App/Scenes/WelcomeView.swift:142-201`

- [ ] **Step 1: 创建 WelcomePathSelectionSection**

```swift
struct WelcomePathSelectionSection: View {
    @Environment(AppStore.self) var store
    @Binding var selectedTab: AppTab
    @State private var selectedPath: OnboardingPath? = nil

    var body: some View {
        VStack(spacing: DesignSystem.wide) {
            Label(L10n.Onboarding.pathTitle, systemImage: "sparkles")
                .font(.headline)

            // 3 个路径卡片
            HStack(spacing: DesignSystem.medium) {
                ForEach(OnboardingPath.allCases, id: \.rawValue) { path in
                    pathCard(path)
                }
            }

            // 选中快速体验时展示 demo 数据预览
            if selectedPath == .quickStart {
                demoPreviewCard
            }
        }
        .padding(DesignSystem.wide)
        .appContainer(background: Color.appCard)
        .padding(.horizontal)
    }

    private func pathCard(_ path: OnboardingPath) -> some View {
        let selected = selectedPath == path
        return Button(action: {
            withAnimation { selectedPath = selected ? nil : path }
        }) {
            VStack(spacing: DesignSystem.tightPadding) {
                Image(systemName: path.icon)
                    .font(.title2)
                    .foregroundStyle(path.color)
                Text(pathLabel(path))
                    .font(.caption.bold())
                Text(pathDesc(path))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity)
            .background(selected ? path.color.opacity(0.1) : Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                    .stroke(selected ? path.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var demoPreviewCard: some View {
        VStack(spacing: DesignSystem.small) {
            Text(L10n.Onboarding.Demo.title)
                .font(.subheadline.bold())
            Text(L10n.Onboarding.Demo.desc)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button(action: { Task { await store.generateDemoData() } }) {
                Label(L10n.Settings.injectDemoData, systemImage: "testtube.2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
    }

    private func pathLabel(_ path: OnboardingPath) -> String {
        switch path {
        case .quickStart: return L10n.Onboarding.Path.quickStart
        case .importData: return L10n.Onboarding.Path.importData
        case .explore: return L10n.Onboarding.Path.explore
        }
    }

    private func pathDesc(_ path: OnboardingPath) -> String {
        switch path {
        case .quickStart: return L10n.Onboarding.Path.quickStartDesc
        case .importData: return L10n.Onboarding.Path.importDataDesc
        case .explore: return L10n.Onboarding.Path.exploreDesc
        }
    }
}
```

- [ ] **Step 2: WelcomeView 中替换 QuickStartGuideSection**

将 `WelcomeQuickStartGuideSection(...)` 替换为 `WelcomePathSelectionSection(selectedTab: $selectedTab)`

- [ ] **Step 3: 编译验证**

- [ ] **Step 4: Commit**

---

### Task 3: 渐进式功能发现——各 Tab 空状态

**Files:**
- Modify: `Sources/Features/AI/Chat/View/ChatView.swift`
- Modify: `Sources/Features/Knowledge/Graph/View/GraphView.swift`
- Create: `Sources/Core/System/Onboarding/OnboardingMilestone.swift`

- [ ] **Step 1: 创建里程碑触发系统**

```swift
// OnboardingMilestone.swift
public enum OnboardingMilestone: String {
    case firstPageCreated
    case firstAIChat
    case firstGraphView
    case firstSynthesis
    case pageCount10
    case pageCount50
    case pageCount100

    var toastMessage: String {
        switch self {
        case .firstPageCreated: return L10n.Onboarding.Milestone.firstPage
        case .firstAIChat: return L10n.Onboarding.Milestone.firstChat
        case .firstGraphView: return L10n.Onboarding.Milestone.firstGraph
        case .firstSynthesis: return L10n.Onboarding.Milestone.firstSynthesis
        case .pageCount10: return L10n.Onboarding.Milestone.page10
        case .pageCount50: return L10n.Onboarding.Milestone.page50
        case .pageCount100: return L10n.Onboarding.Milestone.page100
        }
    }

    var userDefaultsKey: String { "onboarding.milestone.\(rawValue)" }

    var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    func markAsShown() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }
}
```

- [ ] **Step 2: 在 ChatView 首次 AI 对话后触发里程碑**

在 ChatView 的第一次对话完成时，检查并触发 `OnboardingMilestone.firstAIChat`

- [ ] **Step 3: 在 GraphView 首次进入时触发**

在 GraphView `.onAppear` 中检查页面数 ≥ 3 且未触发过

- [ ] **Step 4: 在 KnowledgeStore.createPage 后检查页数里程碑**

在 `createPage` 完成后检查 pageCount 是否触发里程碑阈值

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

---

### Task 4: 单元测试

**Files:**
- Create: `Tests/Unit/System/OnboardingMilestoneTests.swift`

- [ ] **Step 1: 创建测试**

```swift
final class OnboardingMilestoneTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // 清除测试残留
        OnboardingPath.allCases.forEach {
            UserDefaults.standard.removeObject(forKey: "onboarding.milestone.\($0.rawValue)")
        }
    }

    func testMilestoneHasCorrectKeys() {
        XCTAssertEqual(OnboardingMilestone.firstPageCreated.userDefaultsKey, "onboarding.milestone.firstPageCreated")
        XCTAssertEqual(OnboardingMilestone.firstAIChat.userDefaultsKey, "onboarding.milestone.firstAIChat")
    }

    func testMilestoneNotShownByDefault() {
        XCTAssertFalse(OnboardingMilestone.firstPageCreated.hasBeenShown)
    }

    func testMilestoneMarkAsShown() {
        OnboardingMilestone.firstPageCreated.markAsShown()
        XCTAssertTrue(OnboardingMilestone.firstPageCreated.hasBeenShown)
    }

    func testOnboardingPathAllCasesCount() {
        XCTAssertEqual(OnboardingPath.allCases.count, 3)
    }
}
```

- [ ] **Step 2: 运行测试** → 4 passed

- [ ] **Step 3: Commit**

---

### Task 5: 全量测试 + 三平台编译

- [ ] **Step 1: 三平台编译验证**
- [ ] **Step 2: 全量测试**
- [ ] **Step 3: Commit & Push**

---

### Self-Review

1. **OnboardingPath 的 L10n** — displayName 通过 switch 返回 L10n，国际化覆盖
2. **无魔鬼数字** — 里程碑阈值通过 `OnboardingMilestone` 枚举定义，不在代码中散落
3. **无魔鬼字符串** — 所有 UserDefaults key 通过枚举计算属性生成
4. **测试覆盖** — 里程碑正确性、默认状态、标记完成、路径枚举完整性
