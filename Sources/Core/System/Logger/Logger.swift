// Logger.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：本文件定义了全站通用的日志记录系统（Logger），旨在为系统提供统一、高性能且具备持久化能力的监控与调试支持。
// 遵循 @Docs/Requirements/SOFTWARE_REQUIREMENTS_SPECIFICATION.md 中的 DFX 设计要求。
// 该组件通过以下核心功能点保障系统的可观测性：
// 1. 实现分级日志管理（Debug/Error），支持根据编译环境自动切换输出策略，优化生产环境性能。
// 2. 提供基于磁盘持久化的操作日志系统，通过 JSON 序列化技术将操作记录保存至应用沙盒，支持多级缓冲与异步保存。
// 3. 集成 Combine 框架，通过发布者-订阅者模式实时推送日志更新，驱动 UI 层的日志中心进行响应式渲染。
// 
// MARK: @SRS-7.1 (日志记录规范实施)
// MARK: @SRS-7.2 (性能度量标准实施)
//
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 迁移至 Utils/System 并重构为核心工具类，强化了功能说明注释
//   - 2026-05-15: 迁移至 Sources/Core/Logger 并进行卓越工程标准化，添加 SRS 溯源
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

// MARK: - Models

/// 操作执行状态
enum LogStatus: String, Codable {
    case success
    case failure
    case processing
    
    var localizedName: String {
        switch self {
        case .success: return L10n.Common.tr("success")
        case .failure: return L10n.Common.tr("failed")
        case .processing: return L10n.Common.tr("processing")
        }
    }
}

/// 操作日志条目模型，记录系统操作的元数据
struct LogEntry: Identifiable, Codable {
    var id: UUID
    var action: LogAction
    var target: String
    var details: String
    var timestamp: Date
    var duration: TimeInterval?
    var startTime: Date?
    var endTime: Date?
    var module: String? // 来源模块，如 SystemVault, AppStore
    var status: LogStatus?
    var failureReason: String?
    
    /// @SRS-7.1: 初始化日志条目，包含所有必要的元数据
    init(
        id: UUID = UUID(),
        action: LogAction,
        target: String,
        details: String = "",
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        module: String? = nil,
        status: LogStatus? = nil,
        failureReason: String? = nil
    ) {
        self.id = id
        self.action = action
        self.target = target
        self.details = details
        self.timestamp = timestamp
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.module = module
        self.status = status
        self.failureReason = failureReason
    }
}

/// 日志记录协议，定义日志输出与持久化的核心行为
protocol LoggerProtocol: AnyObject, Sendable {
    var logEntries: [LogEntry] { get }
    var logEntriesPublisher: AnyPublisher<[LogEntry], Never> { get }
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?, status: LogStatus?, failureReason: String?)
    func debug(_ message: String, file: String, function: String, line: Int)
    func info(_ message: String, file: String, function: String, line: Int)
    func warning(_ message: String, file: String, function: String, line: Int)
    func error(_ message: String, error: Error?, file: String, function: String, line: Int)
    func saveToDisk()
    func loadFromDisk()
    func clearAllLogs()
    
    /// 执行并记录一个耗时操作 (@SRS-7.2)
    func logTimed<T>(action: LogAction, target: String, module: String?, details: String, operation: () throws -> T) rethrows -> T
}

extension LoggerProtocol {
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.debug(message, file: file, function: function, line: line)
    }
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.info(message, file: file, function: function, line: line)
    }
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.warning(message, file: file, function: function, line: line)
    }
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        self.error(message, error: error, file: file, function: function, line: line)
    }
    
    /// 提供 addLog 的默认参数支持
    func addLog(
        action: LogAction,
        target: String,
        details: String = "",
        duration: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        module: String? = nil,
        status: LogStatus? = nil,
        failureReason: String? = nil
    ) {
        self.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module, status: status, failureReason: failureReason)
    }
}

// MARK: - Logger (Standardized Logging)
/// [L0] 核心层：管理操作日志的持久化与内存缓存
/// 遵循单责任原则，专注于日志生命周期管理。
final class Logger: ObservableObject, LoggerProtocol, @unchecked Sendable {
    static let shared = Logger() // 全局共享实例
    
    @Published var logEntries: [LogEntry] = []
    
    var logEntriesPublisher: AnyPublisher<[LogEntry], Never> {
        $logEntries.eraseToAnyPublisher()
    }
    
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    /// 输出调试日志，仅在 DEBUG 模式下生效
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("🔍 [DEBUG] [\(fileName):\(line)] \(function) -> \(message)")
        #endif
    }
    
    /// 输出常规信息日志
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        print("ℹ️ [INFO] [\(fileName):\(line)] \(function) -> \(message)")
    }
    
    /// 输出警告日志
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        print("⚠️ [WARN] [\(fileName):\(line)] \(function) -> \(message)")
    }
    
    /// 输出错误日志，并自动同步至操作日志 (@SRS-7.1)
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let errorDesc = error?.localizedDescription ?? "None"
        print("❌ [ERROR] [\(fileName):\(line)] \(function) -> \(message) (Error: \(errorDesc))")
        
        // 重要错误也记录到操作日志
        addLog(action: .error, target: fileName, details: "\(message): \(errorDesc)")
    }

    private let logKey = "knowledge-management_logs"
    private let customDirectory: URL?
    
    private var documentsDirectory: URL {
        customDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    internal var logsFileURL: URL {
        documentsDirectory.appendingPathComponent(AppConfig.logsFileName)
    }
    
    // MARK: - Constants
    /// 最大保留日志条目数，防止内存溢出
    private static let maxLogEntries = 500
    
    // MARK: - Init
    init(customDirectory: URL? = nil) {
        self.customDirectory = customDirectory
        loadFromDisk()
        setupSubscriptions()
    }

    /// 设置事件总线订阅，支持远程清除指令
    private func setupSubscriptions() {
        Task { @MainActor in
            AppEventBus.shared.subscribe()
                .receive(on: RunLoop.main)
                .sink { [weak self] event in
                    if case .clearAllDataRequested = event {
                        self?.clearAllLogs()
                    }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Add Entry
    /// 新增一条日志记录 (@SRS-7.1)
    func addLog(
        action: LogAction,
        target: String,
        details: String = "",
        duration: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        module: String? = nil,
        status: LogStatus? = nil,
        failureReason: String? = nil
    ) {
        let entry = LogEntry(
            action: action,
            target: target,
            details: details,
            duration: duration,
            startTime: startTime,
            endTime: endTime,
            module: module,
            status: status,
            failureReason: failureReason
        )
        
        // 打印到控制台，方便调试
        logToConsole(entry)

        Task { @MainActor in
            logEntries.insert(entry, at: 0)
            if logEntries.count > Self.maxLogEntries { 
                logEntries = Array(logEntries.prefix(Self.maxLogEntries)) 
            }
            saveToDisk()
        }
    }

    /// 辅助方法：将日志条目格式化输出至控制台
    private func logToConsole(_ entry: LogEntry) {
        let durationStr = entry.duration.map { " (耗时: \($0.formattedAdaptive))" } ?? ""
        let statusEmoji: String
        switch entry.status {
        case .success: statusEmoji = "✅"
        case .failure: statusEmoji = "❌"
        case .processing: statusEmoji = "⏳"
        case .none: statusEmoji = entry.action == .error ? "❌" : "📝"
        }
        
        print("\(statusEmoji) [LOG] [\(entry.module ?? "System")] \(entry.action.localizedName) -> \(entry.target): \(entry.details)\(durationStr)")
    }

    /// 执行并记录耗时操作 (@SRS-7.2)
    /// 用于 PR-01, PR-02 等性能需求的监控
    func logTimed<T>(
        action: LogAction,
        target: String,
        module: String? = nil,
        details: String = "",
        operation: () throws -> T
    ) rethrows -> T {
        let startTime = Date()
        do {
            let result = try operation()
            let duration = Date().timeIntervalSince(startTime)
            addLog(action: action, target: target, details: details, duration: duration, 
                   startTime: startTime, endTime: Date(), module: module, status: .success)
            return result
        } catch {
            addLog(action: action == .error ? .error : action, target: target, details: details, 
                   duration: Date().timeIntervalSince(startTime), startTime: startTime, 
                   endTime: Date(), module: module, status: .failure, failureReason: error.localizedDescription)
            throw error
        }
    }

    // MARK: - Persistence
    /// 将内存日志异步保存至磁盘 (@RR-01 事务性保障)
    func saveToDisk() {
        let entries = self.logEntries
        
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            do {
                let data = try encoder.encode(entries)
                try data.write(to: self.logsFileURL, options: .atomicWrite)
            } catch {
                print("❌ [Logger] Failed to save logs: \(error.localizedDescription)")
            }
        }
    }

    /// 从磁盘加载历史日志
    func loadFromDisk() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: logsFileURL)
            let loadedEntries = try decoder.decode([LogEntry].self, from: data)
            Task { @MainActor in
                self.logEntries = loadedEntries
            }
        } catch {
            migrateFromUserDefaults(decoder: decoder)
        }
    }

    /// 从旧版本 UserDefaults 迁移数据
    private func migrateFromUserDefaults(decoder: JSONDecoder) {
        if let data = UserDefaults.standard.data(forKey: logKey),
           let decoded = try? decoder.decode([LogEntry].self, from: data) {
            Task { @MainActor in
                self.logEntries = decoded
                self.saveToDisk()
                UserDefaults.standard.removeObject(forKey: self.logKey)
            }
        }
    }

    /// 清空所有日志
    func clearAllLogs() {
        Task { @MainActor in
            logEntries.removeAll()
            saveToDisk()
        }
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    /// 自动根据量级选择最合适的单位进行格式化 (µs, ms, s, m)
    var formattedAdaptive: String {
        if self < 0.001 {
            return String(format: "%.0fµs", self * 1_000_000)
        } else if self < 1.0 {
            return String(format: "%.1fms", self * 1000)
        } else if self < 60.0 {
            return String(format: "%.2fs", self)
        } else {
            let minutes = Int(self) / 60
            let seconds = self.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm %.1fs", minutes, seconds)
        }
    }
}
