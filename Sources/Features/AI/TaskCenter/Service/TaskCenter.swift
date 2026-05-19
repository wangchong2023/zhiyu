// TaskCenter.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：任务类型与管理中心
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

/// RAG / AI 执行阶段 (用于多维视觉反馈)
public enum TaskStage: String, Equatable {
    case pending       = "pending"      // 准备阶段
    case embedding     = "embedding"    // 向量化/特征提取 (Teal)
    case retrieval     = "retrieval"    // 数据库检索/BM25 (Blue)
    case synthesis     = "synthesis"    // 大模型合成生成 (Purple)
    case general       = "general"      // 通用执行 (Orange)
}

/// 任务执行状态
enum TaskStatus: Equatable {
    case pending                                      // 等待中
    case running(progress: Double, stage: TaskStage)  // 执行中（带进度与具体阶段）
    case completed                                    // 已完成
    case failed(error: String)                        // 执行失败（带错误信息）

    static func == (lhs: TaskStatus, rhs: TaskStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending): return true
        case (.completed, .completed): return true
        case let (.running(p1, s1), .running(p2, s2)): return p1 == p2 && s1 == s2
        case let (.failed(e1), .failed(e2)): return e1 == e2
        default: return false
        }
    }
}

/// 全球异步任务模型
struct GlobalTask: Identifiable, Equatable {
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
    
    /// 注入实时活动能力，支持跨平台解耦
    private let activityService: any LiveActivityProtocol = ServiceContainer.shared.resolve((any LiveActivityProtocol).self)

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
        // 实时同步到当前“最活跃”的灵动岛（如果平台支持）
        if let firstRunningTask = tasks.first(where: { if case .running = $0.status { return true }; return false }) {
            Task {
                if case .running(let progress, _) = firstRunningTask.status {
                    await activityService.updateProgress(id: firstRunningTask.id, progress: progress, message: text)
                } else {
                    await activityService.updateProgress(id: firstRunningTask.id, progress: 0.5, message: text)
                }
            }
        }
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
        self.latestStatus = L10n.AI.Task.starting( name, target)

        activityService.startActivity(id: task.id, name: name, target: target)

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
            case .running(let progress, _):
                self.latestStatus = L10n.AI.Task.running( task.name, task.target)
                Task {
                    await activityService.updateProgress(id: task.id, progress: progress, message: self.latestStatus)
                }
            case .completed:
                self.latestStatus = L10n.AI.Task.completed( task.name)
                NotificationCenter.default.post(name: .taskCompleted, object: task)
                Task {
                    await activityService.endActivity(id: task.id)
                }
            case .failed:
                self.latestStatus = L10n.AI.Task.failed( task.name)
                NotificationCenter.default.post(name: .taskCompleted, object: task)
                Task {
                    await activityService.endActivity(id: task.id)
                }
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
