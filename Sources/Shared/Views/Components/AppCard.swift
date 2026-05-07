// AppCard.swift
//
// 作者: Wang Chong
// 功能说明: 应用通用卡片背景及组件。
// 版本: 1.1
// 修改记录:
//   - 创建: 2026-05-02
//   - 2026-05-07: 系统性重构，从 WikiCard 重命名为 AppCard，术语统一为“应用通用卡片”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Card Modifier
/// 应用卡片背景的 ViewModifier。
/// 应用卡片背景的视图修饰符
/// 负责注入一致的内边距、背景色及圆角样式
struct AppCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppUI.cardRadius
    var padding: CGFloat = AppUI.Layout.cardContentPadding
    var backgroundColor: Color = .appCard

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - App Card (Container)
/// 统一的卡片容器，统一背景、圆角、内边距。
/// 标准卡片容器组件
/// 提供符合设计系统的阴影、圆角及背景封装
struct AppCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = AppUI.cardRadius
    var padding: CGFloat = AppUI.Layout.cardContentPadding

    var body: some View {
        content
            .padding(padding)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - App Bordered Card
/// 带边框的卡片，用于入口卡片等需要描边的场景。
/// 带描边效果的卡片
/// 适用于需要视觉分割或引导点击的入口区域
struct AppBorderedCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = AppUI.cardRadius
    var borderColor: Color = .appBorder

    init(
        cornerRadius: CGFloat = AppUI.cardRadius,
        borderColor: Color = .appBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: AppUI.borderWidth)
            )
    }
}

// MARK: - View Extension for Card Background
extension View {
    /// 应用卡片背景的修饰符。
    func appCard(cornerRadius: CGFloat = AppUI.cardRadius, padding: CGFloat = AppUI.Layout.cardContentPadding) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - App Section Header
/// 统一的分组标题样式。
/// 统一的章节标题组件
/// 支持左侧图标、标题文本及右侧自定义工具栏
struct AppSectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .appSource
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.appText)
            Spacer()
            if let trailing = trailing {
                trailing
            }
        }
    }
}

// MARK: - App Labeled Row
/// 带标签和值的行，用于设置项和信息展示。
struct AppLabeledRow: View {
    let label: String
    let value: String
    var valueColor: Color = .appText

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - App Step Row
/// 带数字序号的步骤行。
struct AppStepRow: View {
    let number: Int
    let text: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下从 12pt 升到 15pt
    private var stepFont: Font {
        horizontalSizeClass == .regular ? .subheadline : .caption
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.appAccent))

            Text(text)
                .font(stepFont)
                .foregroundStyle(.appText)
        }
    }
}

// MARK: - App Chip / Badge
/// 胶囊形标签，用于页面类型、标签展示。
struct AppChip: View {
    let text: String
    var color: Color = .appAccent
    var backgroundOpacity: Double = 0.15
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下从 10pt 升到 12pt
    private var chipFont: Font {
        horizontalSizeClass == .regular ? .caption : .caption2
    }

    var body: some View {
        Text(text)
            .font(chipFont)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(backgroundOpacity))
            .clipShape(Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - App Icon Chip
/// 带图标的胶囊标签。
struct AppIconChip: View {
    let icon: String
    let text: String
    var color: Color = .appAccent
    var isSelected: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下从 12pt 升到 15pt
    private var chipFont: Font {
        horizontalSizeClass == .regular ? .subheadline : .caption
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(chipFont)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.25) : Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
        .foregroundStyle(isSelected ? color : .appSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.smallRadius)
                .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: AppUI.borderWidth)
        )
    }
}

// MARK: - App Primary Button
/// 主要操作按钮，渐变背景跟随用户选择的主题色。
/// 品牌色主操作按钮
/// 支持渐变背景、加载状态及主题色自动适配
struct AppPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var gradientColors: [Color] = [.appAccent, .appAccent.opacity(0.7)]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
            .foregroundStyle(.white)
        }
    }
}

// MARK: - App Capsule Button
/// 胶囊形按钮，用于预览视图中的操作。
struct AppCapsuleButton: View {
    let title: String
    var icon: String? = nil
    var isPrimary: Bool = true
    var color: Color = .appAccent

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isPrimary ? color : Color.appCard)
        .foregroundStyle(isPrimary ? .white : .appSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - App Success Banner
/// 成功提示横幅。
struct AppSuccessBanner: View {
    let message: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad 大屏幕下从 12pt 升到 15pt
    private var bannerFont: Font {
        horizontalSizeClass == .regular ? .subheadline : .caption
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(bannerFont)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
    }
}

// MARK: - App Text Field
/// 统一样式的文本输入框。
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
            .foregroundStyle(.appText)
    }
}

// MARK: - App Tag Field
/// 标签输入框（令牌化/芯片式输入）。
struct AppTagField: View {
    let placeholder: String
    @Binding var tags: [String]
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 3) {
                        Text("#\(tag)")
                            .font(.system(size: 11, weight: .medium))
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                tags.removeAll { $0 == tag }
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.appSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundStyle(.appAccent)
                }
                
                TextField(placeholder, text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onChange(of: newTag) { _, newValue in
                        // 自动检测空格或逗号进行分词
                        if newValue.hasSuffix(" ") || newValue.hasSuffix(",") || newValue.hasSuffix("，") {
                            addCurrentTag()
                        }
                    }
                    .onSubmit {
                        addCurrentTag()
                    }
                    .frame(minWidth: 100)
                    .foregroundStyle(.appText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.standardRadius)
                    .stroke(Color.appBorder.opacity(0.5), lineWidth: AppUI.borderWidth)
            )
        }
    }
    
    private func addCurrentTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: ",，")))
            .replacingOccurrences(of: "#", with: "")
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            withAnimation(.spring(response: 0.3)) {
                tags.append(trimmed)
            }
        }
        newTag = ""
    }
}

// MARK: - App Monospaced Text Editor
/// 等宽文本编辑器。
struct AppMonospacedEditor: View {
    @Binding var text: String
    var minHeight: CGFloat = 200

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .foregroundStyle(.appText)
            .frame(minHeight: minHeight)
            .padding(12)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
    }
}

// MARK: - Animated Section
/// 带动画的展开/收起区块。
struct AnimatedSection<Content: View>: View {
    let isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isExpanded {
            content()
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - App Scrollable Chips
/// 水平滚动的胶囊标签列表。
struct AppScrollableChips<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let selectedItem: Data.Element?
    let onSelect: (Data.Element) -> Void
    var colorProvider: (Data.Element) -> Color = { _ in .appAccent }
    @ViewBuilder let chipContent: (Data.Element) -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(items), id: \.self) { item in
                    Button(action: { onSelect(item) }) {
                        chipContent(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
