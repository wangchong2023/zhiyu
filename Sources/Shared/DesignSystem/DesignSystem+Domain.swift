//
//  DesignSystem+Domain.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import SwiftUI
import CoreGraphics

extension DesignSystem {
    
    // MARK: - Domain Specific Layout Constants
    public enum Domain {
        public struct About {
            public static let logoSize: CGFloat = 100
        }
        public struct Auth {
            /// 登录页 Logo 背景圆形直径
            public static let logoBackgroundSize: CGFloat = 60
            /// 登录/注册模式切换按钮宽度
            public static let modePickerWidth: CGFloat = 120
            /// 登录/注册模式切换按钮高度
            public static let modePickerHeight: CGFloat = 38
            /// 获取验证码按钮水平间距
            public static let getCodeButtonHorizontalPadding: CGFloat = 12
            /// 获取验证码按钮垂直间距
            public static let getCodeButtonVerticalPadding: CGFloat = 8
            /// 登录注册动作按钮垂直间距
            public static let actionButtonVerticalPadding: CGFloat = 14
            /// 第三方登录图标容器尺寸
            public static let thirdPartyIconContainerSize: CGFloat = 50
            /// 第三方登录图标字体大小
            public static let thirdPartyIconFontSize: CGFloat = 24
            /// 游客登录按钮顶部间距
            public static let guestButtonTopPadding: CGFloat = 10
        }
        public struct Voice {
            public static let recordButtonSize: CGFloat = 80
            public static let waveScale: CGFloat = 40
            
            /// 录音板块子视图间距
            public static let recordingSectionSpacing: CGFloat = 14
            /// 录音权限提示垂直间距
            public static let permissionSectionSpacing: CGFloat = 12
            /// 语音状态文字垂直间距
            public static let statusTextSpacing: CGFloat = 4
            /// 状态标签水平边距
            public static let statusLabelHorizontalPadding: CGFloat = 12
            /// 状态标签垂直边距
            public static let statusLabelVerticalPadding: CGFloat = 4
            
            /// 波形展示高度
            public static let waveformHeight: CGFloat = 44
            /// 波形条宽度
            public static let waveBarWidth: CGFloat = 5
            /// 波形条最小高度
            public static let waveBarMinHeight: CGFloat = 4
            /// 波形条之间的间距
            public static let waveBarSpacing: CGFloat = 3
            
            /// 实时转写输入框最小高度
            public static let transcriptionEditorMinHeight: CGFloat = 100
            /// 实时转写输入框最大高度
            public static let transcriptionEditorMaxHeight: CGFloat = 200
        }
        public struct Lint {
            /// 巡检健康圆环图直径
            public static let chartSize: CGFloat = 110
            /// 健康分数超大展示字号 (仅用于分数数字)
            public static let scoreFontSize: CGFloat = 38
            /// 健康检查空状态图标尺寸
            public static let emptyIconSize: CGFloat = 56
        }
        public struct AI {
            public struct Chat {
                public static let pulsingDotSize: CGFloat = 6
                public static let bubbleIconScale: CGFloat = 1.2
                public static let avatarSize: CGFloat = 22
                public static let bubbleCornerRadius: CGFloat = 18
                public static let referencePanelCornerRadius: CGFloat = 6
                /// 气泡区块右侧最小留白 (防止遮挡头像)
                public static let bubbleTrailingPadding: CGFloat = 48
            }
        }

        public enum Feedback {
            public static let defaultRating: Int = 3
            public static let maxRating: Int = 5
        }
    }
}
