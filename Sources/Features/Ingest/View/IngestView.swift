// IngestView.swift
//
// 作者: Wang Chong
// 功能说明: 知识摄入（Ingest）功能主视图，协调多渠道导入流程。
// 版本: 1.3
// 修改记录:
//   - 2026-05-15: 引入 IngestCoordinator 实现业务逻辑与 UI 状态的彻底解耦。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI
import UniformTypeIdentifiers

// MARK: - 视图核心
struct IngestView: View {
    @Environment(AppStore.self) var store
    @Environment(IngestStore.self) var ingestStore
    @Environment(Router.self) var router
    @EnvironmentObject var llmService: LLMService
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: AppTab
    
    // 使用专门的协调器管理状态与流程
    @State private var coordinator = IngestCoordinator()

    var body: some View {
        ZStack {
            themeManager.pageBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.standardPadding + DesignSystem.small) {
                    if !coordinator.isLLMConfigured { llmWarningSection }
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
        .alert(L10n.Ingest.tr("error"), isPresented: $coordinator.showError) {
            Button(L10n.Ingest.tr("ok")) { coordinator.errorMessage = nil }
        } message: { Text(coordinator.errorMessage ?? "") }
        #if !os(watchOS)
        .fileImporter(
            isPresented: $coordinator.showFileImporter,
            allowedContentTypes: [.pdf, .text, .plainText, UTType("net.daringfireball.markdown")].compactMap({$0}),
            allowsMultipleSelection: true
        ) { coordinator.handleFileImport($0) }
        #endif
        .sheet(isPresented: $coordinator.showVoiceNote, onDismiss: { if !coordinator.newTitle.isEmpty { coordinator.showManualForm = true } }) {
            VoiceNoteView(onFinish: { coordinator.newTitle = $0; coordinator.newContent = $1; coordinator.manualFormTitle = Localized.tr("speech.title") })
        }
        .sheet(isPresented: $coordinator.showOCRScan, onDismiss: { if !coordinator.newTitle.isEmpty { coordinator.showManualForm = true } }) {
            OCRScanView(onFinish: { coordinator.newTitle = $0; coordinator.newContent = $1; coordinator.manualFormTitle = Localized.tr("ocr.title") })
        }
        .sheet(isPresented: $coordinator.showURLImport) { URLImportSheet(urlText: $coordinator.newURL, onImport: { coordinator.handleURLImport() }) }
        .sheet(isPresented: $coordinator.showManualForm) { manualFormSheet }
        .onReceive(NotificationCenter.default.publisher(for: .importFromClipboard)) { _ in coordinator.performClipboardImport() }
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
                showManualForm: Binding(get: { coordinator.showManualForm }, set: { if $0 { coordinator.manualFormTitle = L10n.Ingest.tr("manualEntry") }; coordinator.showManualForm = $0 }),
                showOCRScan: $coordinator.showOCRScan, 
                newType: $coordinator.newType, 
                showFileImporter: $coordinator.showFileImporter, 
                showVoiceNote: $coordinator.showVoiceNote, 
                showURLImport: $coordinator.showURLImport
            )
            .appContainer(padding: true)
            .disabled(!coordinator.isLLMConfigured).opacity(coordinator.isLLMConfigured ? DesignSystem.fullOpacity : DesignSystem.disabledOpacity)
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
            .appContainer(padding: true)
        }.buttonStyle(.plain)
    }

    private var recentActivitiesSection: some View {
        let ingestTasks = TaskCenter.shared.tasks.filter { $0.type == .ingest }
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.tr("recent"), icon: "list.bullet.rectangle").padding(.horizontal, DesignSystem.atomic * 2)
            if ingestTasks.isEmpty {
                VStack(spacing: DesignSystem.tightPadding) {
                    Image(systemName: DesignSystem.Icons.clock).font(.title2).foregroundStyle(.appSecondary.opacity(DesignSystem.dimmedOpacity))
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
                    TextField(L10n.Creation.tr("pageTitle"), text: $coordinator.newTitle).font(.headline)
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Text(L10n.Creation.tr("pageType")).font(.caption.weight(.medium)).foregroundStyle(.appSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.small) {
                                ForEach(PageType.allCases, id: \.self) { type in
                                    Button(action: { HapticFeedback.shared.trigger(.selection); withAnimation(.spring(response: 0.3)) { coordinator.newType = type } }) {
                                        HStack(spacing: 6) { Image(systemName: type.icon); Text(type.displayName) }
                                        .font(.subheadline.weight(coordinator.newType == type ? .bold : .medium)).padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(coordinator.newType == type ? Color.fromModelColorName(type.colorName).opacity(0.2) : Color.appCard.opacity(0.8))
                                        .foregroundStyle(coordinator.newType == type ? Color.fromModelColorName(type.colorName) : .appSecondary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(coordinator.newType == type ? Color.fromModelColorName(type.colorName).opacity(0.3) : Color.appBorder, lineWidth: 1))
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.horizontal, 1)
                        }
                    }.padding(.vertical, DesignSystem.tiny)
                    NavigationLink(destination: IconPickerView(selectedIcon: $coordinator.newCustomIcon)) {
                        HStack {
                            Label(L10n.Creation.tr("customIcon"), systemImage: "star.square.fill")
                            Spacer()
                            if let icon = coordinator.newCustomIcon { Image(systemName: icon).font(.title3).foregroundStyle(.appAccent).padding(DesignSystem.tiny).background(Color.appAccent.opacity(0.1)).clipShape(Circle())
                            } else { Text(L10n.Common.tr("none")).foregroundColor(.appSecondary).font(.subheadline) }
                        }
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Label(L10n.Ingest.tr("smartIngest"), systemImage: DesignSystem.Icons.sparkles).font(.subheadline.bold()).foregroundStyle(.appAccent)
                            Spacer(); Toggle("", isOn: $coordinator.useSmartIngest).labelsHidden().tint(.appAccent)
                        }
                        if coordinator.useSmartIngest { Text(L10n.Ingest.tr("smartIngestDesc")).font(.system(size: DesignSystem.captionFontSize)).foregroundStyle(.appSecondary).lineLimit(2).fixedSize(horizontal: false, vertical: true) }
                    }.padding(.vertical, DesignSystem.tiny)
                }
                Section(header: Text(L10n.Creation.tr("content"))) {
                    Group {
                        #if os(watchOS)
                        TextField("", text: $coordinator.newContent, axis: .vertical)
                        #else
                        // 这里使用全局环境注入的 appEnv 来判断交互样式
                        if ServiceContainer.shared.resolve((any AppEnvironmentProtocol).self).interactionStyle == InteractionStyle.crown {
                            TextField("", text: $coordinator.newContent, axis: .vertical)
                        } else {
                            TextEditor(text: $coordinator.newContent)
                        }
                        #endif
                    }.frame(minHeight: DesignSystem.Metrics.heroValueSize * 7.7)
                }
            }
            .scrollContentBackground(.hidden).background(themeManager.pageBackground()).navigationTitle(coordinator.manualFormTitle).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.Common.tr("cancel")) { coordinator.showManualForm = false }.buttonStyle(.plain) }
                ToolbarItem(placement: .confirmationAction) { Button(L10n.Common.tr("import")) { coordinator.performIngest() }.disabled(coordinator.newTitle.isEmpty || coordinator.newContent.isEmpty || coordinator.isIngesting).buttonStyle(.plain) }
            }
        }
    }

    private func isRunning(status: TaskStatus) -> Bool { if case .running = status { return true }; return false }
}
