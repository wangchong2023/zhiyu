//
//  RegionCapabilities.swift
//  ZhiYu
//
//  Created by Constantine on 2026/06/21.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层 - 认证存储
//  核心职责：定义从 region_capabilities.json 动态解析出来的区域支持功能映射。
//

import Foundation

/// 地区登录与应用服务能力配置模型
public struct RegionCapabilities: Codable, Sendable {
    
    /// 每个特定地区的具体运行配置信息
    public struct RegionInfo: Codable, Sendable {
        /// 登录页面呈现类型 ("localized" 代表国内版手机一键登录，"international" 代表海外通行密钥免密版)
        public let loginPageType: String
        /// 对应区域所指向的插件中心元数据服务地址
        public let pluginMarketUrl: String
        
        enum CodingKeys: String, CodingKey {
            case loginPageType = "login_page_type"
            case pluginMarketUrl = "plugin_market_url"
        }
    }
    
    /// 以国家或地区标识符 (如 CN, US, default) 作为键值的哈希映射关系表
    public let regions: [String: RegionInfo]
}
