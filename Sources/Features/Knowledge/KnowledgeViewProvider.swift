//
//  KnowledgeViewProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：SwiftUI 视图，负责 KnowledgeProvider 界面的布局与渲染。
//
import SwiftUI

struct KnowledgeViewProvider: ViewProvider {

    /// 创建View
    /// - Returns: 可选值
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
