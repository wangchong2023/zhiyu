// NotebookFormSheet.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本创建与编辑表单。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
struct CreateNotebookSheet: View {
    @Bindable var viewModel: NotebookHubViewModel
    var body: some View {
        NotebookFormSheet(
            title: L10n.Vault.new,
            submitLabel: L10n.Vault.create,
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
            title: L10n.Vault.edit,
            submitLabel: L10n.Common.save,
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
                            
                            Text(L10n.Vault.iconLabel)
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
                                Text(L10n.Vault.nameLabel)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                TextField(L10n.Vault.namePlaceholder, text: $name)
                                    .font(.title3.bold())
                                    .padding()
                                    .background(Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                                Text(L10n.Vault.descriptionLabel)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                
                                TextField(L10n.Vault.descriptionPlaceholder, text: $description, axis: .vertical)
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
                    Button(L10n.Common.cancel) {
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
