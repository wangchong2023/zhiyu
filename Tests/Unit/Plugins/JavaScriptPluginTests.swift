// JavaScriptPluginTests.swift
//
// 作者: Wang Chong
// 功能说明: [Tests] 单元测试层：本文件实现了针对 JavaScript 物理沙箱安全及网关通信（Task 9.3）的深度单元测试套件。
// 核心测试点：
// 1. testJavaScriptPluginWatchdogTimeout：验证死循环 JS 插件求值时，0.5s C 看门狗超时机制能否强制熔断并抛出 408 异常。
// 2. testPluginSandboxGatewayFetchDLP：验证 DLP 网关是否安全拦截未授权域名，放行白名单域名。
// 3. testPluginSandboxGatewayStorageDLP：验证持久化 Payload 大小（最大 5MB）及 Key 长度拦截。
// 版本: 1.0
// 日期: 2026-05-19
// 版权: © 2026 Wang Chong。保留所有权利。

import XCTest
@testable import ZhiYu

#if canImport(JavaScriptCore)

/// JavaScriptCore 沙盒运行时安全防御与通信网关测试套件
@MainActor
final class JavaScriptPluginTests: XCTestCase {
    
    // MARK: - 1. CPU 超时看门狗物理熔断测试
    
    /// 测试当 JavaScript 插件陷入死循环或极慢运算时，底层的 JSContextGroupSetExecutionTimeLimit 看门狗能否成功拦截并抛出超时错误
    func testJavaScriptPluginWatchdogTimeout() {
        let manifest = PluginManifest(
            id: "test.js.timeout",
            version: "1.0.0",
            author: "Tester",
            permissions: ["writeContent"],
            allowedDomains: [],
            names: ["en": "Watchdog Test"],
            descriptions: ["en": "Watchdog Test"]
        )
        
        // 构造一个会陷入死循环的恶意预处理脚本
        let maliciousScript = """
        var preProcess = function(content) {
            var counter = 0;
            while (true) {
                counter++;
            }
            return content;
        };
        """
        
        guard let plugin = JavaScriptPlugin(script: maliciousScript, manifest: manifest) else {
            XCTFail("❌ 无法实例化 JavaScriptPlugin")
            return
        }
        
        // 验证执行是否由于 CPU 时间超限而抛出 408 (Timeout) 错误
        let expectation = self.expectation(description: "Watchdog should interrupt within 1.0s")
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                _ = try plugin.preProcess(content: "hello")
                XCTFail("❌ 未能成功触发熔断：死循环预处理脚本竟然成功返回了")
            } catch {
                let nsErr = error as NSError
                XCTAssertEqual(nsErr.domain, "PluginSandbox", "异常 Domain 应为沙盒命名空间")
                XCTAssertEqual(nsErr.code, 408, "错误码必须为 408 超时限制")
                XCTAssertTrue(
                    nsErr.localizedDescription.contains("CPU") || nsErr.localizedDescription.contains("超限"),
                    "错误信息必须包含 CPU 或超限文字: \(nsErr.localizedDescription)"
                )
                print("🛡️ [单元测试成功] Watchdog 超时熔断完美拦截死循环，错误信息: \(nsErr.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - 2. DLP 域名网关拦截测试
    
    /// 验证沙盒网关能否防御网络外泄攻击（拦截未授权域名，放行白名单域名）
    func testPluginSandboxGatewayFetchDLP() {
        let allowedDomains = ["api.github.com", "api.openai.com"]
        
        // A. 拦截测试：未授权恶意域名（DLP 拦截）
        XCTAssertThrowsError(
            try PluginSandboxGateway.auditFetch(url: "https://evil.com/exfiltrate?token=123", options: nil, allowedDomains: allowedDomains),
            "访问未授权域名必须抛出拦截错误"
        ) { error in
            let nsErr = error as NSError
            XCTAssertEqual(nsErr.domain, "PluginSandboxGateway")
            XCTAssertEqual(nsErr.code, 403, "未授权域名拦截码应为 403 Forbidden")
            XCTAssertTrue(
                nsErr.localizedDescription.contains("未授权") || nsErr.localizedDescription.lowercased().contains("unauthorized"),
                "错误提示应清晰指向未授权 (unauthorized): \(nsErr.localizedDescription)"
            )
        }
        
        // B. 放行测试：已在 manifest 中注册的白名单域名
        XCTAssertNoThrow(
            try PluginSandboxGateway.auditFetch(url: "https://api.github.com/repos/wangchong2023/ZhiYu", options: nil, allowedDomains: allowedDomains),
            "访问受信任的白名单域名必须安全放行"
        )
    }
    
    // MARK: - 3. Payload 存储超限与长 Key 拦截测试
    
    /// 验证持久化存储（saveData）超大体积载荷（>5MB）与越界键名长度（>256字符）的防御机制
    func testPluginSandboxGatewayStorageDLP() {
        // A. 验证超长 Key 拦截
        let longKey = String(repeating: "k", count: 300)
        XCTAssertThrowsError(
            try PluginSandboxGateway.auditStorage(key: longKey, value: "valid_value"),
            "Key 长度超出 256 字符必须报错"
        ) { error in
            let nsErr = error as NSError
            XCTAssertEqual(nsErr.code, 400, "Key 过长报错码为 400")
        }
        
        // B. 验证超限 Payload 拦截 (>5MB)
        let fiveMegabytesAndOneByte = String(repeating: "x", count: 5 * 1024 * 1024 + 1)
        XCTAssertThrowsError(
            try PluginSandboxGateway.auditStorage(key: "valid_key", value: fiveMegabytesAndOneByte),
            "数据载荷超出 5MB 必须拦截"
        ) { error in
            let nsErr = error as NSError
            XCTAssertEqual(nsErr.code, 413, "超载实体报错码应为 413 Payload Too Large")
        }
        
        // C. 验证小容量载荷安全放行
        XCTAssertNoThrow(
            try PluginSandboxGateway.auditStorage(key: "theme_preference", value: "{\"mode\": \"dark\"}"),
            "常规大小载荷必须安全存储放行"
        )
    }
}

#endif
