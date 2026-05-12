import SwiftUI

// MARK: @PR-03: 标准化容器组件，用于列表分组

/// 标准卡片容器
public struct StandardSection<Content: View>: View {
    public let title: String?
    public let footer: String?
    public let content: Content
    
    public init(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let title = title {
                Group {
                    Text(title)
                }
                .font(Typography.captionFont)
                .foregroundStyle(.appSecondary)
                .padding(.leading, Spacing.medium)
                .textCase(.uppercase)
            }
            
            VStack(spacing: 0) {
                content
            }
            .appGlassCardStyle(opacity: 1.0, cornerRadius: Spacing.cardRadius)
            
            if let footer = footer {
                Group {
                    Text(footer)
                }
                .font(Typography.caption2Font)
                .foregroundStyle(.appSecondary)
                .padding(.horizontal, Spacing.medium)
            }
        }
        .padding(.horizontal, Spacing.standardPadding)
        .padding(.vertical, Spacing.small)
    }
}

public extension View {
    /// 应用列表行样式 (用于 StandardSection 内部)
    func appListRowStyle(showDivider: Bool = true) -> some View {
        VStack(spacing: 0) {
            self
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .contentShape(Rectangle())
            
            if showDivider {
                Divider()
                    .padding(.leading, Spacing.medium)
                    .opacity(0.5)
            }
        }
    }
}
