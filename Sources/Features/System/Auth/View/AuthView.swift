//
//  AuthView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Auth 界面的 UI 视图层组件。
//
import SwiftUI

/// 身份认证主视图
struct AuthView: View {
    @Environment(AuthService.self) var authService
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isAgreementChecked: Bool = true
    @State private var showPrivacySheet: Bool = false
    
    var body: some View {
        ZStack {
            // 背景层
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.huge) { // 增加板块之间的巨型间距 (32px)，让顶部 Header 得到完美释放
                    // 1. Logo & 标语 (品牌展示板块)
                    heroHeader
                    
                    // 2. 一键登录交互板块
                    VStack(spacing: Spacing.large) {
                        // 手机号掩码显示
                        Text("180****6625")
                            .font(.system(size: DesignSystem.titleFontSize * 1.2, weight: .bold, design: .rounded))
                            .foregroundStyle(.appText)
                            .padding(.top, Spacing.medium)
                        
                        // 登录动作按钮
                        actionButton
                        
                        // 协议勾选
                        agreementSection
                        
                        Spacer().frame(height: Spacing.large)
                        
                        // 更多登录方式
                        thirdPartySection
                    }
                    .padding(Spacing.wide)
                    .appContainer(cornerRadius: Spacing.largeRadius)
                    
                    // 3. 游客模式
                    guestButton
                }
                .padding(.horizontal, Spacing.wide)
                .padding(.vertical, Spacing.wide)
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            NavigationStack {
                ZStack {
                    themeManager.pageBackground()
                        .ignoresSafeArea()
                        
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text(L10n.Auth.privacyPolicyContent)
                                .font(.body)
                                .foregroundStyle(.appText)
                                .lineSpacing(Spacing.tiny)
                            
                            Spacer()
                        }
                        .padding()
                        .appListRowBackground()
                        .padding()
                    }
                }
                .navigationTitle(L10n.Auth.privacyPolicyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Common.confirm) {
                            showPrivacySheet = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var heroHeader: some View {
        VStack(spacing: Spacing.giant) { // 增加空气感，给予 Logo 到主标题足够的呼吸空间
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.appAccent.opacity(0.2), .appConcept.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: DesignSystem.Domain.Auth.logoBackgroundSize, height: DesignSystem.Domain.Auth.logoBackgroundSize)
                    .blur(radius: Spacing.shadowRadius)
                
                Image(systemName: DesignSystem.Icons.knowledge)
                    .font(.system(size: DesignSystem.displayFontSize * 1.5))
                    .foregroundStyle(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .appAccent.opacity(0.4), radius: Spacing.shadowRadius, y: Spacing.shadowY)
            }
            
            VStack(spacing: Spacing.small) { // 增加间距到 8px，完全拉开字距，告别拥挤
                Text(L10n.Common.appName)
                    .font(.system(size: DesignSystem.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.appText)
                    .tracking(1)
                
                Text(L10n.Onboarding.subtitle)
                    .font(.system(size: DesignSystem.subheadlineFontSize, weight: .medium)) // 优化字号至 14pt，字重提升，前景色柔和，确保清晰与品质感
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Spacing.wide)
    }
    
    private var actionButton: some View {
        Button(action: handleAuth) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(L10n.Auth.oneClickLogin)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Domain.Auth.actionButtonVerticalPadding)
            .background(Color.appAccent)
            .clipShape(Capsule())
            .shadow(color: Color.appAccent.opacity(0.3), radius: Spacing.shadowRadius, y: Spacing.shadowY)
        }
        .disabled(isLoading)
        .accessibilityIdentifier("oneClickLoginButton")
    }
    
    private var agreementSection: some View {
        HStack(alignment: .top, spacing: Spacing.tightPadding) {
            Button(action: {
                withAnimation { isAgreementChecked.toggle() }
            }) {
                Image(systemName: isAgreementChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAgreementChecked ? Color.appAccent : Color.appSecondary)
                    .font(.system(size: Spacing.smallIconSize))
            }
            .accessibilityIdentifier("agreementCheckbox")
            
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text(LocalizedStringKey(L10n.Auth.agreementText))
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                    .lineSpacing(Spacing.atomic)
                    .environment(\.openURL, OpenURLAction { url in
                        if url.scheme == "privacy" {
                            showPrivacySheet = true
                            return .handled
                        }
                        return .systemAction
                    })
                
                if !isAgreementChecked {
                    Text(L10n.Auth.pleaseCheckAgreement)
                        .font(.caption2)
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(.horizontal, Spacing.small)
    }
    
    private var thirdPartySection: some View {
        VStack(spacing: Spacing.large) {
            HStack {
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: DesignSystem.borderWidth)
                Text(L10n.Auth.moreLoginMethods)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, Spacing.small)
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: DesignSystem.borderWidth)
            }
            
            HStack(spacing: Spacing.large) { // 屏蔽了微信和短信，调整了间距
                /* 暂时屏蔽微信登录
                ThirdPartyIconButton(id: "auth.thirdparty.wechat", icon: "WechatLogo", isSystem: false, color: .green) {
                    if authService.isMockMode {
                        handleThirdPartyLogin(using: WeChatAuthStrategy())
                    } else {
                        ToastManager.shared.show(type: .info, message: L10n.Auth.wechatDeveloping)
                    }
                }
                */
                ThirdPartyIconButton(id: "auth.thirdparty.apple", icon: "apple.logo", isSystem: true, color: .primary) { // Apple登录
                    handleThirdPartyLogin(using: AppleAuthStrategy())
                }
                ThirdPartyIconButton(id: "auth.thirdparty.google", icon: "GoogleLogo", isSystem: false, color: .blue) { // Google登录
                    if authService.isMockMode {
                        handleThirdPartyLogin(using: GoogleAuthStrategy())
                    } else {
                        ToastManager.shared.show(type: .info, message: L10n.Auth.googleDeveloping)
                    }
                }
                ThirdPartyIconButton(id: "auth.thirdparty.github", icon: "GithubLogo", isSystem: false, color: .primary) { // Github登录
                    if authService.isMockMode {
                        handleThirdPartyLogin(using: GitHubAuthStrategy())
                    } else {
                        ToastManager.shared.show(type: .info, message: L10n.Auth.githubDeveloping)
                    }
                }
                /* 暂时屏蔽手机短信登录
                ThirdPartyIconButton(id: "auth.thirdparty.carrier", icon: "iphone.gen1", isSystem: true, color: .appAccent) {
                    if authService.isMockMode {
                        handleThirdPartyLogin(using: CarrierAuthStrategy())
                    } else {
                        ToastManager.shared.show(type: .info, message: L10n.Auth.smsDeveloping)
                    }
                }
                */
            }
        }
    }
    
    private var guestButton: some View {
        Button(action: { authService.continueAsGuest() }) {
            Text(L10n.Auth.guestMode)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .padding(.vertical, Spacing.standardPadding)
                .padding(.horizontal, Spacing.giant)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.borderWidth, dash: [Spacing.tightPadding]))
                        .foregroundStyle(.appBorder)
                )
        }
        .padding(.top, DesignSystem.Domain.Auth.guestButtonTopPadding)
        .accessibilityIdentifier("guestButton")
    }
    
    // MARK: - 逻辑
    
    private func handleAuth() {
        if !isAgreementChecked {
            ToastManager.shared.show(type: .error, message: L10n.Auth.agreementRequired)
            HapticFeedback.shared.trigger(.error)
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            // 使用一键登录策略统一处理登录/注册
            let success = await authService.login(using: CarrierAuthStrategy())
            
            if !success {
                errorMessage = L10n.Auth.authFailed
                HapticFeedback.shared.trigger(.error)
            } else {
                HapticFeedback.shared.trigger(.success)
            }
            
            isLoading = false
        }
    }
    
    /// 触发第三方账号授权登录逻辑
    /// - Parameter strategy: 登录策略
    private func handleThirdPartyLogin(using strategy: any AuthStrategy) {
        if !isAgreementChecked {
            ToastManager.shared.show(type: .error, message: L10n.Auth.agreementRequired)
            HapticFeedback.shared.trigger(.error)
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            let success = await authService.login(using: strategy)
            
            if !success {
                errorMessage = L10n.Auth.authFailed
                HapticFeedback.shared.trigger(.error)
            } else {
                HapticFeedback.shared.trigger(.success)
            }
            
            isLoading = false
        }
    }
}

// MARK: - 辅助组件

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .foregroundStyle(.appSecondary)
                .frame(width: Spacing.wide)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(Color.appCard.opacity(0.8)) // 稍微加深背景，提升文字对比度
        .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.standardRadius)
                .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth) // 移除不透明度，确保清晰
        )
    }
}

struct ThirdPartyButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                // 这里用 SF Symbols 代替实际图标，因为目前没法直接加资源
                Image(systemName: icon == "apple_logo" ? DesignSystem.Icons.apple : (icon == "wechat_logo" ? DesignSystem.Icons.message : DesignSystem.Icons.persons))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.standardRadius)
                    .stroke(Color.appBorder.opacity(DesignSystem.softOpacity), lineWidth: DesignSystem.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}
struct ThirdPartyIconButton: View {
    let id: String
    let icon: String
    let isSystem: Bool
    let color: Color
    let action: () -> Void
    
    init(id: String, icon: String, isSystem: Bool = true, color: Color, action: @escaping () -> Void) {
        self.id = id
        self.icon = icon
        self.isSystem = isSystem
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.appCard)
                    .frame(width: DesignSystem.Domain.Auth.thirdPartyIconContainerSize, height: DesignSystem.Domain.Auth.thirdPartyIconContainerSize)
                    .shadow(color: .primary.opacity(0.05), radius: Spacing.tiny, y: Spacing.atomic)
                
                if isSystem {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.Domain.Auth.thirdPartyIconFontSize))
                        .foregroundStyle(color)
                } else {
                    if icon == "GithubLogo" {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: DesignSystem.Domain.Auth.thirdPartyIconFontSize, height: DesignSystem.Domain.Auth.thirdPartyIconFontSize)
                            .foregroundStyle(color)
                    } else {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: DesignSystem.Domain.Auth.thirdPartyIconFontSize, height: DesignSystem.Domain.Auth.thirdPartyIconFontSize)
                    }
                }
            }
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: DesignSystem.borderWidth) // 根据颜色设置边框，与参考图一致
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
