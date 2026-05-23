//
//  StubCollaborationProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Stubs 模块，提供相关的结构体或工具支撑。
//
import Foundation

final class StubCollaborationProvider: CollaborationProviderProtocol {
    weak var delegate: CollaborationProviderDelegate?
    
    func startHosting(roomName: String, userName: String) {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.simulatorNotSupported)
    }
    
    func startBrowsing(userName: String) {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.simulatorNotSupported)
    }
    
    func joinRoom(_ room: DiscoveredRoom) {}
    
    func stop() {
        delegate?.providerDidUpdateStatus(L10n.Collaboration.Status.disconnected)
    }
    
    func broadcast(data: Data) {}
}
