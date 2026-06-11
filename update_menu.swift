import Foundation

let path = "Sources/Shared/UIComponents/Menus/UserProfileMenu.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

// Replace the Menu section with the new Popover design
let newMenuCode = """
        Button(action: {
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("userProfileMenuButton")
"""

// We will use a script to carefully inject this.
