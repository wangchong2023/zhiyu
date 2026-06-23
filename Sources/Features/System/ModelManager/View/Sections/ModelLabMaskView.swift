//
//  ModelLabMaskView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/12.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：无可用本地模型时的毛玻璃引导遮罩视图，展示提示文案与跳转模型商店入口按钮。
//

import SwiftUI

// MARK: - 引导与拦截遮罩

extension ModelLabView {

    var noModelMaskView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: DesignSystem.iconDisplay + DesignSystem.iconTiny))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, DesignSystem.standardPadding + 2)

                    Text(L10n.ModelManager.Lab.noActiveModelTitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.theme.white)

                    Text(L10n.ModelManager.Lab.noActiveModelSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.large)

                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        onGoToStore()
                    }) {
                        Text(L10n.ModelManager.Lab.goToStore)
                            .bold()
                            .padding(.horizontal, DesignSystem.large)
                            .padding(.vertical, DesignSystem.standardPadding + 4)
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(Color.theme.white)
                            .cornerRadius(DesignSystem.smallRadius + 2)
                            .shadow(color: .cyan.opacity(DesignSystem.Opacity.shadow), radius: DesignSystem.shadowRadius)
                    }
                    .padding(.top, DesignSystem.standardPadding + 2)
                }
                .padding(DesignSystem.large)
                .background(Color.theme.black.opacity(DesignSystem.Opacity.disabled))
                .cornerRadius(DesignSystem.largeRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                        .stroke(Color.theme.white.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
                )
                .padding(DesignSystem.large)
            )
    }
}
