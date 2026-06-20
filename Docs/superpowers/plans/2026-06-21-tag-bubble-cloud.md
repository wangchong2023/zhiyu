# 标签气泡云（蜂窝网格与鱼眼缩放）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构标签管理界面，实现 Apple Watch 蜂窝网格螺旋排列、二维阻尼拖拽与立体鱼眼缩放效果，并升级为毛玻璃控制舱排版。

**Architecture:** 采用 L3 表现层垂直化切片。新建 `CircularTagBubbleView` 实现正圆形自适应文本气泡；新建 `TagBubbleCloudCanvas` 结合轴向螺旋坐标系统和 DragGesture 提供双向惯性画布及鱼眼缩放引擎；重构 `TagCloudView` 组合上述视图并美化工具栏。

**Tech Stack:** SwiftUI, CommonCrypto, HapticFeedback, Observation

## Global Constraints

* 语言采用 Swift 6，启用严格并发检查 `SWIFT_STRICT_CONCURRENCY: complete`。
* 严禁在 L1.5 领域层或下层导入 UI 框架（如 SwiftUI, UIKit, AppKit）。当前改动为 L3 表现层，可正常使用 SwiftUI。
* 代码必须提供完善的文件头、函数头和关键步骤的中文注释。
* 修改完成后必须执行 `xcodebuild` 验证，确保编译无误。

---

### Task 1: 螺旋网格计算器设计与 TDD 单元测试

**Files:**
* Create: `Sources/Features/Insight/Dashboard/Utility/HexSpiralCalculator.swift`
* Create: `Tests/Unit/Dashboard/HexSpiralCalculatorTests.swift`

**Interfaces:**
* Consumes: None
* Produces: `HexSpiralCalculator` 结构体提供基于轴向螺旋的坐标转换。
  ```swift
  struct HexCoordinate: Hashable {
      let q: Int
      let r: Int
  }
  struct HexSpiralCalculator {
      static func generateSpiralCoordinates(count: Int) -> [HexCoordinate]
      static func convertToPhysicalPoint(coord: HexCoordinate, stepSize: CGFloat) -> CGPoint
  }
  ```

- [ ] **Step 1: 编写螺旋坐标生成的单元测试**
  
  新建 `Tests/Unit/Dashboard/HexSpiralCalculatorTests.swift`：
  ```swift
  import XCTest
  @testable import ZhiYu

  final class HexSpiralCalculatorTests: XCTestCase {
      func testSpiralCoordinatesUniqueness() {
          let count = 50
          let coords = HexSpiralCalculator.generateSpiralCoordinates(count: count)
          
          XCTAssertEqual(coords.count, count, "生成的坐标数量必须和预期一致")
          
          let uniqueCoords = Set(coords)
          XCTAssertEqual(uniqueCoords.count, count, "所有生成的螺旋轴向坐标必须唯一，不能有重叠节点")
          
          if count > 0 {
              XCTAssertEqual(coords[0].q, 0)
              XCTAssertEqual(coords[0].r, 0, "首个最高频标签必须放置于原点中心")
          }
      }
  }
  ```

- [ ] **Step 2: 运行测试并确保它失败（或无法编译）**
  
  Run: `xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZhiYuTests/HexSpiralCalculatorTests`
  Expected: 编译失败 (No such type HexSpiralCalculator)

- [ ] **Step 3: 编写最小化实现**
  
  创建 `Sources/Features/Insight/Dashboard/Utility/HexSpiralCalculator.swift`：
  ```swift
  //
  //  HexSpiralCalculator.swift
  //  ZhiYu
  //
  //  Created by Antigravity on 2026/06/21.
  //  Copyright © 2026 WangChong. All rights reserved.
  //
  //  系统层级：[L3] 表现层辅助工具
  //  核心职责：计算二维六角蜂窝轴向螺旋分布坐标，以将最高频标签锁定在画布中心，低频向四周辐射。
  //
  
  import Foundation
  import CoreGraphics

  /// 六角网格轴向坐标
  public struct HexCoordinate: Hashable, Sendable {
      public let q: Int
      public let r: Int
      
      public init(q: Int, r: Int) {
          self.q = q
          self.r = r
      }
  }

  /// 六角螺旋分布计算器
  public struct HexSpiralCalculator {
      
      /// 六个基本方向的轴向向量
      private static let hexDirections = [
          HexCoordinate(q: 1, r: -1),
          HexCoordinate(q: 1, r: 0),
          HexCoordinate(q: 0, r: 1),
          HexCoordinate(q: -1, r: 1),
          HexCoordinate(q: -1, r: 0),
          HexCoordinate(q: 0, r: -1)
      ]
      
      /// 根据所需的坐标数生成向外辐射的螺旋序列坐标
      /// - Parameter count: 标签总数
      /// - Returns: 轴向坐标数组
      public static func generateSpiralCoordinates(count: Int) -> [HexCoordinate] {
          guard count > 0 else { return [] }
          var results: [HexCoordinate] = []
          results.reserveCapacity(count)
          
          // 中心原点
          results.append(HexCoordinate(q: 0, r: 0))
          if results.count >= count { return results }
          
          var ring = 1
          while results.count < count {
              // 初始向一个方向移动 ring 步开启该环
              var q = 0 + HexSpiralCalculator.hexDirections[4].q * ring
              var r = 0 + HexSpiralCalculator.hexDirections[4].r * ring
              
              // 遍历 6 个六角蜂窝边
              for i in 0..<6 {
                  for _ in 0..<ring {
                      if results.count >= count { return results }
                      results.append(HexCoordinate(q: q, r: r))
                      q += HexSpiralCalculator.hexDirections[i].q
                      r += HexSpiralCalculator.hexDirections[i].r
                  }
              }
              ring += 1
          }
          return results
      }
      
      /// 将轴向蜂窝坐标映射到二维屏幕物理坐标点
      /// - Parameters:
      ///   - coord: 轴向坐标
      ///   - stepSize: 网格步长（通常为 (气泡最大尺寸 + 间距) / 2）
      /// - Returns: CGPoint 物理偏移坐标
      public static func convertToPhysicalPoint(coord: HexCoordinate, stepSize: CGFloat) -> CGPoint {
          let x = stepSize * (sqrt(3.0) * CGFloat(coord.q) + (sqrt(3.0) / 2.0) * CGFloat(coord.r))
          let y = stepSize * (1.5 * CGFloat(coord.r))
          return CGPoint(x: x, y: y)
      }
  }
  ```

- [ ] **Step 4: 运行测试验证通过**
  
  Run: `xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZhiYuTests/HexSpiralCalculatorTests`
  Expected: PASS

- [ ] **Step 5: 提交更改**
  
  ```bash
  git add Sources/Features/Insight/Dashboard/Utility/HexSpiralCalculator.swift Tests/Unit/Dashboard/HexSpiralCalculatorTests.swift
  git commit -m "feat: 实现六角蜂窝螺旋坐标生成器及单元测试"
  ```

---

### Task 2: 新建 `CircularTagBubbleView` 正圆自适应文本微组件

**Files:**
* Create: `Sources/Features/Insight/Dashboard/View/CircularTagBubbleView.swift`

**Interfaces:**
* Consumes: `TagCloudCoordinator` 数据管理，标签项 `item: (tag: String, count: Int)`。
* Produces: `CircularTagBubbleView` 满足 SwiftUI View 接口，渲染宽高相等的正圆气泡。

- [ ] **Step 1: 创建正圆自适应标签气泡视图**
  
  在 `Sources/Features/Insight/Dashboard/View/CircularTagBubbleView.swift` 写入：
  ```swift
  //
  //  CircularTagBubbleView.swift
  //  ZhiYu
  //
  //  Created by Antigravity on 2026/06/21.
  //  Copyright © 2026 WangChong. All rights reserved.
  //
  //  系统层级：[L3] 表现层组件
  //  核心职责：渲染强制正圆比例、且支持字号自适应压缩与尾部自动截断的单个标签球体。
  //
  
  import SwiftUI

  struct CircularTagBubbleView: View {
      /// 标签信息元组
      let item: (tag: String, count: Int)
      
      /// 视图协调器依赖
      @Bindable var coordinator: TagCloudCoordinator
      
      /// 归一化的气泡大小插值比例 (0.0 到 1.0)
      let bubbleRatio: Double
      
      /// 鱼眼引擎动态传入的缩放比例
      let interactiveScale: CGFloat
      
      /// 鱼眼引擎动态传入的透明度
      let interactiveOpacity: Double
      
      var body: some View {
          let isSelected = coordinator.isEditMode ? 
              coordinator.selectedTagsForBulk.contains(item.tag) : 
              coordinator.selectedTag == item.tag
          
          // 依据比例计算气泡的基础直径
          let baseSize: CGFloat = 68.0 + CGFloat(bubbleRatio * 38.0)
          let finalSize = baseSize * interactiveScale
          
          let textFontSize: CGFloat = 11.0 + CGFloat(bubbleRatio * 4.0)
          
          Button(action: {
              withAnimation(DesignSystem.Animation.prominent) {
                  if coordinator.isEditMode {
                      if coordinator.selectedTagsForBulk.contains(item.tag) {
                          coordinator.selectedTagsForBulk.remove(item.tag)
                      } else {
                          coordinator.selectedTagsForBulk.insert(item.tag)
                      }
                  } else {
                      coordinator.selectedTag = coordinator.selectedTag == item.tag ? nil : item.tag
                  }
              }
              HapticFeedback.shared.trigger(.selection)
          }) {
              VStack(spacing: 3) {
                  // 标签文本：字号自适应压缩 + 截断防溢出
                  Text(item.tag.replacingOccurrences(of: "#", with: ""))
                      .font(.system(size: textFontSize, design: .rounded).weight(isSelected ? .bold : .medium))
                      .lineLimit(1)
                      .minimumScaleFactor(0.48)
                      .multilineTextAlignment(.center)
                      .padding(.horizontal, 4)
                  
                  // 词频指示小微章
                  Text("\(item.count)")
                      .font(.system(size: textFontSize * 0.75, weight: .bold, design: .monospaced))
                      .padding(.horizontal, 5)
                      .padding(.vertical, 0.8)
                      .background(isSelected ? Color.white.opacity(0.25) : Color.appSecondary.opacity(0.18))
                      .clipShape(Capsule())
              }
              .frame(width: baseSize, height: baseSize)
              .foregroundStyle(isSelected ? .white : .appText)
              .background {
                  Circle()
                      .fill(isSelected ? Color.appAccent.opacity(0.9) : Color.appAccent.opacity(0.12 + bubbleRatio * 0.48))
              }
              .overlay {
                  Circle()
                      .stroke(isSelected ? Color.appAccent : Color.appBorder.opacity(0.25 + bubbleRatio * 0.25), lineWidth: 1.2)
              }
              .shadow(color: isSelected ? Color.appAccent.opacity(0.35) : Color.clear, radius: 6, y: 3)
              .scaleEffect(interactiveScale)
              .opacity(interactiveOpacity)
              .overlay(alignment: .topTrailing) {
                  if coordinator.isEditMode {
                      ZStack {
                          Circle()
                              .fill(isSelected ? Color.appAccent : Color.appCard)
                              .frame(width: 18, height: 18)
                          
                          if isSelected {
                              Image(systemName: "checkmark")
                                  .font(.system(size: 10, weight: .black))
                                  .foregroundStyle(.white)
                          } else {
                              Circle()
                                  .stroke(Color.appBorder, lineWidth: 1)
                                  .frame(width: 18, height: 18)
                          }
                      }
                      .offset(x: -2, y: 2)
                  }
              }
          }
          .buttonStyle(.plain)
          .contextMenu {
              if !coordinator.isEditMode {
                  Button(action: {
                      coordinator.tagToRename = item.tag
                      coordinator.newTagName = item.tag
                  }) {
                      Label(L10n.Tag.Action.rename, systemImage: DesignSystem.Icons.edit)
                  }
                  Button(role: .destructive, action: {
                      coordinator.tagToDelete = item.tag
                      coordinator.showDeleteConfirm = true
                  }) {
                      Label(L10n.Tag.Action.delete, systemImage: DesignSystem.Icons.delete)
                  }
              }
          }
      }
  }
  ```

- [ ] **Step 2: 运行编译指令确认无误**
  
  Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
  Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交组件**
  
  ```bash
  git add Sources/Features/Insight/Dashboard/View/CircularTagBubbleView.swift
  git commit -m "feat: 实现正圆型标签气泡微组件"
  ```

---

### Task 3: 新建 `TagBubbleCloudCanvas` 交互式蜂窝鱼眼画布

**Files:**
* Create: `Sources/Features/Insight/Dashboard/View/TagBubbleCloudCanvas.swift`

**Interfaces:**
* Consumes: `TagCloudCoordinator` 作为外部状态来源。
* Produces: `TagBubbleCloudCanvas` 作为独立 SwiftUI 视图挂载于页面中，提供 2D 滑动体验。

- [ ] **Step 1: 编写二维气泡画布视图与鱼眼算法**
  
  在 `Sources/Features/Insight/Dashboard/View/TagBubbleCloudCanvas.swift` 写入完整实现：
  ```swift
  //
  //  TagBubbleCloudCanvas.swift
  //  ZhiYu
  //
  //  Created by Antigravity on 2026/06/21.
  //  Copyright © 2026 WangChong. All rights reserved.
  //
  //  系统层级：[L3] 表现层容器
  //  核心职责：渲染双向拖拽的 2D 画布，按螺旋坐标平铺气泡，并实时执行视口几何欧氏距离计算以驱动余弦鱼眼缩放和边缘裁切。
  //
  
  import SwiftUI

  struct TagBubbleCloudCanvas: View {
      /// 视图协调器
      @Bindable var coordinator: TagCloudCoordinator
      
      // ── 二维滚动偏移状态 ──
      @State private var dragOffset: CGSize = .zero
      @State private var totalOffset: CGSize = .zero
      
      /// 基础网格步长参数 (气泡中心间的距离)
      private let stepSize: CGFloat = 64.0
      
      /// 鱼眼生效最大半径阈值
      private let maxFisheyeDistance: CGFloat = 260.0
      
      /// 视口外元素渲染裁切半径阈值 (超过则停止高负荷 Geometry 监听)
      private let cullingDistance: CGFloat = 320.0
      
      /// 词频比例计算
      private func bubbleRatio(for count: Int, tags: [(tag: String, count: Int)]) -> Double {
          let counts = tags.map { $0.count }
          guard let maxVal = counts.max(), let minVal = counts.min() else { return 0.0 }
          let diff = maxVal - minVal
          guard diff > 0 else { return 0.5 }
          return Double(count - minVal) / Double(diff)
      }
      
      var body: some View {
          let filtered = coordinator.filteredTags
          let coordinates = HexSpiralCalculator.generateSpiralCoordinates(count: filtered.count)
          
          GeometryReader { viewportGeo in
              let viewportCenter = CGPoint(x: viewportGeo.size.width / 2, y: viewportGeo.size.height / 2)
              
              ZStack {
                  // 画布大底板，充当拖拽捕获器
                  Color.clear
                      .contentShape(Rectangle())
                  
                  // 渲染每一个气泡
                  ForEach(Array(filtered.enumerated()), id: \.element.tag) { index, item in
                      let coord = coordinates[safe: index] ?? HexCoordinate(q: 0, r: 0)
                      // 映射物理偏移点
                      let physicalPoint = HexSpiralCalculator.convertToPhysicalPoint(coord: coord, stepSize: stepSize)
                      
                      // 叠加当前累计偏移及拖动偏置，算出相对视口的实时物理点
                      let currentX = physicalPoint.x + totalOffset.width + dragOffset.width
                      let currentY = physicalPoint.y + totalOffset.height + dragOffset.height
                      
                      // 宿主放置气泡，并提供鱼眼 GeometryReader
                      GeometryReader { itemGeo in
                          let frame = itemGeo.frame(in: .global)
                          let itemCenter = CGPoint(x: frame.midX, y: frame.midY)
                          
                          // 宿主外部视口在 global 的中心点
                          let viewportGlobalFrame = viewportGeo.frame(in: .global)
                          let viewportGlobalCenter = CGPoint(x: viewportGlobalFrame.midX, y: viewportGlobalFrame.midY)
                          
                          // 1. 计算与屏幕视口中心的二维欧氏距离
                          let dx = itemCenter.x - viewportGlobalCenter.x
                          let dy = itemCenter.y - viewportGlobalCenter.y
                          let distance = sqrt(dx * dx + dy * dy)
                          
                          // 2. 边缘剔除优化 (Frustum Culling)
                          if distance > cullingDistance {
                              CircularTagBubbleView(
                                  item: item,
                                  coordinator: coordinator,
                                  bubbleRatio: bubbleRatio(for: item.count, tags: filtered),
                                  interactiveScale: 0.55,
                                  interactiveOpacity: 0.2
                              )
                              .position(x: itemGeo.size.width / 2, y: itemGeo.size.height / 2)
                          } else {
                              // 3. 鱼眼变形计算 (基于余弦平滑过渡)
                              let normDist = min(distance / maxFisheyeDistance, 1.0)
                              let interpolator = (cos(normDist * .pi) + 1.0) / 2.0
                              
                              let scale = 0.55 + (1.25 - 0.55) * interpolator
                              let opacity = 0.2 + (1.0 - 0.2) * interpolator
                              
                              CircularTagBubbleView(
                                  item: item,
                                  coordinator: coordinator,
                                  bubbleRatio: bubbleRatio(for: item.count, tags: filtered),
                                  interactiveScale: scale,
                                  interactiveOpacity: opacity
                              )
                              .position(x: itemGeo.size.width / 2, y: itemGeo.size.height / 2)
                          }
                      }
                      .frame(width: 106, height: 106) // 固定的几何探测框，容纳气泡最大缩放态
                      .offset(x: currentX - 53 + viewportCenter.x, y: currentY - 53 + viewportCenter.y)
                  }
              }
              .gesture(
                  DragGesture()
                      .onChanged { gesture in
                          dragOffset = gesture.translation
                      }
                      .onEnded { gesture in
                          // 结合物理阻尼的平滑过渡
                          withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 60.0, damping: 15.0, initialVelocity: 0)) {
                              totalOffset.width += gesture.translation.width
                              totalOffset.height += gesture.translation.height
                              dragOffset = .zero
                              
                              // 约束边界回弹逻辑，防止无限拖走
                              let maxBound: CGFloat = CGFloat(filtered.count) * 8.0 + 200.0
                              if abs(totalOffset.width) > maxBound {
                                  totalOffset.width = totalOffset.width > 0 ? maxBound : -maxBound
                              }
                              if abs(totalOffset.height) > maxBound {
                                  totalOffset.height = totalOffset.height > 0 ? maxBound : -maxBound
                              }
                          }
                      }
              )
          }
      }
  }

  extension Collection {
      subscript(safe index: Index) -> Element? {
          return indices.contains(index) ? self[index] : nil
      }
  }
  ```

- [ ] **Step 2: 运行编译指令确认无误**
  
  Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
  Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交画布**
  
  ```bash
  git add Sources/Features/Insight/Dashboard/View/TagBubbleCloudCanvas.swift
  git commit -m "feat: 实现双向拖动六角错位鱼眼缩放画布容器"
  ```

---

### Task 4: 重构 `TagCloudView.swift` 控制舱与模式挂载

**Files:**
* Modify: `Sources/Features/Insight/Dashboard/View/TagCloudView.swift:138-188`
* Modify: `Sources/Features/Insight/Dashboard/View/TagCloudView.swift:319-354`

**Interfaces:**
* Consumes: 新创建的 `TagBubbleCloudCanvas`。
* Produces: 修改后的 `TagCloudView` 呈现出磨砂控制舱排版，并且在“气泡云”模式下正常渲染螺旋网格。

- [ ] **Step 1: 重构控制舱与 Picker 为磨砂玻璃卡片**
  
  编辑 [TagCloudView.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Features/Insight/Dashboard/View/TagCloudView.swift) 的 `mainContent` 与 `tagScrollView` 部分：
  
  替换 `mainContent` 中的顶部操作栏（第142-188行），升级为带有毛玻璃胶囊形态的控制舱：
  ```swift
              // 1. 顶部重构：精致毛玻璃工具舱 (Unified Toolbar Cabinet)
              HStack(spacing: 12) {
                  // 自定义胶囊型视图切换滑块
                  HStack(spacing: 0) {
                      Button(action: { 
                          withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { displayMode = .list } 
                      }) {
                          Text(L10n.Tag.layoutList)
                              .font(.system(size: 13, weight: .bold))
                              .foregroundStyle(displayMode == .list ? .white : .appSecondary)
                              .padding(.vertical, 8)
                              .padding(.horizontal, 14)
                              .background {
                                  if displayMode == .list {
                                      Capsule()
                                          .fill(Color.appAccent.opacity(0.85))
                                  }
                              }
                      }
                      .buttonStyle(.plain)
                      
                      Button(action: { 
                          withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { displayMode = .bubble } 
                      }) {
                          Text(L10n.Tag.layoutBubble)
                              .font(.system(size: 13, weight: .bold))
                              .foregroundStyle(displayMode == .bubble ? .white : .appSecondary)
                              .padding(.vertical, 8)
                              .padding(.horizontal, 14)
                              .background {
                                  if displayMode == .bubble {
                                      Capsule()
                                          .fill(Color.appAccent.opacity(0.85))
                                  }
                              }
                      }
                      .buttonStyle(.plain)
                  }
                  .padding(3)
                  .background(Color.black.opacity(0.18))
                  .clipShape(Capsule())
                  
                  Spacer()
                  
                  // 右侧统一的正圆磨砂按钮组
                  HStack(spacing: 10) {
                      // 搜索按钮
                      Button(action: {
                          withAnimation(.easeInOut(duration: 0.22)) {
                              showSearchBar.toggle()
                          }
                      }) {
                          Image(systemName: "magnifyingglass")
                              .font(.system(size: 14, weight: .bold))
                              .foregroundStyle(showSearchBar ? .appAccent : .white)
                              .frame(width: 36, height: 36)
                              .background(Color.appCard.opacity(0.6))
                              .clipShape(Circle())
                              .overlay(Circle().stroke(Color.appBorder.opacity(0.3), lineWidth: 1))
                      }
                      .buttonStyle(.plain)
                      
                      if !coordinator.isEditMode {
                          // 新增按钮
                          Button(action: { coordinator.showAddTagDialog = true }) {
                              Image(systemName: "plus")
                                  .font(.system(size: 14, weight: .bold))
                                  .foregroundStyle(.white)
                                  .frame(width: 36, height: 36)
                                  .background(Color.appCard.opacity(0.6))
                                  .clipShape(Circle())
                                  .overlay(Circle().stroke(Color.appBorder.opacity(0.3), lineWidth: 1))
                          }
                          .buttonStyle(.plain)
                      }
                      
                      // 管理/编辑按钮
                      Button(action: {
                          coordinator.isEditMode.toggle()
                          if !coordinator.isEditMode { coordinator.selectedTagsForBulk.removeAll() }
                      }) {
                          Image(systemName: coordinator.isEditMode ? "checkmark" : "list.bullet.indent")
                              .font(.system(size: 14, weight: .bold))
                              .foregroundStyle(coordinator.isEditMode ? .green : .white)
                              .frame(width: 36, height: 36)
                              .background(Color.appCard.opacity(0.6))
                              .clipShape(Circle())
                              .overlay(Circle().stroke(Color.appBorder.opacity(0.3), lineWidth: 1))
                      }
                      .buttonStyle(.plain)
                  }
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(BlurView().background(Color.appCard.opacity(0.45)))
              .clipShape(RoundedRectangle(cornerRadius: 22))
              .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.appBorder.opacity(0.35), lineWidth: 1))
              .padding(.horizontal, isExp ? DesignSystem.wide : DesignSystem.medium)
              .padding(.vertical, 10)
  ```

- [ ] **Step 2: 挂载 `TagBubbleCloudCanvas` 画布**
  
  修改 [TagCloudView.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Features/Insight/Dashboard/View/TagCloudView.swift) 中的 `tagScrollView`（原本的列表/流式气泡渲染，第 319-354 行），挂载新画布：
  ```swift
      private var tagScrollView: some View {
          let isListMode = displayMode == .list
          let tags = coordinator.filteredTags
          let shouldCollapse = isListMode && tags.count > 12 && !isExpanded
          let displayedTags = shouldCollapse ? Array(tags.prefix(12)) : tags
          
          return VStack(spacing: 0) {
              if isListMode {
                  ScrollView {
                      FlowLayout(spacing: DesignSystem.Grid.flowSpacing) {
                          ForEach(displayedTags, id: \.tag) { tagItem in
                              // 列表模式下仍复用原本的样式或组件
                              // 列表的 TagCapsule 依然使用现有的 TagCapsuleView
                              TagCapsuleView(
                                  item: tagItem,
                                  coordinator: coordinator,
                                  bubbleRatio: bubbleRatio(for: tagItem.count),
                                  isBubbleMode: false
                              )
                          }
                      }
                      .padding(DesignSystem.medium)
                  }
                  .frame(maxHeight: isExpanded ? .infinity : DesignSystem.Metrics.maxTagCloudHeight)
                  .fixedSize(horizontal: false, vertical: true)
                  .overlay(alignment: .bottom) {
                      if shouldCollapse {
                          LinearGradient(
                              colors: [.clear, Color.appCard.opacity(0.8), Color.appCard],
                              startPoint: .top,
                              endPoint: .bottom
                          )
                          .frame(height: 35)
                          .allowsHitTesting(false)
                      }
                  }
              } else {
                  // 气泡云模式：直接挂载新实现的双向鱼眼画布，撑满卡片容器
                  TagBubbleCloudCanvas(coordinator: coordinator)
                      .frame(minHeight: 280, maxHeight: .infinity)
              }
          }
      }
  ```

- [ ] **Step 3: 运行完整构建并验证测试**
  
  Run: `xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
  Expected: BUILD SUCCEEDED
  
  运行原本的单元测试确保未破坏原有业务流：
  Run: `xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZhiYuTests/ModelStoreConfigTests`
  Expected: PASS/FAIL (同环境原本测试结果相同，确认协调器相关逻辑未破坏)

- [ ] **Step 4: 提交主页面修改**
  
  ```bash
  git add Sources/Features/Insight/Dashboard/View/TagCloudView.swift
  git commit -m "refactor: 重构标签控制舱排版并挂载双向鱼眼蜂窝画布"
  ```
