// AppEmptyState.swift
//
// 作者: Wang Chong
// 功能说明: 通用空状态组件，用于在列表或页面无数据时提供视觉占位、说明及引导操作。
// MARK: [PR-03] 统一空状态展示规范，优化多端适配与辅助功能支持
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 智适应空状态视图组件
/// 负责在内容为空时展示视觉占位符、说明文案及引导操作按钮。
public struct AppEmptyState: View {
    // MARK: - Properties
    
    public let icon: String
    public let title: String
    public let description: String?
    public let hint: String?
    public let action: Action?

    /// 操作按钮配置结构
    public struct Action {
        public let label: String
        public let icon: String?
        public let role: Role?
        public let handler: () -> Void

        public enum Role { case primary, secondary, destructive }

        public init(label: String, icon: String? = nil, role: Action.Role = .secondary, handler: @escaping () -> Void) {
            self.label = label
            self.icon = icon
            self.role = role
            self.handler = handler
        }
    }

    // MARK: - Initialization
    
    public init(
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

    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: Spacing.giant) { // 24
            // 视觉展示区
            ZStack {
                // 背景装饰圆环
                Circle()
                    .fill(Color.appAccent.opacity(Colors.glassOpacity * 0.5))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.appAccent.opacity(Colors.glassOpacity * 0.3))
                    .frame(width: 160, height: 160)

                // 主图标容器
                Image(systemName: icon)
                    .font(.system(size: Spacing.iconHuge * 1.5, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appAccent, .appAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 100)

            // 文字说明区
            VStack(spacing: Spacing.small) {
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

            // 辅助提示区
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.tiny + Spacing.atomic)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.chipRadius)
                            .fill(Color.appAccent.opacity(Colors.glassOpacity))
                    )
            }

            // 操作引导按钮
            if let action = action {
                Button(action: action.handler) {
                    HStack(spacing: Spacing.tiny + Spacing.atomic) {
                        if let icon = action.icon {
                            Image(systemName: icon)
                        }
                        Text(action.label)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(actionForegroundColor(for: action.role))
                    .padding(.horizontal, Spacing.widePadding)
                    .padding(.vertical, Spacing.medium)
                    .background(
                        action.role == .primary || action.role == nil
                            ? Color.appAccent
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.smallRadius)
                            .stroke(
                                action.role == .primary || action.role == nil ? Color.clear : Color.appAccent, 
                                lineWidth: Spacing.borderWidth
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.huge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
    }

    // MARK: - Private Methods
    
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
        if let hint = hint { label += " 提示：\(hint)" }
        if action != nil { label += " 建议执行：\(action!.label)。" }
        return label
    }
}

// MARK: - Convenience Initializers

public extension AppEmptyState {
    /// 简单空状态：仅图标、标题与描述
    static func simple(icon: String, title: String, description: String? = nil) -> AppEmptyState {
        AppEmptyState(icon: icon, title: title, description: description)
    }

    /// 带操作的空状态：包含主/次引导按钮
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
