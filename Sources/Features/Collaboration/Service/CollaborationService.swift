// CollaborationService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的多端实时协作服务 (CollaborationService)。
// 该服务作为协作逻辑的编排器，通过注入的 CollaborationProviderProtocol 实现跨平台的 P2P 数据同步。
// 版本: 1.2
// 修改记录:
//   - 2026-05-13: 彻底重构，实现 MultipeerConnectivity 的物理隔离与协议化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

/// 协作服务代理协议
@MainActor
protocol CollaborationDelegate: AnyObject {
    var pages: [KnowledgePage] { get }
    func applyRemoteUpdate(_ page: KnowledgePage)
    func insertRemotePage(_ page: KnowledgePage)
}

// MARK: - Collaboration Service
/// 实时多用户协作服务（逻辑编排层）
@MainActor
final class CollaborationService: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isAvailable: Bool = false
    @Published var isHosting: Bool = false
    @Published var isJoined: Bool = false
    @Published var connectedPeers: [CollabUser] = []
    @Published var role: CollabRole = .owner
    @Published var roomName: String = ""
    @Published var recentEdits: [CollabEdit] = []
    @Published var statusMessage: String = ""
    @Published var discoveredRooms: [DiscoveredRoom] = []
    @Published var isSimulator: Bool = false
    @Published var connectionError: String?
    @Published var isConnecting: Bool = false

    /// 注入的协作提供商实现
    @Inject private var provider: any CollaborationProviderProtocol

    /// 数据应用代理
    weak var delegate: CollaborationDelegate?

    private let maxRecentEdits = 100

    private let deviceName: String = {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return "Apple Device"
        #endif
    }()
    
    private var userName: String {
        UserDefaults.standard.string(forKey: "app_username") ?? deviceName
    }

    // MARK: - Init
    override init() {
        #if targetEnvironment(simulator)
        isSimulator = true
        #endif
        super.init()
        setupProvider()
        checkAvailability()
    }

    private func setupProvider() {
        provider.delegate = self
    }

    func setDelegate(_ delegate: CollaborationDelegate) {
        self.delegate = delegate
    }

    // MARK: - Availability
    private func checkAvailability() {
        #if targetEnvironment(simulator)
        isAvailable = false
        statusMessage = L10n.Collaboration.tr("status.simulatorNotSupported")
        #else
        isAvailable = true
        statusMessage = L10n.Collaboration.tr("status.ready")
        #endif
    }

    // MARK: - API
    func startHosting(roomName: String) {
        guard isAvailable else { return }
        self.roomName = roomName
        self.role = .owner
        connectionError = nil
        isConnecting = true
        provider.startHosting(roomName: roomName, userName: userName)
        isHosting = true
        isJoined = true
    }

    func startBrowsing() {
        guard isAvailable else { return }
        connectionError = nil
        isConnecting = true
        provider.startBrowsing(userName: userName)
    }

    func joinRoom(_ room: DiscoveredRoom) {
        guard isAvailable else { return }
        self.role = .editor
        isConnecting = true
        provider.joinRoom(room)
    }

    func stop() {
        provider.stop()
        isHosting = false
        isJoined = false
        isConnecting = false
        connectedPeers.removeAll()
        discoveredRooms.removeAll()
        recentEdits.removeAll()
        connectionError = nil
    }

    // MARK: - Data Transmission
    func broadcastEdit(pageID: UUID, field: String, oldValue: String, newValue: String) {
        guard isJoined, role != .viewer else { return }

        let edit = CollabEdit(
            id: UUID().uuidString,
            userID: userName, // 简化标识
            pageID: pageID,
            field: field,
            oldValue: oldValue,
            newValue: newValue,
            timestamp: Date()
        )
        appendEdit(edit)
        if let data = try? JSONEncoder().encode(edit) {
            provider.broadcast(data: data)
        }
    }

    func broadcastPage(_ page: KnowledgePage) {
        guard isJoined, role != .viewer else { return }

        let payload: [String: Any] = [
            "type": "pageSync",
            "page": [
                "id": page.id.uuidString,
                "title": page.title,
                "content": page.content,
                "type": page.type.rawValue,
                "tags": page.tags,
                "status": page.status.rawValue,
                "updated": page.updated.timeIntervalSince1970
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            provider.broadcast(data: data)
        }
    }

    func setUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "app_username")
    }

    private func appendEdit(_ edit: CollabEdit) {
        recentEdits.append(edit)
        if recentEdits.count > maxRecentEdits {
            recentEdits.removeFirst(recentEdits.count - maxRecentEdits)
        }
    }
}

// MARK: - CollaborationProviderDelegate
extension CollaborationService: CollaborationProviderDelegate {
    func providerDidUpdateStatus(_ message: String) {
        self.statusMessage = message
    }
    
    func providerDidDiscoverRoom(_ room: DiscoveredRoom) {
        if !discoveredRooms.contains(where: { $0.id == room.id }) {
            discoveredRooms.append(room)
        }
    }
    
    func providerDidLoseRoom(id: String) {
        discoveredRooms.removeAll { $0.id == id }
    }
    
    func providerDidConnectPeer(_ user: CollabUser) {
        isConnecting = false
        if !connectedPeers.contains(where: { $0.id == user.id }) {
            connectedPeers.append(user)
        }
        isJoined = true
    }
    
    func providerDidDisconnectPeer(id: String) {
        connectedPeers.removeAll { $0.id == id }
        if connectedPeers.isEmpty && !isHosting {
            isJoined = false
        }
    }
    
    func providerDidReceiveData(_ data: Data, from userID: String) {
        // Try to decode as CollabEdit
        if let edit = try? JSONDecoder().decode(CollabEdit.self, from: data) {
            appendEdit(edit)
            return
        }
        
        // Try to decode as page sync
        if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           payload["type"] as? String == "pageSync",
           let pageData = payload["page"] as? [String: Any] {
            applyRemotePage(pageData)
            return
        }
    }
    
    func providerDidEncounterError(_ error: String) {
        self.connectionError = error
        self.isConnecting = false
    }
}

// MARK: - Remote Page Sync
extension CollaborationService {
    private func applyRemotePage(_ pageData: [String: Any]) {
        guard let idString = pageData["id"] as? String,
              let pageID = UUID(uuidString: idString),
              let title = pageData["title"] as? String,
              let content = pageData["content"] as? String,
              let typeRaw = pageData["type"] as? String,
              let pageType = PageType(rawValue: typeRaw),
              let tags = pageData["tags"] as? [String],
              let statusRaw = pageData["status"] as? String,
              let status = PageStatus(rawValue: statusRaw),
              let updatedTs = pageData["updated"] as? TimeInterval
        else { return }

        let remoteUpdated = Date(timeIntervalSince1970: updatedTs)
        guard let delegate = self.delegate else { return }

        if let existingPage = delegate.pages.first(where: { $0.id == pageID }) {
            if remoteUpdated > existingPage.updated {
                var updated = existingPage
                updated.title = title
                updated.content = content
                updated.type = pageType
                updated.tags = tags
                updated.status = status
                updated.updated = remoteUpdated
                delegate.applyRemoteUpdate(updated)
                self.statusMessage = L10n.Collaboration.tr("status.pageReceived")
            }
        } else {
            let newPage = KnowledgePage(
                id: pageID, title: title, type: pageType, content: content, aliases: [], tags: tags,
                status: status, confidence: .medium, sources: [], relatedPageIDs: [], isPinned: false,
                contentHash: nil, created: remoteUpdated, updated: remoteUpdated
            )
            delegate.insertRemotePage(newPage)
            self.statusMessage = L10n.Collaboration.tr("status.pageReceived")
        }
    }
}
