// KnowledgeViewProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：Knowledge 领域的视图提供者。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct KnowledgeViewProvider: ViewProvider {
    func makeView(for route: AnyHashable) -> AnyView? {
        guard let route = route as? AppRoute, route.domain == .knowledge else { return nil }
        
        switch route {
        case .notebookHub:
            return AnyView(NotebookHubView())
        case .pageList(let type):
            return AnyView(KnowledgePageListView(filterType: type))
        case .pageDetail(let id):
            return AnyView(PageDetailWrapper(id: id))
        case .tagCloud:
            return AnyView(TagCloudView())
        case .ingest:
            return AnyView(IngestView(selectedTab: .constant(.knowledge)))
        case .graph:
            return AnyView(GraphWrapper())
        case .search(let query, let type):
            return AnyView(SearchView(initialQuery: query, initialFilterType: type))
        case .sources:
            return AnyView(SourceView())
        default:
            return nil
        }
    }
}
