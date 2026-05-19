// OnDeviceLLMSettingsView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：OnDeviceLLMSettingsView
// 负责在 UI 中提供直接管理 CoreML、Apple Intelligence 模型的控制中心，完美对齐智宇 (ZhiYu) 全局磨砂毛玻璃视觉风格。
// 版本: 1.1
// 修改记录:
//   - 2026-05-19: 新建文件并完美物理归位，引入极致毛玻璃材质（Glassmorphism）、完整的简体中文注释与 Swift 6 并发安全。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

@preconcurrency import SwiftUI
import UniformTypeIdentifiers

// MARK: - On-Device LLM Settings View
/// 设备端本地大模型配置面板视图
/// 用户可在该控制中心查看端侧 AI 可用性、检索并一键加载内置/外置 Core ML 语言模型、执行端侧推理基准测试（Playground），全面掌握离线隐私知识图谱的合成效率。
@MainActor
public struct OnDeviceLLMSettingsView: View {
    /// 独立托管的端侧推理及编译生命周期服务
    @StateObject private var onDeviceService = OnDeviceLLMService()
    
    /// 全局应用级数据 Store
    @Environment(AppStore.self) var store
    
    /// 全局主题美学管理器，驱动毛玻璃材质投影
    @EnvironmentObject var themeManager: ThemeManager
    
    /// 兼容引入全局云端 LLM 服务，便于后续做端云混合调度
    @EnvironmentObject var llmService: LLMService
    
    /// Haptic 触感生成器
    @State private var feedbackGenerator = UINotificationFeedbackGenerator()
    
    /// 对话测试沙盒 Prompt
    @State private var testPrompt = ""
    
    /// 对话推理生成的结果缓存
    @State private var testResult = ""
    
    /// 是否弹出文件导入器选择本地模型
    @State private var showImportPicker = false
    
    /// 是否弹出 Playground 测试调试 Sheet
    @State private var showTestSheet = false
    
    /// 是否弹出错误弹窗
    @State private var showError = false
    
    /// 具体的错误描述文字
    @State private var errorMessage = ""

    public init() {}

    public var body: some View {
        ZStack {
            // 背景统一使用主题管理器驱动的通透背景，透射毛玻璃
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            Form {
                // HERO 标头区域
                Section {
                    headerSection
                }
                .appListRowBackground()
                
                // 1. 可用性与硬件检测区域
                Section(header: Text(Localized.tr("ondevice.available", table: "AI"))) {
                    availabilitySection
                }
                .appListRowBackground()
                
                // 2. 本地可用模型选型列表
                Section(header: Text(Localized.tr("ondevice.models", table: "AI"))) {
                    modelSelectionSection
                }
                .appListRowBackground()
                
                // 3. 模型生命周期装载/卸载与文件导入
                Section(header: Text(Localized.tr("ondevice.loadModel", table: "AI"))) {
                    modelManagementSection
                }
                .appListRowBackground()
                
                // 4. 离线基准性能测试 Playground
                Section(header: Text(Localized.tr("ondevice.test", table: "AI"))) {
                    testSection
                }
                .appListRowBackground()
                
                // 5. 离线隐私与安全声明
                Section(header: Text(Localized.tr("ondevice.info", table: "AI"))) {
                    infoSection
                }
                .appListRowBackground()
            }
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden) // 隐藏 Form 默认的白色背景，实现高端毛玻璃穿透
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(L10n.Settings.onDeviceLLM)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $showTestSheet) {
            OnDeviceTestView(onDeviceService: onDeviceService)
        }
        .alert(Localized.tr("ondevice.error.inferenceFailed", table: "AI"), isPresented: $showError) {
            Button(L10n.Common.tr("ok"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            onDeviceService.discoverModels()
        }
    }
    
    // MARK: - Hero Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 4)
            Image(systemName: "cpu")
                .font(.system(size: DesignSystem.displayFontSize * 1.3))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appSource, .appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appAccent.opacity(0.3), radius: 8, y: 4)
            
            Text(Localized.tr("ondevice.subtitle", table: "AI"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
    
    // MARK: - 可用性与硬件参数视图
    private var availabilitySection: some View {
        HStack(spacing: 14) {
            Image(systemName: onDeviceService.isAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(onDeviceService.isAvailable ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(onDeviceService.isAvailable ? Localized.tr("ondevice.available", table: "AI") : Localized.tr("ondevice.unavailable", table: "AI"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                
                if onDeviceService.isAvailable {
                    if #available(iOS 18.2, *) {
                        Text(Localized.tr("ondevice.supportsFoundation", table: "AI"))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(Localized.tr("ondevice.supportsCoreML", table: "AI"))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                } else {
                    Text(Localized.tr("ondevice.requiresIOS17", table: "AI"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 模型选型列表
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if onDeviceService.availableModels.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.dashed")
                        .font(.title3)
                        .foregroundStyle(.appSecondary)
                    Text(Localized.tr("ondevice.noModels", table: "AI"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                ForEach(onDeviceService.availableModels) { model in
                    OnDeviceModelRow(
                        model: model,
                        isSelected: onDeviceService.selectedModelID == model.id,
                        onSelect: {
                            onDeviceService.selectedModelID = model.id
                            feedbackGenerator.notificationOccurred(.success)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 加载/卸载/管理模型
    private var modelManagementSection: some View {
        VStack(spacing: 12) {
            if onDeviceService.isModelLoaded {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Localized.tr("ondevice.modelLoaded", table: "AI"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.appText)
                        Text(onDeviceService.loadedModelName)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        onDeviceService.unloadModel()
                        feedbackGenerator.notificationOccurred(.warning)
                    }) {
                        Text(Localized.tr("ondevice.unload", table: "AI"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color.appAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            } else {
                Button(action: loadModel) {
                    HStack(spacing: 8) {
                        if onDeviceService.isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(Localized.tr("ondevice.loadModel", table: "AI"))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(onDeviceService.selectedModelID.isEmpty ? Color.gray : Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
                }
                .disabled(onDeviceService.selectedModelID.isEmpty || onDeviceService.isGenerating)
            }
            
            // 物理模型本地导入入口
            Button(action: { showImportPicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: DesignSystem.Icons.importIcon)
                    Text(Localized.tr("ondevice.importModel", table: "AI"))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.appAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            }
            #if !os(watchOS)
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: {
                    var types: [UTType] = []
                    if let ml = UTType(filenameExtension: "mlmodel") { types.append(ml) }
                    if let mlc = UTType(filenameExtension: "mlmodelc") { types.append(mlc) }
                    return types.isEmpty ? [.data] : types
                }(),
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            do {
                                try await onDeviceService.importModel(from: url)
                                feedbackGenerator.notificationOccurred(.success)
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                                feedbackGenerator.notificationOccurred(.error)
                            }
                        }
                    }
                case .failure:
                    break
                }
            }
            #endif
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 测试 Playground 入口
    private var testSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                showTestSheet = true
                feedbackGenerator.notificationOccurred(.success)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                    Text(Localized.tr("ondevice.testGeneration", table: "AI"))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(onDeviceService.isModelLoaded ? Color.green : Color.gray.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            }
            .disabled(!onDeviceService.isModelLoaded)
            
            if onDeviceService.inferenceSpeed > 0 {
                HStack {
                    Label(
                        Localized.tr("ondevice.inferenceSpeed", table: "AI"),
                        systemImage: "gauge.with.needle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f tok/s", onDeviceService.inferenceSpeed))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 隐私和属性提示
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            OnDeviceInfoRow(
                icon: "lock.shield.fill",
                text: Localized.tr("ondevice.info.privacy", table: "AI")
            )
            
            OnDeviceInfoRow(
                icon: "wifi.slash",
                text: Localized.tr("ondevice.info.offline", table: "AI")
            )
            
            OnDeviceInfoRow(
                icon: "bolt.fill",
                text: Localized.tr("ondevice.info.ne", table: "AI")
            )
            
            OnDeviceInfoRow(
                icon: "memorychip.fill",
                text: Localized.tr("ondevice.info.memory", table: "AI")
            )
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - 异步加载模型动作
    private func loadModel() {
        feedbackGenerator.prepare()
        Task {
            do {
                try await onDeviceService.loadModel()
                feedbackGenerator.notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                feedbackGenerator.notificationOccurred(.error)
            }
        }
    }
}
