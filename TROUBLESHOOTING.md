# Mock 数据未显示问题诊断报告

## 🐛 问题现象

- **模型商店**：显示"Gemma-2B"加载中，但没有显示 Mock 服务器的 4 个模型
- **插件市场**：显示"暂无上架插件"，没有显示 Mock 服务器的 5 个插件

## 🔍 根本原因

### 1. 模型商店问题

**问题位置**：`Sources/Infrastructure/Network/RemoteConfigService.swift:29`

```swift
// 当前代码
let remoteURLString = AppConfig.backendBaseURL + "/api/ai/models/allowlist"
```

**实际 URL**：`http://10.211.55.4:30080/api/ai/models/allowlist`  
**Mock URL**：`http://localhost:8080/api/models`

❌ **应用访问的是后端服务器（30080 端口），而不是 Mock 服务器（8080 端口）**

### 2. 插件市场问题

**问题位置**：`Sources/Infrastructure/Plugins/PluginMarketService.swift:52-55`

```swift
// 当前代码
private let productionURL = URL(string: AppConfig.productionURL)!
private let debugURL = URL(string: AppConfig.mockServerURL)!
```

**AppConfig 配置**：
- `productionURL`: `https://raw.githubusercontent.com/...`
- `mockServerURL`: `http://localhost:9091/api/plugins` ✅

**问题**：虽然配置了 `mockServerURL`，但需要确认：
1. 应用是否在 DEBUG 模式下运行？
2. `targetURL` 是否正确选择了 `debugURL`？

---

## 🔧 解决方案

### 方案 1：临时修改配置（快速测试）

修改 `AppConfig.json` 将 `backendBaseURL` 指向 Mock 服务器：

```json
{
  "network": {
    "backend_base_url": "http://localhost:8080",
    "model_store_debug": "http://localhost:8080/api/models",
    ...
  }
}
```

**问题**：这会影响所有其他 API 调用。

### 方案 2：添加调试开关（推荐）

在 `AppConfig` 中添加模型商店 Mock URL 配置：

```swift
// AppConfig.swift
static var modelStoreDebugURL: String {
    #if DEBUG
    return "http://localhost:8080/api/models"
    #else
    return backendBaseURL + "/api/ai/models/allowlist"
    #endif
}
```

修改 `RemoteConfigService.swift`：

```swift
public func fetchLLMManifests() async throws -> [LLMManifest] {
    #if DEBUG
    let remoteURLString = AppConfig.modelStoreDebugURL
    #else
    let remoteURLString = AppConfig.backendBaseURL + "/api/ai/models/allowlist"
    #endif
    
    // ... 其他代码
}
```

### 方案 3：使用环境变量（生产级）

支持通过环境变量或 scheme 配置切换：

```swift
enum Environment {
    static let useMockServers: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["USE_MOCK"] == "1"
        #else
        return false
        #endif
    }()
}
```

---

## 📊 当前网络配置状态

### AppConfig.json
```json
{
  "network": {
    "backend_base_url": "http://10.211.55.4:30080",
    "plugin_market_production": "https://raw.githubusercontent.com/...",
    "plugin_market_debug": "http://localhost:9091/api/plugins",
    "model_store_debug": "http://localhost:8080/api/models",
    ...
  }
}
```

### 实际使用的 URL

| 功能 | 当前 URL | Mock URL | 状态 |
|-----|---------|----------|------|
| 模型商店 | `http://10.211.55.4:30080/api/ai/models/allowlist` | `http://localhost:8080/api/models` | ❌ 不匹配 |
| 插件市场 | `http://localhost:9091/api/plugins` (DEBUG) | `http://localhost:9091/api/plugins` | ✅ 匹配 |

---

## ✅ 验证步骤

### 1. 确认 Mock 服务器运行
```bash
# 插件市场
curl http://localhost:9091/api/plugins | python3 -m json.tool

# 模型商店
curl http://localhost:8080/api/models | python3 -m json.tool
```

### 2. 确认应用构建模式
- Xcode → Product → Scheme → Edit Scheme → Run → Build Configuration
- 应该是 **Debug** 模式

### 3. 模拟器网络访问
iOS 模拟器应该能访问 `localhost`:
```bash
# 从模拟器测试（使用 xcrun simctl）
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.yourapp"' --level debug
```

---

## 🎯 建议的快速修复

### 步骤 1：修改 RemoteConfigService

```swift
// Sources/Infrastructure/Network/RemoteConfigService.swift

public func fetchLLMManifests() async throws -> [LLMManifest] {
    // 🔧 临时添加 DEBUG 模式支持
    #if DEBUG
    let remoteURLString = "http://localhost:8080/api/models"
    #else
    let remoteURLString = AppConfig.backendBaseURL + "/api/ai/models/allowlist"
    #endif
    
    guard let url = URL(string: remoteURLString) else {
        throw NetworkError.invalidURL
    }
    
    // ... 其他代码保持不变
}
```

### 步骤 2：重新编译运行

```bash
# 清理构建
xcodebuild clean -project ZhiYu.xcodeproj -scheme ZhiYu

# 重新构建（Debug 模式）
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -configuration Debug
```

### 步骤 3：验证插件市场

检查 `PluginMarketService.swift` 的 `targetURL` 属性：

```swift
private var targetURL: URL {
    #if DEBUG
    return debugURL  // ← 确保 DEBUG 模式下使用这个
    #else
    return productionURL
    #endif
}
```

---

## 📝 测试清单

- [ ] Mock 服务器运行正常（9091 和 8080 端口）
- [ ] 应用以 Debug 模式构建
- [ ] RemoteConfigService 使用正确的 Mock URL
- [ ] PluginMarketService 选择 debugURL
- [ ] 重新编译并运行应用
- [ ] 模型商店显示 4 个模型
- [ ] 插件市场显示 5 个插件

---

## 🔗 相关文件

- `Sources/Infrastructure/Network/RemoteConfigService.swift` - 模型商店网络请求
- `Sources/Infrastructure/Plugins/PluginMarketService.swift` - 插件市场网络请求
- `Sources/Resources/AppConfig.json` - 网络配置
- `Sources/Core/Base/Constants/AppConfig.swift` - 配置读取

---

## 💡 长期改进建议

1. **统一 Mock 配置**：所有 Mock URL 都从 AppConfig 读取
2. **环境切换开关**：在设置中添加"使用 Mock 数据"开关
3. **网络日志**：添加详细的网络请求日志便于调试
4. **错误提示**：当无法连接时显示具体的错误信息而不是空白

---

**生成时间**: 2026-06-06  
**状态**: 待修复
