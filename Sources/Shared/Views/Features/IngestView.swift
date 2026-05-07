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
        @Bindable var router = router
        ScrollView {
            VStack(spacing: 24) {
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
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationTitle(L10n.Ingest.title)
        .alert(L10n.Ingest.tr("error"), isPresented: $showError) {
            Button(L10n.Ingest.tr("ok")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $newCustomIcon)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: {
                var types: [UTType] = [.pdf, .plainText, .text]
                if let doc = UTType("com.microsoft.word.doc") { types.append(doc) }
                if let docx = UTType("org.openxmlformats.wordprocessingml.document") { types.append(docx) }
                if let xls = UTType("com.microsoft.excel.xls") { types.append(xls) }
                if let xlsx = UTType("org.openxmlformats.spreadsheetml.sheet") { types.append(xlsx) }
                if let md = UTType("net.daringfireball.markdown") { types.append(md) }
                return types
            }(),
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showVoiceNote) {
            VoiceNoteView(onFinish: { title, content in
                self.newTitle = title
                self.newContent = content
                self.manualFormTitle = Localized.tr("speech.title")
                self.showManualForm = true
            })
        }
        .sheet(isPresented: $showOCRScan) {
            OCRScanView(onFinish: { title, content in
                self.newTitle = title
                self.newContent = content
                self.manualFormTitle = Localized.tr("ocr.title")
                self.showManualForm = true
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
    }

    @ViewBuilder
    private var llmWarningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.Ingest.tr("llmRequired"))
                    .font(.headline)
            }
            Text(L10n.Ingest.tr("llmRequiredDesc"))
                .font(.caption)
                .foregroundStyle(.appSecondary)
            
            Button(action: { selectedTab = .settings }) {
                Text(L10n.Ingest.tr("goToSettings"))
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.cardRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("actions"), icon: "square.and.arrow.down")
                .padding(.horizontal, 4)
            
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
            .prefix(15)
        
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
            .padding(.horizontal, 4)
            
            if sources.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.appSecondary.opacity(0.5))
                    Text(L10n.Ingest.tr("noSources"))
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .appContainer(padding: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sources) { page in
                            SourceCard(page: page) {
                                router.navigate(to: .pageDetail(id: page.id))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var manualFormSheet: some View {
        NavigationStack {
            ScrollView {
                IngestManualFormSection(
                    newTitle: $newTitle,
                    newContent: $newContent,
                    newType: $newType,
                    newCustomIcon: $newCustomIcon,
                    newTags: $newTags,
                    showIconPicker: $showIconPicker,
                    useSmartIngest: $useSmartIngest,
                    smartResult: $smartResult,
                    isIngesting: $isIngesting,
                    ingestSuccess: $ingestSuccess,
                    errorMessage: $errorMessage,
                    showError: $showError,
                    useDeepScan: $useDeepScan,
                    llmService: llmService,
                    store: store,
                    ingestStore: ingestStore,
                    onPerformIngest: performIngest,
                    onConfirmSmartIngest: confirmSmartIngest
                )
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(manualFormTitle)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.tr("cancel")) {
                        showManualForm = false
                    }
                }
            }
        }
    }

    // MARK: - Task Center Link Section
    @ViewBuilder
    private var taskCenterLinkSection: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            Button(action: { router.navigate(to: .taskCenter) }) {
                HStack {
                    Image(systemName: "tray.full.fill")
                        .foregroundStyle(.appAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Ingest.tr("queue.title"))
                            .font(.headline)
                            .foregroundStyle(.appText)
                        Text(L10n.Ingest.tr("queue.desc"))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    Spacer()
                    if TaskCenter.shared.unreadCount > 0 {
                        Text("\(TaskCenter.shared.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.red))
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .appContainer(padding: true)
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - File Import Handler
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                isExtracting = true
                Task {
                    do {
                        let extracted = try await ingestStore.handleFileUpload(at: url)
                        await MainActor.run {
                            self.newTitle = extracted.title
                            self.newContent = extracted.content
                            self.newFileSize = extracted.size
                            self.newSourceType = extracted.type
                            self.manualFormTitle = L10n.Ingest.tr("fileImport")
                            self.isExtracting = false
                            self.showManualForm = true
                            HapticFeedback.shared.trigger(.success)
                        }
                    } catch {
                        await MainActor.run {
                            self.isExtracting = false
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Ingest Logic
    private func performIngest() {
        isIngesting = true
        ingestSuccess = false
        smartResult = nil

        Task {
            do {
                _ = try await ingestStore.performIngest(
                    title: newTitle,
                    content: newContent,
                    type: newType,
                    tags: newTags,
                    customIcon: newCustomIcon,
                    useSmart: useSmartIngest,
                    useDeepScan: useDeepScan,
                    fileSize: newFileSize,
                    sourceType: newSourceType
                )

                await MainActor.run {
                    isIngesting = false
                    ingestSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        resetForm()
                        showManualForm = false
                    }
                }
            } catch {
                await MainActor.run {
                    isIngesting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func confirmSmartIngest() {
        guard let result = smartResult else { return }
        
        Task {
            _ = await ingestStore.finalizeSmartIngest(
                title: newTitle, 
                result: result, 
                customIcon: newCustomIcon
            )
            
            await MainActor.run {
                smartResult = nil
                ingestSuccess = true
                ToastManager.shared.show(type: .success, message: Localized.tr("ingest.success"))

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    resetForm()
                }
            }
        }
    }

    private func resetForm() {
        newTitle = ""
        newContent = ""
        newTags = []
        newCustomIcon = nil
        newFileSize = nil
        newSourceType = nil
        ingestSuccess = false
    }

    // MARK: - Recent Activities Section
    @ViewBuilder
    private var recentActivitiesSection: some View {
        let recentTasks = TaskCenter.shared.tasks
            .filter { $0.type == .ingest }
            .prefix(5)
        
        if !recentTasks.isEmpty {
            VStack(alignment: .leading, spacing: AppUI.medium) {
                AppSectionHeader(title: L10n.Ingest.tr("recentActivities"), icon: "clock.arrow.circlepath")
                    .padding(.horizontal, 4)
                
                VStack(spacing: 8) {
                    ForEach(recentTasks) { task in
                        ActivityRow(item: ActivityItem(
                            title: task.target.isEmpty ? task.name : task.target,
                            status: mapTaskStatus(task.status),
                            timestamp: task.startTime,
                            associatedPageID: task.associatedPageID
                        ), isCurrent: false, selectedTab: $selectedTab)
                    }
                }
                .appContainer(padding: true)
            }
        }
    }
    
    private func mapTaskStatus(_ status: TaskStatus) -> ActivityItem.ActivityStatus {
        switch status {
        case .pending: return .pending
        case .running: return .processing
        case .completed: return .completed
        case .failed: return .failed
        }
    }



    // MARK: - URL Import Handler
    private func handleURLImport() {
        let urls = newURL.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard let firstURL = urls.first else { return }
        
        // 清空输入并关闭 Sheet
        newURL = ""
        showURLImport = false
        isExtracting = true
        ToastManager.shared.show(type: .processing, message: L10n.Ingest.tr("processing"), duration: 0)
        
        Task {
            do {
                let extracted = try await ingestStore.fetchURLContent(urlString: firstURL)
                await MainActor.run {
                    self.newTitle = extracted.title
                    self.newContent = extracted.content
                    self.manualFormTitle = L10n.Ingest.tr("urlImport")
                    self.isExtracting = false
                    ToastManager.shared.dismiss()
                    self.showManualForm = true
                    ToastManager.shared.show(type: .success, message: L10n.Ingest.tr("success"))
                    HapticFeedback.shared.trigger(.success)
                }
            } catch {
                await MainActor.run {
                    self.isExtracting = false
                    ToastManager.shared.show(type: .error, message: error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    // MARK: - Clipboard Import
    private func performClipboardImport() {
        guard let clipboardContent = AppPasteboard.string, !clipboardContent.isEmpty else {
            errorMessage = L10n.Ingest.tr("clipboardEmpty")
            showError = true
            return
        }

        // 解析剪贴板内容
        let lines = clipboardContent.components(separatedBy: "\n")
        var title = ""
        let content = clipboardContent

        if let firstLine = lines.first {
            title = firstLine
                .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }

        if title.isEmpty {
            title = L10n.Settings.tr("importedPageTitle")
        }

        // 填充到表单并显示
        newTitle = title
        newContent = content
        newType = .concept
        newTags = [L10n.Settings.tr("importTag")]
        manualFormTitle = L10n.Ingest.tr("clipboardImport")
        
        withAnimation {
            showManualForm = true
        }
    }
}

// MARK: - 活动行渲染
struct ActivityRow: View {
    @Environment(AppStore.self) var store
    @Environment(AppRouter.self) var router
    let item: ActivityItem
    let isCurrent: Bool
    @Binding var selectedTab: AppTab
    
    var body: some View {
        Button(action: {
            if let pageID = item.associatedPageID {
                HapticFeedback.shared.trigger(.selection)
                router.navigate(to: .pageDetail(id: pageID))
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.fromModelColorName(item.status.colorName).opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    if item.status == .processing {
                        Image(systemName: item.status.icon)
                            .font(.caption)
                            .foregroundStyle(Color.fromModelColorName(item.status.colorName))
                            .rotationEffect(.degrees(isCurrent ? 360 : 0))
                            .animation(
                                isCurrent ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isCurrent
                            )
                    } else {
                        Image(systemName: item.status.icon)
                            .font(.caption)
                            .foregroundStyle(Color.fromModelColorName(item.status.colorName))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption)
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    Text(item.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                if item.associatedPageID != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.appSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrent ? Color.fromModelColorName(item.status.colorName).opacity(0.1) : Color.appCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
        }
        .buttonStyle(.plain)
        .disabled(item.associatedPageID == nil)
    }
}

// MARK: - Source Card Component
/// 导入源卡片组件 (NotebookLM 风格)
private struct SourceCard: View {
    let page: KnowledgePage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top: Icon and Type
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.fromModelColorName(page.type.colorName).opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: page.sourceURL != nil ? "link" : "doc.text")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                    }
                    Spacer()
                    Text(page.type.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appSecondary.opacity(0.1))
                        .foregroundStyle(.appSecondary)
                        .clipShape(Capsule())
                }
                
                // Middle: Title and Snippet
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.appText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let snippet = page.rawTextSnippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.system(size: 10))
                            .foregroundStyle(.appSecondary.opacity(0.8))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    } else if let url = page.sourceURL {
                        Text(url)
                            .font(.system(size: 10))
                            .foregroundStyle(.appAccent.opacity(0.7))
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Bottom: Meta and Action
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(page.created.formatted(.relative(presentation: .numeric)))
                        if let size = page.fileSize, size > 0 {
                            Text(formatBytes(size))
                        }
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(.appSecondary.opacity(0.6))
                    
                    Spacer()
                    
                    if let type = page.sourceType {
                        Text(type.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.appAccent.opacity(0.1))
                            .foregroundStyle(.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .frame(width: 160, height: 180)
            .padding(14)
            .background(AppUI.containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppUI.containerBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
