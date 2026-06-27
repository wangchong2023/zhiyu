//
//  String+PhoneNumber.swift
//  ZhiYu
//
//  系统层级：[L0] 基础设施层
//  核心职责：为 String 提供手机号掩码格式化扩展。
//

import Foundation

extension String {
    /// 手机号掩码：保留前 3 位和后 4 位，中间用 **** 替代。
    /// 例如 "18012346625" -> "180****6625"。
    /// 不足 7 位时返回自身（不掩码，避免误导）。
    var maskedPhoneNumber: String {
        guard count >= 7 else { return self }
        return prefix(3) + "****" + suffix(4)
    }
}
