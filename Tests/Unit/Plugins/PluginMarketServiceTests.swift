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
        XCTAssertEqual(service.availablePlugins.first?.name, "Test Plugin")
        XCTAssertNil(service.errorMessage)
    }
    
    func testFetchPluginsFailure() async throws {
        MockURLProtocol.requestHandler = { request in
            throw URLError(.notConnectedToInternet)
        }
        
        await service.fetchPlugins()
        
        XCTAssertTrue(service.availablePlugins.isEmpty)
        XCTAssertNotNil(service.errorMessage)
    }
}
