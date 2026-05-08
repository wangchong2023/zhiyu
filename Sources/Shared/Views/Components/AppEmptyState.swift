// AppEmptyState.swift
//
// 作者: Wang Chong
// 功能说明: 通用空状态组件，统一各页面的空数据展示。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 2026-05-07: 系统性重构，从 AppEmptyState 重命名为 AppEmptyState，术语统一为“通用空状态组件”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Empty State
/// 通用空状态组件，统一各页面的空数据展示。
/// - Parameters:
///   - icon: SF Symbol 主图标名
///   - title: 主标题
///   - description: 可选描述文本
///   - hint: 可选提示（通常是高亮小字）
///   - action: 可选操作按钮配置
/// 智适应空状态视图
/// 负责在列表或内容为空时展示视觉占位符、说明文案及引导操作按钮
struct AppEmptyState: View {
    let icon: String
    let title: String
    let description: String?
    let hint: String?
    let action: Action?

    /// 操作按钮配置
    struct Action {
        let label: String
        let icon: String?
        let role: Role?
        let handler: () -> Void

        enum Role { case primary, secondary, destructive }

        init(label: String, icon: String? = nil, role: Action.Role = .secondary, handler: @escaping () -> Void) {
            self.label = label
            self.icon = icon
            self.role = role
            self.handler = handler
        }
    }

    init(
        icon: String,
        title: String,
        description: String? = nil,
        hint: String? = nil,
        action: Action? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.hint = hint
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppUI.standardPadding + AppUI.small) { // 24
            // 视觉区：图标 + 装饰卡片
            ZStack {
                // 背景装饰圆
                Circle()
                    .fill(Color.appAccent.opacity(AppUI.glassOpacity * 0.7)) // 0.07
                    .frame(width: AppUI.Metrics.heroValueSize * 3.75, height: AppUI.Metrics.heroValueSize * 3.75) // 120

                Circle()
                    .fill(Color.appAccent.opacity(AppUI.glassOpacity * 0.4)) // 0.04
                    .frame(width: AppUI.Metrics.heroValueSize * 5.0, height: AppUI.Metrics.heroValueSize * 5.0) // 160

                // 主图标
                Image(systemName: icon)
                    .font(.system(size: AppUI.Metrics.largeIconBoxSize, weight: .light)) // 44
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appAccent, .appAccent.opacity(AppUI.fullOpacity * 0.6)], // 0.6
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: AppUI.Metrics.heroValueSize * 3.8) // 100

            // 文字区
            VStack(spacing: AppUI.small) { // 8
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.appText)

                if let description = description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // 提示区
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, AppUI.small + AppUI.tiny) // 14
                    .padding(.vertical, AppUI.tiny + AppUI.atomic) // 7
                    .background(
                        RoundedRectangle(cornerRadius: AppUI.chipRadius)
                            .fill(Color.appAccent.opacity(AppUI.glassOpacity)) // 0.1
                    )
            }

            // 操作按钮
            if let action = action {
                Button(action: action.handler) {
                    HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
                        if let icon = action.icon {
                            Image(systemName: icon)
                        }
                        Text(action.label)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(actionForegroundColor(for: action.role))
                    .padding(.horizontal, AppUI.loosePadding) // 20
                    .padding(.vertical, AppUI.small + AppUI.atomic) // 10
                    .background(
                        action.role == .primary || action.role == nil
                            ? Color.appAccent
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.small)
                            .stroke(action.role == .primary || action.role == nil ? Color.clear : Color.appAccent, lineWidth: AppUI.borderWidth) // 1
                    )
                }
            }
        }
        .padding(.horizontal, AppUI.largeIconSize) // 32
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
    }

    private func actionForegroundColor(for role: Action.Role?) -> Color {
        switch role {
        case .primary, .none: return .white
        case .secondary: return .appAccent
        case .destructive: return .red
        }
    }

    private func buildAccessibilityLabel() -> String {
        var label = "\(title)。"
        if let description = description { label += " \(description)。" }
        if let hint = hint { label += " \(L10n.Common.Empty.tr("hint"))：\(hint)" }
        if action != nil { label += " \(L10n.Common.Empty.tr("actionHint"))。" }
        return label
    }
}

// MARK: - Convenience Initializers
extension AppEmptyState {
    /// 图标 + 标题 + 描述（无操作）
    static func simple(icon: String, title: String, description: String? = nil) -> AppEmptyState {
        AppEmptyState(icon: icon, title: title, description: description)
    }

    /// 带操作按钮的空状态
    static func withAction(
        icon: String,
        title: String,
        description: String? = nil,
        hint: String? = nil,
        actionLabel: String,
        actionIcon: String? = nil,
        actionRole: Action.Role = .secondary,
        actionHandler: @escaping () -> Void
    ) -> AppEmptyState {
        AppEmptyState(
            icon: icon,
            title: title,
            description: description,
            hint: hint,
            action: Action(label: actionLabel, icon: actionIcon, role: actionRole, handler: actionHandler)
        )
    }
}
