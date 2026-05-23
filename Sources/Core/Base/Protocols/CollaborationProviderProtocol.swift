//
//  CollaborationProviderProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 CollaborationProvider 模块的抽象契约接口。
//
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
