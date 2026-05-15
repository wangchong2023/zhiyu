// WorkflowService.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：本文件实现了知识管理系统的工作流自动化服务（WorkflowService），作为应用内部知识与外部系统生态（如 Apple 提醒事项、日历）之间的交互枢纽。
// 该服务致力于将静态知识转化为可执行的行动力，核心功能点如下：
// 1. 系统级能力集成：基于 EventKit 框架实现了与 macOS/iOS 原生提醒事项的深度集成，支持全量访问权限的智能请求。
// 2. 智能任务解析：内置 Markdown 任务提取引擎，能够自动识别 AI 生成内容中的待办事项（如 - [ ] 标记），并将其无损转化为系统级提醒。
// 3. 跨应用上下文同步：在建立提醒事项时自动注入知识库来源（Context），确保用户在处理任务时能快速回溯至对应的 知识库 页面。
// 4. 闭环反馈机制：通过 HapticFeedback 建立操作反馈，确保任务同步过程的感知可靠性。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，完善 EventKit 集成与任务解析逻辑说明
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 工作流服务：连接知识与外部系统（如提醒事项、日历）
@MainActor
final class WorkflowService: ObservableObject {
    static let shared = WorkflowService()
    
    @Inject private var appEnv: any AppEnvironmentProtocol
    @Inject private var reminderService: any ReminderServiceProtocol
    
    enum WorkflowError: Error {
        case accessDenied
        case saveFailed
    }
    
    /// 请求提醒事项权限
    func requestAccess() async -> Bool {
        await reminderService.requestAccess()
    }
    
    /// 将 AI 提取的行动项同步至系统提醒事项
    func syncToReminders(text: String, title: String) async throws {
        let hasAccess = await requestAccess()
        guard hasAccess else {
            ToastManager.shared.show(type: .error, message: "无法访问提醒事项，请在系统设置中授权")
            throw WorkflowError.accessDenied 
        }
        
        // 解析 Markdown 任务列表（支持 - [ ], - , *, 1. 等多种格式）
        let lines = text.components(separatedBy: .newlines)
        let tasks = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                // 匹配列表项：- , * , 1. , - [ ]
                line.hasPrefix("-") || line.hasPrefix("*") || (line.count > 2 && line.first?.isNumber == true && line.contains("."))
            }
            .map { line -> String in
                var cleaned = line
                if cleaned.hasPrefix("- [ ] ") || cleaned.hasPrefix("- [x] ") || cleaned.hasPrefix("- [X] ") {
                    cleaned = String(cleaned.dropFirst(6))
                } else if cleaned.hasPrefix("- ") || cleaned.hasPrefix("* ") {
                    cleaned = String(cleaned.dropFirst(2))
                } else if let dotIndex = cleaned.firstIndex(of: "."), !cleaned.prefix(upTo: dotIndex).isEmpty, cleaned.prefix(upTo: dotIndex).allSatisfy({ $0.isNumber }) {
                    cleaned = String(cleaned[cleaned.index(after: dotIndex)...])
                }
                return cleaned.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
        
        print("📝 [Workflow] 提取到待办事项: \(tasks.count) 条")
        
        guard !tasks.isEmpty else {
            print("⚠️ [Workflow] 未能在文本中解析出待办事项")
            ToastManager.shared.show(type: .info, message: "未发现可同步的待办事项（需以列表格式编写）")
            return
        }
        
        ToastManager.shared.show(type: .processing, message: "正在同步 \(tasks.count) 条事项...", duration: 0)
        
        do {
            for task in tasks {
                try await reminderService.createReminder(
                    title: task,
                    notes: "来自智宇：\(title)"
                )
            }
            
            print("✅ [Workflow] 成功同步 \(tasks.count) 条事项至提醒事项")
            ToastManager.shared.dismiss()
            ToastManager.shared.show(type: .success, message: "成功同步 \(tasks.count) 条待办事项")
            HapticFeedback.shared.trigger(.success)
        } catch {
            print("❌ [Workflow] 同步失败: \(error.localizedDescription)")
            ToastManager.shared.dismiss()
            ToastManager.shared.show(type: .error, message: "同步失败: \(error.localizedDescription)")
            throw error
        }
    }
}
