//
//  CollaborationModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation
#if canImport(MultipeerConnectivity)
import MultipeerConnectivity
#endif

// MARK: - Collaboration Models
struct CollabUser: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let deviceName: String
    let joinedAt: Date

    var displayLabel: String { "\(displayName) (\(deviceName))" }
}

struct CollabEdit: Identifiable, Codable {
    let id: String
    let userID: String
    let pageID: UUID
    let field: String
    let oldValue: String
    let newValue: String
    let timestamp: Date
}

enum CollabRole: String, Codable {
    case owner = "owner"
    case editor = "editor"
    case viewer = "viewer"

    var displayName: String {
        switch self {
        case .owner: return L10n.Collaboration.role.owner
        case .editor: return L10n.Collaboration.role.editor
        case .viewer: return L10n.Collaboration.role.viewer
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .editor: return "pencil.circle.fill"
        case .viewer: return "eye.fill"
        }
    }
}

// MARK: - Discovered Room Model
struct DiscoveredRoom: Identifiable, Hashable {
    let id: String
    let platformPeer: AnyHashable // 平台相关的 Peer 对象 (如 MCPeerID)
    let roomName: String
    let owner: String

    static func == (lhs: DiscoveredRoom, rhs: DiscoveredRoom) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
