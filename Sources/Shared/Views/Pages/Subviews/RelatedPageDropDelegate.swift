// RelatedPageDropDelegate.swift
//
// 作者: Wang Chong
// 功能说明: 相关页面排序拖拽代理，实现知识图谱节点关联的手动排序功能。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import UniformTypeIdentifiers

#if !os(watchOS)
/// 相关页面排序拖拽代理
struct RelatedPageDropDelegate: DropDelegate {
    let item: KnowledgePage
    @Binding var page: KnowledgePage

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let fromItem = info.itemProviders(for: [.text]).first else { return }
        
        fromItem.loadObject(ofClass: NSString.self) { (uuidString, error) in
            guard let uuidString = uuidString as? String,
                  let fromID = UUID(uuidString: uuidString),
                  fromID != item.id else { return }
            
            DispatchQueue.main.async {
                let fromIndex = page.relatedPageIDs.firstIndex(of: fromID)
                let toIndex = page.relatedPageIDs.firstIndex(of: item.id)
                
                if let from = fromIndex, let to = toIndex {
                    withAnimation {
                        page.relatedPageIDs.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                    }
                }
            }
        }
    }
}
#endif
