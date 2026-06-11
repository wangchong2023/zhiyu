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
    /// 当前选择的性别（0:未知, 1:男, 2:女）
    @State private var gender: Int = 0
    /// 当前选择的生日
    @State private var birthday: Date = Date()
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
                    }
                    .padding(DesignSystem.medium)
                }

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
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(L10n.Common.done) {
                        handleProfileSave()
                    }
                }
            }
        }
        .onAppear {
            // 从当前登录用户初始化昵称、性别、生日
            if let user = authService.currentUser {
                nickname = user.name
                gender = user.gender ?? 0
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if let birthdayString = user.birthday,
                   let date = formatter.date(from: birthdayString) {
                    birthday = date
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            if let item = newItem {
                handleAvatarUpload(item)
            }
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
                    // swiftlint:disable:next magic_numbers_frame
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                } else {
                    Image(systemName: DesignSystem.Icons.personCropFill)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        // swiftlint:disable:next magic_numbers_frame
                        .frame(width: 88, height: 88)
                        .foregroundStyle(.appSecondary)
                }

                // 上传过程中显示遮罩
                if isUploading {
                    Circle()
                        .fill(Color.black.opacity(DesignSystem.Opacity.disabled))
                        // swiftlint:disable:next magic_numbers_frame
                        .frame(width: 88, height: 88)
                    ProgressView()
                        .tint(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.appAccent.opacity(DesignSystem.Opacity.medium), lineWidth: 2)
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
                    .background(Color.appAccent.opacity(DesignSystem.Opacity.subtle))
                    .clipShape(Capsule())
            }
            .disabled(isUploading)
        }
        .padding(.vertical, DesignSystem.medium)
    }

    /// 昵称修改表单区域
    private var infoFormSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DesignSystem.large) {
                // 账号 ID (不可修改)
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    Text(L10n.Auth.accountId)
                        .font(.caption.bold())
                        .foregroundStyle(.appSecondary)
                    Text(authService.currentUser?.id.uuidString ?? "-")
                        .font(.subheadline)
                        .foregroundStyle(.appText)
                        .textSelection(.enabled)
                }
                
                // 手机号（如果通过短信登录则展示，不可修改）
                if let phone = authService.currentUser?.phone, !phone.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        Text(L10n.Auth.phoneLabel)
                            .font(.caption.bold())
                            .foregroundStyle(.appSecondary)
                        Text(phone)
                            .font(.subheadline)
                            .foregroundStyle(.appText)
                    }
                }

                // 昵称修改
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    Text(L10n.Auth.nickname)
                        .font(.caption.bold())
                        .foregroundStyle(.appSecondary)

                    // AppTextField 正确参数顺序：placeholder: 在前，text: 在后
                    AppTextField(
                        placeholder: L10n.Auth.nicknamePlaceholder,
                        text: $nickname
                    )
                    .accessibilityIdentifier("nicknameTextField")
                }
                
                // 性别选择
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    Text(L10n.Auth.gender)
                        .font(.caption.bold())
                        .foregroundStyle(.appSecondary)
                    
                    Picker("", selection: $gender) {
                        Text(L10n.Auth.genderSecret).tag(0)
                        Text(L10n.Auth.genderMale).tag(1)
                        Text(L10n.Auth.genderFemale).tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                // 生日选择
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    Text(L10n.Auth.birthday)
                        .font(.caption.bold())
                        .foregroundStyle(.appSecondary)
                    
                    DatePicker("", selection: $birthday, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale.current)
                }
            }
            .padding(DesignSystem.medium)
        }
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

    /// 点击"保存修改"后触发昵称（及现有头像 URL）、性别和生日更新
    private func handleProfileSave() {
        Task {
            isSaving = true
            let avatarString = authService.currentUser?.avatarURL?.absoluteString
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let birthdayString = formatter.string(from: birthday)
            
            let success = await authService.updateUserProfile(
                nickname: nickname,
                avatar: avatarString,
                gender: gender,
                birthday: birthdayString
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
