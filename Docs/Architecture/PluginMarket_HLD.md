# 智宇 (ZhiYu) 插件市场 (Plugin Market) 高层设计文档 (High-Level Design)

## 1. 业务愿景与系统定位 (System Vision & Positioning)

随着 AI 原生知识管理应用向生态化演进，智宇 (ZhiYu) 需要一套**高度安全、平台无关、易于扩展且支持多端同步**的插件系统。
插件市场旨在通过引入云端分发与热插拔式 JS 脚本引擎，实现以下核心目标：
* **无限功能延展**：允许第三方开发者提供诸如特定的 markdown 解析器、API 适配器、数据导入导出规则及知识图谱定制化渲染器。
* **物理防线隔离 (Sandbox Enforcement)**：绝不允许插件脚本直接访问用户的物理文件、网络网关、钥匙串等敏感隐私，所有系统 API 必须通过白名单受控网关进行代理。
* **极速加载与并发控制**：在 Swift 6 严格并发架构下，采用 MainActor 线程防阻塞与 actor 化隔离，保障插件运行在极低资源损耗下。

---

## 2. 插件体系逻辑架构与核心流程

### 2.1 整体架构视图

插件系统在智宇 (ZhiYu) 的整体系统架构中所处位置如下：

```
+---------------------------------------------------------+
|                  L3 应用与 UI 渲染层 (SwiftUI)            |
+---------------------------------------------------------+
                             | 触发下载 / 运行配置
                             v
+---------------------------------------------------------+
|             PluginMarketService / PluginRegistry        | [L1/L2 插件管理中枢]
+---------------------------------------------------------+
       | 下载解包                       | 启动与生命周期编排
       v                               v
+------------------+         +----------------------------+
|  本地沙盒存储     |         |  PluginSandboxGateway      | [L1.5 安全白名单受控网关]
|  (Documents/     |         +----------------------------+
|   plugins/)      |                       | 控制 / 数据单向注入
+------------------+                       v
                             +----------------------------+
                             |   JavaScriptPlugin         | [L0.5 运行沙盒：JavaScriptCore]
                             +----------------------------+
```

### 2.2 核心业务流程

#### ① 市场检索与元数据拉取
1. 客户端在冷启动或用户进入插件市场时，通过 `PluginMarketService` 发起异步网关查询（Debug 模式请求本地 `MockServer`，生产环境请求云端 `AppConfig.productionURL`）。
2. 云端返回 `MarketPlugin` 的 JSON 元数据，客户端执行强类型模型解析，加载插件列表。

#### ② 插件静默下载、HMAC 校验与物理安装
1. 用户点击“安装”，`PluginMarketService` 启动后台任务，获取插件包（包含 `manifest.json` 与 `.js` 脚本压缩包）。
2. **指纹校验**：通过 `SecurityManager` 配合 `signatureRepository` 计算文件的 HMAC-SHA256，防止包在传输过程中遭受中间人注入篡改。
3. **物理归位**：将插件包物理降噪解压到应用的沙盒安全路径 `/Documents/plugins/{plugin_id}/` 下。

#### ③ JS 脚本载入与 JavaScriptCore 金沙箱隔离
1. 当开启插件时，`PluginRegistry` 实例化 `JavaScriptPlugin`，初始化底层的 `JSContext`（iOS / macOS 原生 `JavaScriptCore` 引擎）。
2. **注入受控沙盒网关**：`PluginSandboxGateway` 将极简的 API（如 `log`、`readPageTitle` 等）以 Swift block 形式注册至 `JSContext` 中。
3. **隔离机制**：沙盒内**彻底不提供** `window`、`fetch`、`XMLHttpRequest` 等网络与物理文件 API。任何向外的网络交互必须声明 `requiredPermissions` 并在权限白名单中经过用户弹窗授权，由 Swift 原生网络库代理请求。

---

## 3. 数据模型设计 (Data Models)

云端返回的元数据必须完美适配多语言、权限控制以及未来的商业变现策略：

```json
{
  "id": "com.zhiyu.plugin.exporter.pdf",
  "version": "1.0.4",
  "author": "ZhiYu Core Team",
  "downloads": "2.4k",
  "rating": 4.8,
  "icon": "doc.plaintext",
  "downloadURL": "https://cdn.zhiyu.app/plugins/pdf_exporter_v1.0.4.zip",
  "minAppVersion": "1.2.0",
  "requiredPermissions": [
    "storage.read",
    "export.share"
  ],
  "monetization": {
    "type": "one_time",
    "price": "2.99",
    "currency": "USD"
  },
  "names": {
    "en": "PDF Smart Exporter",
    "zh": "PDF 智能导出器"
  },
  "descriptions": {
    "en": "Beautifully exports markdown pages to strict PDF documents with dynamic TOC and link support.",
    "zh": "完美地将 Markdown 知识页面导出为高保真 PDF 文档，支持动态目录及链接保留。"
  }
}
```

---

## 4. 安全机制 (Security & Guardrails)

为确保第三方代码的绝对安全，插件引擎被赋予了**三大宪法级红线规则**：

### 4.1 白名单调用网关限制
所有的外部交互（如存储、分享）统一收口至 `PluginSandboxGateway`：
```swift
// 门面安全限制示范
func registerSecureAPIs(to context: JSContext) {
    // 注入日志桥接，所有 JS 的 console.log 经过 Swift 日志引擎脱敏与格式化
    let consoleLog: @convention(block) (String) -> Void = { message in
        Logger.shared.info("🔌 [PluginConsole] \(message)")
    }
    context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
    
    // 强隔离：JS 严禁直接访问数据库。必须通过 Swift 侧提供的 Page DTO 副本进行只读评估。
    let getPageContent: @convention(block) (String) -> String? = { pageTitle in
        guard self.checkPermission("storage.read") else { return nil }
        // 仅在主线程安全解析并脱敏后返回数据副本，绝不返回真实 DB Pointer
        return self.cachedPageContents[pageTitle]
    }
    context.setObject(getPageContent, forKeyedSubscript: "secureGetPageContent" as NSString)
}
```

### 4.2 熔断守护守护（Plugin Watchdog）
为防止任何非正常 JS 脚本引起死循环（如 `while(true)`）拖垮应用主线程性能：
* 每次 JS 调用均会被赋予 `300ms` 执行时钟配额。
* 独立守护线程（Watchdog Task）在后台进行毫秒级轮询监测，一旦超时立即强行注销 `JSContext` 执行，并为用户展示熔断崩溃页，保障系统整体响应性。

---

## 5. 商业化变现与演进蓝图 (Monetization & Evolution Roadmap)

在智宇未来的迭代中，插件市场将按三步走战略深入铺开：
1. **MVP 阶段 (v1.0 - 当前)**：支持官方及社区白名单机制，拉取本地 Mock / 远程 GitHub 的打包配置，基于 JavaScriptCore 实现 Markdown 渲染管道的热插拔过滤。
2. **Pro 阶段 (v1.5)**：引入 `MonetizationInfo` 处理单次内购或订阅，打通 Swift 应用内收费机制；提供全面的插件配置 UI 面板。
3. **Eco 生态阶段 (v2.0)**：发布 `ZhiYu Plugin SDK` 与 CLI 开发工具，支持本地局域网无线调试模式与热重载；通过 iCloud 云端自动同步用户跨设备的已购插件列表。
