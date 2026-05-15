// NotebookHubView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本工作台 (Notebook Hub) 的主视图。
// 采用 2 列卡片式布局展现所有笔记本，提供沉浸式的笔记本管理体验。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
/// 笔记本工作台视图
public struct NotebookHubView: View {
    // MARK: - 状态与环境
    
    @State private var viewModel = NotebookHubViewModel()
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Inject var appEnv: any AppEnvironmentProtocol // 注入环境能力
    
    // MARK: - 初始化
    
    public init() {}
    
    // MARK: - 视图主体
    
    public var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack(alignment: .top) {
            // 统一背景系统：自动适配深浅模式与强调色
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                    // 1. 现代风格搜索区域
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.appAccent)
                        
                        TextField(L10n.Common.tr("search"), text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                        
                        if !viewModel.searchText.isEmpty {
                            Button { viewModel.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.appSecondary.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.standardPadding)
                    .padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic)
                    .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.appAccent.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
                    )
                    .padding(.horizontal, DesignSystem.Vault.homePadding)
                    .padding(.top, DesignSystem.medium)
                    
                    AIProcessingStatusBanner()
                        .padding(.horizontal, DesignSystem.Vault.homePadding)

                    notebookGridSection
                }
                .padding(.bottom, DesignSystem.huge)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(L10n.Vault.tr("homeTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticFeedback.shared.trigger(.selection)
                    router.navigate(to: .lint)
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.appAccent)
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DesignSystem.medium) {
                    #if !os(watchOS)
                    sortMenu
                    #endif
                    displayModeButton
                    UserProfileMenu()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("toggleDisplayMode"))) { _ in
            viewModel.toggleDisplayMode()
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CreateNotebookSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            EditNotebookSheet(viewModel: viewModel)
        }
        .alert(L10n.Vault.tr("rename"), isPresented: $viewModel.isShowingRenameAlert) {
            TextField(L10n.Vault.tr("namePlaceholder"), text: $viewModel.editingName)
            Button(L10n.Common.tr("cancel"), role: .cancel) { }
            Button(L10n.Common.tr("ok")) {
                viewModel.confirmRename()
            }
        } message: {
            Text(L10n.Vault.tr("renameMessage"))
        }
        .environment(viewModel)
    }
    
    // MARK: - 子视图组件
    
    private var notebookGridSection: some View {
        Group {
            if viewModel.displayMode == .grid {
                let columns = appEnv.screenClass == .expansive 
                    ? [GridItem(.adaptive(minimum: 250), spacing: DesignSystem.standardPadding)]
                    : [GridItem(.flexible(), spacing: DesignSystem.standardPadding), GridItem(.flexible(), spacing: DesignSystem.standardPadding)]
                
                LazyVGrid(columns: columns, spacing: DesignSystem.standardPadding) {
                    createNotebookCard
                    
                    ForEach(viewModel.notebooks) { notebook in
                        NotebookCard(notebook: notebook) {
                            viewModel.selectNotebook(notebook)
                        }
                    }
                }
            } else {
                VStack(spacing: DesignSystem.medium) {
                    createNotebookListRow
                    
                    ForEach(viewModel.notebooks) { notebook in
                        NotebookListRow(notebook: notebook) {
                            viewModel.selectNotebook(notebook)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
    
    private var createNotebookListRow: some View {
        Button(action: { viewModel.isShowingCreateSheet = true }) {
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: DesignSystem.titleFontSize))
                    .foregroundStyle(.appAccent)
                
                Text(L10n.Vault.tr("new"))
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                    .foregroundStyle(.appText)
                
                Spacer()
            }
            .padding(DesignSystem.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.borderWidth, dash: [4]))
                    .foregroundStyle(.appAccent.opacity(DesignSystem.secondaryOpacity))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var createNotebookCard: some View {
        Button(action: { viewModel.isShowingCreateSheet = true }) {
            VStack(spacing: DesignSystem.medium) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.appAccent)
                }
                
                Text(L10n.Vault.tr("new"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.appText)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color.appCard.opacity(DesignSystem.subtleFillOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.appAccent.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var brandLogo: some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(LinearGradient(colors: [.appAccent, .appSource], startPoint: .top, endPoint: .bottom))
            Text(L10n.Vault.tr("appName"))
                .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                .foregroundStyle(.appText)
        }
    }
    
    private var displayModeButton: some View {
        Button(action: { viewModel.toggleDisplayMode() }) {
            Image(systemName: viewModel.displayMode.icon)
                .font(.system(size: DesignSystem.bodyFontSize))
                .foregroundStyle(.appSecondary)
        }
        .buttonStyle(.plain)  // 消除 Toolbar 中 Button 的 bordered 白色背景
    }
    
    @ViewBuilder
    private var sortMenu: some View {
        #if os(watchOS)
        EmptyView()
        #else
        Menu {
            Button {
                viewModel.sortOption = .date
            } label: {
                Label(L10n.Vault.tr("sort.date"), systemImage: "calendar")
            }
            
            Button {
                viewModel.sortOption = .name
            } label: {
                Label(L10n.Vault.tr("sort.name"), systemImage: "abc")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: DesignSystem.bodyFontSize))
                .foregroundStyle(.appSecondary)
        }
        .buttonStyle(.plain)  // 消除 Toolbar 中 Menu 的 bordered 白色背景
        #endif
    }
}

// MARK: - 辅助组件

struct NotebookCard: View {
    @Environment(NotebookHubViewModel.self) var viewModel
    let notebook: Vault
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
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                // 1. 图标展示 (彩色光晕底座)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorForVault.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.system(size: 22))
                }
                .padding(.top, DesignSystem.tiny) // 增加顶部呼吸空间
                
                // 2. 标题
                Text(notebook.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 3. 摘要描述
                Text(notebook.description ?? L10n.Vault.tr("defaultDescription"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: DesignSystem.small)
                
                // 4. 元数据 (国际化相对时间)
                Text("\(L10n.Vault.tr("lastEdited")) \(notebook.updatedAt.formatted(.relative(presentation: .numeric)))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.04), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
            .contextMenu {
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.tr("edit"), systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.tr("delete"), systemImage: "trash")
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var colorForVault: Color {
        // 对齐图 3 的柔和底座逻辑
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        let index = abs(notebook.name.hashValue) % colors.count
        return colors[index]
    }
    
    private var defaultIcon: String {
        let icons = ["📓", "📚", "💡", "🧠", "✍️", "🚀", "🎨", "📁", "🌟", "🛠️"]
        let index = abs(notebook.id.hashValue) % icons.count
        return icons[index]
    }
}

// MARK: - 列表行组件

struct NotebookListRow: View {
    @Environment(NotebookHubViewModel.self) var viewModel
    let notebook: Vault
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Sidebar.rowSpacing) {
                // 1. 系统风格图标框 (对齐 KnowledgePageRow)
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                        .fill(Color.appAccent.opacity(DesignSystem.glassOpacity))
                        .frame(width: DesignSystem.Sidebar.iconBoxSize, height: DesignSystem.Sidebar.iconBoxSize)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.system(size: 20))
                }
                
                // 2. 文本信息流
                VStack(alignment: .leading, spacing: 4) {
                    Text(notebook.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(notebook.pageCount)\(L10n.Vault.tr("page.knowledge"))")
                        Text(DesignSystem.Icons.dotSeparator)
                        Text(notebook.updatedAt.formatted(date: .numeric, time: .omitted))
                    }
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                // 3. 状态与指示器
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.appSecondary.opacity(0.5))
            }
            .padding(.vertical, DesignSystem.tiny)
            .background(Color.clear)
            .contentShape(Rectangle())
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.tr("delete"), systemImage: "trash")
                }
                
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.tr("edit"), systemImage: "pencil")
                }
                .tint(.orange)
            }
            .contextMenu {
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.tr("edit"), systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.tr("delete"), systemImage: "trash")
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var defaultIcon: String {
        let icons = ["📓", "📚", "💡", "🧠", "✍️", "🚀", "🎨", "📁", "🌟", "🛠️"]
        let index = abs(notebook.id.hashValue) % icons.count
        return icons[index]
    }
}

// MARK: - 笔记本表单
@MainActor
struct CreateNotebookSheet: View {
    @Bindable var viewModel: NotebookHubViewModel
    var body: some View {
        NotebookFormSheet(
            title: L10n.Vault.tr("new"),
            submitLabel: L10n.Vault.tr("create"),
            name: $viewModel.newNotebookName,
            icon: $viewModel.newNotebookIcon,
            description: $viewModel.newNotebookDescription,
            onSubmit: { viewModel.createNotebook() }
        )
    }
}

@MainActor
struct EditNotebookSheet: View {
    @Bindable var viewModel: NotebookHubViewModel
    var body: some View {
        NotebookFormSheet(
            title: L10n.Vault.tr("edit"),
            submitLabel: L10n.Common.tr("save"),
            name: $viewModel.editingName,
            icon: $viewModel.editingIcon,
            description: $viewModel.editingDescription,
            onSubmit: { viewModel.confirmEdit() }
        )
    }
}

@MainActor
struct NotebookFormSheet: View {
    let title: String
    let submitLabel: String
    @Binding var name: String
    @Binding var icon: String
    @Binding var description: String
    var onSubmit: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    private let iconOptions = ["📓", "📚", "💡", "🧠", "✍️", "🚀", "🎨", "📁", "🌟", "🛠️", "📅", "🎯", "🔥", "🌈", "🧩"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.huge) {
                        // 1. 图标选择
                        VStack(spacing: DesignSystem.medium) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Text(icon.isEmpty ? "📓" : icon)
                                    .font(.system(size: 60))
                            }
                            
                            Text(L10n.Vault.tr("iconLabel"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.medium) {
                                    ForEach(iconOptions, id: \.self) { item in
                                        Button {
                                            icon = item
                                        } label: {
                                            Text(item)
                                                .font(.title)
                                                .frame(width: 54, height: 54)
                                                .background(icon == item ? Color.appAccent.opacity(0.2) : Color.primary.opacity(0.05))
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(icon == item ? Color.appAccent : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, DesignSystem.huge)
                        
                        // 2. 表单
                        VStack(alignment: .leading, spacing: DesignSystem.medium) {
                            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                                Text(L10n.Vault.tr("nameLabel"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                TextField(L10n.Vault.tr("namePlaceholder"), text: $name)
                                    .font(.title3.bold())
                                    .padding()
                                    .background(Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                                Text(L10n.Vault.tr("descriptionLabel"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                TextField(L10n.Vault.tr("descriptionPlaceholder"), text: $description, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding()
                                    .background(Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.tr("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(submitLabel) {
                        onSubmit()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
