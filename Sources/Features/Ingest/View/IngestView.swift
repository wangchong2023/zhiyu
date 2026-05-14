// IngestView.swift
//
// 作者: Wang Chong
// 功能说明: 知识摄入（Ingest）功能主视图，协调多渠道导入流程。
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI
import UniformTypeIdentifiers

// MARK: - 活动项模型
struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let status: ActivityStatus
    let timestamp: Date
    var associatedPageID: UUID? = nil
    
    enum ActivityStatus {
        case pending, processing, completed, failed
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .processing: return "arrow.triangle.2.circlepath"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - 视图核心
struct IngestView: View {
    @Environment(AppStore.self) var store
    @Environment(IngestStore.self) var ingestStore
    @Environment(Router.self) var router
    @EnvironmentObject var llmService: LLMService
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: AppTab
    @Inject var appEnv: any AppEnvironmentProtocol

    @State private var newTitle = ""
    @State private var newContent = ""
    @State private var newType: PageType = .source
    @State private var newCustomIcon: String? = nil
    @State private var isIngesting = false
    @State private var useSmartIngest = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showManualForm = false
    @State private var manualFormTitle = L10n.Ingest.tr("manualEntry")
    @State private var showOCRScan = false
    @State private var showURLImport = false
    @State private var newURL = ""
    @State private var showFileImporter = false
    @State private var showVoiceNote = false

    private var isLLMConfigured: Bool {
        llmService.isEnabled && !llmService.apiKey.isEmpty
    }

    var body: some View {
        ZStack {
            themeManager.pageBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.standardPadding + DesignSystem.small) {
                    if !isLLMConfigured { llmWarningSection }
                    actionsSection
                    importSourcesSection
                    if !TaskCenter.shared.tasks.filter({ $0.type == .ingest }).isEmpty { taskCenterLinkSection }
                    recentActivitiesSection
                }
                .padding(.horizontal)
                .padding(.top, DesignSystem.standardPadding)
                .padding(.bottom, DesignSystem.standardPadding * 2)
            }
        }
        .appTabToolbar(title: L10n.Ingest.title)
        .alert(L10n.Ingest.tr("error"), isPresented: $showError) {
            Button(L10n.Ingest.tr("ok")) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        #if !os(watchOS)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .text, .plainText, UTType("net.daringfireball.markdown")].compactMap({$0}),
            allowsMultipleSelection: true
        ) { handleFileImport($0) }
        #endif
        .sheet(isPresented: $showVoiceNote, onDismiss: { if !newTitle.isEmpty { showManualForm = true } }) {
            VoiceNoteView(onFinish: { self.newTitle = $0; self.newContent = $1; self.manualFormTitle = Localized.tr("speech.title") })
        }
        .sheet(isPresented: $showOCRScan, onDismiss: { if !newTitle.isEmpty { showManualForm = true } }) {
            OCRScanView(onFinish: { self.newTitle = $0; self.newContent = $1; self.manualFormTitle = Localized.tr("ocr.title") })
        }
        .sheet(isPresented: $showURLImport) { URLImportSheet(urlText: $newURL, onImport: { handleURLImport() }) }
        .sheet(isPresented: $showManualForm) { manualFormSheet }
        .onReceive(NotificationCenter.default.publisher(for: .importFromClipboard)) { _ in performClipboardImport() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(PageBackgroundView(accentColor: .appSource))
    }

    private var llmWarningSection: some View {
        NavigationLink(destination: LLMSettingsView()) {
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                Text(L10n.Ingest.tr("llmRequired")).font(.subheadline).foregroundStyle(.appText)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.appSecondary)
            }
            .padding().background(Color.orange.opacity(DesignSystem.glassOpacity))
        }
        .buttonStyle(.plain)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("actions"), icon: "square.and.arrow.down").padding(.horizontal, DesignSystem.tiny)
            IngestEntryCardsSection(
                showManualForm: Binding(get: { showManualForm }, set: { if $0 { manualFormTitle = L10n.Ingest.tr("manualEntry") }; showManualForm = $0 }),
                showOCRScan: $showOCRScan, newType: $newType, showFileImporter: $showFileImporter, showVoiceNote: $showVoiceNote, showURLImport: $showURLImport
            )
            .appContainer(padding: true)
            .disabled(!isLLMConfigured).opacity(isLLMConfigured ? DesignSystem.fullOpacity : DesignSystem.disabledOpacity)
        }
    }

    private var importSourcesSection: some View {
        let sources = store.pages.filter { $0.type == .source || $0.sourceURL != nil }.sorted(by: { $0.created > $1.created }).prefix(DesignSystem.Metrics.maxDashboardItems)
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                AppSectionHeader(title: L10n.Ingest.tr("sources"), icon: "tray.full")
                Spacer()
                if !sources.isEmpty { Text(L10n.Common.trf("history.count", sources.count)).font(.caption2).foregroundStyle(.appSecondary) }
            }
            .padding(.horizontal, DesignSystem.tiny)
            if sources.isEmpty {
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: "tray").font(.system(size: DesignSystem.Metrics.dashboardValueSize)).foregroundStyle(.appSecondary.opacity(0.5))
                    Text(L10n.Common.Empty.tr("noData")).font(.caption).foregroundStyle(.appSecondary)
                }.frame(maxWidth: .infinity).padding(.vertical, DesignSystem.standardPadding * 2).appContainer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.medium) {
                        ForEach(sources) { page in
                            Button(action: { HapticFeedback.shared.trigger(.selection); router.navigateToPage(id: page.id) }) { SourceCardView(page: page) }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, DesignSystem.atomic / 2)
                }
            }
        }
    }

    private var taskCenterLinkSection: some View {
        Button(action: { HapticFeedback.shared.trigger(.selection); router.navigateToTool(.taskCenter) }) {
            HStack {
                Image(systemName: "clock.arrow.circlepath").font(.subheadline.bold()).foregroundStyle(.appAccent)
                VStack(alignment: .leading, spacing: 2) {
                    let runningCount = TaskCenter.shared.tasks.filter({ $0.type == .ingest && isRunning(status: $0.status) }).count
                    Text(L10n.Ingest.trf("activeTasks", runningCount)).font(.system(size: 11, weight: .bold)).foregroundStyle(.appText)
                    Text(L10n.Ingest.tr("recentActivity")).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.appSecondary)
            }
            .padding(DesignSystem.standardPadding).background(Color.appCard.opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
        }.buttonStyle(.plain)
    }

    private var recentActivitiesSection: some View {
        let ingestTasks = TaskCenter.shared.tasks.filter { $0.type == .ingest }
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("recent"), icon: "list.bullet.rectangle").padding(.horizontal, DesignSystem.atomic * 2)
            if ingestTasks.isEmpty {
                VStack(spacing: DesignSystem.tightPadding) {
                    Image(systemName: "clock").font(.title2).foregroundStyle(.appSecondary.opacity(DesignSystem.dimmedOpacity))
                    Text(L10n.Ingest.tr("noActivities")).font(.caption).foregroundStyle(.appSecondary)
                }.frame(maxWidth: .infinity).padding(.vertical, DesignSystem.loosePadding).appContainer()
            } else {
                VStack(spacing: 0) {
                    ForEach(ingestTasks.prefix(DesignSystem.Metrics.maxRecentItems)) { task in
                        ActivityRow(task: task)
                        if task.id != ingestTasks.prefix(DesignSystem.Metrics.maxRecentItems).last?.id { Divider().padding(.leading, DesignSystem.Metrics.largeIconBoxSize) }
                    }
                }.appContainer(padding: false)
            }
        }
    }

    private var manualFormSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n.Creation.tr("basicInfo"))) {
                    TextField(L10n.Creation.tr("pageTitle"), text: $newTitle).font(.headline)
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Text(L10n.Creation.tr("pageType")).font(.caption.weight(.medium)).foregroundStyle(.appSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.small) {
                                ForEach(PageType.allCases, id: \.self) { type in
                                    Button(action: { HapticFeedback.shared.trigger(.selection); withAnimation(.spring(response: 0.3)) { newType = type } }) {
                                        HStack(spacing: 6) { Image(systemName: type.icon); Text(type.displayName) }
                                        .font(.subheadline.weight(newType == type ? .bold : .medium)).padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(newType == type ? Color.fromModelColorName(type.colorName).opacity(0.2) : Color.appCard.opacity(0.8))
                                        .foregroundStyle(newType == type ? Color.fromModelColorName(type.colorName) : .appSecondary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(newType == type ? Color.fromModelColorName(type.colorName).opacity(0.3) : Color.appBorder, lineWidth: 1))
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.horizontal, 1)
                        }
                    }.padding(.vertical, DesignSystem.tiny)
                    NavigationLink(destination: IconPickerView(selectedIcon: $newCustomIcon)) {
                        HStack {
                            Label(L10n.Creation.tr("customIcon"), systemImage: "star.square.fill")
                            Spacer()
                            if let icon = newCustomIcon { Image(systemName: icon).font(.title3).foregroundStyle(.appAccent).padding(DesignSystem.tiny).background(Color.appAccent.opacity(0.1)).clipShape(Circle())
                            } else { Text(L10n.Common.tr("none")).foregroundColor(.appSecondary).font(.subheadline) }
                        }
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Label(L10n.Ingest.tr("smartIngest"), systemImage: "sparkles").font(.subheadline.bold()).foregroundStyle(.appAccent)
                            Spacer(); Toggle("", isOn: $useSmartIngest).labelsHidden().tint(.appAccent)
                        }
                        if useSmartIngest { Text(L10n.Ingest.tr("smartIngestDesc")).font(.system(size: DesignSystem.captionFontSize)).foregroundStyle(.appSecondary).lineLimit(2).fixedSize(horizontal: false, vertical: true) }
                    }.padding(.vertical, DesignSystem.tiny)
                }
                Section(header: Text(L10n.Creation.tr("content"))) {
                    Group {
                        if appEnv.interactionStyle == .crown { TextField("", text: $newContent) }
                        else { TextEditor(text: $newContent) }
                    }.frame(minHeight: DesignSystem.Metrics.heroValueSize * 7.7)
                }
            }
            .scrollContentBackground(.hidden).background(themeManager.pageBackground()).navigationTitle(manualFormTitle).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.Common.tr("cancel")) { showManualForm = false } }
                ToolbarItem(placement: .confirmationAction) { Button(L10n.Common.tr("import")) { performIngest() }.disabled(newTitle.isEmpty || newContent.isEmpty || isIngesting) }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result {
            for url in urls {
                let _ = url.startAccessingSecurityScopedResource()
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("importingFile"), target: url.lastPathComponent)
                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let page = await store.ingestService.ingestDocument(at: url, pageStore: store)
                    await MainActor.run {
                        if let _ = page { TaskCenter.shared.updateTask(taskID, status: .completed); HapticFeedback.shared.trigger(.success) }
                        else { TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed"))); HapticFeedback.shared.trigger(.error) }
                    }
                }
            }
        } else if case .failure(let error) = result { errorMessage = error.localizedDescription; showError = true }
    }

    private func handleURLImport() {
        guard let url = URL(string: newURL) else { errorMessage = L10n.Ingest.tr("invalidURL"); showError = true; return }
        showURLImport = false
        let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("fetchingURL"), target: url.host ?? url.absoluteString)
        Task {
            let page = try? await store.ingestService.ingestURL(urlString: url.absoluteString, pageStore: store)
            await MainActor.run {
                if let _ = page { TaskCenter.shared.updateTask(taskID, status: .completed); HapticFeedback.shared.trigger(.success); newURL = "" }
                else { TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed"))); HapticFeedback.shared.trigger(.error) }
            }
        }
    }

    private func performClipboardImport() {
        if let content = AppPasteboard.string, !content.isEmpty {
            self.newTitle = String(content.prefix(20)); self.newContent = content; self.manualFormTitle = L10n.Ingest.tr("manualEntry"); self.showManualForm = true
        }
    }

    private func performIngest() {
        isIngesting = true
        let title = newTitle, content = newContent, type = newType, icon = newCustomIcon
        Task {
            var finalPage: KnowledgePage?
            do { finalPage = try await ingestStore.performIngest(title: title, content: content, type: type, tags: [], customIcon: icon, useSmart: useSmartIngest, useDeepScan: true) }
            catch { Logger.shared.error("Failed to ingest: \(error)") }
            if let page = finalPage, let icon = icon { var updated = page; updated.customIcon = icon; store.updatePage(updated, forceDeepScan: true) }
            await MainActor.run {
                isIngesting = false
                if finalPage != nil { showManualForm = false; newTitle = ""; newContent = ""; newCustomIcon = nil; HapticFeedback.shared.trigger(.success) }
                else { errorMessage = L10n.Ingest.tr("importFailed"); showError = true; HapticFeedback.shared.trigger(.error) }
            }
        }
    }
    
    private func isRunning(status: TaskStatus) -> Bool { if case .running = status { return true }; return false }
}

// MARK: - 辅助子视图
struct SourceCardView: View {
    let page: KnowledgePage
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack {
                ZStack {
                    Circle().fill(Color.fromModelColorName(page.type.colorName).opacity(DesignSystem.glassOpacity * 1.2)).frame(width: DesignSystem.Metrics.smallIconBoxSize, height: DesignSystem.Metrics.smallIconBoxSize)
                    Image(systemName: page.type.icon).font(.system(size: DesignSystem.iconTiny, weight: .bold)).foregroundStyle(Color.fromModelColorName(page.type.colorName))
                }
                Spacer()
                if let url = page.sourceURL { Image(systemName: url.contains("http") ? "link" : "doc.fill").font(.system(size: DesignSystem.iconTiny - DesignSystem.atomic)).foregroundStyle(.appSecondary.opacity(DesignSystem.dimmedOpacity)) }
            }
            Text(page.title).font(.system(size: DesignSystem.captionFontSize + DesignSystem.atomic / 2, weight: .bold)).lineLimit(2).foregroundStyle(.appText)
            Spacer()
            HStack {
                Text(page.created.formatted(.relative(presentation: .named).locale(Localized.currentLocale))).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
                Spacer()
                Text(L10n.Common.trf("wordCount", page.wordCount)).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.appSecondary)
            }
        }.padding(DesignSystem.medium).frame(width: DesignSystem.Metrics.sourceCardWidth, height: DesignSystem.Metrics.sourceCardHeight).appMetricCardStyle(color: Color.fromModelColorName(page.type.colorName), cornerRadius: DesignSystem.standardRadius)
    }
}

struct ActivityRow: View {
    let task: GlobalTask
    @Environment(Router.self) var router
    var body: some View {
        Button(action: { if let id = task.associatedPageID { HapticFeedback.shared.trigger(.selection); router.navigateToPage(id: id) } }) {
            HStack(spacing: DesignSystem.medium) {
                ZStack {
                    Circle().fill(taskColor.opacity(DesignSystem.glassOpacity)).frame(width: DesignSystem.Metrics.smallIconBoxSize + DesignSystem.atomic * 2, height: DesignSystem.Metrics.smallIconBoxSize + DesignSystem.atomic * 2)
                    Image(systemName: taskIcon).font(.system(size: DesignSystem.subheadlineFontSize)).foregroundStyle(taskColor)
                }
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(task.name + ": " + task.target).font(.system(size: DesignSystem.subheadlineFontSize, weight: .medium)).foregroundStyle(.appText).lineLimit(1)
                    Text(task.startTime.formatted(Date.FormatStyle(locale: Localized.currentLocale))).font(.system(size: DesignSystem.captionFontSize)).foregroundStyle(.appSecondary)
                }
                Spacer()
                if task.associatedPageID != nil { Image(systemName: "chevron.right").font(.system(size: DesignSystem.captionFontSize, weight: .bold)).foregroundStyle(.appSecondary.opacity(DesignSystem.disabledOpacity)) }
            }.padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic).padding(.horizontal, DesignSystem.medium)
        }.buttonStyle(.plain)
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
