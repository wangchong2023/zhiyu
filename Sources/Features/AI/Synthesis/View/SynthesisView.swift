//
//  SynthesisView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Synthesis 界面的 UI 视图层组件。
//
import SwiftUI

// MARK: - 合成视图入口
struct SynthesisView: View {
    @Binding var selection: SidebarSelection?
    @Binding var selectedTab: AppTab
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Environment(SynthesisStore.self) var synthesisStore
    @ObservedObject var taskCenter = TaskCenter.shared
    @State private var showOutput = false
    @State private var outputType: SynthesisStore.SynthesisType = .mindmap
    @State private var selectedDoc: SynthesisStore.SynthesisDocument?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var pdfURL: IdentifiableURL?

    @State private var exportError: String?
    @State private var showExportError = false
    @State private var docToRename: SynthesisStore.SynthesisDocument?
    @State private var newDocName = ""
    @State private var docToDelete: SynthesisStore.SynthesisDocument?
    @State private var showDeleteDocConfirm = false
    @State private var showRenameDialog = false
    
    @State private var editMode: SynthesisDocRow.EditMode = .inactive
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
        
        NavigationStack {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                mainList
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .appTabToolbar(title: L10n.AI.Synthesis.title)
            .synthesisViewPresentations(
                showOutput: $showOutput,
                pdfURL: $pdfURL,
                showNoPagesAlert: $showNoPagesAlert,
                showLimitAlert: $showLimitAlert,
                showRenameDialog: $showRenameDialog,
                showLLMAlert: $showLLMAlert,
                showBatchDeleteConfirm: $showBatchDeleteConfirm,
                showDeleteDocConfirm: $showDeleteDocConfirm,
                newDocName: $newDocName,
                docToRename: docToRename,
                docToDelete: docToDelete,
                batchDelete: batchDelete,
                outputSheet: outputSheet
            )
            .onChange(of: taskCenter.tasks) { oldTasks, newTasks in
                // 找出从 running 变为 completed 或 failed 的任务，进行 VoiceOver 主动语音公告播报
                for newTask in newTasks {
                    if let oldTask = oldTasks.first(where: { $0.id == newTask.id }) {
                        switch (oldTask.status, newTask.status) {
                        case (.running, .completed):
                            AccessibilityService.postAnnouncement(L10n.AI.Task.Accessibility.taskFinishedAnnouncement(newTask.name))
                        case (.running, .failed(let error)):
                            AccessibilityService.postAnnouncement(L10n.AI.Task.Accessibility.taskFailedAnnouncement(newTask.name) + "，" + error)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }

    private var mainList: some View {
        List {
            entrySection
            runningTasksContainer
            mainContentSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .padding(.top, DesignSystem.widePadding)
    }

    private var runningTasksContainer: some View {
        let tasks = taskCenter.tasks.filter { task in
            if task.type != .synthesis { return false }
            switch task.status {
            case .running: return true
            default: return false
            }
        }
        return Group {
            if !tasks.isEmpty {
                runningTasksSection(tasks: tasks)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.standardPadding, bottom: DesignSystem.loosePadding, trailing: DesignSystem.standardPadding))
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var entrySection: some View {
        Section {
            synthesisEntryView
        }
        #if !os(watchOS)
        .listRowSeparator(.hidden)
        #endif
        .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.standardPadding, bottom: DesignSystem.loosePadding, trailing: DesignSystem.standardPadding))
        .listRowBackground(Color.clear)
    }

    private var mainContentSection: some View {
        Section {
            listHeader
                .listRowInsets(EdgeInsets(top: DesignSystem.medium, leading: DesignSystem.standardPadding, bottom: DesignSystem.small, trailing: DesignSystem.standardPadding))
            
            filterPillsBar
                .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.standardPadding, bottom: DesignSystem.small, trailing: DesignSystem.standardPadding))

            documentRows
        }
        #if !os(watchOS)
        .listRowSeparator(.hidden)
        #endif
        .listRowBackground(Color.clear)
    }

    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Chip.spacing) {
                FilterPill(title: L10n.Search.all, isSelected: selectedFilterType == nil) {
                    withAnimation(.spring()) { selectedFilterType = nil }
                }
                ForEach(SynthesisStore.SynthesisType.allCases) { type in
                    FilterPill(title: type.title, icon: type.icon, color: type.formatColor, isSelected: selectedFilterType == type) {
                        withAnimation(.spring()) { selectedFilterType = type }
                    }
                }
            }
            .padding(.vertical, DesignSystem.tiny)
        }
    }

    private var filteredDocs: [(SynthesisStore.SynthesisType, SynthesisStore.SynthesisDocument)] {
        if let type = selectedFilterType {
            return synthesisStore.allSortedDocuments.filter { $0.0 == type }
        }
        return synthesisStore.allSortedDocuments
    }

    @ViewBuilder
    private var documentRows: some View {
        let docs = filteredDocs
        
        if docs.isEmpty {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: DesignSystem.Icons.weeklyInsight)
                    .font(.system(size: DesignSystem.Timeline.emptyIconSize))
                    .foregroundStyle(.appSecondary.opacity(DesignSystem.Metrics.emptyStateIconOpacity))
                Text(L10n.AI.Synthesis.noDocs)
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Metrics.emptyStateVerticalPadding)
            .appContainer(background: DesignSystem.containerMaterial)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.standardPadding, bottom: 0, trailing: DesignSystem.standardPadding))
        } else {
            ForEach(docs, id: \.1.id) { type, doc in
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
                .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.standardPadding, bottom: 0, trailing: DesignSystem.standardPadding))
                .listRowBackground(
                    ZStack {
                        DesignSystem.containerMaterial
                        if doc.id != docs.last?.1.id {
                            VStack {
                                Spacer()
                                Divider()
                                    .background(Color.appBorder.opacity(DesignSystem.secondaryOpacity))
                                    .padding(.horizontal, DesignSystem.standardPadding)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.standardPadding)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
                )
            }
        }
    }
    
    private var listHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.medium) {
            Text(L10n.AI.Synthesis.documentList)
                .font(.title3.bold())
            
            Spacer()
            
            if editMode == .active {
                HStack(alignment: .firstTextBaseline, spacing: DesignSystem.medium) {
                    Button(action: {
                        HapticFeedback.shared.trigger(.warning)
                        showBatchDeleteConfirm = true
                    }) {
                        Text(L10n.Common.delete)
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedDocIDs.isEmpty ? .appSecondary.opacity(DesignSystem.disabledOpacity) : .red)
                    }
                    .disabled(selectedDocIDs.isEmpty)
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        HapticFeedback.shared.trigger(.warning)
                        showClearAllConfirm = true
                    }) {
                        Text(L10n.Common.Misc.clear)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appSecondary)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(L10n.AI.Synthesis.clearAllConfirm, isPresented: $showClearAllConfirm, titleVisibility: .visible) {
                        Button(L10n.Common.Misc.clear, role: .destructive) {
                            synthesisStore.clearAll()
                            HapticFeedback.shared.trigger(.success)
                        }
                        Button(L10n.Common.cancel, role: .cancel) { }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                withAnimation(DesignSystem.standardAnimation) {
                    if editMode == .inactive {
                        editMode = .active
                    } else {
                        editMode = .inactive
                        selectedDocIDs.removeAll()
                    }
                }
            }) {
                Text(editMode == .active ? L10n.Common.done : L10n.Common.edit)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignSystem.tightPadding)
        .foregroundStyle(.appText)
        .textCase(nil)
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
                        VStack(spacing: DesignSystem.standardPadding) {
                            if let title = extractTitle(from: doc.content) {
                                Text(title)
                                    .font(.title2.bold())
                                    .padding(.top, DesignSystem.widePadding)
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
                    Button(L10n.Common.done) { showOutput = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DesignSystem.headlineFontSize) {
                        Button {
                            if let doc = selectedDoc {
                                AppPasteboard.string = doc.content
                                HapticFeedback.shared.trigger(.success)
                            }
                        } label: { Image(systemName: DesignSystem.Icons.copy) }

                        Button { exportAction() } label: { Image(systemName: DesignSystem.Icons.export) }
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

    private func runningTasksSection(tasks: [GlobalTask]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.AI.Task.running)
                .font(.title3.bold())
                .foregroundStyle(.appAccent)
                .padding(.horizontal, DesignSystem.tiny)
            
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    synthesisTaskRow(task: task)
                        .padding()
                    if task.id != tasks.last?.id {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .appContainer(padding: false)
        }
    }

    private func synthesisTaskRow(task: GlobalTask) -> some View {
        HStack(spacing: DesignSystem.standardPadding) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(DesignSystem.glassOpacity / 1.5)).frame(width: DesignSystem.Graph.selectedNodeSize, height: DesignSystem.Graph.selectedNodeSize)
                ProgressView()
            }
            VStack(alignment: .leading, spacing: DesignSystem.small) {
                Text(task.name).font(.subheadline.weight(.semibold))
                if case .running(let progress, _) = task.status {
                    ProgressView(value: progress).tint(.appAccent)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(buildTaskAccessibilityLabel(task))
    }

    /// 构造任务在运行中的无障碍语音标签
    /// - Parameter task: 异步后台任务
    /// - Returns: 结合了进度与执行阶段描述的文本
    private func buildTaskAccessibilityLabel(_ task: GlobalTask) -> String {
        let base = "\(task.name)，\(L10n.AI.Task.Accessibility.taskInProgress)"
        if case .running(let progress, let stage) = task.status {
            let percentage = Int(progress * 100)
            let stageName = localizedStageName(stage)
            return base + "，" + L10n.AI.Task.Accessibility.progressValue(percentage, stageName)
        }
        return base
    }

    /// 将 RAG 执行阶段转化为强类型多语言 Status 描述文案
    /// - Parameter stage: RAG 任务阶段
    /// - Returns: 对应的本地化描述文案
    private func localizedStageName(_ stage: TaskStage) -> String {
        switch stage {
        case .embedding: return L10n.AI.Status.extracting
        case .retrieval: return L10n.AI.Status.scanning
        case .synthesis: return L10n.AI.Status.synthesizing
        default: return L10n.AI.Status.thinking
        }
    }

    private var synthesisEntryView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.AI.Synthesis.actions, icon: DesignSystem.Icons.wand)
                .padding(.horizontal, DesignSystem.tiny)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.medium) {
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

// MARK: - 辅助扩展：解耦 View Presentations
extension View {

    /// synthesisViewPresentations
    func synthesisViewPresentations(
        showOutput: Binding<Bool>,
        pdfURL: Binding<IdentifiableURL?>,
        showNoPagesAlert: Binding<Bool>,
        showLimitAlert: Binding<Bool>,
        showRenameDialog: Binding<Bool>,
        showLLMAlert: Binding<Bool>,
        showBatchDeleteConfirm: Binding<Bool>,
        showDeleteDocConfirm: Binding<Bool>,
        newDocName: Binding<String>,
        docToRename: SynthesisStore.SynthesisDocument?,
        docToDelete: SynthesisStore.SynthesisDocument?,
        batchDelete: @escaping () -> Void,
        outputSheet: some View
    ) -> some View {
        self
            .sheet(isPresented: showOutput) { outputSheet }
            .sheet(item: pdfURL) { identifiable in
                #if !os(watchOS)
                PDFPreviewWrapper(url: identifiable.url)
                #else
                Text(identifiable.url.lastPathComponent)
                #endif
            }
            .synthesisAlerts(
                showNoPagesAlert: showNoPagesAlert,
                showLimitAlert: showLimitAlert,
                showRenameDialog: showRenameDialog,
                showLLMAlert: showLLMAlert,
                showBatchDeleteConfirm: showBatchDeleteConfirm,
                showDeleteDocConfirm: showDeleteDocConfirm,
                newDocName: newDocName,
                docToRename: docToRename,
                docToDelete: docToDelete,
                batchDelete: batchDelete
            )
    }

    private func synthesisAlerts(
        showNoPagesAlert: Binding<Bool>,
        showLimitAlert: Binding<Bool>,
        showRenameDialog: Binding<Bool>,
        showLLMAlert: Binding<Bool>,
        showBatchDeleteConfirm: Binding<Bool>,
        showDeleteDocConfirm: Binding<Bool>,
        newDocName: Binding<String>,
        docToRename: SynthesisStore.SynthesisDocument?,
        docToDelete: SynthesisStore.SynthesisDocument?,
        batchDelete: @escaping () -> Void
    ) -> some View {
        self
            .alertNoPages(isPresented: showNoPagesAlert)
            .alertLimitReached(isPresented: showLimitAlert)
            .alertRenameDoc(isPresented: showRenameDialog, name: newDocName, doc: docToRename)
            .alertLLMNotConfigured(isPresented: showLLMAlert)
            .confirmBatchDelete(isPresented: showBatchDeleteConfirm, action: batchDelete)
            .alertDeleteDoc(isPresented: showDeleteDocConfirm, doc: docToDelete)
    }
}

extension View {

    /// alertNoPages
    /// /// - Parameter isPresented: isPresented
    func alertNoPages(isPresented: Binding<Bool>) -> some View {
        self.alert(L10n.AI.Synthesis.Error.noPages, isPresented: isPresented) {
            Button(L10n.Common.ok, role: .cancel) { }
        }
    }
    
    /// alertLimitReached
    /// /// - Parameter isPresented: isPresented
    func alertLimitReached(isPresented: Binding<Bool>) -> some View {
        self.alert(L10n.AI.Synthesis.Error.limitReached, isPresented: isPresented) {
            Button(L10n.Common.done, role: .cancel) { }
        }
    }
    
    /// alert重命名Doc
    /// /// - Parameter isPresented: isPresented
    /// /// - Parameter name: name
    /// /// - Parameter doc: doc
    func alertRenameDoc(isPresented: Binding<Bool>, name: Binding<String>, doc: SynthesisStore.SynthesisDocument?) -> some View {
        self.alert(L10n.Tag.Action.rename, isPresented: isPresented) {
            TextField(L10n.Tag.Management.inputName, text: name)
            Button(L10n.Tag.Action.rename) {
                if let doc = doc {
                    @Inject var store: SynthesisStore
                    store.renameSynthesisDoc(type: doc.type, docID: doc.id, newName: name.wrappedValue)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        }
    }
    
    /// alertLLMNotConfigured
    /// /// - Parameter isPresented: isPresented
    func alertLLMNotConfigured(isPresented: Binding<Bool>) -> some View {
        self.alert(L10n.Chat.configureFirst, isPresented: isPresented) {
            Button(L10n.Common.confirm, role: .cancel) { }
        } message: {
            Text(L10n.AI.LLM.Error.notConfigured)
        }
    }
    
    /// confirmBatch删除
    /// /// - Parameter isPresented: isPresented
    /// /// - Parameter action: action
    /// /// - Returns: 视图
    func confirmBatchDelete(isPresented: Binding<Bool>, action: @escaping () -> Void) -> some View {
        self.confirmationDialog(L10n.AI.Synthesis.batchDeleteConfirm, isPresented: isPresented, titleVisibility: .automatic) {
            Button(L10n.Common.delete, role: .destructive) { action() }
            Button(L10n.Common.cancel, role: .cancel) { }
        }
    }
    
    /// alert删除Doc
    /// /// - Parameter isPresented: isPresented
    /// /// - Parameter doc: doc
    func alertDeleteDoc(isPresented: Binding<Bool>, doc: SynthesisStore.SynthesisDocument?) -> some View {
        self.alert(L10n.Common.deleteConfirm, isPresented: isPresented) {
            Button(L10n.Common.delete, role: .destructive) {
                if let doc = doc {
                    @Inject var store: SynthesisStore
                    store.deleteSynthesisDoc(type: doc.type, docID: doc.id)
                    HapticFeedback.shared.trigger(.success)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        }
    }
}
