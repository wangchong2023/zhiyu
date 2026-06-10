//
//  IngestView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Ingest 界面的 UI 视图层组件。
//
@preconcurrency import SwiftUI
import UniformTypeIdentifiers

// MARK: - 视图核心
struct IngestView: View {
    @Environment(KnowledgeStore.self) var store
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
                    ingestProgressPanel
                    actionsSection
                    importSourcesSection
                    ImportRecordSection()
                    if !TaskCenter.shared.tasks.filter({ $0.type == .ingest }).isEmpty { taskCenterLinkSection }
                    recentActivitiesSection
                }
                .padding(.horizontal)
                .padding(.top, DesignSystem.standardPadding)
                .padding(.bottom, DesignSystem.standardPadding * 2)
            }
        }
        .appTabToolbar(title: L10n.Ingest.title)
        .alert(L10n.Ingest.error, isPresented: $coordinator.showError) {
            Button(L10n.Ingest.ok) { coordinator.errorMessage = nil }
        } message: { Text(coordinator.errorMessage ?? "") }
        #if !os(watchOS)
        .fileImporter(
            isPresented: $coordinator.showFileImporter,
            allowedContentTypes: [.pdf, .text, .plainText, UTType("net.daringfireball.markdown")].compactMap({$0}),
            allowsMultipleSelection: true
        ) { coordinator.handleFileImport($0) }
        #endif
        .sheet(isPresented: $coordinator.showVoiceNote, onDismiss: { if !coordinator.newTitle.isEmpty { coordinator.showManualForm = true } }) {
            VoiceNoteView(onFinish: { coordinator.newTitle = $0; coordinator.newContent = $1; coordinator.manualFormTitle = L10n.Voice.Speech.title })
        }
        .sheet(isPresented: $coordinator.showOCRScan, onDismiss: { if !coordinator.newTitle.isEmpty { coordinator.showManualForm = true } }) {
            OCRScanView(onFinish: { coordinator.newTitle = $0; coordinator.newContent = $1; coordinator.manualFormTitle = L10n.Ingest.OCR.title })
        }
        .sheet(isPresented: $coordinator.showURLImport) { URLImportSheet(urlText: $coordinator.newURL, onImport: { coordinator.handleURLImport() }) }
        .sheet(isPresented: $coordinator.showManualForm) { manualFormSheet }
        .onReceive(NotificationCenter.default.publisher(for: .importFromClipboard)) { _ in coordinator.performClipboardImport() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(PageBackgroundView(accentColor: .appSource))
    }

    /// 动态渲染的玻璃态 Ingest 细粒度子状态反馈面板
    private var ingestProgressPanel: some View {
        let runningIngestTasks = TaskCenter.shared.tasks.filter { $0.type == .ingest && isRunning(status: $0.status) }
        guard let activeTask = runningIngestTasks.first else { return AnyView(EmptyView()) }
        
        let (progress, currentStage) = {
            if case .running(let p, let s) = activeTask.status { return (p, s) }
            return (0.0, TaskStage.pending)
        }()
        
        return AnyView(
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                        Text(L10n.Ingest.smartIngest)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                        Text(activeTask.target)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: DesignSystem.captionFontSize, weight: .bold, design: .monospaced))
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.tiny)
                        .background(Color.appAccent.opacity(0.15))
                        .foregroundStyle(Color.appAccent)
                        .clipShape(Capsule())
                }
                
                Divider()
                
                IngestTimelineView(currentStage: currentStage, subLogs: activeTask.subLogs)
                    .padding(.top, DesignSystem.tiny)
            }
            .appContainer(padding: true)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                    .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.appAccent.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var llmWarningSection: some View {
        NavigationLink(value: AppRoute.settings) {
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: DesignSystem.Icons.warning).foregroundStyle(.orange)
                Text(L10n.Ingest.llmRequired).font(.subheadline).foregroundStyle(.appText)
                Spacer()
                Image(systemName: DesignSystem.Icons.forward).font(.caption).foregroundStyle(.appSecondary)
            }
            .padding().background(Color.orange.opacity(DesignSystem.glassOpacity))
        }
        .buttonStyle(.plain)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.actions, icon: DesignSystem.Icons.trayArrowDown).padding(.horizontal, DesignSystem.tiny)
            IngestEntryCardsSection(
                showManualForm: Binding(get: { coordinator.showManualForm }, set: { if $0 { coordinator.manualFormTitle = L10n.Ingest.manualEntry }; coordinator.showManualForm = $0 }),
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
        let sources = store.pages.filter { $0.pageType == .source || $0.sourceURL != nil }.sorted(by: { $0.createdAt > $1.createdAt }).prefix(DesignSystem.Metrics.maxDashboardItems)
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                AppSectionHeader(title: L10n.Ingest.sources, icon: DesignSystem.Icons.trayFill)
                Spacer()
                if !sources.isEmpty { Text("\(sources.count)_items").font(.caption2).foregroundStyle(.appSecondary) }
            }
            .padding(.horizontal, DesignSystem.tiny)
            if sources.isEmpty {
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: DesignSystem.Icons.tray).font(.system(size: DesignSystem.Metrics.dashboardValueSize)).foregroundStyle(.appSecondary.opacity(0.5))
                    Text(L10n.Common.Global.noData).font(.caption).foregroundStyle(.appSecondary)
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
                Image(systemName: DesignSystem.Icons.history).font(.subheadline.bold()).foregroundStyle(.appAccent)
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    let runningCount = TaskCenter.shared.tasks.filter({ $0.type == .ingest && isRunning(status: $0.status) }).count
                    Text(L10n.Ingest.activeTasks(runningCount)).font(.caption.weight(.bold)).foregroundStyle(.appText)
                    Text(L10n.Ingest.recentActivity).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: DesignSystem.Icons.forward).font(.caption2).foregroundStyle(.appSecondary)
            }
            .appContainer(padding: true)
        }.buttonStyle(.plain)
    }

    private var recentActivitiesSection: some View {
        let ingestTasks = TaskCenter.shared.tasks.filter { $0.type == .ingest }
        return VStack(alignment: .leading, spacing: DesignSystem.medium) {
            AppSectionHeader(title: L10n.Ingest.recent, icon: DesignSystem.Icons.listBulletRectangle).padding(.horizontal, DesignSystem.atomic * 2)
            if ingestTasks.isEmpty {
                VStack(spacing: DesignSystem.tightPadding) {
                    Image(systemName: DesignSystem.Icons.clock).font(.title2).foregroundStyle(.appSecondary.opacity(DesignSystem.dimmedOpacity))
                    Text(L10n.Ingest.noActivities).font(.caption).foregroundStyle(.appSecondary)
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
                Section(header: Text(L10n.Creation.basicInfo)) {
                    TextField(L10n.Creation.pageTitle, text: $coordinator.newTitle).font(.headline)
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Text(L10n.Creation.pageType).font(.caption.weight(.medium)).foregroundStyle(.appSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.small) {
                                ForEach(PageType.allCases, id: \.self) { type in
                                    Button(action: { HapticFeedback.shared.trigger(.selection); withAnimation(.spring(response: 0.3)) { coordinator.newType = type } }) {
                                        HStack(spacing: DesignSystem.tightPadding) { Image(systemName: type.icon); Text(type.displayName) }
                                        .font(.subheadline.weight(coordinator.newType == type ? .bold : .medium)).padding(.horizontal, DesignSystem.medium).padding(.vertical, DesignSystem.small)
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
                            Label(L10n.Creation.customIcon, systemImage: DesignSystem.Icons.starSquareFill)
                            Spacer()
                            if let icon = coordinator.newCustomIcon { Image(systemName: icon).font(.title3).foregroundStyle(.appAccent).padding(DesignSystem.tiny).background(Color.appAccent.opacity(0.1)).clipShape(Circle())
                            } else { Text(L10n.Common.none).foregroundColor(.appSecondary).font(.subheadline) }
                        }
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Label(L10n.Ingest.smartIngest, systemImage: DesignSystem.Icons.sparkles).font(.subheadline.bold()).foregroundStyle(.appAccent)
                            Spacer(); Toggle("", isOn: $coordinator.useSmartIngest).labelsHidden().tint(.appAccent)
                        }
                        if coordinator.useSmartIngest { Text(L10n.Ingest.smartIngestDesc).font(.system(size: DesignSystem.captionFontSize)).foregroundStyle(.appSecondary).lineLimit(2).fixedSize(horizontal: false, vertical: true) }
                    }.padding(.vertical, DesignSystem.tiny)
                }
                Section(header: Text(L10n.Creation.content)) {
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
                ToolbarItem(placement: .cancellationAction) { Button(L10n.Common.cancel) { coordinator.showManualForm = false }.buttonStyle(.plain) }
                ToolbarItem(placement: .confirmationAction) { Button(L10n.Common.import) { coordinator.performIngest() }.disabled(coordinator.newTitle.isEmpty || coordinator.newContent.isEmpty || coordinator.isIngesting).buttonStyle(.plain) }
            }
        }
    }

    private func isRunning(status: TaskStatus) -> Bool { if case .running = status { return true }; return false }
}
