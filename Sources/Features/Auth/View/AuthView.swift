// AuthView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的身份认证视图 (AuthView)。
// 提供登录、注册以及游客模式入口，采用工业级玻璃拟态设计。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
    
    var body: some View {
        ZStack {
            // 背景层
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.medium) {
                    // 1. Logo & 标语
                    heroHeader
                    
                    // 2. 模式切换 (登录/注册)
                    modePicker
                    
                    // 3. 表单区域
                    VStack(spacing: Spacing.medium) {
                        if isRegisterMode {
                            registerForm
                        } else {
                            loginForm
                        }
                        
                        actionButton
                    }
                    .padding(Spacing.standardPadding)
                    .appContainer(cornerRadius: Spacing.largeRadius)
                    
                    // 4. 第三方登录
                    thirdPartySection
                    
                    // 5. 游客模式
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
        VStack(spacing: Spacing.medium) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.appAccent.opacity(0.2), .appConcept.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                
                Image(systemName: DesignSystem.Icons.knowledge)
                    .font(.system(size: DesignSystem.displayFontSize * 1.5))
                    .foregroundStyle(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .appAccent.opacity(0.4), radius: 10, y: 4)
            }
            
            VStack(spacing: Spacing.atomic) {
                Text(Localized.tr("app.name"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.appText)
                    .tracking(1)
                
                Text(Localized.tr("welcome.subtitle"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.top, 20)
    }
    
    private var modePicker: some View {
        ZStack(alignment: isRegisterMode ? .trailing : .leading) {
            Capsule()
                .fill(Color.appAccent)
                .frame(width: 120, height: 38)
                .shadow(color: .appAccent.opacity(0.3), radius: 8, y: 4)
            
            HStack(spacing: 0) {
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRegisterMode = false 
                    }
                }) {
                    Text(L10n.Common.tr("login"))
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .frame(width: 120, height: 38)
                        .foregroundStyle(!isRegisterMode ? .white : .appSecondary)
                }
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRegisterMode = true 
                    }
                }) {
                    Text(L10n.Common.tr("register"))
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .frame(width: 120, height: 38)
                        .foregroundStyle(isRegisterMode ? .white : .appSecondary)
                }
            }
        }
        .padding(4)
        .background(Color.appCard.opacity(0.8))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1)) // 增强边框对比度
        .padding(.vertical, 12)
    }
    
    private var loginForm: some View {
        VStack(spacing: Spacing.medium) {
            AuthTextField(
                icon: "person.fill",
                placeholder: L10n.Auth.tr("identity.placeholder"), // 手机号/邮箱/微信
                text: $identity
            )
            
            AuthTextField(
                icon: "lock.fill",
                placeholder: L10n.Auth.tr("password.placeholder"),
                text: $password,
                isSecure: true
            )
        }
    }
    
    private var registerForm: some View {
        VStack(spacing: Spacing.medium) {
            AuthTextField(
                icon: "iphone",
                placeholder: L10n.Auth.tr("phone.placeholder"),
                text: $phone
            )
            
            HStack(spacing: Spacing.small) {
                AuthTextField(
                    icon: "shield.fill",
                    placeholder: L10n.Auth.tr("code.placeholder"),
                    text: $code
                )
                
                Button(action: {}) {
                    Text(L10n.Auth.tr("getCode"))
                        .font(.caption.bold())
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            AuthTextField(
                icon: "lock.fill",
                placeholder: L10n.Auth.tr("setPassword.placeholder"),
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
                    Text(isRegisterMode ? L10n.Common.tr("register") : L10n.Common.tr("login"))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            .shadow(color: .appAccent.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(isLoading)
    }
    
    private var thirdPartySection: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: 1)
                Text(L10n.Auth.tr("thirdParty"))
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
                Rectangle().fill(Color.appBorder.opacity(0.3)).frame(height: 1)
            }
            
            HStack(spacing: Spacing.medium) {
                ThirdPartyIconButton(icon: "message.fill", color: .green)
                ThirdPartyIconButton(icon: "person.2.fill", color: .blue)
                ThirdPartyIconButton(icon: "apple.logo", color: .primary)
            }
        }
    }
    
    private var guestButton: some View {
        Button(action: { authService.continueAsGuest() }) {
            Text(L10n.Auth.tr("guestMode"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.appBorder)
                )
        }
        .padding(.top, 10)
    }
    
    // MARK: - 逻辑
    
    private func handleAuth() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let success: Bool
            if isRegisterMode {
                success = await authService.register(phone: phone, code: code, password: password)
            } else {
                success = await authService.login(identity: identity, password: password)
            }
            
            if !success {
                errorMessage = "认证失败，请重试"
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
                .frame(width: 20)
            
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
                .stroke(Color.appBorder, lineWidth: 1) // 移除不透明度，确保清晰
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
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(Color.appCard)
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            .overlay(
                Circle()
                    .stroke(Color.appBorder, lineWidth: 1) // 增强图标边框
            )
        }
        .buttonStyle(.plain)
    }
}
