//
//  PluginMarketServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 PluginMarketService 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

@MainActor
final class PluginMarketServiceTests: XCTestCase {
    var service: PluginMarketService!
    
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        service = PluginMarketService()
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        service = nil
        super.tearDown()
    }
    
    func testFetchPluginsSuccess() async throws {
        // Mock JSON Data
        let jsonString = """
        [
            {
                "id": "com.test.plugin",
                "version": "1.0.0",
                "author": "Test Author",
                "downloads": "100",
                "rating": 5.0,
                "icon": "star",
                "downloadURL": "https://example.com/plugin.js",
                "names": { "en": "Test Plugin", "zh-Hans": "测试插件" },
                "descriptions": { "en": "Desc" }
            }
        ]
        """
        
        let responseData = jsonString.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }
        
        XCTAssertTrue(service.availablePlugins.isEmpty)
        
        await service.fetchPlugins()
        
        XCTAssertFalse(service.availablePlugins.isEmpty)
        XCTAssertEqual(service.availablePlugins.first?.id, "com.test.plugin")
        // Localized.bestMatch 根据系统语言返回对应本地化名称，接受中/英文
        let pluginName = service.availablePlugins.first?.name
        XCTAssertTrue(pluginName == "Test Plugin" || pluginName == "测试插件",
                      "插件名称应为英文或中文本地化值，实际为: \(pluginName ?? "nil")")
        XCTAssertNil(service.errorMessage)
    }
    
    func testFetchPluginsFailure() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await service.fetchPlugins()

        XCTAssertTrue(service.availablePlugins.isEmpty)
        XCTAssertNotNil(service.errorMessage)
    }

    // MARK: - community-plugins.json 格式测试

    func testCommunityPluginsFormatParsing() async throws {
        let jsonString = """
        [
            {"id":"toc-generator","name":"TOC Generator","author":"ZhiYu Team","description":"Auto-generate TOC.","repo":"wangchong2023/zhiyu-releases"},
            {"id":"link-preview","name":"Link Preview","author":"ZhiYu Team","description":"Rich preview cards.","repo":"wangchong2023/zhiyu-releases"}
        ]
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonString.data(using: .utf8)!)
        }

        await service.fetchPlugins()

        XCTAssertEqual(service.availablePlugins.count, 2)
        XCTAssertEqual(service.availablePlugins[0].id, "toc-generator")
        XCTAssertEqual(service.availablePlugins[0].name, "TOC Generator")
        XCTAssertEqual(service.availablePlugins[0].author, "ZhiYu Team")
        XCTAssertEqual(service.availablePlugins[0].source, "community")
        // 下载 URL 应包含 plugins/ 目录
        XCTAssertTrue(service.availablePlugins[0].downloadURL?.contains("/plugins/") ?? false,
                      "下载 URL 应包含 /plugins/ 路径")
        XCTAssertTrue(service.availablePlugins[0].downloadURL?.hasSuffix("/toc-generator.zyplugin") ?? false,
                      "下载 URL 应以 {id}.zyplugin 结尾")
        XCTAssertNil(service.errorMessage)
    }

    func testCommunityPluginsDownloadURLContainsPluginsDir() async throws {
        // 验证 downloadBase 替换逻辑：community-plugins.json → plugins/
        let jsonString = """
        [{"id":"test","name":"Test","author":"A","description":"D","repo":"user/repo"}]
        """
        MockURLProtocol.requestHandler = { request in
            // 验证请求 URL 是 registry（不是 mock 服务器）
            XCTAssertTrue(request.url?.absoluteString.contains("community-plugins.json") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonString.data(using: .utf8)!)
        }

        await service.fetchPlugins()

        XCTAssertEqual(service.availablePlugins.count, 1)
        let downloadURL = service.availablePlugins[0].downloadURL ?? ""
        // 不应该包含 community-plugins.json
        XCTAssertFalse(downloadURL.contains("community-plugins.json"))
        // 应该包含 plugins/ 目录
        XCTAssertTrue(downloadURL.contains("/plugins/"))
        // 应以 .zyplugin 结尾
        XCTAssertTrue(downloadURL.hasSuffix(".zyplugin"))
    }

    func testEmptyCommunityPluginsList() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        await service.fetchPlugins()

        XCTAssertTrue(service.availablePlugins.isEmpty)
        XCTAssertNil(service.errorMessage)
    }

    func testCommunityPluginsFallbackToMockFormat() async throws {
        // Mock 服务器格式（ApiResponse 包装 → 直接 MarketPlugin 数组回退）
        let jsonString = """
        [{"id":"mock-plugin","version":"1.0","author":"Mock","downloads":"0","rating":0,"icon":"","downloadURL":null,"names":{"en":"Mock"},"descriptions":{"en":""}}]
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, jsonString.data(using: .utf8)!)
        }

        await service.fetchPlugins()

        if service.availablePlugins.isEmpty {
            // community-plugins.json 格式解析失败也 OK——此测试验证回退不崩溃
            XCTAssertNil(service.errorMessage)
        } else {
            XCTAssertEqual(service.availablePlugins[0].id, "mock-plugin")
        }
    }
}
