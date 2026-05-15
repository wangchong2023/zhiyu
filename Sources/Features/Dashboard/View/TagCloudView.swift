// TagCloudView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的标签管理中心（TagCloudView）。
// 它作为全局标签的聚合展示与维护入口，具备以下核心能力：
// 1. 动态标签云：通过 FlowLayout 自动排列标签，并根据页面引用热度实时更新实时计数。
// 2. 增强型 CRUD 交互：支持标签的新增、重命名、单项删除及基于多选模式的批量删除。
// 3. 关联检索：点击标签可实时筛选并展示关联的 知识库 页面，形成“标签 -> 内容”快速导航。
// 4. 视觉规范对齐：严格遵循系统的模块化 UI 语言，确保边框宽度与卡片间距在全平台一致。
// 版本: 1.3
// 修改记录:
//   - 2026-05-05: 修复标签云容器宽度未撑满导致边框与下方列表不齐的问题
//   - 2026-05-05: 完善详细中文文档注释，规范函数头
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

#if os(macOS)
import AppKit
#endif

// MARK: - 标签云视图 (导航容器)
/// 标签管理的顶层视图容器，负责承载主内容
struct TagCloudView: View {
    /// 初始选中的标签（由外部跳转传入）
    var initialTag: String? = nil
    
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
            // 重命名对话框
            .alert(Localized.tr("tag.renameTag"), isPresented: Binding(
                get: { coordinator.tagToRename != nil },
                set: { if !$0 { coordinator.tagToRename = nil } }
            )) {
                TextField(Localized.tr("tag.newName"), text: $coordinator.newTagName)
                Button(L10n.Common.tr("cancel"), role: .cancel) { coordinator.tagToRename = nil }
                Button(L10n.Common.tr("ok")) {
                    coordinator.performRename()
                }
            } message: {
                Text(Localized.trf("tag.renameMessage", coordinator.tagToRename ?? ""))
            }
            // 删除确认对话框
            .confirmationDialog(
                coordinator.tagToDelete.map { Localized.trf("tag.deleteMessage", $0) } ?? Localized.tr("tag.deleteTag"),
                isPresented: $coordinator.showDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.tr("delete"), role: .destructive) {
                    coordinator.performDelete()
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) { coordinator.tagToDelete = nil }
            } message: {
                Text(Localized.tr("settings.clearAll.message"))
            }
            // 新增标签对话框
            .alert(Localized.tr("tags.addNew"), isPresented: $coordinator.showAddTagDialog) {
                TextField(Localized.tr("tags.inputName"), text: $coordinator.addTagName)
                Button(L10n.Common.tr("cancel"), role: .cancel) { coordinator.addTagName = "" }
                Button(L10n.Common.tr("create")) {
                    coordinator.performAddTag()
                }
            } message: {
                Text(Localized.tr("tags.createHint"))
            }
            // 批量删除确认
            .confirmationDialog(
                Localized.trf("tags.bulkDeleteWarning", coordinator.selectedTagsForBulk.count),
                isPresented: $showBulkDeleteConfirm,
                titleVisibility: .automatic
            ) {
                Button(L10n.Common.tr("deleteAll"), role: .destructive) {
                    coordinator.performBulkDelete()
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
            } message: {
                Text(Localized.tr("settings.clearAll.message"))
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
                        Label(Localized.tr("tags.addNew"), systemImage: "plus.circle")
                            .font(.subheadline.bold())
                    }
                }
                
                Button(action: {
                    coordinator.isEditMode.toggle()
                    if !coordinator.isEditMode { coordinator.selectedTagsForBulk.removeAll() }
                }) {
                    Label(coordinator.isEditMode ? L10n.Common.tr("done") : Localized.tr("tags.manageTitle"), 
                          systemImage: coordinator.isEditMode ? "checkmark.circle" : "checklist")
                        .font(.subheadline.bold())
                        .foregroundStyle(coordinator.isEditMode ? .green : .appAccent)
                }
            }
            .padding(.horizontal, DesignSystem.wide)
            .padding(.vertical, DesignSystem.Layout.headerVerticalPadding)

            // 2. 标签云展示区（带标准边框的卡片）
            if coordinator.tags.isEmpty {
                emptyTagsView
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    AppSectionHeader(
                        title: L10n.Tag.allTags,
                        icon: "tag.fill",
                        iconColor: .appAccent
                    )
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
                        icon: "doc.on.doc.fill",
                        iconColor: .appSource
                    )
                    Spacer()
                    if let _ = coordinator.selectedTag, !coordinator.isEditMode {
                        Text(Localized.trf("tag.tagPages", coordinator.filteredPages.count))
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
            Text(Localized.trf("tags.selectedCount", coordinator.selectedTagsForBulk.count))
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
            Button(role: .destructive, action: { showBulkDeleteConfirm = true }) {
                Text(L10n.Common.tr("bulkDelete"))
                    .padding(.horizontal, DesignSystem.large)
                    .padding(.vertical, DesignSystem.small - DesignSystem.atomic) // 6
                    .background(Color.red)
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
            Image(systemName: "tag")
                .font(.system(size: DesignSystem.iconHuge))
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("tag.noTags"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("tag.noTagsHint"))
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
        let isSelected = coordinator.isEditMode ? coordinator.selectedTagsForBulk.contains(item.tag) : coordinator.selectedTag == item.tag
        
        return Button(action: {
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
                            Image(systemName: "checkmark")
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
                    Label(Localized.tr("tag.rename"), systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                    coordinator.tagToDelete = item.tag
                    coordinator.showDeleteConfirm = true
                }) {
                    Label(Localized.tr("tag.delete"), systemImage: "trash")
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
                            NavigationLink(destination: PageDetailView(page: page)) {
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
                    Image(systemName: coordinator.isEditMode ? "checklist" : "tag")
                        .font(.system(size: DesignSystem.iconHuge))
                        .foregroundStyle(.appSecondary.opacity(DesignSystem.translucentOpacity))
                    Text(coordinator.isEditMode ? Localized.tr("tags.selectToManage") : Localized.tr("tagcloud.selectTag"))
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
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .withinWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#else
struct BlurView: View {
    var body: some View {
        Color.clear
    }
}
#endif


