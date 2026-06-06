# 深度调试指南

## 🔍 当前状态

### ✅ 已验证正常
- Mock 服务器运行中（9091 和 8080 端口）
- Mock API 返回正确的 JSON 数据
- 代码已修复使用正确的 URL
- DEBUG 模式已启用

### ❌ 问题依旧
- 模型商店仍显示 "Gemma-2B"
- 插件市场仍显示 "暂无上架插件"

## 🎯 可能的原因

### 原因 1: 网络权限配置
iOS 可能阻止了对 localhost 的 HTTP 请求。

**检查方法：**
```bash
grep -A 10 "NSAppTransportSecurity" Sources/Info.plist
```

**应该包含：**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 原因 2: 应用缓存旧数据
应用可能缓存了之前的网络响应。

**解决方法：**
1. 完全卸载应用
2. 清理模拟器数据
3. 重新安装

```bash
# 卸载应用
DEVICE_ID="9ABEC5B9-E952-422A-A0AB-E2B785C1B36C"
xcrun simctl uninstall $DEVICE_ID com.zhiyu.app

# 清理构建
xcodebuild clean -project ZhiYu.xcodeproj -scheme ZhiYu

# 重新编译安装
# 在 Xcode 中 Product → Run
```

### 原因 3: 代码使用了离线兜底
`RemoteConfigService` 有 catch 块返回兜底数据。

**检查代码：**
```swift
do {
    // 网络请求
} catch {
    // 🟢 离线兜底 - 返回 Gemma-2B
    return getFallbackLLMManifests()
}
```

如果网络请求失败，会直接返回兜底数据而不抛出错误。

### 原因 4: 模拟器 localhost 网络问题
模拟器可能无法访问 Mac 的 localhost。

**测试方法：**
在模拟器的 Safari 中访问：
- http://localhost:9091/api/plugins
- http://localhost:8080/api/models

如果无法访问，改用 `127.0.0.1`。

## 🛠️ 调试步骤

### 步骤 1: 添加详细日志

在 `RemoteConfigService.swift` 中添加：

```swift
public func fetchLLMManifests() async throws -> [LLMManifest] {
    let remoteURLString = AppConfig.modelStoreURL
    print("🔍 [DEBUG] Fetching models from: \(remoteURLString)")
    
    guard let url = URL(string: remoteURLString) else {
        print("❌ [DEBUG] Invalid URL: \(remoteURLString)")
        throw NetworkError.invalidURL
    }
    
    do {
        let (data, response) = try await session.data(from: url)
        print("✅ [DEBUG] Response received, status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("📦 [DEBUG] Data size: \(data.count) bytes")
        
        // ... 解析逻辑
    } catch {
        print("❌ [DEBUG] Network error: \(error)")
        return getFallbackLLMManifests()
    }
}
```

在 `PluginMarketService.swift` 中添加：

```swift
func fetchPlugins() async {
    print("🔍 [DEBUG] Target URL: \(targetURL)")
    
    do {
        let (data, _) = try await URLSession.shared.data(from: targetURL)
        print("✅ [DEBUG] Plugin data received: \(data.count) bytes")
        // ... 解析逻辑
    } catch {
        print("❌ [DEBUG] Plugin fetch error: \(error)")
    }
}
```

### 步骤 2: 查看实时日志

```bash
# 启动日志监控
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -i "debug"

# 在模拟器中触发操作
# 1. 打开 AI → 模型商店
# 2. 打开 设置 → 插件中心 → 社区市场
```

### 步骤 3: 测试网络连接

在应用中添加简单的网络测试：

```swift
// 测试代码
Task {
    do {
        let url = URL(string: "http://localhost:8080/api/models")!
        let (data, _) = try await URLSession.shared.data(from: url)
        print("✅ Network test success: \(data.count) bytes")
    } catch {
        print("❌ Network test failed: \(error)")
    }
}
```

### 步骤 4: 检查 Info.plist

确保有网络权限：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

如果没有，添加后重新编译。

## 🎯 快速修复方案

### 方案 1: 完全清理重装

```bash
#!/bin/bash
DEVICE_ID="9ABEC5B9-E952-422A-A0AB-E2B785C1B36C"

# 1. 卸载应用
echo "卸载应用..."
xcrun simctl uninstall $DEVICE_ID com.zhiyu.app

# 2. 清理构建
echo "清理构建..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ZhiYu-*
xcodebuild clean -project ZhiYu.xcodeproj -scheme ZhiYu

# 3. 重启模拟器
echo "重启模拟器..."
xcrun simctl shutdown $DEVICE_ID
sleep 2
xcrun simctl boot $DEVICE_ID

# 4. 在 Xcode 中重新编译
echo "请在 Xcode 中重新运行应用"
open ZhiYu.xcodeproj
```

### 方案 2: 使用 127.0.0.1 替代 localhost

修改 `AppConfig.json`:

```json
{
  "network": {
    "plugin_market_debug": "http://127.0.0.1:9091/api/plugins",
    "model_store_debug": "http://127.0.0.1:8080/api/models"
  }
}
```

### 方案 3: 添加强制日志

在 `AppDelegate` 或主视图中添加：

```swift
init() {
    #if DEBUG
    print("🚀 App launched in DEBUG mode")
    print("📍 Plugin Market URL: \(AppConfig.mockServerURL)")
    print("📍 Model Store URL: \(AppConfig.modelStoreURL)")
    #endif
}
```

## 📊 检查清单

### 环境检查
- [ ] Mock 服务器运行中
- [ ] DEBUG 模式启用
- [ ] 代码已更新使用 AppConfig.modelStoreURL
- [ ] Info.plist 有网络权限

### 网络检查
- [ ] curl 可以访问 Mock API
- [ ] 模拟器 Safari 可以访问 localhost
- [ ] 应用日志显示正确的 URL

### 应用检查
- [ ] 已清理构建缓存
- [ ] 已卸载旧版本
- [ ] 重新编译安装
- [ ] 日志显示网络请求

## 🆘 最后的杀手锏

如果以上都不行，使用硬编码测试：

```swift
// 临时测试代码
public func fetchLLMManifests() async throws -> [LLMManifest] {
    // 硬编码 URL
    let url = URL(string: "http://127.0.0.1:8080/api/models")!
    
    print("🔍 Hardcoded URL test: \(url)")
    
    let (data, response) = try await session.data(from: url)
    print("✅ Response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
    print("📦 Data: \(String(data: data, encoding: .utf8) ?? "nil")")
    
    // ... 解析
}
```

这样可以确定是配置问题还是网络问题。

---

**更新时间**: 2026-06-06 02:25
**状态**: 深度调试中
