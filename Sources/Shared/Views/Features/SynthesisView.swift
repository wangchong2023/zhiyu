// SynthesisView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的“知识合成”功能（SynthesisView），利用 LLM 能力将零散的知识点转化为结构化的高级产出。
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，规范化 UI 常量与物理常数
//   - 2026-05-06: 架构重构，提取子组件到 Views/Components/Synthesis/
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 合成视图入口
/// 知识合成功能主视图
/// 负责利用 LLM 将分散知识转化为思维导图、测验、报告等高级结构化产出，并管理生成文档的生命周期
struct SynthesisView: View {
    @Binding var selection: SidebarSelection?
    @Binding var selectedTab: AppTab
    @Environment(AppStore.self) var store
    @Environment(AppRouter.self) var router
    @Environment(SynthesisStore.self) var synthesisStore
    @ObservedObject var taskCenter = TaskCenter.shared
    @State private var showOutput = false
    @State private var outputType: SynthesisStore.SynthesisType = .mindmap
    @State private var selectedDoc: SynthesisStore.SynthesisDocument?
    @State private var pdfURL: IdentifiableURL?

    @State private var exportError: String?
    @State private var showExportError = false
    @State private var docToRename: SynthesisStore.SynthesisDocument?
    @State private var newDocName = ""
    @State private var docToDelete: SynthesisStore.SynthesisDocument?
    @State private var showDeleteDocConfirm = false
    @State private var showRenameDialog = false
    
    @State private var editMode: EditMode = .inactive
    @State private var selectedDocIDs = Set<UUID>()
    @State private var showLimitAlert = false
    @State private var showNoPagesAlert = false
    @State private var expandedSynthesisSections: Set<SynthesisStore.SynthesisType> = Set(SynthesisStore.SynthesisType.allCases)
    @State private var showClearAllConfirm = false
    @State private var showBatchDeleteConfirm = false
    @State private var showLLMAlert = false
    @State private var selectedFilterType: SynthesisStore.SynthesisType? = nil

    var body: some View {
        @Bindable var synthesisStore = synthesisStore
        let runningTasks = taskCenter.tasks.filter { task in
            guard task.type == .synthesis else { return false }
            if case .running = task.status { return true }
            return false
        }
        
        return ScrollView {
            VStack(spacing: AppUI.loosePadding) {
                // 1. 合成操作入口
                synthesisEntryView
                
                // 2. 正在运行的任务
                if !runningTasks.isEmpty {
                    runningTasksSection(tasks: runningTasks)
                }
                
                // 3. 文档列表区域
                documentListArea
            }
            .padding(.horizontal, AppUI.standardPadding)
            .padding(.vertical, AppUI.widePadding)
            .alert(L10n.Synthesis.tr("error.noPages"), isPresented: $showNoPagesAlert) {
                Button(L10n.Common.tr("ok"), role: .cancel) { }
            }
            .alert(L10n.Synthesis.tr("error.limitReached"), isPresented: $showLimitAlert) {
                Button(L10n.Common.tr("done"), role: .cancel) { }
            }
            .alert(Localized.tr("tag.rename"), isPresented: $showRenameDialog) {
                 TextField(Localized.tr("tags.inputName"), text: $newDocName)
                 Button(Localized.tr("tag.rename")) {
                     if let doc = docToRename {
                         synthesisStore.renameSynthesisDoc(type: doc.type, docID: doc.id, newName: newDocName)
                     }
                 }
                 Button(L10n.Common.tr("cancel"), role: .cancel) { }
            }
            .alert(Localized.tr("chat.configureFirst"), isPresented: $showLLMAlert) {
                Button(L10n.Common.tr("confirm"), role: .cancel) { }
            } message: {
                Text(Localized.tr("llm.error.notConfigured"))
            }
            .confirmationDialog(Localized.tr("synthesis.batchDeleteConfirm"), isPresented: $showBatchDeleteConfirm, titleVisibility: .visible) {
                Button(L10n.Common.tr("delete"), role: .destructive) {
                    batchDelete()
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
            }
            .confirmationDialog(L10n.Common.tr("deleteConfirm"), isPresented: $showDeleteDocConfirm, titleVisibility: .visible) {
                Button(L10n.Common.tr("delete"), role: .destructive) {
                    if let doc = docToDelete {
                        synthesisStore.deleteSynthesisDoc(type: doc.type, docID: doc.id)
                        HapticFeedback.shared.trigger(.success)
                    }
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(Localized.tr("sidebar.synthesis"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { backButton }
        }
        .sheet(isPresented: $showOutput) { outputSheet }
        .sheet(item: $pdfURL) { identifiable in
            PDFPreviewWrapper(url: identifiable.url)
        }
    }

    // MARK: - Subviews

    /// 文档列表聚合区域
    private var documentListArea: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            listHeader
            
            // 过滤器药丸栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppUI.Chip.spacing) {
                    FilterPill(
                        title: Localized.tr("search.all"),
                        isSelected: selectedFilterType == nil
                    ) {
                        withAnimation(.spring()) { selectedFilterType = nil }
                    }
                    
                    ForEach(SynthesisStore.SynthesisType.allCases) { type in
                        FilterPill(
                            title: type.title,
                            icon: type.icon,
                            color: type.formatColor,
                            isSelected: selectedFilterType == type
                        ) {
                            withAnimation(.spring()) { selectedFilterType = type }
                        }
                    }
                }
                .padding(.vertical, AppUI.tiny)
            }
            
            VStack(spacing: 0) {
                let typesToShow = selectedFilterType == nil ? SynthesisStore.SynthesisType.allCases : [selectedFilterType!]
                let filteredDocs = typesToShow.flatMap { type in
                    (synthesisStore.synthesisResults[type] ?? []).map { (type, $0) }
                }.sorted { $0.1.createdAt > $1.1.createdAt }
                
                if filteredDocs.isEmpty {
                    VStack(spacing: AppUI.medium) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: AppUI.Timeline.emptyIconSize))
                            .foregroundStyle(.appSecondary.opacity(AppUI.Metrics.emptyStateIconOpacity)) // 0.15
                        Text(Localized.tr("synthesis.noDocs"))
                            .font(.subheadline)
                            .foregroundStyle(.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppUI.Metrics.emptyStateVerticalPadding) // 24
                } else {
                    ForEach(filteredDocs, id: \.1.id) { type, doc in
                        SynthesisDocRow(
                            doc: doc,
                            type: type,
                            editMode: editMode,
                            isSelected: selectedDocIDs.contains(doc.id),
                            onTap: {
                                if editMode == .active {
                                    if selectedDocIDs.contains(doc.id) {
                                        selectedDocIDs.remove(doc.id)
                                    } else {
                                        selectedDocIDs.insert(doc.id)
                                    }
                                } else {
                                    selectedDoc = doc
                                    showOutput = true
                                }
                            },
                            onRename: {
                                docToRename = doc
                                newDocName = doc.name
                                showRenameDialog = true
                            },
                            onDelete: {
                                docToDelete = doc
                                showDeleteDocConfirm = true
                            }
                        )
                        
                        if doc.id != filteredDocs.last?.1.id {
                            Divider().padding(.leading, AppUI.Sidebar.iconBoxSize + AppUI.medium) 
                        }
                    }
                }
            }
            .appContainer(background: AnyView(Rectangle().fill(AppUI.containerMaterial)))
        }
    }
    
    private var listHeader: some View {
        HStack {
            Text(L10n.Synthesis.tr("documentList")).font(.title3.bold())
            Spacer()
            editAndBatchDeleteControls
        }
        .padding(.vertical, AppUI.tightPadding)
        .foregroundStyle(.appText)
        .textCase(nil)
    }

    private var editAndBatchDeleteControls: some View {
        HStack(spacing: AppUI.tightPadding) {
            if editMode == .active {
                HStack(spacing: AppUI.medium) {
                    Button(action: {
                        HapticFeedback.shared.trigger(.warning)
                        showBatchDeleteConfirm = true
                    }) {
                        HStack(spacing: AppUI.tiny) {
                            Image(systemName: "trash")
                            Text(L10n.Common.tr("delete"))
                        }
                        .font(.footnote.bold())
                        .foregroundStyle(selectedDocIDs.isEmpty ? .appSecondary.opacity(AppUI.disabledOpacity) : .white)
                        .padding(.horizontal, AppUI.Chip.horizontalPadding)
                        .padding(.vertical, AppUI.smallRadius)
                        .background(
                            Capsule().fill(selectedDocIDs.isEmpty ? Color.clear : Color.red)
                        )
                        .overlay(
                            Capsule().stroke(selectedDocIDs.isEmpty ? Color.appBorder : Color.red, lineWidth: AppUI.borderWidth)
                        )
                    }
                    .disabled(selectedDocIDs.isEmpty)
                    
                    Button(action: {
                        HapticFeedback.shared.trigger(.warning)
                        showClearAllConfirm = true
                    }) {
                        HStack(spacing: AppUI.tiny) {
                            Image(systemName: "trash.slash")
                            Text(L10n.Common.tr("clearAll"))
                        }
                        .font(.footnote.bold())
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, AppUI.medium)
                        .padding(.vertical, AppUI.smallRadius)
                        .background(
                            Capsule().stroke(Color.appBorder, lineWidth: AppUI.borderWidth)
                        )
                    }
                    .confirmationDialog(Localized.tr("synthesis.clearAllConfirm"), isPresented: $showClearAllConfirm, titleVisibility: .visible) {
                        Button(L10n.Common.tr("clearAll"), role: .destructive) {
                            synthesisStore.clearAll()
                            HapticFeedback.shared.trigger(.success)
                        }
                        Button(L10n.Common.tr("cancel"), role: .cancel) { }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                withAnimation(AppUI.standardAnimation) {
                    if editMode == .inactive {
                        editMode = .active
                    } else {
                        editMode = .inactive
                        selectedDocIDs.removeAll()
                    }
                }
            }) {
                Text(editMode == .active ? L10n.Common.tr("done") : L10n.Common.tr("edit"))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var backButton: some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            if selection != nil {
                withAnimation(AppUI.standardAnimation) { selection = nil }
            } else {
                router.pop()
            }
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: AppUI.iconSmall, weight: .bold))
                .foregroundStyle(.appText)
                .frame(width: AppUI.Action.backButtonWidth, height: AppUI.inputBarHeight)
        }
    }
    
    private func batchDelete() {
        HapticFeedback.shared.trigger(.warning)
        synthesisStore.batchDeleteSynthesisDocs(ids: selectedDocIDs)
        selectedDocIDs.removeAll()
        editMode = .inactive
        HapticFeedback.shared.trigger(.success)
    }
    
    @ViewBuilder
    private var outputSheet: some View {
        NavigationStack {
            Group {
                if let doc = selectedDoc {
                    switch doc.type {
                    case .mindmap, .infographic:
                        VStack(spacing: AppUI.standardPadding) {
                            if let title = extractTitle(from: doc.content) {
                                Text(title)
                                    .font(.title2.bold())
                                    .padding(.top, AppUI.widePadding)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            MermaidWebView(mermaidCode: extractMermaidCode(from: doc.content))
                                .id(doc.id)
                        }
                    case .quiz:
                        if let data = doc.content.data(using: .utf8),
                           let quiz = try? JSONDecoder().decode(QuizModel.self, from: data) {
                            QuizView(quiz: quiz)
                        } else {
                            fallbackView(doc: doc)
                        }
                    default:
                        fallbackView(doc: doc)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.tr("done")) { showOutput = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppUI.headlineFontSize) {
                        Button {
                            if let doc = selectedDoc {
                                #if os(iOS)
                                UIPasteboard.general.string = doc.content
                                #endif
                                HapticFeedback.shared.trigger(.success)
                            }
                        } label: { Image(systemName: "doc.on.doc") }

                        Button { exportAction() } label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fallbackView(doc: SynthesisStore.SynthesisDocument) -> some View {
        ScrollView {
            MarkdownRendererView(content: doc.content, isPrivate: false, onLinkTap: { _ in })
                .padding()
        }
    }

    private func exportAction() {
        guard let doc = selectedDoc else { return }
        Task {
            do {
                let url = try await synthesisStore.exportSynthesisDocument(doc)
                await MainActor.run { 
                    self.pdfURL = IdentifiableURL(url: url)
                    HapticFeedback.shared.trigger(.success) 
                }
            } catch {
                await MainActor.run { 
                    self.exportError = error.localizedDescription
                    self.showExportError = true 
                }
            }
        }
    }

    /// 正在运行的任务区域
    @ViewBuilder
    private func runningTasksSection(tasks: [GlobalTask]) -> some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            Text(L10n.AI.Task.tr("status.running"))
                .font(.title3.bold())
                .foregroundStyle(.appAccent)
                .padding(.horizontal, AppUI.tiny)
            
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    synthesisTaskRow(task: task)
                        .padding()
                    if task.id != tasks.last?.id {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(AppUI.containerMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.cardRadius)
                    .stroke(AppUI.containerBorder.opacity(AppUI.dimmedOpacity), lineWidth: AppUI.borderWidth / 2)
            )
            .shadow(color: Color.black.opacity(AppUI.shadowOpacity * 0.3), radius: AppUI.small, y: AppUI.tiny) // 0.03
        }
    }

    /// 渲染任务状态行
    private func synthesisTaskRow(task: GlobalTask) -> some View {
        HStack(spacing: AppUI.standardPadding) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(AppUI.glassOpacity / 1.5)).frame(width: AppUI.Graph.selectedNodeSize, height: AppUI.Graph.selectedNodeSize)
                ProgressView()
            }
            VStack(alignment: .leading, spacing: AppUI.small) {
                Text(task.name).font(.subheadline.weight(.semibold))
                if case .running(let progress) = task.status {
                    ProgressView(value: progress).tint(.appAccent)
                }
            }
        }
    }

    /// 合成操作入口视图
    private var synthesisEntryView: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            AppSectionHeader(title: L10n.Synthesis.tr("actions"), icon: "wand.and.stars")
                .padding(.horizontal, AppUI.tiny)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppUI.medium) {
                ForEach(SynthesisStore.SynthesisType.allCases) { type in
                    SynthesisActionButton(type: type, 
                                         store: store, 
                                         showNoPagesAlert: $showNoPagesAlert, 
                                         showLimitAlert: $showLimitAlert,
                                         showLLMAlert: $showLLMAlert)
                }
            }
            .appContainer(padding: true)
        }
    }

    // MARK: - Logic Helpers

    private func extractTitle(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        if let firstLine = lines.map({ $0.trimmingCharacters(in: .whitespaces) }).first(where: { !$0.isEmpty }),
           firstLine.hasPrefix("# ") {
            return firstLine.replacingOccurrences(of: "# ", with: "")
        }
        return nil
    }

    private func extractMermaidCode(from content: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "```(?:mermaid)?\\n([\\s\\S]*?)```", options: []),
           let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let lines = content.components(separatedBy: .newlines)
        return lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.hasPrefix("#") && !trimmed.hasPrefix("```") && !trimmed.isEmpty
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
