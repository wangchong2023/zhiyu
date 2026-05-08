// AppTooltip.swift
//
// 作者: Wang Chong
// 功能说明: 引导提示组件，用于首次使用时的操作引导。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 2026-05-07: 系统性重构，从 WikiTooltip 重命名为 AppTooltip，术语统一为“引导提示组件”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Tooltip
/// 引导提示组件，用于首次使用时的操作引导。
@MainActor
/// 操作引导提示组件
/// 负责在 UI 元素周围弹出气泡样式的提示信息，用于新手引导或新功能展示
struct AppTooltip: View {
    let title: String
    let description: String
    let icon: String
    var arrowDirection: ArrowDirection = .top
    var accentColor: Color = .appAccent

    enum ArrowDirection {
        case top, bottom, left, right
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.medium - AppUI.atomic) { // 10
            HStack(alignment: .top, spacing: AppUI.medium - AppUI.atomic) { // 10
                Image(systemName: icon)
                    .font(.system(size: AppUI.titleIconSize, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: AppUI.largeIconSize - AppUI.tiny, height: AppUI.largeIconSize - AppUI.tiny) // 28
                    .background(accentColor.opacity(AppUI.glassOpacity * 1.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppUI.tiny) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.appText)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppUI.medium + AppUI.atomic * 2) // 14
        .background(
            RoundedRectangle(cornerRadius: AppUI.medium)
                .fill(Color.appCard)
                .shadow(color: .black.opacity(AppUI.glassOpacity * 1.2), radius: AppUI.shadowRadius + AppUI.small, x: 0, y: AppUI.shadowY + AppUI.atomic * 2) // 0.12, 16, 6
        )
        .overlay(
            arrowView,
            alignment: arrowAlignment
        )
        .clipShape(RoundedRectangle(cornerRadius: AppUI.medium))
    }

    @ViewBuilder
    private var arrowView: some View {
        switch arrowDirection {
        case .top:
            VStack(spacing: 0) {
                Triangle()
                    .fill(Color.appCard)
                    .frame(width: AppUI.medium, height: AppUI.small) // 12, 8
                    .shadow(color: .black.opacity(AppUI.shadowOpacity * 1.5), radius: AppUI.borderWidth * 2, x: 0, y: -AppUI.atomic) // 0.06, 2, -1
                Spacer()
            }
        case .bottom:
            VStack(spacing: 0) {
                Spacer()
                Triangle()
                    .fill(Color.appCard)
                    .frame(width: AppUI.medium, height: AppUI.small) // 12, 8
                    .rotationEffect(.degrees(180))
                    .shadow(color: .black.opacity(AppUI.shadowOpacity * 1.5), radius: AppUI.borderWidth * 2, x: 0, y: AppUI.atomic) // 0.06, 2, 1
            }
        case .left:
            HStack(spacing: 0) {
                Triangle()
                    .fill(Color.appCard)
                    .frame(width: AppUI.small, height: AppUI.medium) // 8, 12
                    .rotationEffect(.degrees(-90))
                Spacer()
            }
        case .right:
            HStack(spacing: 0) {
                Spacer()
                Triangle()
                    .fill(Color.appCard)
                    .frame(width: AppUI.small, height: AppUI.medium) // 8, 12
                    .rotationEffect(.degrees(90))
            }
        }
    }

    private var arrowAlignment: Alignment {
        switch arrowDirection {
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .trailing
        case .right: return .leading
        }
    }
}

// MARK: - Triangle Shape
/// 基础三角形形状
/// 负责绘制气泡提示组件的指向箭头，支持 2D 路径闭合
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extension
extension View {
    /// 在视图上叠加一个引导提示浮层
    func tooltip(_ type: TooltipManager.TooltipType, isPresented: Binding<Bool>) -> some View {
        self.overlay(alignment: .bottom) {
            if isPresented.wrappedValue {
                AppTooltip(
                    title: Localized.tr(type.titleKey),
                    description: Localized.tr(type.descriptionKey),
                    icon: type.icon,
                    arrowDirection: .top,
                    accentColor: .appAccent
                )
                .padding(.horizontal, AppUI.standardPadding + AppUI.small) // 24
                .padding(.bottom, AppUI.small)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .onTapGesture {
                    withAnimation(.easeOut(duration: AppUI.Animation.standardDuration * 0.8)) { // 0.2
                        isPresented.wrappedValue = false
                        TooltipManager.shared.markShown(type)
                    }
                }
            }
        }
    }
}
