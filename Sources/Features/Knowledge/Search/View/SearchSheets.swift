//
//  SearchSheets.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：为 Search 搜索功能模块提供高品质、符合现代设计美学的弹出表单 (Sheet) 视图。
//           1. PagePreviewSheet: 用于快速预览知识卡片页面。
//           2. SearchDiagnosticSheet: 用于深度展示混合检索及 AI 查询重写的召回诊断指标。
//

import SwiftUI

// MARK: - 页面预览弹出页
/// 知识库页面的快速预览表单
struct PagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    /// 待预览的知识卡片页面数据模型
    let page: KnowledgePage
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.large) {
                    // ── 顶部物理解耦卡片横幅 ──
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Image(systemName: page.displayIcon)
                                .font(.title)
                                .foregroundStyle(page.pageType.color)
                                .padding(DesignSystem.small)
                                .background(page.pageType.color.opacity(0.15))
                                .clipShape(Circle())
                            
                            Spacer()
                            
                            // 状态与置信度胶囊
                            HStack(spacing: DesignSystem.tiny) {
                                Text(page.status.displayName)
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, DesignSystem.small)
                                    .padding(.vertical, 4)
                                    .background(page.status.color.opacity(0.15))
                                    .foregroundStyle(page.status.color)
                                    .clipShape(Capsule())
                                
                                Text(page.confidence.displayName)
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, DesignSystem.small)
                                    .padding(.vertical, 4)
                                    .background(page.confidence.color.opacity(0.15))
                                    .foregroundStyle(page.confidence.color)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(page.title)
                            .font(.title)
                            .bold()
                            .foregroundStyle(.primary)
                            .padding(.top, DesignSystem.tiny)
                        
                        Text(page.pageType.displayName)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(page.pageType.color)
                            .padding(.horizontal, DesignSystem.small)
                            .padding(.vertical, 2)
                            .background(page.pageType.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                page.pageType.color.opacity(0.08),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    
                    // ── 标签胶囊流式布局 (使用设计系统内建的 FlowLayout) ──
                    if !page.tags.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                            Text(L10n.Tag.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            
                            FlowLayout(spacing: DesignSystem.tiny) {
                                ForEach(page.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .bold()
                                        .padding(.horizontal, DesignSystem.small)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .foregroundStyle(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // ── 正文内容预览 ──
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        Text(L10n.Knowledge.Page.content)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if page.content.isEmpty {
                            Text(L10n.Search.noResultsHint)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            Text(page.content)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineSpacing(6)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, DesignSystem.huge)
                }
            }
            .background(themeManager.pageBackground())
            .navigationTitle(L10n.Search.base)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.confirm) {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - 搜索检索诊断面板
/// 集中式多维度混合检索与 AI 重写查询的诊断卡片弹出页
struct SearchDiagnosticSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    /// 诊断数据包结构体
    let info: SearchDiagnosticInfo
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.large) {
                    
                    // ── 1. AI 查询重写诊断卡 ──
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                                .font(.headline)
                            Text(L10n.Search.Diag.rewrite)
                                .font(.headline)
                                .bold()
                        }
                        
                        Divider()
                            .background(Color.secondary.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                            Text(L10n.Search.Diag.originalQuery)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .bold()
                            Text(info.query)
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.primary)
                                .padding(DesignSystem.small)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.06))
                                .cornerRadius(DesignSystem.smallRadius)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                            Text(L10n.Search.Diag.rewrittenQuery)
                                .font(.caption2)
                                .foregroundStyle(.purple)
                                .bold()
                            Text(info.rewrittenQuery)
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.purple)
                                .padding(DesignSystem.small)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.06))
                                .cornerRadius(DesignSystem.smallRadius)
                        }
                    }
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(DesignSystem.cardRadius)
                    .shadow(color: DesignSystem.shadowColor.opacity(0.03), radius: DesignSystem.shadowRadius, y: DesignSystem.shadowY)
                    .padding(.horizontal)
                    
                    // ── 2. 多源召回对比圆环/指标面板 ──
                    HStack(spacing: DesignSystem.large) {
                        // 全文检索召回卡
                        VStack(spacing: DesignSystem.tiny) {
                            Text(L10n.Search.Diag.ftsRank)
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.secondary)
                            
                            Text("\(info.ftsCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                            
                            Text("FTS5 SQLite")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(DesignSystem.cardRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        )
                        
                        // 向量检索召回卡
                        VStack(spacing: DesignSystem.tiny) {
                            Text(L10n.Search.Diag.vectorRank)
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.secondary)
                            
                            Text("\(info.vectorCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                            
                            Text("HNSW / Vector")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.05), Color.green.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(DesignSystem.cardRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                                .stroke(Color.green.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // ── 3. RRF (Reciprocal Rank Fusion) 重排精细得分列表 ──
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Image(systemName: "list.number")
                                .foregroundStyle(.orange)
                            Text(L10n.Search.Diag.rrfDetail)
                                .font(.headline)
                                .bold()
                        }
                        .padding(.horizontal)
                        
                        if info.rrfTopResults.isEmpty {
                            Text(L10n.Search.noResults)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(info.rrfTopResults.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: DesignSystem.medium) {
                                        // 序号标识
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(.orange)
                                            .frame(width: 24, height: 24)
                                            .background(Color.orange.opacity(0.1))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            HStack(spacing: DesignSystem.small) {
                                                // FTS 排位
                                                HStack(spacing: 2) {
                                                    Text("FTS:")
                                                    Text(item.ftsRank > 0 ? "#\(item.ftsRank)" : L10n.Search.Diag.miss)
                                                }
                                                .font(.system(size: 10))
                                                .foregroundStyle(item.ftsRank > 0 ? Color.blue : Color.secondary)
                                                
                                                // 向量排位
                                                HStack(spacing: 2) {
                                                    Text("Vec:")
                                                    Text(item.vectorRank > 0 ? "#\(item.vectorRank)" : L10n.Search.Diag.miss)
                                                }
                                                .font(.system(size: 10))
                                                .foregroundStyle(item.vectorRank > 0 ? Color.green : Color.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // 综合 RRF 打分
                                        Text(String(format: L10n.Search.Diag.scoreFormat, item.finalScore))
                                            .font(.system(.subheadline, design: .monospaced))
                                            .bold()
                                            .foregroundStyle(.orange)
                                            .padding(.horizontal, DesignSystem.small)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.06))
                                            .cornerRadius(DesignSystem.microRadius)
                                    }
                                    .padding(.vertical, DesignSystem.small)
                                    .padding(.horizontal)
                                    
                                    if index < info.rrfTopResults.count - 1 {
                                        Divider()
                                            .background(Color.secondary.opacity(0.1))
                                            .padding(.leading, 48)
                                    }
                                }
                            }
                            .background(Color.appCard)
                            .cornerRadius(DesignSystem.cardRadius)
                        }
                    }
                    .padding(.top, DesignSystem.small)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(themeManager.pageBackground())
            .navigationTitle(L10n.Search.Diag.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.confirm) {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
