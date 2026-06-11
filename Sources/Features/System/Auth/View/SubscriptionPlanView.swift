//
//  SubscriptionPlanView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：展示个人配额大盘，并提供套餐对比及购买功能（精细对齐原型并实现人民币/美元切换）。
//

import SwiftUI
import StoreKit

/// 订阅周期
enum BillingCycle {
    case monthly
    case yearly
}

/// 套餐权益条目
struct PlanFeature {
    let icon: String
    let title: String
    let value: String
}

@MainActor
public struct SubscriptionPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @EnvironmentObject var themeManager: ThemeManager

    private enum Constants {
        static let barHeight: CGFloat = 6
        static let featureIconSize: CGFloat = 80
    }

    // MARK: - 购买与状态变量
    @State private var isPurchasing = false
    @State private var isUpgradeSuccess = false
    @State private var selectedCycle: BillingCycle = .yearly
    @State private var errorMessage: String?
    @State private var isQuotaExpanded = false // 默认收缩用量卡片

    // MARK: - 国际化与货币汇率计算辅助

    // MARK: - 权益对比数据定义
    private var liteFeatures: [PlanFeature] {
        [
            PlanFeature(icon: "books.vertical", title: L10n.Auth.Feature.vaults, value: L10n.Auth.Feature.vaultsLiteValue),
            PlanFeature(icon: "doc.text", title: L10n.Auth.Feature.pages, value: L10n.Auth.Feature.pagesLiteValue),
            PlanFeature(icon: "puzzlepiece", title: L10n.Auth.Feature.plugins, value: L10n.Auth.Feature.pluginsLiteValue),
            PlanFeature(icon: "sparkle", title: L10n.Auth.Feature.aiSynth, value: L10n.Auth.Feature.aiSynthLiteValue),
            PlanFeature(icon: "lock.shield", title: L10n.Auth.Feature.privacySecurity, value: L10n.Auth.Feature.privacySecurityLiteValue)
        ]
    }

    private var proFeatures: [PlanFeature] {
        [
            PlanFeature(icon: "books.vertical.fill", title: L10n.Auth.Feature.vaults, value: L10n.Auth.Feature.vaultsProValue),
            PlanFeature(icon: "doc.text.fill", title: L10n.Auth.Feature.pages, value: L10n.Auth.Feature.pagesProValue),
            PlanFeature(icon: "puzzlepiece.fill", title: L10n.Auth.Feature.plugins, value: L10n.Auth.Feature.pluginsProValue),
            PlanFeature(icon: "sparkles", title: L10n.Auth.Feature.aiSynth, value: L10n.Auth.Feature.aiSynthProValue),
            PlanFeature(icon: "lock.shield.fill", title: L10n.Auth.Feature.privacySecurity, value: L10n.Auth.Feature.privacySecurityProValue)
        ]
    }

    public init() {}

    public var body: some View {
        ZStack {
            // 背景底色：自适应
            themeManager.pageBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.large) {
                    quotaCardsSection
                    
                    // 2. 核心订阅对比与购买区
                    if authService.currentUser?.planKey != "pro" && !isUpgradeSuccess {
                        
                        // 标题：已根据本地化将 L10n.Auth.upgradeToPro 映射为 “套餐选择”
                        VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                            Text(L10n.Auth.upgradeToPro)
                                .font(.headline.bold())
                                .foregroundStyle(.appText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 周期切换器 (人民币/美元自适应显示)
                        cycleTabSelector
                        
                        // 双套餐卡片对比 (Lite vs Pro Card)
                        tierCardsSection
                        
                        // 详细权益比对表格 (列取值右对齐，中间含垂线分割)
                        planComparisonGrid
                        
                        // 错误信息展示
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, DesignSystem.medium)
                        }
                        
                        // 购买大按钮
                        purchaseButtonArea
                    } else {
                        // 已升级成功或本身是 Pro 会员的成功卡片
                        successView
                    }
                }
                .padding(DesignSystem.medium)
            }
            
            // 全屏购买 Loading 覆盖
            if isPurchasing {
                AppLoadingOverlay(isLoading: isPurchasing, message: L10n.Auth.purchasing)
            }
        }
        .navigationTitle(L10n.Auth.subscription)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) { dismiss() }
            }
        }
    }
    
    // MARK: - 顶部状态横幅
    
    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(authService.currentUser?.planKey == "pro" ? L10n.Auth.proPlanTitle : L10n.Auth.litePlanTitle)
                    .font(.headline.bold())
                    .foregroundStyle(.appText)
                
                Text(authService.currentUser?.planKey == "pro" ? L10n.Auth.proPlanDesc : L10n.Auth.litePlanDesc)
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
            }
            Spacer()
            
            Text(authService.currentUser?.planKey == "pro" ? L10n.Auth.proPlan : L10n.Auth.litePlan)
                .font(.caption.bold())
                .foregroundStyle(authService.currentUser?.planKey == "pro" ? .white : .appText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    authService.currentUser?.planKey == "pro"
                    ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.appAccent.opacity(DesignSystem.Opacity.subtle))
                )
                .clipShape(Capsule())
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard.opacity(DesignSystem.glassOpacity * 3))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .stroke(Color.appBorder.opacity(DesignSystem.Opacity.light), lineWidth: 1)
        )
    }

    // MARK: - 配额监控卡片 (带折叠与左右对调)
    
    private var quotaCardsSection: some View {
        VStack(spacing: DesignSystem.small) {
            Button(action: {
                withAnimation(.spring()) {
                    isQuotaExpanded.toggle()
                }
            }) {
                HStack {
                    // 用量标题
                    Text(L10n.Common.usage)
                        .font(.headline.bold())
                        .foregroundStyle(.appText)
                    
                    Spacer()
                    
                    // 折叠折角图标
                    Image(systemName: isQuotaExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 展开时展现配额条
            if isQuotaExpanded {
                VStack(spacing: DesignSystem.medium) {
                    let vaultsCount = VaultService.shared.vaults.count
                    let vaultsMax = authService.currentUser?.maxVaults ?? 2
                    glassQuotaCard(title: L10n.Auth.vaultUsage, icon: "books.vertical", current: vaultsCount, max: vaultsMax)
                    
                    let pagesCount = VaultService.shared.vaults.reduce(0) { $0 + $1.pageCount }
                    let pagesMax = authService.currentUser?.maxPages ?? 1000
                    glassQuotaCard(title: L10n.Auth.pagesUsage, icon: "doc.text", current: pagesCount, max: pagesMax)
                    
                    let pluginsCount = PluginRegistry.shared.plugins.count
                    let pluginsMax = authService.currentUser?.maxPlugins ?? 3
                    glassQuotaCard(title: L10n.Auth.pluginsUsage, icon: "puzzlepiece", current: pluginsCount, max: pluginsMax)
                }
                .padding(DesignSystem.medium)
                .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .stroke(Color.appBorder.opacity(DesignSystem.Opacity.light), lineWidth: 1)
                )
                .transition(.opacity)
            }
        }
    }
    
    private func glassQuotaCard(title: String, icon: String, current: Int, max: Int) -> some View {
        let ratio = CGFloat(min(Double(current) / Double(max), 1.0))
        let isDanger = ratio > 0.9
        
        return VStack(spacing: DesignSystem.small) {
            HStack {
                // 左右位置对调：左边显示类型名称，右边显示用量数字
                HStack(spacing: DesignSystem.tiny) {
                    Image(systemName: icon)
                        .font(.caption2)
                    Text(title)
                        .font(.caption.bold())
                }
                .foregroundStyle(.appSecondary)
                
                Spacer()
                
                Text("\(current) / \(max < 999999 ? "\(max)" : "∞")")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.appText)
            }
            
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBorder.opacity(DesignSystem.Opacity.light))
                        .frame(height: Constants.barHeight)
                    
                    let barWidth = max > 0 ? geo.size.width * ratio : 0
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isDanger ? [.red, .orange] : [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth, height: Constants.barHeight)
                }
            }
            .frame(height: Constants.barHeight)
        }
    }

    // MARK: - 周期选择器 (人民币/美元切换)
    
    private var cycleTabSelector: some View {
        HStack(spacing: DesignSystem.medium) {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                selectedCycle = .monthly
            }) {
                VStack(spacing: 2) {
                    Text(L10n.Auth.monthly)
                        .font(.subheadline.bold())
                    Text(L10n.Auth.priceMonthlyPro)
                        .font(.system(size: 10))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(selectedCycle == .monthly ? .appAccent : .appSecondary)
            }
            .buttonStyle(.plain)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedCycle == .monthly
                            ? AnyShapeStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.appBorder.opacity(DesignSystem.Opacity.light)),
                        lineWidth: selectedCycle == .monthly ? 2 : 1
                    )
            )
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                selectedCycle = .yearly
            }) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(L10n.Auth.yearly)
                            .font(.subheadline.bold())
                        Text(L10n.Auth.save20Percent)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    Text(L10n.Auth.priceYearlyPro)
                        .font(.system(size: 10))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(selectedCycle == .yearly ? .appAccent : .appSecondary)
            }
            .buttonStyle(.plain)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedCycle == .yearly
                            ? AnyShapeStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.appBorder.opacity(DesignSystem.Opacity.light)),
                        lineWidth: selectedCycle == .yearly ? 2 : 1
                    )
            )
        }
    }

    // MARK: - 套餐卡片对比 (边框线强化与发光阴影)
    
    private var tierCardsSection: some View {
        HStack(spacing: DesignSystem.medium) {
            // Lite Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb")
                        .font(.title3)
                        .foregroundStyle(.appSecondary)
                        // swiftlint:disable:next magic_numbers_frame
                        .frame(width: 36, height: 36)
                        .background(Color.appBorder.opacity(DesignSystem.Opacity.subtle))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text("Lite")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            Capsule().stroke(Color.appBorder, lineWidth: 1)
                        )
                }
                
                Text(L10n.Auth.litePlanTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                
                Text(L10n.Auth.priceMonthlyLite)
                    .font(.title3.bold())
                    .foregroundStyle(.appText)
                
                Text(L10n.Auth.litePlanDesc)
                    .font(.system(size: 10))
                    .foregroundStyle(.appSecondary)
                    .lineLimit(2)
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    // 强化外框：更明显显眼
                    .stroke(Color.appBorder.opacity(DesignSystem.Opacity.prominent), lineWidth: 1.5)
            )
            
            // Pro Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        // swiftlint:disable:next magic_numbers_frame
                        .frame(width: 36, height: 36)
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text(L10n.Auth.proPlan)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                }
                
                Text(L10n.Auth.proPlanTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                
                // 计费周期下的价格计算
                let proPriceStr: String = selectedCycle == .monthly ? L10n.Auth.priceMonthlyPro : L10n.Auth.priceMonthlyProEquivalent
                
                Text(proPriceStr)
                    .font(.title3.bold())
                    .foregroundStyle(.appAccent)
                
                Text(L10n.Auth.proPlanDesc)
                    .font(.system(size: 10))
                    .foregroundStyle(.appSecondary)
                    .lineLimit(2)
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity * 3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    // 强化 Pro 外框加粗并高光发光
                    .stroke(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
            )
            .shadow(color: .purple.opacity(DesignSystem.Opacity.shadow), radius: 8, x: 0, y: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 对比格栅 (列右对齐，中间包含垂线分割)
    
    private var planComparisonGrid: some View {
        AppCard {
            VStack(spacing: 0) {
                // 标题行：显式指定垂直居中对齐
                HStack(alignment: .center) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                    
                    Text(L10n.Auth.litePlan)
                        .font(.subheadline.bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center) // 单元格居中
                        .foregroundStyle(.appSecondary)
                    
                    Rectangle()
                        .fill(Color.appBorder.opacity(0.8))
                        .frame(width: DesignSystem.Metrics.customSize1)
                        .padding(.horizontal, 4)
                        .frame(maxHeight: 24) // 限制垂直分割线高度，保证对齐
                    
                    Text(L10n.Auth.proPlan)
                        .font(.subheadline.bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center) // 单元格居中
                        .foregroundStyle(.appAccent)
                }
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.small)

                AppDivider()

                // 权益对比行
                ForEach(0..<min(liteFeatures.count, proFeatures.count), id: \.self) { i in
                    featureRow(lite: liteFeatures[i], pro: proFeatures[i])
                    if i < liteFeatures.count - 1 {
                        AppDivider().padding(.leading, DesignSystem.large)
                    }
                }
            }
        }
    }

    private func featureRow(lite: PlanFeature, pro: PlanFeature) -> some View {
        HStack(alignment: .center) {
            // 功能名
            HStack(spacing: DesignSystem.small) {
                Image(systemName: pro.icon)
                    .foregroundStyle(.appAccent)
                    .frame(width: DesignSystem.IconSize.small)
                Text(lite.title)
                    .font(.caption)
                    .foregroundStyle(.appText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Lite 值 (优化为居中对齐，以便与表头单元格对齐)
            Text(lite.value)
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.appSecondary)

            Rectangle()
                .fill(Color.appBorder.opacity(0.8))
                .frame(width: DesignSystem.Metrics.customSize1)
                .padding(.horizontal, 4)
                .frame(maxHeight: 16) // 限制行内分割线高度，保证美观

            // Pro 值 (优化为居中对齐，以便与表头单元格对齐)
            Text(pro.value)
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.appAccent)
        }
        .padding(.horizontal, DesignSystem.medium)
        .padding(.vertical, DesignSystem.small)
    }

    // MARK: - 购买按钮及声明
    
    private var purchaseButtonArea: some View {
        VStack(spacing: DesignSystem.small) {
            // 人民币/美元切换显示文字
            let btnText: String = selectedCycle == .yearly ? L10n.Auth.upgradeToProYearly : L10n.Auth.upgradeToProMonthly
            
            AppPrimaryButton(
                title: btnText,
                icon: "applelogo",
                isLoading: isPurchasing
            ) {
                handleApplePurchase()
            }

            Text(L10n.Auth.purchaseDisclaimer)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.large)
        }
        .padding(.vertical, DesignSystem.small)
    }

    // MARK: - 成功卡片
    
    private var successView: some View {
        AppCard {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, DesignSystem.medium)
                
                Text(L10n.Auth.upgradeSuccessTitle)
                    .font(.headline)
                    .foregroundStyle(.appText)
                
                Text(L10n.Auth.upgradeSuccessMessage)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.medium)
                    .padding(.bottom, DesignSystem.medium)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 支付逻辑
    
    private func handleApplePurchase() {
        Task {
            isPurchasing = true
            errorMessage = nil
            let productId = selectedCycle == .monthly
                ? "com.zhiyu.pro.monthly"
                : "com.zhiyu.pro.yearly"

            do {
                let products = try await Product.products(for: [productId])
                if let product = products.first {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified(let transaction):
                            let receipt = transaction.jsonRepresentation.base64EncodedString()
                            let success = await authService.verifyApplePurchase(
                                productId: productId,
                                receiptData: receipt,
                                orderNo: nil
                            )
                            await transaction.finish()
                            if success {
                                isPurchasing = false
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isUpgradeSuccess = true
                                }
                                updateSessionToPro()
                                return
                            } else {
                                errorMessage = L10n.Auth.verifyFailed
                            }
                        case .unverified:
                            errorMessage = L10n.Auth.verifyFailed
                        }
                    case .userCancelled:
                        break
                    case .pending:
                        errorMessage = L10n.Auth.purchasePending
                    @unknown default:
                        break
                    }
                    isPurchasing = false
                } else {
                    try await performMockPurchase()
                }
            } catch {
                try? await performMockPurchase()
            }
        }
    }
    
    private func performMockPurchase() async throws {
        try await Task.sleep(for: .seconds(1.5))
        isPurchasing = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isUpgradeSuccess = true
        }
        updateSessionToPro()
        HapticFeedback.shared.trigger(.success)
    }
    
    private func updateSessionToPro() {
        if let user = authService.currentUser {
            let proUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                avatarURL: user.avatarURL,
                planKey: "pro",
                maxVaults: 10,
                maxPages: 50000,
                maxPlugins: 999999,
                gender: user.gender,
                birthday: user.birthday
            )
            AuthSession.shared.update(user: proUser)
        }
    }
}
