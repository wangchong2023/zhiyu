import re

with open("Sources/Shared/UIComponents/Menus/UserProfileMenu.swift", "r", encoding="utf-8") as f:
    content = f.read()

# Add showMenuPopover state
if "@State private var showMenuPopover" not in content:
    content = content.replace("@State private var showDeveloper = false", 
                              "@State private var showDeveloper = false\n    @State private var showMenuPopover = false")

# Replace Menu
menu_pattern = re.compile(r'Menu \{.*?} label: \{\s*profileLabel\s*\}\s*\.menuIndicator\(\.hidden\)\s*\.buttonStyle\(\.plain\)', re.DOTALL)

popover_code = """Button(action: {
            HapticFeedback.shared.trigger(.selection)
            showMenuPopover = true
        }) {
            profileLabel
        }
        .popover(isPresented: $showMenuPopover, arrowEdge: .top) {
            CustomProfilePopover(
                showProfile: $showProfile,
                showStats: $showStats,
                showPlugins: $showPlugins,
                showFeedback: $showFeedback,
                showDeveloper: $showDeveloper,
                showMenuPopover: $showMenuPopover
            )
            .environment(authService)
            .environment(store)
            .environment(router)
            .environmentObject(themeManager)
            .presentationCompactAdaptation(.popover)
        }
        .buttonStyle(.plain)"""

content = menu_pattern.sub(popover_code, content)

# Add CustomProfilePopover struct at the end
popover_struct = """

// MARK: - 自定义个人中心悬浮弹窗
struct CustomProfilePopover: View {
    @Environment(AuthService.self) var authService
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager

    @Binding var showProfile: Bool
    @Binding var showStats: Bool
    @Binding var showPlugins: Bool
    @Binding var showFeedback: Bool
    @Binding var showDeveloper: Bool
    @Binding var showMenuPopover: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 头部：头像与用户信息
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                showMenuPopover = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showProfile = true }
            }) {
                HStack(spacing: DesignSystem.medium) {
                    if let avatar = authService.currentUser?.avatar, let url = URL(string: avatar) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.appBorder
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.appAccent)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.name ?? L10n.Auth.profileAndQuota)
                            .font(.headline)
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        Text(authService.currentUser?.email ?? authService.currentUser?.phone ?? "guest@zhiyu.app")
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(DesignSystem.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            AppDivider()

            // 菜单列表
            ScrollView {
                VStack(spacing: DesignSystem.small) {
                    menuRow(icon: "gearshape.fill", color: .blue, title: L10n.Common.settings) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { router.isShowingSettingsSheet = true }
                    }
                    
                    menuRow(icon: "puzzlepiece.extension.fill", color: .orange, title: L10n.Plugin.title) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showPlugins = true }
                    }
                    
                    menuRow(icon: "chart.bar.fill", color: .green, title: L10n.Common.usage) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showStats = true }
                    }
                    
                    menuRow(icon: "bubble.left.and.bubble.right.fill", color: .purple, title: L10n.Settings.Feedback.title) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showFeedback = true }
                    }
                    
                    menuRow(icon: "lock.fill", color: .teal, title: L10n.Common.lock) {
                        showMenuPopover = false
                        store.securityService.lock()
                        store.requestRelayout()
                    }
                    
                    #if DEBUG
                    menuRow(icon: "hammer.fill", color: .gray, title: L10n.Settings.Section.developer) {
                        showMenuPopover = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showDeveloper = true }
                    }
                    #endif
                }
                .padding(DesignSystem.small)
            }
            
            AppDivider()
            
            // 底部：退出登录
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                showMenuPopover = false
                authService.logout()
            }) {
                HStack {
                    Spacer()
                    Text(L10n.Common.logout)
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding(.vertical, DesignSystem.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            .padding(DesignSystem.small)
        }
        .frame(width: 260)
        .background(
            themeManager.pageBackground().ignoresSafeArea()
        )
    }
    
    private func menuRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            action()
        }) {
            HStack(spacing: DesignSystem.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.appText)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.small)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
"""

if "CustomProfilePopover" not in content:
    content += popover_struct

with open("Sources/Shared/UIComponents/Menus/UserProfileMenu.swift", "w", encoding="utf-8") as f:
    f.write(content)

