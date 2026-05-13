// CollaborationProviderProtocol.swift
//
// 作者: Wang Chong
// 功能说明: 协作提供商抽象协议，定义跨平台 P2P 协作能力。
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，旨在剥离 MultipeerConnectivity。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// 协作提供商代理，用于反向通知业务层连接状态与数据变更
@MainActor
protocol CollaborationProviderDelegate: AnyObject {
    func providerDidUpdateStatus(_ message: String)
    func providerDidDiscoverRoom(_ room: DiscoveredRoom)
    func providerDidLoseRoom(id: String)
    func providerDidConnectPeer(_ user: CollabUser)
    func providerDidDisconnectPeer(id: String)
    func providerDidReceiveData(_ data: Data, from userID: String)
    func providerDidEncounterError(_ error: String)
}

/// 协作提供商协议
@MainActor
protocol CollaborationProviderProtocol: AnyObject {
    var delegate: CollaborationProviderDelegate? { get set }
    
    /// 开始作为房主广播
    func startHosting(roomName: String, userName: String)
    
    /// 开始搜索房间
    func startBrowsing(userName: String)
    
    /// 加入特定房间
    func joinRoom(_ room: DiscoveredRoom)
    
    /// 停止所有协作活动
    func stop()
    
    /// 向所有已连接的对等端发送数据
    func broadcast(data: Data)
}
