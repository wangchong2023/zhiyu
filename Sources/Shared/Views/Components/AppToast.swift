// AppToast.swift
//
// 作者: Wang Chong
// 功能说明: enum AppToastType
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-04
//   - 2026-05-07: 系统性重构，从 AppToast 重命名为 AppToast，术语统一为“轻提示组件”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Combine

// MARK: - App Toast Type
/// 轻提示类型枚举
/// 负责定义 Toast 的视觉风格（图标与色彩）及其代表的业务状态
enum AppToastType: Equatable {
    case success
    case error
    case info
    case processing
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .processing: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .appAccent
        case .processing: return .appAccent
        }
    }
}

// MARK: - App Toast Model
/// 轻提示数据模型
/// 负责封装单条 Toast 的展示内容、类型标识及显示时长，具备唯一标识符
struct AppToast: Identifiable, Equatable {
    let id = UUID()
    let type: AppToastType
    let message: String
    var duration: Double = AppUI.Animation.slowDuration * 6 // 3.0
}

// MARK: - 提示管理器
@MainActor
/// 轻提示全局管理单例
/// 负责 Toast 的队列调度、生命周期计时（自动隐藏）及并发状态管理，确保 UI 层的非阻塞反馈
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: AppToast?
    private var timer: AnyCancellable?
    
    private init() {}
    
    func show(type: AppToastType, message: String, duration: Double = 3.0) {
        withAnimation(.spring(response: AppUI.Animation.standardDuration * 1.6, dampingFraction: AppUI.Animation.standardDamping)) { // 0.4, 0.8
            currentToast = AppToast(type: type, message: message, duration: duration)
        }
        
        timer?.cancel()
        if duration > 0 {
            timer = Just(())
                .delay(for: .seconds(duration), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    self?.dismiss()
                }
        }
    }
    
    func dismiss() {
        withAnimation(.spring(response: AppUI.Animation.standardDuration * 1.6, dampingFraction: AppUI.Animation.standardDamping)) { // 0.4, 0.8
            currentToast = nil
        }
    }
}

// MARK: - App Toast View
/// 系统轻提示（Toast）组件
/// 提供非侵入式的状态反馈信息，支持成功、错误、警告等多种语义化样式
/// 轻提示（Toast）视觉组件
/// 负责在界面顶部提供非侵入式的即时反馈，支持模糊背板与弹性入场动画
struct AppToastView: View {
    let toast: AppToast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppUI.medium) { // 12
            if toast.type == .processing {
                ProgressView()
                    .tint(toast.type.color)
                    .scaleEffect(AppUI.fullOpacity * 0.8) // 0.8
            } else {
                Image(systemName: toast.type.icon)
                    .foregroundStyle(toast.type.color)
            }
            
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appText)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding(.horizontal, AppUI.standardPadding) // 16
        .padding(.vertical, AppUI.medium) // 12
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppUI.medium) // 12
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: AppUI.medium) // 12
                    .fill(Color.appCard.opacity(AppUI.fullOpacity * 0.7)) // 0.7
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.medium) // 12
                .stroke(Color.appBorder.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth / 2) // 0.3, 0.5
        )
        .shadow(color: .black.opacity(AppUI.shadowOpacity), radius: AppUI.standardRadius, y: AppUI.small + AppUI.atomic) // 0.1, 10, 5
        .padding(.horizontal, AppUI.loosePadding) // 20
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - View Modifier
/// 轻提示视图修饰符
/// 负责将 Toast 展示层注入到视图树的最顶层，实现跨页面的即时消息提示能力
struct AppToastModifier: ViewModifier {
    @StateObject private var manager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = manager.currentToast {
                AppToastView(toast: toast) {
                    manager.dismiss()
                }
                .padding(.top, AppUI.small + AppUI.atomic) // 10
                .zIndex(9999)
            }
        }
    }
}

extension View {
    func appToast() -> some View {
        modifier(AppToastModifier())
    }
}
