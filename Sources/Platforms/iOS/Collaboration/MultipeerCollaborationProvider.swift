//
//  MultipeerCollaborationProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 Collaboration 模块，提供相关的结构体或工具支撑。
//
#if canImport(MultipeerConnectivity)
import Foundation
import MultipeerConnectivity

@MainActor
final class MultipeerCollaborationProvider: NSObject, CollaborationProviderProtocol {
    weak var delegate: CollaborationProviderDelegate?
    
    private let serviceType = "km-collab"
    private var myPeerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var sessionDelegate: MCSessionDelegateImpl?
    private var advertiserDelegate: MCAdvertiserDelegateImpl?
    private var browserDelegate: MCBrowserDelegateImpl?
    
    func startHosting(roomName: String, userName: String) {
        let peerID = MCPeerID(displayName: "\(userName)|\(UUID().uuidString.prefix(8))")
        self.myPeerID = peerID
        
        setupSession(peerID: peerID)
        
        advertiserDelegate = MCAdvertiserDelegateImpl(
            onInvitation: { [weak self] _, _, handler in
                handler(true, self?.session)
            },
            onError: { [weak self] error in
                self?.delegate?.providerDidEncounterError(error.localizedDescription)
            }
        )
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: [
            "room": roomName,
            "owner": userName
        ], serviceType: serviceType)
        advertiser?.delegate = advertiserDelegate
        advertiser?.startAdvertisingPeer()
        
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.hosting)
    }
    
    func startBrowsing(userName: String) {
        let peerID = MCPeerID(displayName: "\(userName)|\(UUID().uuidString.prefix(8))")
        self.myPeerID = peerID
        
        setupSession(peerID: peerID)
        
        browserDelegate = MCBrowserDelegateImpl(
            onRoomFound: { [weak self] peerID, info in
                let room = DiscoveredRoom(
                    id: peerID.displayName,
                    platformPeer: peerID,
                    roomName: info?["room"] ?? L10n.Collaboration.defaultRoom,
                    owner: info?["owner"] ?? peerID.displayName
                )
                self?.delegate?.providerDidDiscoverRoom(room)
            },
            onRoomLost: { [weak self] peerID in
                self?.delegate?.providerDidLoseRoom(id: peerID.displayName)
            },
            onError: { [weak self] error in
                self?.delegate?.providerDidEncounterError(error.localizedDescription)
            }
        )
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = browserDelegate
        browser?.startBrowsingForPeers()
        
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.searching)
    }
    
    func joinRoom(_ room: DiscoveredRoom) {
        guard let session = session, let browser = browser, let targetPeer = room.platformPeer as? MCPeerID else { return }
        browser.invitePeer(targetPeer, to: session, withContext: nil, timeout: 30)
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.joining)
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.disconnected)
    }
    
    func broadcast(data: Data) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    private func setupSession(peerID: MCPeerID) {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        sessionDelegate = MCSessionDelegateImpl(
            onPeerConnected: { [weak self] peerID in
                let user = CollabUser(id: peerID.displayName, displayName: peerID.displayName.components(separatedBy: "|").first ?? peerID.displayName, deviceName: "", joinedAt: Date())
                self?.delegate?.providerDidConnectPeer(user)
            },
            onPeerDisconnected: { [weak self] peerID in
                self?.delegate?.providerDidDisconnectPeer(id: peerID.displayName)
            },
            onDataReceived: { [weak self] data, peerID in
                self?.delegate?.providerDidReceiveData(data, from: peerID.displayName)
            },
            onStatusChange: { [weak self] state, _ in
                if state == .connecting {
                    self?.delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.connecting)
                }
            }
        )
        session.delegate = sessionDelegate
        self.session = session
    }
}
#endif
