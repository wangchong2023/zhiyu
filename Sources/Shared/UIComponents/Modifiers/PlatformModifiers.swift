//
//  PlatformModifiers.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/03.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：封装特定平台的 SwiftUI View Modifiers，解耦 Feature 层的宏依赖。
//
import SwiftUI

public extension View {
    
    /// 仅在支持的平台应用 Segmented Picker Style
    @ViewBuilder

    /// segmentedPickerStyleIfAvailable
    func segmentedPickerStyleIfAvailable() -> some View {
        #if os(iOS) || os(macOS)
        self.pickerStyle(.segmented)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 应用 navigationBarTitleDisplayMode
    @ViewBuilder

    /// inlineNavigationBarTitleIfAvailable
    func inlineNavigationBarTitleIfAvailable() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 应用 large navigationBarTitleDisplayMode
    @ViewBuilder

    /// largeNavigationBarTitleIfAvailable
    func largeNavigationBarTitleIfAvailable() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 隐藏 Navigation Bar Back Button
    @ViewBuilder

    /// 隐藏BackButtonIfIOS
    /// /// - Parameter hidden: hidden
    func hideBackButtonIfIOS(_ hidden: Bool = true) -> some View {
        #if os(iOS)
        self.navigationBarBackButtonHidden(hidden)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 修改 Navigation Bar 可见性
    @ViewBuilder

    /// 隐藏NavigationBarIfIOS
    /// /// - Parameter hidden: hidden
    func hideNavigationBarIfIOS(_ hidden: Bool) -> some View {
        #if os(iOS)
        self.toolbar(hidden ? .hidden : .visible, for: .navigationBar)
        #else
        self
        #endif
    }
    
    /// 仅在非 watchOS 上填满最大宽度
    @ViewBuilder

    /// maxWidthIfNot监听OS
    /// /// - Parameter alignment: alignment
    func maxWidthIfNotWatchOS(_ alignment: Alignment = .center) -> some View {
        #if !os(watchOS)
        self.frame(maxWidth: .infinity, alignment: alignment)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 设置 listStyle 为 insetGrouped
    @ViewBuilder

    /// insetGroupedListStyleIfIOS
    func insetGroupedListStyleIfIOS() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
    
    /// 仅在 macOS 设置 listStyle 为 inset
    @ViewBuilder

    /// insetListStyleIfMac
    func insetListStyleIfMac() -> some View {
        #if os(macOS)
        self.listStyle(.inset)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 或 macOS 设置 textFieldStyle 为 roundedBorder
    @ViewBuilder

    /// roundedBorderTextFieldStyle
    func roundedBorderTextFieldStyle() -> some View {
        #if os(iOS) || os(macOS)
        self.textFieldStyle(.roundedBorder)
        #else
        self
        #endif
    }
    
    /// 仅在 iOS 或 macOS 应用 keyboardType
    @ViewBuilder

    /// numberPadKeyboardIfAvailable
    func numberPadKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    /// 在 watchOS 上隐藏视图（手表端不支持的操作/控件）
    func hiddenOnWatch() -> some View {
        #if os(watchOS)
        self.hidden()
        #else
        self
        #endif
    }

    @ViewBuilder
    /// 仅在 iOS/macOS 显示视图（手表端不渲染）
    func visibleOniOSOrMac() -> some View {
        #if os(watchOS)
        self.hidden()
        #else
        self
        #endif
    }
}
