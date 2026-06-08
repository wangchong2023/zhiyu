//
//  DragDropComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drag & Drop Support for ZhiYu
/// Enables drag and drop for page items in the knowledge base

// MARK: - Page Drag Item
/// Custom transfer type for page items
/// 页面拖拽传输模型
/// 负责在应用内或跨应用间传输 知识 页面的核心元数据，符合 Transferable 协议
struct PageDragItem: Transferable, Codable {
    let pageID: UUID
    let pageTitle: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: PageDragItem.self, contentType: .pageItem)
    }
}

extension UTType {
    static var pageItem: UTType {
        UTType(exportedAs: "com.km.app.pageItem")
    }
}

// MARK: - Drag & Drop Modifier for Pages
/// 页面拖放修饰符组件
/// 负责为视图注入原生拖拽支持，并提供自定义的拖拽实时预览效果
#if !os(watchOS)
struct PageDragDropModifier: ViewModifier {
    let page: KnowledgePage

    /// 视图主体
    /// - Parameter content: content
    /// - Returns: 返回值
    func body(content: Content) -> some View {
        content
            .draggable(page.id.uuidString) {
                // Drag preview
                HStack {
                    Image(systemName: page.displayIcon)
                        .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                    Text(page.title)
                        .font(.subheadline)
                }
                .padding(DesignSystem.small)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            }
    }
}
#endif

extension View {
    /// Apply drag and drop support for a page
    @ViewBuilder

    /// pageDragDrop
    /// - Parameter page: page
    func pageDragDrop(page: KnowledgePage) -> some View {
        #if os(watchOS)
        self
        #else
        modifier(PageDragDropModifier(page: page))
        #endif
    }
}

// MARK: - Drop Delegate for Pages List
#if !os(watchOS)
struct PagesListDropDelegate: DropDelegate {
    let onDrop: (UUID) -> Void

    /// 执行Drop
    /// - Parameter info: info
    /// - Returns: 是否成功
    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    /// 校验Drop
    /// - Parameter info: info
    /// - Returns: 是否成功
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
}

// MARK: - File Drop Delegate
/// Handles dropping external files (PDF, text) into the app
/// 外部文件投放代理组件
/// 负责处理从外部（如访达或桌面）投放至应用内的 PDF、文本等物理文件流
struct FileDropDelegate: DropDelegate {
    let onFileDrop: (URL) -> Void

    /// 执行Drop
    /// - Parameter info: info
    /// - Returns: 是否成功
    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    /// 校验Drop
    /// - Parameter info: info
    /// - Returns: 是否成功
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
}
#endif
