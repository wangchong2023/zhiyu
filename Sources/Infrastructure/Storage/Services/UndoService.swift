//
//  UndoService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 Undo 模块的核心业务逻辑服务。
//
import Foundation
import Combine

// MARK: - Undo Service
/// Manages undo/redo for AppStore operations using snapshot-based approach.
/// Each mutation saves a snapshot of pages before the change, enabling full rollback.
final class UndoService: ObservableObject {
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    private var undoStack: [[KnowledgePage]] = []
    private var redoStack: [[KnowledgePage]] = []
    private let maxStackSize = 50

    // MARK: - Snapshot Management
    /// 推送Snapshot
    /// - Parameter pages: pages
    func pushSnapshot(_ pages: [KnowledgePage]) {
        undoStack.append(pages.map { $0 })
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        // Any new action clears the redo stack
        redoStack.removeAll()
        updatePublishedState()
    }

    /// 撤销
    /// - Parameter currentPages: currentPages
    /// - Returns: 列表
    func undo(currentPages: [KnowledgePage]) -> [KnowledgePage]? {
        guard !undoStack.isEmpty else { return nil }
        // Save current state to redo stack
        redoStack.append(currentPages.map { $0 })
        let previous = undoStack.removeLast()
        updatePublishedState()
        return previous
    }

    /// 重做
    /// - Parameter currentPages: currentPages
    /// - Returns: 列表
    func redo(currentPages: [KnowledgePage]) -> [KnowledgePage]? {
        guard !redoStack.isEmpty else { return nil }
        // Save current state to undo stack
        undoStack.append(currentPages.map { $0 })
        let next = redoStack.removeLast()
        updatePublishedState()
        return next
    }

    /// 清除
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updatePublishedState()
    }

    private func updatePublishedState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}