# iPad 主页布局重构优化设计规格书 (iPad-Specific Layout Optimization)

- **作者**: Wang Chong / Antigravity AI
- **日期**: 2026-05-23
- **版本**: 1.0
- **项目**: 智宇 (ZhiYu) - AI 原生知识管理应用
- **版权**: 版权所有 © 2026 Wang Chong。保留所有权利。

---

## 1. 背景与痛点

在当前的架构设计中，iPad 平台和 macOS 平台在 `appEnv.screenClass != .compact` 的判定下，共享同一套三栏式 `NavigationSplitView`。但在实际的使用场景中，iPad 的屏幕物理尺寸与分屏状态限制使得三栏全部展开时体验极差，具体表现在：
1. **核心区拥挤**：三栏（Tab 栏 - 页面列表 - 内容详情）并排常驻时，核心的笔记编辑与 AI 聊天区域受到严重挤压，特别是在竖屏（Compact Width）或 Split View 分屏模式下基本无法正常操作。
2. **空白第二栏 UI 缺陷**：当用户切换到非知识库模块（如 `Chat`、`Graph`、`Ingest`）时，中间的列表栏由于没有关联的数据源而呈现为一片空白占位色块，而右侧的 Detail 视图被强行塞在最右边的狭小空间。
3. **空间冗余**：左侧第一栏 `AdaptiveSidebarView` 仅承载了 5 个模块的 Tab 切换，信息密度极低，白白浪费了宝贵的横向宽度。

---

## 2. 设计原则与方案概述

为了在不影响 macOS (三栏) 和 iPhone (单栏底栏 TabBar) 体验的前提下优化 iPad 端界面，我们采用了 **方案 A：iPad 专属双栏 + 底部 TabBar 集成 + 智能侧边栏折叠联动方案**。

### 2.1 核心设计要点
1. **双栏扁平化 (Sidebar - Detail)**：剔除最左侧常驻的 Tab 栏。左侧侧边栏只在 `.knowledge` 模式下承载知识库列表；右侧承载所有核心的主内容详情。
2. **磨砂页脚 Tab 切换器 (`iPadTabBar`)**：将顶层的 5 个模块切换逻辑，集成在左侧侧边栏的底端。这既节省了整栏的物理宽度，也极大地提升了手势操作的便捷性。
3. **自动折叠与唤出逻辑**：
   - 切换到非知识库（`.chat`、`.graph`、`.synthesis`、`.ingest`）等无二级列表的模块时，侧边栏通过重置折叠状态（`ipadColumnVisibility = .detailOnly`）自动向左隐藏，将 Detail 主视窗拉伸为 100% 满屏状态。
   - 当用户想切换模块时，可通过左上角系统自带的 Sidebar 唤出按钮（或从左边缘向右拖曳）拉出侧边栏，轻点 `iPadTabBar` 上的图标切回知识库；一旦切回知识库（`.knowledge`），侧边栏立即恢复为常驻展开的双栏状态（`ipadColumnVisibility = .doubleColumn`）。

---

## 3. 详细设计与代码接口

### 3.1 跨平台隔离策略 (Platform Isolation)
使用 Swift 的平台编译条件与 `UIKit` 运行期 idiom 检查相结合，精确锁死 iPadOS 平台：
```swift
#if os(iOS)
let isPad = UIDevice.current.userInterfaceIdiom == .pad
#else
let isPad = false
#endif
```
确保该条件只在 iOS 的 iPad 设备上生效。macOS 端依旧输出 `macOSSplitView`，iPhone 端依旧输出 `legacy/modernTabView`。

### 3.2 核心状态管理 (State Management)
在 `ContentView.swift` 中引入新的状态属性，专门绑定 iPadOS 分栏控制：
```swift
/// 控制 iPad 专属双栏 SplitView 的折叠可见性
@State internal var ipadColumnVisibility: NavigationSplitViewVisibility = .automatic
```

### 3.3 布局组装与切换 (Layout Pipeline)
在 `AppLayoutComponents.swift` 的扩展方法中重构：
```swift
@ViewBuilder
func adaptiveSplitView(tintColor: Color) -> some View {
    #if os(watchOS)
    Text("Not used on watchOS")
    #else
    @Bindable var store = store
    @Bindable var router = router
    
    #if os(iOS)
    if UIDevice.current.userInterfaceIdiom == .pad {
        iPadSplitView(tintColor: tintColor)
    } else {
        macOSSplitView(tintColor: tintColor)
    }
    #else
    macOSSplitView(tintColor: tintColor)
    #endif
    #endif
}
```

- **`iPadSplitView` 的核心逻辑**：
  1. **左侧 Sidebar**：使用 `VStack(spacing: 0)` 包裹。上半部分根据 `router.selectedTab` 显示具体内容列表（若为知识库则显示 `SidebarView`，其他显示占位符视图 `iPadSidebarPlaceholderView`），下半部分放置 `iPadTabBar(tintColor: tintColor)`。
  2. **右侧 Detail**：加载 `AdaptiveDetailView`。
  3. **交互监听**：通过 `.onChange(of: router.selectedTab)` 对 Tab 进行监听。当新 Tab 为非知识库时，用动画过渡将 `ipadColumnVisibility` 修改为 `.detailOnly`；当切回知识库时，将其重置为 `.doubleColumn`。

---

## 4. 验证与测试防线

### 4.1 编译正确性验证
分别对三大编译平台进行独立构建：
- `iOS` (iPad/iPhone)：
  ```bash
  xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
  ```
- `macOS` (macCatalyst / macOS)：
  ```bash
  xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
  ```

### 4.2 单元与 UI 测试回溯
- 运行针对 iOS 全部的单元测试：
  ```bash
  xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  ```
- 检验 `ZhiYuPlatformUITests.swift` 中的 `testiPadNavigationSplitViewVisible()`。如果三栏改为双栏折叠后断言有偏差，需同步修正断言以匹配智能折叠与双栏的全新特性。
