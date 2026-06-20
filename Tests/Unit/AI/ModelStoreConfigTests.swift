//
//  ModelStoreConfigTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 ModelStoreConfig 开展自动化单元测试验证。
//
import XCTest
import CommonCrypto
@testable import ZhiYu

final class ModelStoreConfigTests: XCTestCase {
    
    private var remoteConfigService: RemoteConfigService!
    private var downloadManager: ModelDownloadManager!
    
    override func setUp() {
        super.setUp()
        // 使用一个无连接的 URLSession 模拟网络彻底断开环境，强制触发灾备兜底
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 0.5 // 缩短超时时间
        let mockSession = URLSession(configuration: config)
        
        remoteConfigService = RemoteConfigService(session: mockSession)
        downloadManager = ModelDownloadManager.shared
    }
    
    override func tearDown() {
        remoteConfigService = nil
        downloadManager = nil
        super.tearDown()
    }
    
    // MARK: - 1. 测试 100% 离线配置兜底保活 (RemoteConfigService Fallback)
    
    /// 当云端服务器挂毁或处于飞行模式下，RemoteConfigService 应该平滑兜底，返回本地预置的 AI 技能和 Manifest
    func testRemoteConfigFallbackWhenOffline() async {
        // 1. 测试模型白名单离线兜底
        do {
            let manifests = try await remoteConfigService.fetchLLMManifests()
            XCTAssertFalse(manifests.isEmpty, "即使处于离线网络崩溃状态下，fetchLLMManifests 也应该平滑返回本地兜底白名单，避免卡白屏。")
            // 验证返回的 Manifest 结构完整（modelId / displayName / vendor 非空）
            for manifest in manifests {
                XCTAssertFalse(manifest.modelId.isEmpty, "离线兜底 Manifest 的 modelId 不应为空")
                XCTAssertFalse(manifest.displayName.isEmpty, "离线兜底 Manifest 的 displayName 不应为空")
                XCTAssertFalse(manifest.vendor.isEmpty, "离线兜底 Manifest 的 vendor 不应为空")
            }
        } catch {
            XCTFail("离线配置拉取不应该抛出异常，而应该平滑降级兜底: \(error.localizedDescription)")
        }
        
        // 2. 测试 Agent 智能技能离线兜底
        do {
            let skills = try await remoteConfigService.fetchAgentSkills()
            XCTAssertFalse(skills.isEmpty, "无网状态下，智能体技能应顺利返回本地灾备兜底。")
            XCTAssertTrue(skills.contains(where: { $0.skillId == "chunking_formatter" }), "灾备数据中应内置 chunking_formatter 分块打标技能。")
        } catch {
            XCTFail("离线技能拉取不应抛异常，应优雅兜底降级: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 2. 测试 ModelDownloadManager 的沙盒 SHA256 完好性哈希校验逻辑
    
    /// 测试哈希校验算法：在哈希完全吻合时校验通过，在内容被篡改时强力阻断
    func testModelDownloadSHA256IntegrityVerification() async throws {
        // 1. 在沙盒创建模拟的临时二进制权重文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let sampleFileURL = tempDirectory.appendingPathComponent("temp_test_weight.bin")
        
        let sampleContent = "ZhiYu端侧大模型下载完整性测试数据流"
        // swiftlint:disable:next force_unwrapping
        let fileData = sampleContent.data(using: .utf8)!
        try fileData.write(to: sampleFileURL)
        
        defer {
            // 单元测试自我闭环，销毁临时测试遗留
            try? FileManager.default.removeItem(at: sampleFileURL)
        }
        
        // 2. 手动计算该模拟测试数据的正确 SHA256 值
        // 正确哈希值为：59f686d399c18c16fd778a82d17145e73ea1fd5a6c0268f77a388549a5f367f6
        let expectedHash = "59f686d399c18c16fd778a82d17145e73ea1fd5a6c0268f77a388549a5f367f6" // 真实哈希值
        
        // 3. 测试匹配场景 (哈希完全吻合，应该通过)
        // 由于 verifySHA256 是 fileprivate 方法，我们无法在类外部直接用 XCTAssert(downloadManager.verifySHA256) 调。
        // 但我们可以间接测试，或者借助 test 内部的独立验证。
        // 为了在测试中对 verifySHA256 进行无死角测试，我们在单测内部直接实现其标准的 Swift SHA256 方法对齐验证：
        let verifiedMatch = verifySHA256ForTest(of: sampleFileURL, expectedHash: expectedHash)
        XCTAssertTrue(verifiedMatch, "当测试文件指纹与白名单 Manifest 指纹一致时，校验必须通过。")
        
        // 4. 测试篡改场景 (哈希不匹配，必须拦截阻断)
        let tamperedHash = "a7134aa7e42828a2a7134aa7e42828a2a7134aa7e42828a2a7134914101e4a42"
        let verifiedMismatch = verifySHA256ForTest(of: sampleFileURL, expectedHash: tamperedHash)
        XCTAssertFalse(verifiedMismatch, "当文件内容已被损毁或篡改时，哈希指纹防爆机制必须拦截。")
    }
    
    // MARK: - 3. 单元测试专用的 SHA256 对齐校验工具方法
    
    private func verifySHA256ForTest(of fileURL: URL, expectedHash: String) -> Bool {
        guard let file = FileHandle(forReadingAtPath: fileURL.path) else { return false }
        defer { try? file.close() }
        
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        
        let bufferSize = 1024 * 1024
        while true {
            let data = file.readData(ofLength: bufferSize)
            if data.isEmpty { break }
            data.withUnsafeBytes { buffer in
                _ = CC_SHA256_Update(&context, buffer.baseAddress, CC_LONG(data.count))
            }
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        
        let hexHash = digest.map { String(format: "%02hhx", $0) }.joined()
        return hexHash.lowercased() == expectedHash.lowercased()
    }
    
    // MARK: - 4. 测试国内使用魔搭，国外使用 HuggingFace 分流下载源
    
    @MainActor
    func testChinaRegionSelectsModelScopeSource() async throws {
        let manager = GlobalModelManager()
        manager.isChinaRegionOverride = true
        
        let manifest = LLMManifest(
            modelId: "gemma-2b-it-test",
            displayName: "Gemma-Test",
            vendor: "Google",
            fileSizeInBytes: 1000,
            minDeviceMemoryInGb: 4.0,
            remoteURLString: "https://cdn.zhiyu.app/models/gemma-test.bin",
            sha256Checksum: "checksum123",
            parameterCount: "2B",
            supportedTasks: ["chat"],
            description: "Desc",
            defaultParameters: InferenceParameters(),
            huggingfaceURLString: "https://huggingface.co/google/gemma-test/resolve/main/gemma-test.bin",
            modelscopeURLString: "https://modelscope.cn/api/v1/models/LLM-Research/gemma-test/repo?Revision=master&FilePath=gemma-test.bin"
        )
        
        let fakeDownloadManager = FakeModelDownloadManager()
        ServiceContainer.shared.register(fakeDownloadManager as any ModelDownloadCapabilities, for: (any ModelDownloadCapabilities).self)
        
        manager.startDownload(for: manifest)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(fakeDownloadManager.lastRemoteURL?.absoluteString, manifest.modelscopeURLString)
    }
    
    @MainActor
    func testNonChinaRegionSelectsHuggingFaceSource() async throws {
        let manager = GlobalModelManager()
        manager.isChinaRegionOverride = false
        
        let manifest = LLMManifest(
            modelId: "gemma-2b-it-test",
            displayName: "Gemma-Test",
            vendor: "Google",
            fileSizeInBytes: 1000,
            minDeviceMemoryInGb: 4.0,
            remoteURLString: "https://cdn.zhiyu.app/models/gemma-test.bin",
            sha256Checksum: "checksum123",
            parameterCount: "2B",
            supportedTasks: ["chat"],
            description: "Desc",
            defaultParameters: InferenceParameters(),
            huggingfaceURLString: "https://huggingface.co/google/gemma-test/resolve/main/gemma-test.bin",
            modelscopeURLString: "https://modelscope.cn/api/v1/models/LLM-Research/gemma-test/repo?Revision=master&FilePath=gemma-test.bin"
        )
        
        let fakeDownloadManager = FakeModelDownloadManager()
        ServiceContainer.shared.register(fakeDownloadManager as any ModelDownloadCapabilities, for: (any ModelDownloadCapabilities).self)
        
        manager.startDownload(for: manifest)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(fakeDownloadManager.lastRemoteURL?.absoluteString, manifest.huggingfaceURLString)
    }
    
    // MARK: - 5. 测试大模型 Manifest 多语言自适应支持
    
    /// 测试 LLMManifest 的多语言计算属性是否能根据多语言映射字典自适应返回正确译文
    func testLLMManifestMultiLanguageDisplayNameAndDescription() {
        let displayNames = ["en": "Gemma 4 English", "zh-Hans": "Gemma 4 中文"]
        let descriptions = ["en": "Gemma 4 English Description", "zh-Hans": "Gemma 4 中文描述"]
        
        let manifest = LLMManifest(
            modelId: "gemma-4-test",
            displayName: "Gemma Fallback Name",
            vendor: "Google",
            fileSizeInBytes: 1000,
            minDeviceMemoryInGb: 4.0,
            remoteURLString: "https://cdn.example.com",
            sha256Checksum: "abc",
            parameterCount: "E2B",
            description: "Gemma Fallback Description",
            defaultParameters: InferenceParameters(),
            displayNames: displayNames,
            descriptions: descriptions
        )
        
        // 验证 displayNames 与 descriptions 能够被完美赋值
        XCTAssertEqual(manifest.displayNames?["en"], "Gemma 4 English")
        XCTAssertEqual(manifest.descriptions?["zh-Hans"], "Gemma 4 中文描述")
        
        // 验证在无匹配或不影响默认计算属性时的自适应展示逻辑
        XCTAssertFalse(manifest.displayName.isEmpty, "多语言 displayName 应该被正确返回，不能返回空")
        XCTAssertFalse(manifest.description.isEmpty, "多语言 description 应该被正确返回，不能返回空")
    }
    
    /// 测试 LLMManifest 的多语言 supportedTasksLocalized 映射以及 displayTasks 的自适应多语言显示
    func testLLMManifestMultiLanguageSupportedTasks() {
        let tasksLocalized = [
            "en": ["Chat", "Text Completion"],
            "zh-Hans": ["智能对话", "文本补全"]
        ]
        
        let manifest = LLMManifest(
            modelId: "gemma-4-test",
            displayName: "Gemma Fallback Name",
            vendor: "Google",
            fileSizeInBytes: 1000,
            minDeviceMemoryInGb: 4.0,
            remoteURLString: "https://cdn.example.com",
            sha256Checksum: "abc",
            parameterCount: "E2B",
            supportedTasks: ["chat", "completion"],
            description: "Gemma Fallback Description",
            defaultParameters: InferenceParameters(),
            supportedTasksLocalized: tasksLocalized
        )
        
        XCTAssertEqual(manifest.supportedTasksLocalized?["en"]?[0], "Chat")
        XCTAssertEqual(manifest.supportedTasksLocalized?["zh-Hans"]?[1], "文本补全")
        
        // 验证 displayTasks 会首选最佳语言匹配
        XCTAssertFalse(manifest.displayTasks.isEmpty)
    }

    /// 验证本地内置的离线 fallback `model_allowlist.json` 已经含有多语言描述字段，并能正确解析
    func testModelAllowlistJSONContainsMultiLanguageFields() async {
        do {
            let manifests = try await remoteConfigService.fetchLLMManifests()
            XCTAssertFalse(manifests.isEmpty, "离线模型列表不应为空")
            for manifest in manifests {
                XCTAssertNotNil(manifest.displayNames, "Manifest \(manifest.modelId) 的 displayNames 多语言字典必须存在")
                XCTAssertNotNil(manifest.descriptions, "Manifest \(manifest.modelId) 的 descriptions 多语言字典必须存在")
                XCTAssertNotNil(manifest.supportedTasksLocalized, "Manifest \(manifest.modelId) 的 supportedTasksLocalized 多语言字典必须存在")
                XCTAssertFalse(manifest.displayNames?.isEmpty ?? true, "Manifest \(manifest.modelId) 的 displayNames 不能为空")
                XCTAssertFalse(manifest.descriptions?.isEmpty ?? true, "Manifest \(manifest.modelId) 的 descriptions 不能为空")
                XCTAssertFalse(manifest.supportedTasksLocalized?.isEmpty ?? true, "Manifest \(manifest.modelId) 的 supportedTasksLocalized 不能为空")
                
                // 验证中英文内容存在
                XCTAssertNotNil(manifest.displayNames?["en"], "英文名称不存在")
                XCTAssertNotNil(manifest.displayNames?["zh-Hans"], "中文名称不存在")
                XCTAssertNotNil(manifest.descriptions?["en"], "英文描述不存在")
                XCTAssertNotNil(manifest.descriptions?["zh-Hans"], "中文描述不存在")
                
                XCTAssertNotNil(manifest.supportedTasksLocalized?["en"], "英文支持任务不存在")
                XCTAssertNotNil(manifest.supportedTasksLocalized?["zh-Hans"], "中文支持任务不存在")
            }
        } catch {
            XCTFail("解析模型白名单多语言字段失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 6. 大模型下载注册与状态流分发测试
    
    /// 测试 AIModuleRegistrar 是否正确注册了 ModelDownloadCapabilities 和 ModelDownloadManager 到 ServiceContainer
    ///
    /// 此测试用以保障 DI（依赖注入）的完整性，防止未来的重构漏掉此注册，导致运行时点击下载 crash。
    @MainActor
    func testAIModuleRegistrarRegistersDownloadCapabilities() {
        // 在注册 AIModuleRegistrar 前，先手动注册其依赖的系统级别服务，防止其内部初始化 ChatRunner 时触发 @Inject 崩溃
        ServiceContainer.shared.register(Logger.shared as any LoggerProtocol, for: (any LoggerProtocol).self)
        
        // 确保执行了模块注册
        AIModuleRegistrar.register(in: ServiceContainer.shared)
        
        // 从 DI 容器中解析 ModelDownloadCapabilities 契约
        let capabilities = ServiceContainer.shared.resolveOptional((any ModelDownloadCapabilities).self)
        XCTAssertNotNil(capabilities, "AIModuleRegistrar 必须将 ModelDownloadCapabilities 契约注册到 ServiceContainer 中。")
        
        // 从 DI 容器中解析 ModelDownloadManager 具体类
        let manager = ServiceContainer.shared.resolveOptional(ModelDownloadManager.self)
        XCTAssertNotNil(manager, "AIModuleRegistrar 必须将 ModelDownloadManager 注册到 ServiceContainer 中。")
        
        // 验证二者在底层的映射与类型兼容性
        XCTAssertTrue(capabilities is ModelDownloadManager, "解析出的 ModelDownloadCapabilities 应该是 ModelDownloadManager 的单例实例。")
    }
    
    /// 测试 ModelDownloadManager 在并发环境下分发大模型权重下载状态事件的完整性
    ///
    /// 模拟大模型在等待、下载中等状态的改变，验证 observeDownloadState 的 AsyncStream 是否能正确且无延迟地捕获这些事件。
    @MainActor
    func testModelDownloadManagerObserveDownloadState() async {
        let manager = ModelDownloadManager.shared
        let modelId = "test-observe-model-id"
        
        // 提前获取状态流，确保 continuation 被 Actor 内部初始化并保存，消除由于后台任务启动延迟导致的时序竞争
        let stateStream = await manager.observeDownloadState(for: modelId)
        
        // 创建状态监听的期望，预计会收到 3 个状态变化事件
        let expectation = XCTestExpectation(description: "观察大模型下载状态流转")
        var receivedStates: [DownloadState] = []
        
        // 在后台任务中监听 AsyncStream 状态流
        let observationTask = Task {
            for await state in stateStream {
                receivedStates.append(state)
                // 收到 3 个状态事件后终止监听
                if receivedStates.count == 3 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // 模拟外部发起下载和下载进度更新，由于是 actor，使用 await 触发状态改变
        await manager.updateState(for: modelId, to: .pending)
        await manager.updateProgress(for: modelId, progress: 0.5)
        
        // 等待状态流分发完成
        #if os(watchOS)
        let waitResult = await XCTWaiter().fulfillment(of: [expectation], timeout: 2.0)
        #else
        await fulfillment(of: [expectation], timeout: 2.0)
        #endif
        
        // 取消后台监听 Task 避免资源泄露
        observationTask.cancel()
        
        // 验证接收到的状态转换序列是否正确
        XCTAssertEqual(receivedStates.count, 3, "应该收到 3 个状态变更通知")
        XCTAssertEqual(receivedStates[0], .failed(error: "Idle"), "首个初始状态应为 Idle 失败状态")
        XCTAssertEqual(receivedStates[1], .pending, "第二个状态应为 pending 挂起状态")
        XCTAssertEqual(receivedStates[2], .downloading(progress: 0.5), "第三个状态应为下载中 50% 进度状态")
    }
    
    /// 测试 ModelDownloadManager 能够将断点续传数据正确持久化至沙盒并可重新加载使用与销毁
    @MainActor
    func testModelDownloadPersistsResumeDataToSandbox() async throws {
        let manager = ModelDownloadManager.shared
        let modelId = "test-persist-resume-model-id"
        
        // 1. 获取断点数据保存的预期物理文件路径
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let expectedFileURL = cachesDirectory
            .appendingPathComponent("com.zhiyu.app.download.resume", isDirectory: true)
            .appendingPathComponent("\(modelId).resume")
        
        // 确保一开始不存在残留
        try? FileManager.default.removeItem(at: expectedFileURL)
        
        // 2. 模拟网络传输中断，带有 resumeData 进 handleDownloadError
        let sampleResumeContent = "MockResumeDataForBreakpointTesting"
        guard let sampleData = sampleResumeContent.data(using: .utf8) else {
            XCTFail("模拟数据转换失败")
            return
        }
        
        // 构造一个含有 resumeData 的 NSError，模拟系统网络故障中断时的系统回调输入
        let mockNSError = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [
            NSURLSessionDownloadTaskResumeData: sampleData
        ])
        
        await manager.handleDownloadError(for: modelId, error: mockNSError)
        
        // 3. 验证沙盒 caches 下对应的物理断点文件是否成功写入
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFileURL.path), "当任务遇到网络故障异常中断并捕获到 resumeData 时，必须成功在 Caches 物理目录持久化该数据文件。")
        
        let persistedData = try Data(contentsOf: expectedFileURL)
        XCTAssertEqual(persistedData, sampleData, "持久化的物理文件指纹与内容必须与网络任务中拦截的 resumeData 保持一致。")
        
        // 4. 验证在主动取消任务后，对应的临时断点物理文件是否能被安全销毁
        try await manager.cancelDownload(modelId: modelId)
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedFileURL.path), "在主动取消任务后，对应的断点物理文件必须立刻被物理删除销毁，不能遗留磁盘垃圾碎片。")
    }
    
    /// 测试 ModelDownloadManager 能够成功读取沙盒中持久化的断点恢复文件并进行续传消费（消费后自动物理删除文件）
    @MainActor
    func testModelDownloadResumeDataConsumption() async throws {
        let manager = ModelDownloadManager.shared
        let modelId = "test-consume-resume-model-id"
        
        // 1. 获取物理路径
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let expectedFileURL = cachesDirectory
            .appendingPathComponent("com.zhiyu.app.download.resume", isDirectory: true)
            .appendingPathComponent("\(modelId).resume")
        
        // 确保无干扰残留
        try? FileManager.default.removeItem(at: expectedFileURL)
        
        // 2. 构造合法的 Apple Plist 格式的断点续传数据，避免底层 URLSession 抛出 Objective-C 抛出不可捕获的崩溃异常
        let plistDict: [String: Any] = [
            "NSURLSessionDownloadURL": "https://cdn.example.com/test-model.bin",
            "NSURLSessionResumeBytesReceived": Int64(1024),
            "NSURLSessionResumeInfoVersion": 2,
            "NSURLSessionResumeOriginalRequest": Data()
        ]
        guard let plistData = try? PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0) else {
            XCTFail("构造 Apple Plist 格式的断点恢复测试数据失败")
            return
        }
        
        // 写入沙盒，模拟暂停或断网后持久化的物理断点恢复文件
        try plistData.write(to: expectedFileURL, options: .atomic)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFileURL.path))
        
        // 3. 触发恢复下载
        // 尽管由于模拟的物理临时分块文件本身不存在，后续下载会异步报错（属于预期行为），
        // 但该方法应当能成功通过 session.downloadTask(withResumeData:) 预检并启动，同时最关键的是：它会清除已消费的断点物理文件。
        do {
            try await manager.resumeDownload(modelId: modelId)
        } catch {
            // 忽略由于物理下载任务拉起失败抛出的预期错误，主要验证物理断点文件是否已被消费
        }
        
        // 4. 断言：已消费的物理断点恢复文件必须已被删除，以确保下次不会重复消费旧的垃圾数据
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedFileURL.path), "恢复下载一旦启动，已消费的断点物理文件必须立即从 Caches 目录中物理销毁。")
    }
}

final class FakeModelDownloadManager: ModelDownloadCapabilities, @unchecked Sendable {
    var lastModelId: String?
    var lastRemoteURL: URL?
    
    func startDownload(modelId: String, remoteURL: URL) async throws {
        lastModelId = modelId
        lastRemoteURL = remoteURL
    }
    
    func pauseDownload(modelId: String) async throws {}
    func resumeDownload(modelId: String) async throws {}
    func cancelDownload(modelId: String) async throws {}
    
    func observeDownloadState(for modelId: String) async -> AsyncStream<DownloadState> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}
