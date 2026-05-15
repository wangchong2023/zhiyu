// PDFKitRepresentedView.swift
//
// 作者: Wang Chong
// 功能说明: 将 PDFKit 包装为 SwiftUI 视图。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if canImport(PDFKit)
import SwiftUI
import PDFKit

/// PDFKit 包装视图
struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFKit.PDFDocument
    @Binding var currentPage: Int
    var onTextSelected: (String) -> Void

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

    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator: NSObject {
        var parent: PDFKitRepresentedView

        init(_ parent: PDFKitRepresentedView) {
            self.parent = parent
        }

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
