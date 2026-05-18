// PluginSettingsGenerator.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 插件声明式 UI 生成器：支持通过 JSON Schema 自动渲染原生 SwiftUI 设置表单
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 插件自定义设置详情视图
struct PluginCustomSettingsView: View {
    let tab: PluginSettingTab
    @Environment(\.dismiss) var dismiss
    
    // 自动双向绑定状态
    @State private var configData: [String: String] = [:]
    @State private var schemaItems: [PluginUISchemaItem] = []
    
    var body: some View {
        Form {
            if schemaItems.isEmpty {
                Section {
                    Text("该插件尚未提供可配置的选项。")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(schemaItems) { item in
                    renderItem(item)
                }
            }
            
            Section {
                Button(action: {
                    // 保存最终快照
                    HapticFeedback.shared.trigger(.success)
                    dismiss()
                }) {
                    Text(L10n.Common.done)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(tab.name)
        .onAppear {
            loadInitialData()
            parseSchema()
        }
    }
    
    private func loadInitialData() {
        // 从加密 Storage 中预加载该插件的所有数据
        self.configData = PluginRegistry.shared.loadAllPluginData(pluginID: tab.pluginID)
    }
    
    private func parseSchema() {
        guard let schemaJson = tab.schema, let data = schemaJson.data(using: .utf8) else { return }
        do {
            let decoded = try JSONDecoder().decode([PluginUISchemaItem].self, from: data)
            self.schemaItems = decoded
        } catch {
            Logger.shared.error("❌ [PluginUI] Schema 解析失败", error: error)
        }
    }
    
    @ViewBuilder
    private func renderItem(_ item: PluginUISchemaItem) -> some View {
        Section(header: item.header != nil ? Text(item.header!) : nil) {
            switch item.type {
            case "toggle":
                Toggle(item.label, isOn: Binding(
                    get: { (configData[item.key] == "true") },
                    set: { newValue in
                        let stringVal = newValue ? "true" : "false"
                        configData[item.key] = stringVal
                        PluginRegistry.shared.savePluginData(pluginID: tab.pluginID, key: item.key, value: stringVal)
                    }
                ))
            case "text":
                TextField(item.label, text: Binding(
                    get: { configData[item.key] ?? "" },
                    set: { newValue in
                        configData[item.key] = newValue
                        PluginRegistry.shared.savePluginData(pluginID: tab.pluginID, key: item.key, value: newValue)
                    }
                ))
            case "info":
                HStack {
                    Text(item.label)
                    Spacer()
                    Text(item.value ?? "").foregroundStyle(.secondary)
                }
            default:
                EmptyView()
            }
        }
    }
}

/// 插件 UI 描述项模型
struct PluginUISchemaItem: Codable, Identifiable {
    var id: String { key }
    let key: String
    let type: String // toggle, text, picker, info
    let label: String
    let header: String?
    let value: String?
}
