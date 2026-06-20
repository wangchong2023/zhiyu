# 标签气泡云（蜂窝网格与鱼眼缩放）设计规格说明书

本规格说明书定义了智宇 (ZhiYu) 应用中「标签管理」界面的蜂窝网格气泡云与控制舱重构设计。

---

## 1. 核心目标与痛点解决

### 1.1 现有痛点
* **气泡拉伸变形**：当前的标签气泡采用流式排版 (`FlowLayout`)，由于内边距和字符长度不同，导致圆形背景被横向拉扯成生硬的椭圆。
* **排版单调**：流式折行缺乏视觉张力，与 Apple Watch 的蜂窝主屏体验相差甚远。
* **控制栏杂乱**：视图切换 Picker 与日常管理操作按钮（搜索、新增、管理）大小不一、摆放局促，缺乏一致的系统级视觉精致感。

### 1.2 预期效果
* **二维蜂窝排布**：以词频最高的核心标签为中心，其余标签呈错位六角网格螺旋向外扩散。
* **双向阻尼交互**：支持 X/Y 轴的自由拖拽，松手时具备柔和的惯性滑动与边界回弹。
* **立体鱼眼缩放 (Fisheye)**：滑动过程中，距离视口几何中心越近的气泡平滑膨胀，边缘气泡收缩并淡出。
* **磨砂玻璃控制舱**：重构顶部操作区为一体化毛玻璃控制舱，统一按钮尺寸和间距。

---

## 2. 详细技术方案

### 2.1 螺旋坐标定位算法
网格排布以轴向坐标系 (Axial Coordinates) `(q, r)` 描述蜂窝节点。

#### 坐标物理映射：
气泡在大画布上的中心点 `(x, y)` 计算公式为：
$$x = S \cdot \left(\sqrt{3} \cdot q + \frac{\sqrt{3}}{2} \cdot r\right)$$
$$y = S \cdot \left(\frac{3}{2} \cdot r\right)$$
其中 $S$ 为基础网格步长，计算值为：`S = (气泡最大直径 + 气泡间距) / 2`。

#### 螺旋映射序列：
将词频最高的标签置于 `(0, 0)`，后续标签按词频降序依次映射至以下螺旋环绕坐标集：
* 环绕圈 $N$（从 1 开始递增）包含 $6N$ 个节点。
* 使用 Swift 轴向方向向量顺时针旋转遍历生成坐标环，并将排序后的标签序列与坐标逐一绑定。

### 2.2 二维画布与鱼眼引擎 (Fisheye Engine)

#### 交互视口结构：
* 外层使用固定尺寸的容器，通过 `GeometryReader` 捕获几何中心 `viewportCenter`。
* 内部使用 `ZStack` 承载大画布，通过拖拽手势 `DragGesture` 实时更新 `dragOffset` 与累计偏移 `totalOffset`。

#### 鱼眼形变计算：
对每一个气泡，计算其在视口坐标系中的实时全局中心点：
$$D = \sqrt{dx^2 + dy^2}$$
其中 $dx, dy$ 为气泡全局坐标与 `viewportCenter` 坐标之差。

在有效缩放半径 $R_{max} = 260$ 内应用余弦插值函数：
```swift
let normalizedDistance = min(D / R_max, 1.0)
let interpolator = (cos(normalizedDistance * .pi) + 1.0) / 2.0 // 输出 1.0 (中心) 到 0.0 (边缘)

let scale = scaleMin + (scaleMax - scaleMin) * interpolator    // (scaleMin: 0.55, scaleMax: 1.25)
let opacity = opacityMin + (1.0 - opacityMin) * interpolator  // (opacityMin: 0.2, opacityMax: 1.0)
```

### 2.3 气泡自适应文本微组件
* **几何约束**：强制设定 `.frame(width: size, height: size)` 并在背景绘制 `Circle()`，保障正圆形态。
* **文字避让**：气泡内采用 `VStack(spacing: 3)` 排布。标签文字限制为 `.lineLimit(1)` 并配合 `.minimumScaleFactor(0.48)`，对于超长文本自动执行尾部截断。

### 2.4 控制舱栏 (Toolbar Redesign)
重构 [TagCloudView.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Features/Insight/Dashboard/View/TagCloudView.swift) 的顶部控制栏：
* **悬浮卡片背景**：外层采用磨砂玻璃背景，配合微细边框。
* **胶囊 Picker**：切换按钮采用纯自定义的胶囊切换样式，平滑的位移滑块背景指示当前模式。
* **原子控制键**：右侧的「搜索」、「新增」、「管理」独立承载在 `36pt * 36pt` 的正圆磨砂按键中，间距定为统一的 `12pt`。

---

## 3. 性能优化方案

* **视口外元素渲染剔除 (Culling)**：当气泡到视口中心的欧氏距离 $D > 320$ 像素（即已划出视口）时，**直接屏蔽 `GeometryReader` 定位监听**，将其缩放固定为 `scaleMin` 且**隐藏耗电的霓虹外阴影描边**，极大减少 GPU 的着色带宽和 Swift 视图重绘频次。
* **离线预计算**：六角坐标一次性静态生成，拖动时仅改变父容器 `offset`。

---

## 4. 验证规划

### 4.1 自动测试
* 运行项目单元测试包，确保大模型下载管理器的重构改动及标签云底层协调器 `TagCloudCoordinator` 数据层不受影响。

### 4.2 手动测试
* **布局形变**：确认超长文字标签在正圆形中不会导致气泡变成椭圆。
* **交互顺滑度**：确保在 iOS 模拟器上拖拽气泡云时无卡顿（不丢帧），回弹与鱼眼过渡柔和。
* **状态联动**：验证选中标签后，下方「关联页面」列表数据刷新正确。
