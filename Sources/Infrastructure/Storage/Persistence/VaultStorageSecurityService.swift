// VaultStorageSecurityService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了金库安全服务（VaultStorageSecurityService），利用本地生物识别（FaceID/TouchID）保护用户隐私。
// 核心机制：
// 1. 硬件鉴权：通过 LocalAuthentication 框架与系统安全隔区（Secure Enclave）交互。
// 2. 状态锁定：提供全局 isLocked 状态，用于在 UI 层屏蔽敏感内容。
// 3. 容错逻辑：在硬件不支持生物识别的环境下（如旧款设备或未配置），提供降级处理。
// MARK: [SR-03] 金库级锁定集成系统 LocalAuthentication 框架
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 增加详细中文文档注释，规范函数头
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class VaultStorageSecurityService {
    /// 当前金库是否处于锁定状态（UI 应据此显示遮罩或锁定视图）
    var isLocked = false

    /// 当前硬件环境是否支持并已配置生物识别（FaceID/TouchID）
    var biometricsAvailable = false

    /// 注入的平台策略提供者
    @ObservationIgnored @Inject var provider: BiometricAuthProviderProtocol

    /**
     * @description: 初始化安全服务并执行首次硬件能力监控
     * @return {*}
     */
    init() {
        checkBiometrics()
    }

    /// 暂存当前的认证上下文，防止闭包回调前被释放导致闪退
    private var activeContext: LAContext?

    /**
     * @description: 检查并更新当前设备的生物识别可用性状态
     * @return {*}
     */
    func checkBiometrics() {
        let context = LAContext()
        biometricsAvailable = provider.canEvaluatePolicy(context: context)
    }

    /**
     * @description: 触发生物识别解锁流程，成功后更新 isLocked 状态并触发震动反馈
     * @return {*}
     */
    func unlock() {
        Task {
            let success = await authenticateWithBiometrics()
            if success {
                self.isLocked = false
                HapticFeedback.shared.trigger(.unlock)
            } else {
                HapticFeedback.shared.trigger(.error)
            }
        }
    }

    /**
     * @description: 执行一次性生物识别认证，常用于切换安全开关或验证操作权限
     * @return {Bool} 认证是否成功。注意：若硬件不支持则默认返回 true 以免逻辑死锁
     */
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        self.activeContext = context // 保持引用

        let policy = provider.authenticationPolicy
        
        guard provider.canEvaluatePolicy(context: context) else {
            self.activeContext = nil
            return true
        }

        let result = await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: Localized.tr("security.unlockReason")) { success, _ in
                continuation.resume(returning: success)
            }
        }

        self.activeContext = nil
        return result
    }

    /**
     * @description: 立即锁定金库，更新 isLocked 状态并触发震动反馈
     * @return {*}
     */
    func lock() {
        isLocked = true
        HapticFeedback.shared.trigger(.lock)
    }
}
