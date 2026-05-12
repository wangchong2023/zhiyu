// IngestView.swift
//
// 作者: Wang Chong
// 功能说明: 知识摄入（Ingest）功能主视图，协调多渠道导入流程。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-06 (重构布局并增加溯源元数据)
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI
import UniformTypeIdentifiers

// MARK: - 活动项模型
/// 摄入活动数据模型
/// 负责封装单个内容摄入任务的元数据，包括标题、状态、时间戳及关联的 知识库页面标识符
struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let status: ActivityStatus
    let timestamp: Date
    var associatedPageID: UUID? = nil
    
    enum ActivityStatus {
        case pending
        case processing
        case completed
        case failed
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .processing: return "arrow.triangle.2.circlepath"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var colorName: String {
            switch self {
            case .pending: return "gray"
            case .processing: return "blue"
            case .completed: return "green"
            case .failed: return "red"
            }
        }
    }
}

// MARK: - 视图核心
/// 知识摄入（Ingest）中心主视图
/// 负责协调多渠道（文件导入、语音转写、OCR 扫描、URL 抓取及剪贴板）的知识获取流程，管理异步任务队列与入库配置
struct IngestView: View {
    @Environment(AppStore.self) var store
    @Environment(IngestStore.self) var ingestStore
    @Environment(AppRouter.self) var router
    @EnvironmentObject var llmService: LLMService
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: AppTab

    @State private var newTitle = ""
    @State private var newContent = ""
    @State private var newType: PageType = .source
    @State private var newCustomIcon: String? = nil
    @State private var newTags: [String] = []
    @State private var isIngesting = false
    @State private var ingestSuccess = false
    @State private var useSmartIngest = false
    @State private var smartResult: SmartIngestResult?
    @State private var showSmartPreview = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showIconPicker = false
    @State private var showManualForm = false
    @State private var manualFormTitle = L10n.Ingest.tr("manualEntry")
    @State private var showOCRScan = false
    @State private var showURLImport = false
    @State private var newURL = ""
    @State private var useDeepScan = false
    @State private var isExtracting = false
    @State private var newFileSize: Int64?
    @State private var newSourceType: String?
    
    // File Import State
    @State private var showFileImporter = false

    // Voice Note State
    @State private var showVoiceNote = false

    private var isLLMConfigured: Bool {
        llmService.isEnabled && !llmService.apiKey.isEmpty
    }

    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppUI.standardPadding + AppUI.small) { // 24
                    // 0. LLM 配置警告 (如果未配置则强制提示)
                    if !isLLMConfigured {
                        llmWarningSection
                    }

                    // 1. 导入操作区域
                    actionsSection

                    // 2. 导入源区域 (参考 Notebook LM)
                    importSourcesSection

                    // 3. 导入活动状态展示区域
                    if !TaskCenter.shared.tasks.filter({ $0.type == .ingest }).isEmpty {
                        taskCenterLinkSection
                    }
                    
                    // 4. 最近处理的文档列表
                    recentActivitiesSection
                }
                .padding(.horizontal)
                .padding(.top, AppUI.standardPadding)
                .padding(.bottom, AppUI.standardPadding * 2)
            }
        }
        .navigationTitle(L10n.Ingest.title)
        .alert(L10n.Ingest.tr("error"), isPresented: $showError) {
            Button(L10n.Ingest.tr("ok")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        #if !os(watchOS)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: {
                var types: [UTType] = [.pdf, .text, .plainText]
                if let md = UTType("net.daringfireball.markdown") {
                    types.append(md)
                }
                return types
            }(),
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        #endif
        .sheet(isPresented: $showVoiceNote, onDismiss: {
            if !newTitle.isEmpty {
                showManualForm = true
            }
        }) {
            VoiceNoteView(onFinish: { title, content in
                self.newTitle = title
                self.newContent = content
                self.manualFormTitle = Localized.tr("speech.title")
                // Remove immediate showManualForm = true to avoid sheet conflict
            })
        }
        .sheet(isPresented: $showOCRScan, onDismiss: {
            if !newTitle.isEmpty {
                showManualForm = true
            }
        }) {
            OCRScanView(onFinish: { title, content in
                self.newTitle = title
                self.newContent = content
                self.manualFormTitle = Localized.tr("ocr.title")
                // Remove immediate showManualForm = true
            })
        }
        .sheet(isPresented: $showURLImport) {
            URLImportSheet(
                urlText: $newURL,
                onImport: { handleURLImport() }
            )
        }
        .sheet(isPresented: $showManualForm) {
            manualFormSheet
        }
        .onReceive(NotificationCenter.default.publisher(for: .importFromClipboard)) { _ in
            performClipboardImport()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(PageBackgroundView(accentColor: .appSource))
    }

    @ViewBuilder
    private var llmWarningSection: some View {
        NavigationLink(destination: LLMSettingsView()) {
            HStack(spacing: AppUI.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.Ingest.tr("llmRequired"))
                    .font(.subheadline)
                    .foregroundStyle(.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            .padding()
            .background(Color.orange.opacity(AppUI.glassOpacity))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("actions"), icon: "square.and.arrow.down")
                .padding(.horizontal, AppUI.tiny)
            
            IngestEntryCardsSection(
                showManualForm: Binding(
                    get: { showManualForm },
                    set: { newValue in
                        if newValue { manualFormTitle = L10n.Ingest.tr("manualEntry") }
                        showManualForm = newValue
                    }
                ),
                showOCRScan: $showOCRScan,
                newType: $newType,
                showFileImporter: $showFileImporter,
                showVoiceNote: $showVoiceNote,
                showURLImport: $showURLImport
            )
            .appContainer(padding: true)
            .disabled(!isLLMConfigured)
            .opacity(isLLMConfigured ? AppUI.fullOpacity : AppUI.disabledOpacity)
        }
    }

    // MARK: - Import Sources Section
    private var importSourcesSection: some View {
        let sources = store.pages.filter { $0.type == .source || $0.sourceURL != nil }
            .sorted(by: { $0.created > $1.created }) // 改为按导入时间排序
            .prefix(AppUI.Metrics.maxDashboardItems) // 15
        
        return VStack(alignment: .leading, spacing: AppUI.medium) {
            HStack {
                AppSectionHeader(title: L10n.Ingest.tr("sources"), icon: "tray.full")
                Spacer()
                if !sources.isEmpty {
                    Text(L10n.Common.trf("history.count", sources.count))
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                }
            }
            .padding(.horizontal, AppUI.tiny)
            
            if sources.isEmpty {
                VStack(spacing: AppUI.medium) {
                    Image(systemName: "tray")
                        .font(.system(size: AppUI.Metrics.dashboardValueSize))
                        .foregroundStyle(.appSecondary.opacity(0.5))
                    Text(L10n.Common.Empty.tr("noData"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppUI.standardPadding * 2)
                .appContainer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppUI.medium) {
                        ForEach(sources) { page in
                            Button(action: {
                                HapticFeedback.shared.trigger(.selection)
                                router.navigateToPage(id: page.id)
                            }) {
                                SourceCardView(page: page)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppUI.atomic / 2) // 1
                }
            }
        }
    }

    private var taskCenterLinkSection: some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            router.navigateToTool(.taskCenter)
        }) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline.bold())
                    .foregroundStyle(.appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    let runningCount = TaskCenter.shared.tasks.filter({ $0.type == .ingest && isRunning(status: $0.status) }).count
                    Text(L10n.Ingest.trf("activeTasks", runningCount))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.appText)
                    Text(L10n.Ingest.tr("recentActivity"))
                        .font(.system(size: 10))
                        .foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            .padding(AppUI.standardPadding)
            .background(Color.appCard.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
        }
        .buttonStyle(.plain)
    }

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) { // 12
            AppSectionHeader(title: L10n.Ingest.tr("recent"), icon: "list.bullet.rectangle")
                .padding(.horizontal, AppUI.atomic * 2)
            
            let ingestTasks = TaskCenter.shared.tasks.filter { $0.type == .ingest }
            if ingestTasks.isEmpty {
                VStack(spacing: AppUI.tightPadding) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.appSecondary.opacity(AppUI.dimmedOpacity)) // 0.5
                    Text(L10n.Ingest.tr("noActivities"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppUI.loosePadding) // 20
                .appContainer()
            } else {
                VStack(spacing: 0) {
                    ForEach(ingestTasks.prefix(AppUI.Metrics.maxRecentItems)) { task in // 5
                        ActivityRow(task: task)
                        if task.id != ingestTasks.prefix(AppUI.Metrics.maxRecentItems).last?.id {
                            Divider().padding(.leading, AppUI.Metrics.largeIconBoxSize)
                        }
                    }
                }
                .appContainer(padding: false)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let _ = url.startAccessingSecurityScopedResource()
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("importingFile"), target: url.lastPathComponent)
                
                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let page = await store.ingestService.ingestDocument(at: url, pageStore: store)
                    await MainActor.run {
                        if let _ = page {
                            TaskCenter.shared.updateTask(taskID, status: .completed)
                            HapticFeedback.shared.trigger(.success)
                        } else {
                            TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed")))
                            HapticFeedback.shared.trigger(.error)
                        }
                    }
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleURLImport() {
        guard let url = URL(string: newURL) else {
            errorMessage = L10n.Ingest.tr("invalidURL")
            showError = true
            return
        }

        showURLImport = false
        let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("fetchingURL"), target: url.host ?? url.absoluteString)

        Task {
            let page = try? await store.ingestService.ingestURL(urlString: url.absoluteString, pageStore: store)
            await MainActor.run {
                if let _ = page {
                    TaskCenter.shared.updateTask(taskID, status: .completed)
                    HapticFeedback.shared.trigger(.success)
                    newURL = ""
                } else {
                    TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed")))
                    HapticFeedback.shared.trigger(.error)
                }
            }
        }
    }

    private func performClipboardImport() {
        #if os(iOS)
        if let content = UIPasteboard.general.string, !content.isEmpty {
            self.newTitle = String(content.prefix(20))
            self.newContent = content
            self.manualFormTitle = L10n.Ingest.tr("manualEntry")
            self.showManualForm = true
        }
        #elseif os(macOS)
        if let content = NSPasteboard.general.string(forType: .string), !content.isEmpty {
            self.newTitle = String(content.prefix(20))
            self.newContent = content
            self.manualFormTitle = L10n.Ingest.tr("manualEntry")
            self.showManualForm = true
        }
        #endif
    }

    private var manualFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.Creation.tr("basicInfo"))) {
                    TextField(L10n.Creation.tr("pageTitle"), text: $newTitle)
                        .font(.headline)
                    
                    // Horizontal Type Selector (Faster than Picker)
                    VStack(alignment: .leading, spacing: AppUI.medium) {
                        Text(L10n.Creation.tr("pageType"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.appSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppUI.small) {
                                ForEach(PageType.allCases, id: \.self) { type in
                                    Button(action: {
                                        HapticFeedback.shared.trigger(.selection)
                                        withAnimation(.spring(response: 0.3)) {
                                            newType = type
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .font(.subheadline.weight(newType == type ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(newType == type ? Color.fromModelColorName(type.colorName).opacity(0.2) : Color.appCard.opacity(0.8))
                                        .foregroundStyle(newType == type ? Color.fromModelColorName(type.colorName) : .appSecondary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(newType == type ? Color.fromModelColorName(type.colorName).opacity(0.3) : Color.appBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    .padding(.vertical, AppUI.tiny)
                    
                    // Custom Icon Selection
                    NavigationLink(destination: IconPickerView(selectedIcon: $newCustomIcon)) {
                        HStack {
                            Label(L10n.Creation.tr("customIcon"), systemImage: "star.square.fill")
                            Spacer()
                            if let icon = newCustomIcon {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(.appAccent)
                                    .padding(AppUI.tiny)
                                    .background(Color.appAccent.opacity(0.1))
                                    .clipShape(Circle())
                            } else {
                                Text(L10n.Common.tr("none"))
                                    .foregroundColor(.appSecondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Smart Ingest Entry (Directly below Custom Icon)
                    VStack(alignment: .leading, spacing: AppUI.small) {
                        HStack {
                            Label(L10n.Ingest.tr("smartIngest"), systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundStyle(.appAccent)
                            Spacer()
                            Toggle("", isOn: $useSmartIngest)
                                .labelsHidden()
                                .tint(.appAccent)
                        }
                        
                        if useSmartIngest {
                            Text(L10n.Ingest.tr("smartIngestDesc"))
                                .font(.system(size: AppUI.captionFontSize))
                                .foregroundStyle(.appSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, AppUI.tiny)
                }
                
                Section(header: Text(L10n.Creation.tr("content"))) {
                    Group {
                        #if os(watchOS)
                        TextField("", text: $newContent)
                        #else
                        TextEditor(text: $newContent)
                        #endif
                    }
                    .frame(minHeight: AppUI.Metrics.heroValueSize * 7.7) // 200
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.pageBackground())
            .navigationTitle(manualFormTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.tr("cancel")) { showManualForm = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.tr("import")) {
                        performIngest()
                    }
                    .disabled(newTitle.isEmpty || newContent.isEmpty || isIngesting)
                }
            }
        }
    }

    private func performIngest() {
        isIngesting = true
        let title = newTitle
        let content = newContent
        let type = newType
        let icon = newCustomIcon
        
        Task {
            var finalPage: KnowledgePage?
            
            do {
                finalPage = try await ingestStore.performIngest(
                    title: title,
                    content: content,
                    type: type,
                    tags: [],
                    customIcon: icon,
                    useSmart: useSmartIngest,
                    useDeepScan: true
                )
            } catch {
                Logger.shared.error("Failed to ingest: \(error)")
            }
            
            if let page = finalPage, let icon = icon {
                var updated = page
                updated.customIcon = icon
                store.updatePage(updated, forceDeepScan: true)
            }
            
            await MainActor.run {
                isIngesting = false
                if finalPage != nil {
                    showManualForm = false
                    newTitle = ""
                    newContent = ""
                    newCustomIcon = nil
                    HapticFeedback.shared.trigger(.success)
                } else {
                    errorMessage = L10n.Ingest.tr("importFailed")
                    showError = true
                    HapticFeedback.shared.trigger(.error)
                }
            }
        }
    }
    
    private func isRunning(status: TaskStatus) -> Bool {
        if case .running = status { return true }
        return false
    }
}

// MARK: - 辅助子视图

struct SourceCardView: View {
    let page: KnowledgePage
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.tightPadding) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.fromModelColorName(page.type.colorName).opacity(AppUI.glassOpacity * 1.2)) // 0.12
                        .frame(width: AppUI.Metrics.smallIconBoxSize, height: AppUI.Metrics.smallIconBoxSize)
                    Image(systemName: page.type.icon)
                        .font(.system(size: AppUI.iconTiny, weight: .bold))
                        .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                }
                Spacer()
                if let url = page.sourceURL {
                    Image(systemName: url.contains("http") ? "link" : "doc.fill")
                        .font(.system(size: AppUI.iconTiny - AppUI.atomic)) // -2
                        .foregroundStyle(.appSecondary.opacity(AppUI.dimmedOpacity)) // 0.5
                }
            }
            
            Text(page.title)
                .font(.system(size: AppUI.captionFontSize + AppUI.atomic / 2, weight: .bold)) // +1
                .lineLimit(2)
                .foregroundStyle(.appText)
            
            Spacer()
            
            HStack {
                Text(page.created.formatted(.relative(presentation: .named).locale(Localized.currentLocale)))
                    .font(.system(size: AppUI.microFontSize))
                    .foregroundStyle(.appSecondary)
                Spacer()
                Text(L10n.Common.trf("wordCount", page.wordCount))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(AppUI.medium)
        .frame(width: AppUI.Metrics.sourceCardWidth, height: AppUI.Metrics.sourceCardHeight)
        .appMetricCardStyle(color: Color.fromModelColorName(page.type.colorName), cornerRadius: AppUI.standardRadius)
    }
}

struct ActivityRow: View {
    let task: GlobalTask
    @Environment(AppRouter.self) var router
    
    var body: some View {
        Button(action: {
            if let id = task.associatedPageID {
                HapticFeedback.shared.trigger(.selection)
                router.navigateToPage(id: id)
            }
        }) {
            HStack(spacing: AppUI.medium) {
                ZStack {
                    Circle()
                        .fill(taskColor.opacity(AppUI.glassOpacity)) // 0.1
                        .frame(width: AppUI.Metrics.smallIconBoxSize + AppUI.atomic * 2, height: AppUI.Metrics.smallIconBoxSize + AppUI.atomic * 2) // +4
                    Image(systemName: taskIcon)
                        .font(.system(size: AppUI.subheadlineFontSize))
                        .foregroundStyle(taskColor)
                }
                
                VStack(alignment: .leading, spacing: AppUI.atomic) {
                    Text(task.name + ": " + task.target)
                        .font(.system(size: AppUI.subheadlineFontSize, weight: .medium))
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    Text(task.startTime.formatted(Date.FormatStyle(locale: Localized.currentLocale)))
                        .font(.system(size: AppUI.captionFontSize))
                        .foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                if task.associatedPageID != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppUI.captionFontSize, weight: .bold))
                        .foregroundStyle(.appSecondary.opacity(AppUI.disabledOpacity)) // 0.3
                }
            }
            .padding(.vertical, AppUI.tightPadding + AppUI.atomic)
            .padding(.horizontal, AppUI.medium)
        }
        .buttonStyle(.plain)
    }
    
    private var taskColor: Color {
        switch task.status {
        case .completed: return .green
        case .failed: return .red
        case .running: return .blue
        case .pending: return .gray
        }
    }
    
    private var taskIcon: String {
        switch task.status {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .pending: return "clock"
        }
    }
}

