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
    
    // 使用协调器管理状态与交互
    @State private var coordinator: TagCloudCoordinator
    @State private var showBulkDeleteConfirm = false

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
        VStack(spacing: 0) {
            // 1. 顶部操作栏
            HStack(spacing: DesignSystem.wide) {
                Spacer()
                if !coordinator.isEditMode {
                    Button(action: { coordinator.showAddTagDialog = true }) {
                        Label(L10n.Tag.Management.addNew, systemImage: DesignSystem.Icons.plusCircle)
                            .font(.subheadline.bold())
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
                }
            }
            .padding(.horizontal, DesignSystem.wide)
            .padding(.vertical, DesignSystem.Layout.headerVerticalPadding)

            // 2. 搜索栏（标签数 > 30 时显示）
            if coordinator.tags.count > TagCloudCoordinator.searchThreshold {
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

    private var tagScrollView: some View {
        ScrollView {
            FlowLayout(spacing: DesignSystem.Grid.flowSpacing) {
                ForEach(coordinator.filteredTags, id: \.tag) { tagItem in
                    tagCapsule(tagItem)
                }
            }
            .padding(DesignSystem.medium)
        }
        .frame(maxHeight: DesignSystem.Metrics.maxTagCloudHeight) // 300
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tagCapsule(_ item: (tag: String, count: Int)) -> some View {
        TagCapsuleView(item: item, coordinator: coordinator)
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
    
    var body: some View {
        let isSelected = coordinator.isEditMode ? coordinator.selectedTagsForBulk.contains(item.tag) : coordinator.selectedTag == item.tag
        
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
            HStack(spacing: DesignSystem.Layout.listRowSpacing) {
                Text(item.tag.replacingOccurrences(of: "#", with: ""))
                    .font(.system(.subheadline, design: .rounded).weight(isSelected ? .semibold : .regular))
                
                Text("\(item.count)")
                    .font(.system(size: DesignSystem.microFontSize, weight: .bold, design: .monospaced))
                    .padding(.horizontal, DesignSystem.small)
                    .padding(.vertical, DesignSystem.atomic)
                    .background(isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity) : Color.appSecondary.opacity(DesignSystem.glassOpacity * 0.5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DesignSystem.large)
            .padding(.vertical, DesignSystem.small)
            .background(
                Capsule()
                    .fill(isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity) : Color.appCard.opacity(DesignSystem.translucentOpacity))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.appAccent.opacity(DesignSystem.surfaceOpacity) : Color.appBorder.opacity(DesignSystem.translucentOpacity), lineWidth: DesignSystem.borderWidth * 1.5)
            )
            .scaleEffect(isSelected ? DesignSystem.Gallery.hoverScale : 1.0)
            .shadow(color: isSelected ? Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8) : Color.clear, radius: DesignSystem.shadowRadius, y: DesignSystem.shadowY)
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
                    .offset(x: DesignSystem.small, y: -DesignSystem.small)
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
    }
}
