//
//  UserProfileView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：个人资料展示与编辑视图，包含头像选择与上传、昵称修改，以及套餐限额监控。
//

import SwiftUI
import PhotosUI

/// 个人资料及套餐详情视图
@MainActor
public struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - 状态属性

    /// 当前编辑的昵称
    @State private var nickname: String = ""
    /// 用户通过 PhotosPicker 选中的图片项
    @State private var selectedItem: PhotosPickerItem?
    /// 是否正在上传头像
    @State private var isUploading = false
    /// 是否正在保存资料
    @State private var isSaving = false
    /// Toast 提示文字
    @State private var toastMessage: String?
    /// 是否显示 Toast
    @State private var showToastOverlay = false
    /// 是否显示升级 Sheet
    @State private var isShowingUpgrade = false

    // MARK: - 初始化

    public init() {}

    // MARK: - 视图主体

    public var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignSystem.large) {
                        // 1. 头像区
                        avatarSection

                        // 2. 基本信息表单
                        infoFormSection

                        // 3. 套餐与额度展示
                        quotaSection
                    }
                    .padding(DesignSystem.medium)
                }

                // 4. 保存按钮
                saveButtonArea
            }

            // 提示弹窗（使用正确签名：isLoading + message）
            AppLoadingOverlay(
                isLoading: showToastOverlay,
                message: toastMessage
            )
            .transition(.opacity)
        }
        .navigationTitle(L10n.Auth.profileAndQuota)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Common.close) {
                    dismiss()
                }
            }
        }
        .onAppear {
            // 从当前登录用户初始化昵称
            if let user = authService.currentUser {
                nickname = user.name
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            if let item = newItem {
                handleAvatarUpload(item)
            }
        }
        .sheet(isPresented: $isShowingUpgrade) {
            NavigationStack {
                SubscriptionUpgradeView()
            }
            .environmentObject(themeManager)
        }
    }

    // MARK: - 子视图组件

    /// 头像修改区域（包含 PhotosPicker 触发与上传 Loading 覆层）
    private var avatarSection: some View {
        VStack(spacing: DesignSystem.small) {
            ZStack {
                // 显示现有头像或默认占位图
                if let avatarURL = authService.currentUser?.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                } else {
                    Image(systemName: DesignSystem.Icons.personCropFill)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                        .foregroundStyle(.appSecondary)
                }

                // 上传过程中显示遮罩
                if isUploading {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 88, height: 88)
                    ProgressView()
                        .tint(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.appAccent.opacity(0.2), lineWidth: 2)
            )

            // 打开相册的胶囊按钮
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text(L10n.Auth.avatar)
                    .font(.caption.bold())
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, DesignSystem.medium)
                    .padding(.vertical, DesignSystem.tiny)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
            }
            .disabled(isUploading)
        }
        .padding(.vertical, DesignSystem.medium)
    }

    /// 昵称修改表单区域
    private var infoFormSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                Text(L10n.Auth.nickname)
                    .font(.caption.bold())
                    .foregroundStyle(.appSecondary)

                // AppTextField 正确参数顺序：placeholder: 在前，text: 在后
                AppTextField(
                    placeholder: L10n.Auth.identityPlaceholder,
                    text: $nickname
                )
                .accessibilityIdentifier("nicknameTextField")
            }
            .padding(DesignSystem.medium)
        }
    }

    /// 配额展示区（金库数、知识页、插件数）
    private var quotaSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DesignSystem.large) {
                // 头部：当前套餐类型 + 升级按钮
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                        Text(L10n.Auth.currentSubscription)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)

                        Text(authService.currentUser?.planKey == "pro"
                             ? L10n.Auth.proPlan
                             : L10n.Auth.litePlan)
                            .font(.title3.bold())
                            .foregroundStyle(.appText)
                    }

                    Spacer()

                    // 仅 Lite 用户展示升级按钮
                    if authService.currentUser?.planKey != "pro" {
                        Button(action: { isShowingUpgrade = true }) {
                            Text(L10n.Auth.upgradePro)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, DesignSystem.medium)
                                .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic)
                                .background(Color.appAccent)
                                .clipShape(Capsule())
                        }
                    }
                }

                AppDivider()

                // 1. 金库限额（通过 VaultService.shared 获取，不依赖 AppStore）
                let vaultsCount = VaultService.shared.vaults.count
                let vaultsMax = authService.currentUser?.maxVaults ?? 2
                quotaRow(
                    title: L10n.Auth.vaultUsage,
                    current: vaultsCount,
                    max: vaultsMax
                )

                // 2. 知识页数限额
                let pagesCount = VaultService.shared.vaults.reduce(0) { $0 + $1.pageCount }
                let pagesMax = authService.currentUser?.maxPages ?? 1000
                quotaRow(
                    title: L10n.Auth.pagesUsage,
                    current: pagesCount,
                    max: pagesMax
                )

                // 3. 插件限额
                let pluginsCount = PluginRegistry.shared.plugins.count
                let pluginsMax = authService.currentUser?.maxPlugins ?? 3
                quotaRow(
                    title: L10n.Auth.pluginsUsage,
                    current: pluginsCount,
                    max: pluginsMax
                )
            }
            .padding(DesignSystem.medium)
        }
    }

    /// 配额监控子行：标题 + 当前/上限数字 + 进度条
    private func quotaRow(title: String, current: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.appText)
                Spacer()
                Text("\(current) / \(max < 999999 ? "\(max)" : "∞")")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.appSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBorder.opacity(0.5))
                        .frame(height: 6)

                    let ratio = max > 0 ? CGFloat(current) / CGFloat(max) : 0.0
                    let fillWidth = max >= 999999 ? 0.0 : min(1.0, ratio) * geo.size.width

                    Capsule()
                        .fill(ratio >= 1.0 && max < 999999 ? Color.red : Color.appAccent)
                        .frame(width: max >= 999999 ? geo.size.width : fillWidth, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    /// 底部保存按钮区域
    private var saveButtonArea: some View {
        VStack {
            AppDivider()

            AppPrimaryButton(title: L10n.Auth.saveChanges, isLoading: isSaving) {
                handleProfileSave()
            }
            .padding(.horizontal, DesignSystem.medium)
            .padding(.vertical, DesignSystem.small)
        }
        .background(Color.appCard.opacity(DesignSystem.glassOpacity))
    }

    // MARK: - 业务操作

    /// 从 PhotosPicker 选取图片后触发上传流程
    private func handleAvatarUpload(_ item: PhotosPickerItem) {
        Task {
            isUploading = true
            presentToast(L10n.Auth.uploadingAvatar)
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let avatarURL = await authService.uploadAvatar(imageData: data) {
                        let success = await authService.updateUserProfile(
                            nickname: nickname,
                            avatar: avatarURL
                        )
                        presentToast(success ? L10n.Auth.uploadSuccess : L10n.Auth.uploadFailed)
                    } else {
                        presentToast(L10n.Auth.uploadFailed)
                    }
                }
            } catch {
                presentToast(L10n.Auth.uploadFailed)
            }
            isUploading = false
        }
    }

    /// 点击"保存修改"后触发昵称（及现有头像 URL）更新
    private func handleProfileSave() {
        Task {
            isSaving = true
            let avatarString = authService.currentUser?.avatarURL?.absoluteString
            let success = await authService.updateUserProfile(
                nickname: nickname,
                avatar: avatarString
            )
            isSaving = false
            if success {
                presentToast(L10n.Auth.saveSuccess)
                // 延迟 1.2 秒后自动关闭 Sheet
                try? await Task.sleep(for: .seconds(1.2))
                dismiss()
            } else {
                presentToast(L10n.Auth.saveFailed)
            }
        }
    }

    /// 展示 Toast 覆层（2 秒后自动消失）
    private func presentToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showToastOverlay = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation {
                showToastOverlay = false
                toastMessage = nil
            }
        }
    }
}
