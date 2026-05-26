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
    
    @State private var isRegisterMode: Bool = false
    @State private var identity: String = ""
    @State private var password: String = ""
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isAgreementChecked: Bool = false
    
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
                        
                        // 一键登录按钮
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRegisterMode)
    }
    
    // MARK: - 子视图
    
    private var heroHeader: some View {
        VStack(spacing: Spacing.giant) { // 增加空气感，给予 Logo 到主标题足够的呼吸空间
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.appAccent.opacity(0.2), .appConcept.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: DesignSystem.Domain.Auth.logoBackgroundSize, height: DesignSystem.Domain.Auth.logoBackgroundSize)
                    .blur(radius: 10)
                
                Image(systemName: DesignSystem.Icons.knowledge)
                    .font(.system(size: DesignSystem.displayFontSize * 1.5))
                    .foregroundStyle(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .appAccent.opacity(0.4), radius: 10, y: 4)
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
    
    private var modePicker: some View {
        ZStack(alignment: isRegisterMode ? .trailing : .leading) {
            Capsule()
                .fill(Color.appAccent)
                .frame(width: DesignSystem.Domain.Auth.modePickerWidth, height: DesignSystem.Domain.Auth.modePickerHeight)
                .shadow(color: .appAccent.opacity(0.3), radius: 8, y: 4)
            
            HStack(spacing: 0) {
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRegisterMode = false 
                    }
                }) {
                    Text(L10n.Auth.login)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .frame(width: DesignSystem.Domain.Auth.modePickerWidth, height: DesignSystem.Domain.Auth.modePickerHeight)
                        .foregroundStyle(!isRegisterMode ? .white : .appSecondary)
                }
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRegisterMode = true 
                    }
                }) {
                    Text(L10n.Auth.register)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .frame(width: DesignSystem.Domain.Auth.modePickerWidth, height: DesignSystem.Domain.Auth.modePickerHeight)
                        .foregroundStyle(isRegisterMode ? .white : .appSecondary)
                }
            }
        }
        .padding(Spacing.tightPadding)
        .background(Color.appCard.opacity(0.8))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth)) // 增强边框对比度
        .padding(.vertical, Spacing.standardPadding)
    }
    
    private var loginForm: some View {
        VStack(spacing: Spacing.medium) {
            AuthTextField(
                icon: "person.fill",
                placeholder: L10n.Auth.identityPlaceholder, // 手机号/邮箱/微信
                text: $identity
            )
            
            AuthTextField(
                icon: "lock.fill",
                placeholder: L10n.Auth.passwordPlaceholder,
                text: $password,
                isSecure: true
            )
        }
    }
    
    private var registerForm: some View {
        VStack(spacing: Spacing.medium) {
            AuthTextField(
                icon: "iphone",
                placeholder: L10n.Auth.phonePlaceholder,
                text: $phone
            )
            
            HStack(spacing: Spacing.small) {
                AuthTextField(
                    icon: "shield.fill",
                    placeholder: L10n.Auth.codePlaceholder,
                    text: $code
                )
                
                Button(action: {}) {
                    Text(L10n.Auth.getCode)
                        .font(.caption.bold())
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.Domain.Auth.getCodeButtonHorizontalPadding)
                        .padding(.vertical, DesignSystem.Domain.Auth.getCodeButtonVerticalPadding)
                        .background(Color.appAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            AuthTextField(
                icon: "lock.fill",
                placeholder: L10n.Auth.setPasswordPlaceholder,
                text: $password,
                isSecure: true
            )
        }
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
            .shadow(color: Color.appAccent.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(isLoading)
    }
    
    private var agreementSection: some View {
        HStack(alignment: .top, spacing: Spacing.tightPadding) {
            Button(action: {
                withAnimation { isAgreementChecked.toggle() }
            }) {
                Image(systemName: isAgreementChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAgreementChecked ? Color.appAccent : Color.appSecondary)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Auth.agreementText)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                    .lineSpacing(2)
                
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
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: 1)
                Text(L10n.Auth.moreLoginMethods)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, Spacing.small)
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: 1)
            }
            
            HStack(spacing: Spacing.large) { // 加大间距以容纳5个图标
                ThirdPartyIconButton(icon: "WechatLogo", isSystem: false, color: .green) { // 微信登录
                    ToastManager.shared.show(type: .info, message: L10n.Auth.wechatDeveloping)
                }
                ThirdPartyIconButton(icon: "apple.logo", isSystem: true, color: .primary) { // Apple登录
                    handleAppleLogin()
                }
                ThirdPartyIconButton(icon: "GoogleLogo", isSystem: false, color: .blue) { // Google登录
                    ToastManager.shared.show(type: .info, message: L10n.Auth.googleDeveloping)
                }
                ThirdPartyIconButton(icon: "GithubLogo", isSystem: false, color: .primary) { // Github登录
                    ToastManager.shared.show(type: .info, message: L10n.Auth.githubDeveloping)
                }
                ThirdPartyIconButton(icon: "iphone.gen1", isSystem: true, color: .appAccent) { // 手机短信登录
                    ToastManager.shared.show(type: .info, message: L10n.Auth.smsDeveloping)
                }
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
            
            // 模拟一键登录逻辑，这里简单处理为直接登录成功
            let success = await authService.login(identity: "180XXXX6625", password: "one_click_login_mock")
            
            if !success {
                errorMessage = L10n.Auth.authFailed
                HapticFeedback.shared.trigger(.error)
            } else {
                HapticFeedback.shared.trigger(.success)
            }
            
            isLoading = false
        }
    }
    
    /// 触发第三方 Apple ID 授权登录逻辑，并驱动统一会话中台校验
    private func handleAppleLogin() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let success = await authService.login(using: AppleAuthStrategy())
            
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
    let icon: String
    let isSystem: Bool
    let color: Color
    let action: () -> Void
    
    init(icon: String, isSystem: Bool = true, color: Color, action: @escaping () -> Void) {
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
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
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
                    .stroke(color.opacity(0.5), lineWidth: 1) // 根据颜色设置边框，与参考图一致
            )
        }
        .buttonStyle(.plain)
    }
}
