//
//  SubscriptionUpgradeView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：套餐升级收银台视图，展示 Lite vs Pro 对比、支付渠道选择、StoreKit 模拟购买及后端凭证校验。
//

import SwiftUI
import StoreKit

// MARK: - 升级收银台主视图

/// 套餐升级收银台
@MainActor
public struct SubscriptionUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - 状态

    /// 选中的订阅周期：月付 / 年付
    @State private var selectedCycle: BillingCycle = .yearly

    /// 是否正在处理购买
    @State private var isPurchasing = false
    /// 是否已升级成功（触发 Confetti）
    @State private var isUpgradeSuccess = false
    /// 错误提示
    @State private var errorMessage: String?

    // MARK: - 数据

    /// Lite 套餐权益列表
    private let liteFeatures = [
        PlanFeature(icon: "books.vertical", title: L10n.Auth.Feature.vaults, value: L10n.Auth.Feature.vaultsLiteValue),
        PlanFeature(icon: "doc.text", title: L10n.Auth.Feature.pages, value: L10n.Auth.Feature.pagesLiteValue),
        PlanFeature(icon: "puzzlepiece", title: L10n.Auth.Feature.plugins, value: L10n.Auth.Feature.pluginsLiteValue),
        PlanFeature(icon: "sparkle", title: L10n.Auth.Feature.aiSynth, value: L10n.Auth.Feature.aiSynthLiteValue)
    ]

    /// Pro 套餐权益列表
    private let proFeatures = [
        PlanFeature(icon: "books.vertical.fill", title: L10n.Auth.Feature.vaults, value: L10n.Auth.Feature.vaultsProValue),
        PlanFeature(icon: "doc.text.fill", title: L10n.Auth.Feature.pages, value: L10n.Auth.Feature.pagesProValue),
        PlanFeature(icon: "puzzlepiece.fill", title: L10n.Auth.Feature.plugins, value: L10n.Auth.Feature.pluginsProValue),
        PlanFeature(icon: "sparkles", title: L10n.Auth.Feature.aiSynth, value: L10n.Auth.Feature.aiSynthProValue)
    ]

    // MARK: - 视图主体

    public var body: some View {
        ZStack {
            themeManager.pageBackground().ignoresSafeArea()

            if isUpgradeSuccess {
                // 升级成功的庆祝页面
                successView
            } else {
                mainContent
            }

            // 购买中全屏遮罩
            AppLoadingOverlay(
                isLoading: isPurchasing,
                message: L10n.Auth.purchasing
            )
        }
        .navigationTitle(L10n.Auth.upgradePro)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Common.close) { dismiss() }
            }
        }
    }

    // MARK: - 子视图

    /// 主内容滚动区
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignSystem.large) {
                    // 1. 套餐对比网格
                    planComparisonGrid

                    // 2. 订阅周期选择
                    cycleSelector

                    // 3. 错误提示
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, DesignSystem.medium)
                    }
                }
                .padding(DesignSystem.medium)
            }

            // 5. 底部确认按钮
            purchaseButton
        }
    }

    /// Lite / Pro 权益对比网格
    private var planComparisonGrid: some View {
        AppCard {
            VStack(spacing: 0) {
                // 标题行
                HStack {
                    Spacer()
                    Text(L10n.Auth.litePlan)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.appSecondary)
                    Text(L10n.Auth.proPlan)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.appAccent)
                }
                .padding(DesignSystem.medium)

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

    /// 单项权益对比行
    private func featureRow(lite: PlanFeature, pro: PlanFeature) -> some View {
        HStack(alignment: .center) {
            // 功能名
            HStack(spacing: DesignSystem.small) {
                Image(systemName: pro.icon)
                    .foregroundStyle(.appAccent)
                    .frame(width: 20)
                Text(lite.title)
                    .font(.caption)
                    .foregroundStyle(.appText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Lite 值
            Text(lite.value)
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.appSecondary)

            // Pro 值
            Text(pro.value)
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.appAccent)
        }
        .padding(.horizontal, DesignSystem.medium)
        .padding(.vertical, DesignSystem.small)
    }

    /// 订阅周期选择器（月付 / 年付）
    private var cycleSelector: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                Text(L10n.Auth.selectCycle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                    .padding(.horizontal, DesignSystem.medium)
                    .padding(.top, DesignSystem.medium)

                HStack(spacing: DesignSystem.small) {
                    // 月付选项
                    cycleOption(
                        cycle: .monthly,
                        price: L10n.Auth.monthlyPrice,
                        label: L10n.Auth.monthly,
                        badge: nil
                    )
                    // 年付选项（推荐标记）
                    cycleOption(
                        cycle: .yearly,
                        price: L10n.Auth.yearlyPrice,
                        label: L10n.Auth.yearly,
                        badge: L10n.Auth.bestValue
                    )
                }
                .padding(.horizontal, DesignSystem.medium)
                .padding(.bottom, DesignSystem.medium)
            }
        }
    }

    /// 单个周期选项卡
    private func cycleOption(cycle: BillingCycle, price: String, label: String, badge: String?) -> some View {
        let isSelected = selectedCycle == cycle
        return Button(action: { selectedCycle = cycle }) {
            VStack(spacing: DesignSystem.atomic) {
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(isSelected ? .white : .appText)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .appSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.medium)
            .background(isSelected ? Color.appAccent : Color.appCard)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cardRadius)
                    .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
        }
        .buttonStyle(ScaleButtonStyle())
    }



    /// 底部确认支付按钮
    private var purchaseButton: some View {
        VStack {
            AppDivider()
            AppPrimaryButton(
                title: L10n.Auth.confirmPurchase,
                icon: "applelogo",
                isLoading: isPurchasing
            ) {
                handleApplePurchase()
            }
            .padding(.horizontal, DesignSystem.medium)
            .padding(.vertical, DesignSystem.small)

            Text(L10n.Auth.purchaseDisclaimer)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.large)
                .padding(.bottom, DesignSystem.small)
        }
        .background(Color.appCard.opacity(DesignSystem.glassOpacity))
    }

    /// 升级成功视图（含 Confetti 特效）
    private var successView: some View {
        VStack(spacing: DesignSystem.large) {
            Spacer()

            // 金色皇冠动画
            Image(systemName: "crown.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: isUpgradeSuccess)

            Text(L10n.Auth.upgradeSuccessTitle)
                .font(.title.bold())
                .foregroundStyle(.appText)

            Text(L10n.Auth.upgradeSuccessMessage)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.large)

            Spacer()

            AppPrimaryButton(title: L10n.Auth.startUsingPro, gradientColors: [.yellow, .orange]) {
                dismiss()
            }
            .padding(DesignSystem.medium)
        }
    }

    // MARK: - 购买逻辑



    /// 调起 StoreKit 内购流程（仅 Apple Pay）
    private func handleApplePurchase() {
        Task {
            isPurchasing = true
            let productId = selectedCycle == .monthly
                ? "com.zhiyu.pro.monthly"
                : "com.zhiyu.pro.yearly"

            do {
                // 从 App Store 拉取商品
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    isPurchasing = false
                    errorMessage = L10n.Auth.productNotFound
                    return
                }

                // 发起购买
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        // StoreKit 2：使用 jsonRepresentation 转 Base64 作为凭证传给后端
                        let receipt = transaction.jsonRepresentation.base64EncodedString()
                        let success = await authService.verifyApplePurchase(
                            productId: productId,
                            receiptData: receipt,
                            orderNo: nil
                        )
                        await transaction.finish()
                        isPurchasing = false
                        if success {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isUpgradeSuccess = true
                            }
                        } else {
                            errorMessage = L10n.Auth.verifyFailed
                        }
                    case .unverified:
                        isPurchasing = false
                        errorMessage = L10n.Auth.verifyFailed
                    }
                case .userCancelled:
                    isPurchasing = false
                case .pending:
                    isPurchasing = false
                    errorMessage = L10n.Auth.purchasePending
                @unknown default:
                    isPurchasing = false
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 辅助枚举与模型

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
