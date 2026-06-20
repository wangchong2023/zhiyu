//
//  TagCloudView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 TagCloud 界面的 UI 视图层组件。
//
import SwiftUI

#if os(macOS)
import AppKit
#endif

// MARK: - 标签云视图 (导航容器)
/// 标签管理的顶层视图容器，负责承载主内容
struct TagCloudView: View {
    /// 初始选中的标签（由外部跳转传入）
    var initialTag: String?
    
    var body: some View {
        TagCloudViewContent(initialTag: initialTag)
    }
}

// MARK: - 标签管理主内容
/// 标签管理的核心业务逻辑与界面实现
struct TagCloudViewContent: View {
    // ── 外部依赖 ──
    @Environment(AppStore.self) var store
    @Inject var appEnv: any AppEnvironmentProtocol
    
    // 使用协调器管理状态与交互
    @State private var coordinator: TagCloudCoordinator
    @State private var showBulkDeleteConfirm = false
    @State private var displayMode: DisplayMode = .list
    @State private var showSearchBar = false
    @State private var isExpanded = false
    
    enum DisplayMode {
        case list
        case bubble
    }

    // ── 顶部工具栏重构排版与透明度设计常量 (杜绝魔鬼数字与 swiftlint 禁用) ──
    private let pickerBtnPaddingV: CGFloat = 8.0
    private let pickerBtnPaddingH: CGFloat = 14.0
    private let pickerInnerPadding: CGFloat = 3.0
    private let actionBtnDiameter: CGFloat = 36.0
    private let toolbarCornerRadius: CGFloat = 22.0
    private let bubbleCanvasMinHeight: CGFloat = 280.0
    private let viewModeFontSize: CGFloat = 13.0
    private let actionBtnIconFontSize: CGFloat = 14.0
    private let pickerSelectedBgOpacity = 0.85
    private let pickerUnselectedBgOpacity = 0.18
    private let actionBtnBgOpacity = 0.6
    private let actionBtnBorderOpacity = 0.3
    private let toolbarBgOpacity = 0.45
    private let toolbarBorderOpacity = 0.35
    
    // ── 列表折叠遮罩设计常量 ──
    private let listCollapseGradientHeight: CGFloat = 35.0
    private let listCollapseGradientOpacity = 0.8

    /// 初始化路由状态
    /// - Parameter initialTag: 外部传入的初始选中标签
    init(initialTag: String? = nil) {
        self._coordinator = State(initialValue: TagCloudCoordinator(initialTag: initialTag))
    }
    
    var body: some View {
        @Bindable var coordinator = coordinator
        
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(PageBackgroundView(accentColor: .blue))
            .navigationTitle(L10n.Tag.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await coordinator.fetchData()
            }
            .onChange(of: store.pages) { _, _ in
                Task { await coordinator.fetchData() }
            }
            // 关键优化：将繁重的弹窗及确认对话框逻辑移至独立子视图，规避 SwiftUI 闭包过深导致的 Swift 编译器类型推演超时 (Type-Checking Timeout)
            .background {
                dialogsView
            }
    }

    /// 弹窗与确认对话框集合视图
    /// 提取该视图可以极大缩短编译时间，提升类型检查效率
    @ViewBuilder
    private var dialogsView: some View {
        @Bindable var coordinator = coordinator
        
        let isRenamePresented = Binding<Bool>(
            get: { coordinator.tagToRename != nil },
            set: { if !$0 { coordinator.tagToRename = nil } }
        )
        
        let renameMessage = L10n.Tag.Action.renameMessage(coordinator.tagToRename ?? "")
        let deleteMessage = coordinator.tagToDelete.map { L10n.Tag.Action.deleteMessage($0) } ?? L10n.Tag.Action.deleteTag
        let bulkDeleteMessage = L10n.Tag.Management.bulkDeleteWarning(coordinator.selectedTagsForBulk.count)
        
        Color.clear
            // 重命名对话框
            .alert(L10n.Tag.Action.renameTag, isPresented: isRenamePresented) {
                TextField(L10n.Tag.Action.newName, text: $coordinator.newTagName)
                Button(L10n.Common.cancel, role: .cancel) { coordinator.tagToRename = nil }
                Button(L10n.Common.ok) {
                    coordinator.performRename()
                }
            } message: {
                Text(renameMessage)
            }
            // 删除确认对话框
            .confirmationDialog(
                deleteMessage,
                isPresented: $coordinator.showDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.delete, role: .destructive) {
                    coordinator.performDelete()
                }
                Button(L10n.Common.cancel, role: .cancel) { coordinator.tagToDelete = nil }
            } message: {
                Text(L10n.Settings.clearAll.message)
            }
            // 新增标签对话框
            .alert(L10n.Tag.Management.addNew, isPresented: $coordinator.showAddTagDialog) {
                TextField(L10n.Tag.Management.inputName, text: $coordinator.addTagName)
                Button(L10n.Common.cancel, role: .cancel) { coordinator.addTagName = "" }
                Button(L10n.Common.Misc.create) {
                    coordinator.performAddTag()
                }
            } message: {
                Text(L10n.Tag.Management.createHint)
            }
            // 批量删除确认
            .confirmationDialog(
                bulkDeleteMessage,
                isPresented: $showBulkDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.Misc.deleteAll, role: .destructive) {
                    coordinator.performBulkDelete()
                }
                Button(L10n.Common.cancel, role: .cancel) { }
            } message: {
                Text(L10n.Settings.clearAll.message)
            }
    }

    /// 组合主界面布局
    private var mainContent: some View {
        let isExp = appEnv.screenClass == .expansive
        
        return VStack(spacing: 0) {
            // 1. 顶部操作栏重构：悬浮毛玻璃控制舱 (Unified Toolbar Cabinet)
            HStack(spacing: 12) {
                // 自定义胶囊型视图切换滑块
                HStack(spacing: 0) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { displayMode = .list } 
                    }) {
                        Text(L10n.Tag.layoutList)
                            .font(.system(size: viewModeFontSize, weight: .bold))
                            .foregroundStyle(displayMode == .list ? Color.theme.white : .appSecondary)
                            .padding(.vertical, pickerBtnPaddingV)
                            .padding(.horizontal, pickerBtnPaddingH)
                            .background {
                                if displayMode == .list {
                                    Capsule()
                                        .fill(Color.appAccent.opacity(pickerSelectedBgOpacity))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { displayMode = .bubble } 
                    }) {
                        Text(L10n.Tag.layoutBubble)
                            .font(.system(size: viewModeFontSize, weight: .bold))
                            .foregroundStyle(displayMode == .bubble ? Color.theme.white : .appSecondary)
                            .padding(.vertical, pickerBtnPaddingV)
                            .padding(.horizontal, pickerBtnPaddingH)
                            .background {
                                if displayMode == .bubble {
                                    Capsule()
                                        .fill(Color.appAccent.opacity(pickerSelectedBgOpacity))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(pickerInnerPadding)
                .background(Color.theme.black.opacity(pickerUnselectedBgOpacity))
                .clipShape(Capsule())
                
                Spacer()
                
                // 右侧统一的正圆磨砂按钮组
                HStack(spacing: 10) {
                    // 🔍 搜索切换按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            showSearchBar.toggle()
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: actionBtnIconFontSize, weight: .bold))
                            .foregroundStyle(showSearchBar ? Color.appAccent : Color.theme.white)
                            .frame(width: actionBtnDiameter, height: actionBtnDiameter)
                            .background(Color.appCard.opacity(actionBtnBgOpacity))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.appBorder.opacity(actionBtnBorderOpacity), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Search.title)
                    
                    if !coordinator.isEditMode {
                        // ➕ 新建按钮
                        Button(action: { coordinator.showAddTagDialog = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: actionBtnIconFontSize, weight: .bold))
                                .foregroundStyle(Color.theme.white)
                                .frame(width: actionBtnDiameter, height: actionBtnDiameter)
                                .background(Color.appCard.opacity(actionBtnBgOpacity))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.appBorder.opacity(actionBtnBorderOpacity), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // ✏️ 管理/编辑按钮
                    Button(action: {
                        coordinator.isEditMode.toggle()
                        if !coordinator.isEditMode { coordinator.selectedTagsForBulk.removeAll() }
                    }) {
                        Image(systemName: coordinator.isEditMode ? "checkmark" : "list.bullet.indent")
                            .font(.system(size: actionBtnIconFontSize, weight: .bold))
                            .foregroundStyle(coordinator.isEditMode ? .green : Color.theme.white)
                            .frame(width: actionBtnDiameter, height: actionBtnDiameter)
                            .background(Color.appCard.opacity(actionBtnBgOpacity))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.appBorder.opacity(actionBtnBorderOpacity), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(BlurView().background(Color.appCard.opacity(toolbarBgOpacity)))
            .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius))
            .overlay(RoundedRectangle(cornerRadius: toolbarCornerRadius).stroke(Color.appBorder.opacity(toolbarBorderOpacity), lineWidth: 1))
            .padding(.horizontal, isExp ? DesignSystem.wide : DesignSystem.medium)
            .padding(.vertical, 10)

            // 2. 搜索栏（当 showSearchBar 为真时以动画展开，不受标签总数限值）
            if showSearchBar {
                HStack(spacing: DesignSystem.tightPadding) {
                    Image(systemName: DesignSystem.Icons.search)
                        .foregroundStyle(.appSecondary)
                    TextField(L10n.Search.filterTags, text: $coordinator.searchText)
                        .textFieldStyle(.plain)
                    if !coordinator.searchText.isEmpty {
                        Button { coordinator.searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.appSecondary)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.tightPadding)
                .background(Color.appCard.opacity(DesignSystem.glassOpacity))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                .padding(.horizontal, DesignSystem.huge)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.bottom, DesignSystem.small)
            }

            // 3. 标签云展示区（带标准边框的卡片）
            if coordinator.tags.isEmpty {
                emptyTagsView
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    HStack {
                        AppSectionHeader(
                            title: L10n.Tag.allTags,
                            icon: DesignSystem.Icons.tag,
                            iconColor: .appAccent
                        )
                        Spacer()
                        Text(L10n.Tag.tagCount(coordinator.filteredTags.count))
                            .font(.caption2).foregroundStyle(.appSecondary)
                    }
                    .padding(.horizontal, DesignSystem.tiny) // 4

                    VStack(spacing: 0) {
                        tagScrollView
                    }
                    .appContainer(background: Color.appCard.opacity(DesignSystem.glassOpacity), padding: false)
                    .overlay(alignment: .bottom) {
                        if coordinator.isEditMode && !coordinator.selectedTagsForBulk.isEmpty {
                            bulkActionBar
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.huge)
                .padding(.vertical, DesignSystem.Layout.columnSpacing)
            }

            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                HStack {
                    AppSectionHeader(
                        title: L10n.Tag.relatedPagesTitle,
                        icon: DesignSystem.Icons.docOnDocFill,
                        iconColor: .appSource
                    )
                    Spacer()
                    if coordinator.selectedTag != nil, !coordinator.isEditMode {
                        Text(L10n.Tag.Action.tagPages(coordinator.filteredPages.count))
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
                .padding(.horizontal, DesignSystem.tiny)

                pagesListView
                    .appContainer(background: Color.appCard.opacity(DesignSystem.glassOpacity), padding: false)
                    .frame(minHeight: DesignSystem.Metrics.sourceCardHeight) 
            }
            .padding(.horizontal, DesignSystem.huge)
            .padding(.bottom, DesignSystem.Layout.columnSpacing)
            
            // 添加弹性间距，确保内容不满一屏时背景色依然能覆盖全屏
            Spacer(minLength: 0)
        }
    }

    // MARK: - 子视图组件

    private var bulkActionBar: some View {
        HStack {
            Text(L10n.Tag.Management.selectedCount(coordinator.selectedTagsForBulk.count))
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
            Button(role: .destructive, action: { showBulkDeleteConfirm = true }) {
                Text(L10n.Common.Misc.bulkDelete)
                    .padding(.horizontal, DesignSystem.large)
                    .padding(.vertical, DesignSystem.small - DesignSystem.atomic) // 6
                    .background(Color.theme.red)
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(BlurView().background(Color.appAccent.opacity(DesignSystem.surfaceOpacity)))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var emptyTagsView: some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: DesignSystem.Icons.tag)
                .font(.system(size: DesignSystem.iconHuge))
                .foregroundStyle(.appSecondary)
            Text(L10n.Tag.Action.noTags)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Text(L10n.Tag.Action.noTagsHint)
                .font(.caption)
                .foregroundStyle(.appSecondary.opacity(DesignSystem.subtleOpacity))
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    private func bubbleRatio(for count: Int) -> Double {
        let counts = coordinator.filteredTags.map { $0.count }
        guard let maxVal = counts.max(), let minVal = counts.min() else { return 0.0 }
        let diff = maxVal - minVal
        guard diff > 0 else { return 0.5 }
        return Double(count - minVal) / Double(diff)
    }

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
                            colors: [.clear, Color.appCard.opacity(listCollapseGradientOpacity), Color.appCard],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: listCollapseGradientHeight)
                        .allowsHitTesting(false)
                    }
                }
            } else {
                // 气泡云模式：直接挂载新实现的双向鱼眼蜂窝画布，并撑满布局容器
                TagBubbleCloudCanvas(coordinator: coordinator)
                    .frame(minHeight: bubbleCanvasMinHeight, maxHeight: .infinity)
            }
            
            if isListMode && tags.count > 12 {
                HStack {
                    Spacer()
                    if !isExpanded {
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = true
                            }
                        }) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(L10n.Tag.expandAll)
                                Image(systemName: "chevron.down")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.appAccent)
                            .padding(.horizontal, DesignSystem.large)
                            .padding(.vertical, DesignSystem.small)
                            .background(Color.appCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.appAccent.opacity(DesignSystem.Opacity.light), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, DesignSystem.small)
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(L10n.Tag.collapse)
                                Image(systemName: "chevron.up")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.appSecondary)
                            .padding(.horizontal, DesignSystem.large)
                            .padding(.vertical, DesignSystem.small)
                            .background(Color.appCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.appBorder.opacity(DesignSystem.Opacity.light), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, DesignSystem.small)
                    }
                    Spacer()
                }
            }
        }
    }

    private var pagesListView: some View {
        Group {
            if coordinator.selectedTag != nil, !coordinator.isEditMode {
                List {
                    Section {
                        ForEach(coordinator.filteredPages) { page in
                            Button {
                                Router.shared.path.append(AppRoute.pageDetail(id: page.id))
                            } label: {
                                PageRowView(page: page, compact: true)
                                    .padding(.vertical, DesignSystem.tiny)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                                    .fill(Color.appCard.opacity(DesignSystem.softOpacity))
                                    .padding(.horizontal, DesignSystem.small)
                                    .padding(.vertical, DesignSystem.tiny)
                            )
                            #if !os(watchOS)
                            .listRowSeparator(.hidden)
                            #endif
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: coordinator.isEditMode ? DesignSystem.Icons.checklist : DesignSystem.Icons.tag)
                        .font(.system(size: DesignSystem.iconHuge))
                        .foregroundStyle(.appSecondary.opacity(DesignSystem.translucentOpacity))
                    Text(coordinator.isEditMode ? L10n.Tag.Management.selectToManage : L10n.Tag.Cloud.selectTag)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Metrics.sourceCardHeight)
                .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
                .onTapGesture {
                    if coordinator.isEditMode { coordinator.isEditMode = false }
                }
            }
        }
    }

}

// 简单的模糊背景视图 (macOS only)
#if os(macOS)
struct BlurView: NSViewRepresentable {

    /// 创建NSView
    /// - Parameter context: context
    /// - Returns: 返回值
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .withinWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }

    /// 更新NSView
    /// - Parameter nsView: nsView
    /// - Parameter context: context
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#else
struct BlurView: View {
    var body: some View {
        Color.clear
    }
}
#endif

// MARK: - 标签气泡微组件

/// 标签气泡视图，负责展示单个标签字词及其词频，支持编辑选中和单选行为
private struct TagCapsuleView: View {
    /// 标签及总数的元组
    let item: (tag: String, count: Int)
    
    /// 绑定的协调器
    @Bindable var coordinator: TagCloudCoordinator
    
    /// 词频插值比例
    var bubbleRatio: Double = 0.0
    
    /// 是否为气泡云显示模式
    var isBubbleMode: Bool = false
    
    // ── 气泡及流式布局视觉参数常量 ──
    private let bubbleModeBaseFontSize: CGFloat = 10.0
    private let bubbleModeFontSizeDelta: CGFloat = 4.0
    private let listModeFontSize: CGFloat = 13.0
    
    private let bubbleModeBasePaddingH: CGFloat = 8.0
    private let bubbleModePaddingHDelta: CGFloat = 4.0
    private let listModePaddingH: CGFloat = 12.0
    
    private let bubbleModeBasePaddingV: CGFloat = 4.0
    private let bubbleModePaddingVDelta: CGFloat = 2.0
    private let listModePaddingV: CGFloat = 6.0
    
    private let bubbleModeMinOpacity = 0.08
    private let bubbleModeOpacityRange = 0.35
    
    private let bubbleModeBaseSize: CGFloat = 42.0
    private let bubbleModeSizeDelta: CGFloat = 32.0
    
    // ── 透明度和边框微调参数常量 (杜绝 magic_number) ──
    private let textBackgroundSelectedOpacity = 0.2
    private let textBackgroundUnselectedOpacity = 0.15
    private let bubbleSelectedFillOpacity = 0.85
    private let bubbleUnselectedFillOpacityBase = 0.1
    private let bubbleUnselectedFillOpacityFactor = 0.5
    private let bubbleBorderOpacityBase = 0.25
    private let bubbleBorderOpacityFactor = 0.15
    
    // ── 气泡云列表滚动弹性缩放形变参数常量 ──
    /// 气泡形变计算的屏幕中心点最大偏移影响距离
    private let listScrollMaxDistance: CGFloat = 280.0
    /// 气泡在屏幕中心时的最大缩放系数
    private let listScrollMaxScale: CGFloat = 1.12
    /// 气泡由于偏移中心导致的缩放衰减范围
    private let listScrollScaleRange: CGFloat = 0.52
    /// 气泡在屏幕中心时的最大不透明度
    private let listScrollMaxOpacity: CGFloat = 1.0
    /// 气泡由于偏移中心导致的不透明度衰减范围
    private let listScrollOpacityRange: CGFloat = 0.55
    
    // ── 计算属性 ──
    private var isSelected: Bool {
        coordinator.isEditMode ? coordinator.selectedTagsForBulk.contains(item.tag) : coordinator.selectedTag == item.tag
    }
    
    private var fontSize: CGFloat {
        isBubbleMode ? bubbleModeBaseFontSize + CGFloat(bubbleRatio * bubbleModeFontSizeDelta) : listModeFontSize
    }
    
    private var paddingH: CGFloat {
        isBubbleMode ? bubbleModeBasePaddingH + CGFloat(bubbleRatio * bubbleModePaddingHDelta) : listModePaddingH
    }
    
    private var paddingV: CGFloat {
        isBubbleMode ? bubbleModeBasePaddingV + CGFloat(bubbleRatio * bubbleModePaddingVDelta) : listModePaddingV
    }
    
    private var opacity: Double {
        isBubbleMode ? bubbleModeMinOpacity + bubbleRatio * bubbleModeOpacityRange : DesignSystem.translucentOpacity
    }
    
    private var size: CGFloat {
        bubbleModeBaseSize + CGFloat(bubbleRatio * bubbleModeSizeDelta)
    }
    
    private var countTextBg: Color {
        let selectedTextBg = Color.theme.white.opacity(textBackgroundSelectedOpacity)
        let unselectedTextBg = Color.appSecondary.opacity(textBackgroundUnselectedOpacity)
        return isSelected ? selectedTextBg : unselectedTextBg
    }
    
    // ── 主视图主体 ──
    var body: some View {
        if isBubbleMode {
            bubbleModeView
        } else {
            listModeView
        }
    }
    
    // ── 气泡模式子视图 ──
    /// 气泡模式子视图，利用几何读取器（GeometryReader）根据视口位置动态计算缩放与透明度，实现 3D 浮动气泡效果
    @ViewBuilder
    private var bubbleModeView: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let screenHeight: CGFloat = {
                #if os(macOS)
                return NSScreen.main?.frame.height ?? 800
                #else
                return UIScreen.main.bounds.height
                #endif
            }()
            // 计算屏幕中心 Y 轴坐标
            let centerY = screenHeight / 2.0
            // 计算当前气泡中心与屏幕中心的绝对 Y 轴距离
            let distance = abs(frame.midY - centerY)
            // 计算归一化的偏移比例（0.0 到 1.0 之间）
            let pct = max(0, min(1, distance / listScrollMaxDistance))
            
            // 根据与屏幕中心的距离动态计算气泡的缩放系数与透明度，使越接近中心的气泡越突出
            let scale = listScrollMaxScale - (pct * listScrollScaleRange)
            let fOpacity = listScrollMaxOpacity - (pct * listScrollOpacityRange)
            
            buttonContent(isSelected: isSelected)
                .scaleEffect(scale)
                .opacity(fOpacity)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75, blendDuration: 0), value: scale)
        }
        .fixedSize()
    }
    
    // ── 列表模式子视图 ──
    /// 列表模式下的标签按钮视图
    @ViewBuilder
    private var listModeView: some View {
        buttonContent(isSelected: isSelected)
    }
    
    // ── 共享 Button 结构 ──
    @ViewBuilder
    private func buttonContent(isSelected: Bool) -> some View {
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
            labelContent(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .appAccent : .appText)
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
    
    // ── 共享 Label 内部渲染 ──
    @ViewBuilder
    private func labelContent(isSelected: Bool) -> some View {
        if isBubbleMode {
            VStack(spacing: DesignSystem.tiny) {
                Text(item.tag.replacingOccurrences(of: "#", with: ""))
                    .font(.system(size: fontSize, design: .rounded).weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                
                Text("\(item.count)")
                    .font(.system(size: fontSize * 0.8, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 0.5)
                    .background(countTextBg)
                    .clipShape(Capsule())
            }
            .padding(bubbleRatio > 0.5 ? DesignSystem.medium : DesignSystem.small)
            .frame(minWidth: size * 0.7)
            .background {
                Circle()
                    .fill(isSelected ? Color.appAccent.opacity(bubbleSelectedFillOpacity) : Color.appAccent.opacity(bubbleUnselectedFillOpacityBase + bubbleRatio * bubbleUnselectedFillOpacityFactor))
            }
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.appAccent : Color.appBorder.opacity(bubbleBorderOpacityBase + bubbleRatio * bubbleBorderOpacityFactor), lineWidth: DesignSystem.borderWidth)
            }
            .scaleEffect(isSelected ? DesignSystem.Gallery.hoverScale : 1.0)
            .shadow(color: isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8) : Color.appAccent.opacity(bubbleRatio * 0.08), radius: bubbleRatio > 0.5 ? DesignSystem.shadowRadius : 2, y: bubbleRatio > 0.5 ? DesignSystem.shadowY : 1)
            .overlay(alignment: .topTrailing) {
                if coordinator.isEditMode {
                    editBadgeView(isSelected: isSelected)
                }
            }
        } else {
            HStack(spacing: DesignSystem.Layout.listRowSpacing) {
                Text(item.tag.replacingOccurrences(of: "#", with: ""))
                    .font(.system(size: fontSize, design: .rounded).weight(isSelected ? .semibold : .regular))
                
                Text("\(item.count)")
                    .font(.system(size: DesignSystem.microFontSize, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity) : Color.appSecondary.opacity(DesignSystem.glassOpacity * 0.5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .background {
                Capsule()
                    .fill(isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity) : Color.appCard.opacity(opacity))
            }
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.appAccent.opacity(DesignSystem.surfaceOpacity) : Color.appBorder.opacity(DesignSystem.translucentOpacity), lineWidth: DesignSystem.borderWidth * 1.5)
            }
            .scaleEffect(isSelected ? DesignSystem.Gallery.hoverScale : 1.0)
            .shadow(color: isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8) : Color.appAccent.opacity(bubbleRatio * 0.08), radius: bubbleRatio > 0.5 ? DesignSystem.shadowRadius : 2, y: bubbleRatio > 0.5 ? DesignSystem.shadowY : 1)
            .overlay(alignment: .topTrailing) {
                if coordinator.isEditMode {
                    editBadgeView(isSelected: isSelected)
                }
            }
        }
    }
    
    // ── 编辑角标 ──
    @ViewBuilder
    private func editBadgeView(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.appAccent : Color.appCard)
                .frame(width: DesignSystem.headlineFontSize, height: DesignSystem.headlineFontSize)
            
            if isSelected {
                Image(systemName: DesignSystem.Icons.check)
                    .font(.system(size: DesignSystem.microFontSize, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth)
                    .frame(width: DesignSystem.headlineFontSize, height: DesignSystem.headlineFontSize)
            }
        }
        .offset(
            x: isBubbleMode ? -DesignSystem.small : DesignSystem.small,
            y: isBubbleMode ? DesignSystem.small : -DesignSystem.small
        )
    }
}

// MARK: - View 扩展
extension View {
    /// 智适应 Label 样式转换器，支持在不同屏幕状态下在图文和纯图标间弹性切换，避开三元运算符类型匹配限制
    @ViewBuilder
    func adaptiveLabelStyle(isExpanded: Bool) -> some View {
        if isExpanded {
            self.labelStyle(.titleAndIcon)
        } else {
            self.labelStyle(.iconOnly)
        }
    }
}
