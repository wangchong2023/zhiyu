// TaskCenter.swift
//
// 作者: Wang Chong
// 功能说明: 任务类型与管理中心
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 移除平台宏污染，隔离 ActivityService。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// 任务类型
enum TaskType: String, CaseIterable {
    case ai             // 通用 AI 任务
    case ingest         // 导入任务
    case aiScan         // AI 扫描
    case healthCheck    // 健康检查
    case synthesis      // 知识合成

    var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .ingest: return "tray.and.arrow.down"
        case .aiScan: return "bolt.shield.fill"
        case .healthCheck: return "stethoscope"
        case .synthesis: return "wand.and.stars"
        }
    }

    var defaultColor: String {
        switch self {
        case .ingest: return "blue"
        case .healthCheck: return "red"
        case .aiScan, .ai: return "orange"
        case .synthesis: return "purple"
        }
    }
}

/// 任务执行状态
enum TaskStatus: Equatable {
    case pending                    // 等待中
    case running(progress: Double)  // 执行中（带进度）
    case completed                  // 已完成
    case failed(error: String)      // 执行失败（带错误信息）

    static func == (lhs: TaskStatus, rhs: TaskStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending): return true
        case (.completed, .completed): return true
        case (.running(let p1), .running(let p2)): return p1 == p2
        case (.failed(let e1), .failed(let e2)): return e1 == e2
        default: return false
        }
    }
}

/// 全球异步任务模型
struct GlobalTask: Identifiable {
    let id = UUID()
    let type: TaskType
    let name: String                // 任务名称
    let target: String              // 目标对象
    var status: TaskStatus          // 当前状态
    let startTime = Date()          // 启动时间
    var isRead: Bool = false        // 用户是否已读
    var associatedPageID: UUID? // 关联页面
}

/// 全局任务管理中心 (单例)
@MainActor
class TaskCenter: ObservableObject {
    static let shared = TaskCenter()

    @Published var tasks: [GlobalTask] = []
    @Published var latestStatus: String = ""
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                if case .clearAllDataRequested = event {
                    self?.reset()
                }
            }
            .store(in: &cancellables)
    }

    func updateLatestStatus(_ text: String) {
        self.latestStatus = text
        #if os(iOS)
        // 实时同步到当前“最活跃”的灵动岛（如果存在的话）
        if let firstRunningTask = tasks.first(where: { if case .running = $0.status { return true }; return false }) {
            Task {
                if case .running(let progress) = firstRunningTask.status {
                    await ActivityService.shared.updateProgress(id: firstRunningTask.id, progress: progress, message: text)
                } else {
                    await ActivityService.shared.updateProgress(id: firstRunningTask.id, progress: 0.5, message: text)
                }
            }
        }
        #endif
    }

    struct TaskMetrics {
        let total: Int
        let completed: Int
        let running: Int
        let failed: Int
    }

    func metrics(for type: TaskType) -> TaskMetrics {
        let relevant = tasks.filter { $0.type == type }
        let completed = relevant.filter { $0.status == .completed }.count
        let running = relevant.filter {
            if case .running = $0.status { return true }; return false
        }.count
        let failed = relevant.filter {
            if case .failed = $0.status { return true }; return false
        }.count

        return TaskMetrics(total: relevant.count, completed: completed, running: running, failed: failed)
    }

    var unreadCount: Int {
        tasks.filter { task in
            if task.isRead { return false }
            switch task.status {
            case .completed, .failed: return true
            default: return false
            }
        }.count
    }

    func addTask(type: TaskType = .ai, name: String, target: String) -> UUID {
        let task = GlobalTask(type: type, name: name, target: target, status: .pending)
        self.tasks.insert(task, at: 0)
        self.latestStatus = Localized.trf("aitask.status.startingFormat", name, target)

        #if os(iOS)
        ActivityService.shared.startActivity(id: task.id, name: name, target: target)
        #endif

        return task.id
    }

    func updateTask(_ id: UUID, status: TaskStatus, associatedPageID: UUID? = nil) {
        if let index = self.tasks.firstIndex(where: { $0.id == id }) {
            self.tasks[index].status = status
            if let pageID = associatedPageID {
                self.tasks[index].associatedPageID = pageID
            }

            let task = self.tasks[index]
            switch status {
            case .running(let progress):
                self.latestStatus = Localized.trf("aitask.status.runningFormat", task.name, task.target)
                #if os(iOS)
                Task {
                    await ActivityService.shared.updateProgress(id: task.id, progress: progress, message: self.latestStatus)
                }
                #endif
            case .completed:
                self.latestStatus = Localized.trf("aitask.status.completedFormat", task.name)
                NotificationCenter.default.post(name: .taskCompleted, object: task)
                #if os(iOS)
                Task {
                    await ActivityService.shared.endActivity(id: task.id)
                }
                #endif
            case .failed:
                self.latestStatus = Localized.trf("aitask.status.failedFormat", task.name)
                NotificationCenter.default.post(name: .taskCompleted, object: task)
                #if os(iOS)
                Task {
                    await ActivityService.shared.endActivity(id: task.id)
                }
                #endif
            case .pending:
                break
            }

            if case .completed = status {
                if self.tasks.count > 20 {
                    self.tasks.removeLast()
                }
            }
        }
    }

    func completeTask(id: UUID, associatedPageID: UUID? = nil) {
        updateTask(id, status: .completed, associatedPageID: associatedPageID)
    }

    func failTask(id: UUID, error: String) {
        updateTask(id, status: .failed(error: error))
    }

    func markAsRead(_ id: UUID) {
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == id }) {
                self.tasks[index].isRead = true
            }
        }
    }

    func markAllAsRead() {
        for i in 0..<self.tasks.count {
            self.tasks[i].isRead = true
        }
    }

    func removeTask(_ id: UUID) {
        DispatchQueue.main.async {
            self.tasks.removeAll(where: { $0.id == id })
        }
    }

    func reset() {
        self.tasks.removeAll()
        self.latestStatus = ""
    }
}

extension NSNotification.Name {
    static let taskCompleted = NSNotification.Name("app_task_completed")
}
