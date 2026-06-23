//
//  iOSDeviceInfoService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/20.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：iOS 平台设备信息获取实现，封装 UIDevice / UIScreen API。

#if os(iOS) && !os(watchOS)
import UIKit

/// iOS 设备信息服务
final class iOSDeviceInfoService: DeviceInfoProtocol, @unchecked Sendable {
    var systemVersion: String {
        MainActor.assumeIsolated { UIDevice.current.systemVersion }
    }

    var deviceModel: String {
        MainActor.assumeIsolated { UIDevice.current.model }
    }

    var deviceName: String {
        MainActor.assumeIsolated { UIDevice.current.name }
    }

    var screenHeight: CGFloat {
        MainActor.assumeIsolated { UIScreen.main.bounds.height }
    }
}
#endif
