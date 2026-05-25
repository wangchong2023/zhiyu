//
//  PDFKitRepresentedView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：构建 PDFKitRepresented 界面的 UI 视图层组件。
//
#if canImport(PDFKit)
import SwiftUI
import PDFKit

/// PDFKit 包装视图
struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFKit.PDFDocument
    @Binding var currentPage: Int
    var onTextSelected: (String) -> Void

    /// 创建UIView
    /// /// - Parameter context: context
    /// /// - Returns: 返回值
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    /// 更新UIView
    /// /// - Parameter pdfView: pdfView
    /// /// - Parameter context: context
    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.parent = self
    }

    /// 创建Coordinator
    /// /// - Returns: 返回值
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject {
        var parent: PDFKitRepresentedView

        init(_ parent: PDFKitRepresentedView) {
            self.parent = parent
        }

        /// pageChanged
        /// /// - Parameter notification: notification
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: page)
            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }
    }
}
#endif
