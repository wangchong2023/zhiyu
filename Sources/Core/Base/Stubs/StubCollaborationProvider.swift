// StubCollaborationProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：协作提供商的空实现，用于不支持 P2P 的平台或模拟器。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

final class StubCollaborationProvider: CollaborationProviderProtocol {
    weak var delegate: CollaborationProviderDelegate?
    
    func startHosting(roomName: String, userName: String) {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.tr("status.simulatorNotSupported"))
    }
    
    func startBrowsing(userName: String) {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.tr("status.simulatorNotSupported"))
    }
    
    func joinRoom(_ room: DiscoveredRoom) {}
    
    func stop() {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.tr("status.disconnected"))
    }
    
    func broadcast(data: Data) {}
}
