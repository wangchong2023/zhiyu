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
            // 1. 顶部操作栏
            HStack(spacing: isExp ? DesignSystem.wide : DesignSystem.medium) {
                // 视图模式选择 (放在左侧)
                Picker("", selection: $displayMode) {
                    Text(L10n.Tag.layoutList).tag(DisplayMode.list)
                    Text(L10n.Tag.layoutBubble).tag(DisplayMode.bubble)
                }
                .pickerStyle(.segmented)
                .frame(width: DesignSystem.Metrics.customSize140)
                
                Spacer()
                
                // 🔍 搜索切换按钮 (移至右侧)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSearchBar.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.bold())
                        .foregroundStyle(showSearchBar ? .appAccent : .appSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Search.title)
                
                if !coordinator.isEditMode {
                    Button(action: { coordinator.showAddTagDialog = true }) {
                        Label(L10n.Tag.Management.addNew, systemImage: DesignSystem.Icons.plusCircle)
                            .font(.subheadline.bold())
                            .adaptiveLabelStyle(isExpanded: isExp)
                    }
                }
                
                Button(action: {
                    coordinator.isEditMode.toggle()
                    if !coordinator.isEditMode { coordinator.selectedTagsForBulk.removeAll() }
                }) {
                    Label(coordinator.isEditMode ? L10n.Common.done : L10n.Tag.Management.manageTitle, 
                          systemImage: coordinator.isEditMode ? DesignSystem.Icons.checkCircle : DesignSystem.Icons.checklist)
                        .font(.subheadline.bold())
                        .foregroundStyle(coordinator.isEditMode ? .green : .appAccent)
                        .adaptiveLabelStyle(isExpanded: isExp)
                }
            }
            .padding(.horizontal, isExp ? DesignSystem.wide : DesignSystem.medium)
            .padding(.vertical, DesignSystem.Layout.headerVerticalPadding)

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
            ScrollView {
                FlowLayout(spacing: isListMode ? DesignSystem.Grid.flowSpacing : DesignSystem.small) {
                    ForEach(displayedTags, id: \.tag) { tagItem in
                        TagCapsuleView(
                            item: tagItem,
                            coordinator: coordinator,
                            bubbleRatio: bubbleRatio(for: tagItem.count),
                            isBubbleMode: !isListMode
                        )
                    }
                }
                .padding(DesignSystem.medium)
            }
            .frame(maxHeight: isListMode ? (isExpanded ? .infinity : DesignSystem.Metrics.maxTagCloudHeight) : .infinity)
            .fixedSize(horizontal: false, vertical: isListMode)
            .overlay(alignment: .bottom) {
                if shouldCollapse {
                    // swiftlint:disable magic_numbers_opacity magic_numbers_frame
                    LinearGradient(
                        colors: [.clear, Color.appCard.opacity(0.8), Color.appCard],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 35)
                    .allowsHitTesting(false)
                    // swiftlint:enable magic_numbers_opacity magic_numbers_frame
                }
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
    
    // swiftlint:disable magic_numbers_opacity
    var body: some View {
        let isSelected = coordinator.isEditMode ? coordinator.selectedTagsForBulk.contains(item.tag) : coordinator.selectedTag == item.tag
        
        let fontSize: CGFloat = isBubbleMode ? 10.0 + CGFloat(bubbleRatio * 4.0) : 13.0
        let paddingH: CGFloat = isBubbleMode ? 8.0 + CGFloat(bubbleRatio * 4.0) : 12.0
        let paddingV: CGFloat = isBubbleMode ? 4.0 + CGFloat(bubbleRatio * 2.0) : 6.0
        let opacity: Double = isBubbleMode ? 0.08 + bubbleRatio * 0.35 : DesignSystem.translucentOpacity
        let size: CGFloat = 42.0 + CGFloat(bubbleRatio * 32.0)
        
        let buttonContent = Button(action: {
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
            Group {
                if isBubbleMode {
                    VStack(spacing: 2) {
                        Text(item.tag.replacingOccurrences(of: "#", with: ""))
                            .font(.system(size: fontSize, design: .rounded).weight(isSelected ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                        
                        Text("\(item.count)")
                            .font(.system(size: fontSize * 0.8, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 0.5)
                            .background(isSelected ? Color.theme.white.opacity(0.2) : Color.appSecondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(bubbleRatio > 0.5 ? DesignSystem.medium : DesignSystem.small)
                    .frame(minWidth: size * 0.7)
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
                }
            }
            .background {
                if isBubbleMode {
                    Circle()
                        .fill(isSelected ? Color.appAccent.opacity(0.85) : Color.appAccent.opacity(0.1 + bubbleRatio * 0.5))
                } else {
                    Capsule()
                        .fill(isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity) : Color.appCard.opacity(opacity))
                }
            }
            .overlay {
                if isBubbleMode {
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.appBorder.opacity(0.25 + bubbleRatio * 0.15), lineWidth: DesignSystem.borderWidth)
                } else {
                    Capsule()
                        .stroke(isSelected ? Color.appAccent.opacity(DesignSystem.surfaceOpacity) : Color.appBorder.opacity(DesignSystem.translucentOpacity), lineWidth: DesignSystem.borderWidth * 1.5)
                }
            }
            .scaleEffect(isSelected ? DesignSystem.Gallery.hoverScale : 1.0)
            .shadow(color: isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8) : Color.appAccent.opacity(bubbleRatio * 0.08), radius: bubbleRatio > 0.5 ? DesignSystem.shadowRadius : 2, y: bubbleRatio > 0.5 ? DesignSystem.shadowY : 1)
            .overlay(alignment: .topTrailing) {
                if coordinator.isEditMode {
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
        
        Group {
            if isBubbleMode {
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    let screenHeight: CGFloat = {
                        #if os(macOS)
                        return NSScreen.main?.frame.height ?? 800
                        #else
                        return UIScreen.main.bounds.height
                        #endif
                    }()
                    let centerY = screenHeight / 2.0
                    let distance = abs(frame.midY - centerY)
                    let maxDistance: CGFloat = 280.0
                    let pct = max(0, min(1, distance / maxDistance))
                    
                    let scale = 1.12 - (pct * 0.52)
                    let fOpacity = 1.0 - (pct * 0.55)
                    
                    buttonContent
                        .scaleEffect(scale)
                        .opacity(fOpacity)
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75, blendDuration: 0), value: scale)
                }
                .fixedSize()
            } else {
                buttonContent
            }
        }
    }
    // swiftlint:enable magic_numbers_opacity
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
