# 简化测试方案

## 🎯 问题分析

既然清空重编译后问题依旧，我们需要确认几个关键点：

### 可能的原因

1. **DEBUG 宏未生效**
   - `#if DEBUG` 条件为 false
   - 使用了 RELEASE URL

2. **AppConfig.json 未正确打包**
   - 读取失败返回空字符串
   - Bundle 中没有这个文件

3. **网络权限未生效**
   - Info.plist 更改未生效
   - ATS 仍然阻止请求

4. **应用缓存**
   - URLCache 缓存了旧响应
   - 需要清除缓存

## 🧪 快速验证方案

### 方案 1: 硬编码 URL 测试

临时修改代码，直接硬编码 URL：

```swift
// RemoteConfigService.swift
public func fetchLLMManifests() async throws -> [LLMManifest] {
    // 🔥 临时硬编码，绕过所有配置
    let remoteURLString = "http://127.0.0.1:8080/api/models"
    print("🔍 [HARDCODED] Using URL: \(remoteURLString)")
    
    // ... 其他代码不变
}
```

```swift
// PluginMarketService.swift
private var targetURL: URL {
    // 🔥 临时硬编码
    return URL(string: "http://127.0.0.1:9091/api/plugins")!
}
```

**如果硬编码后可以显示数据**：
→ 说明是配置或 DEBUG 宏的问题

**如果硬编码后还是不行**：
→ 说明是网络权限或其他问题

### 方案 2: 检查 Bundle 中的配置文件

在应用启动时打印：

```swift
// AppDelegate 或主视图 init
print("📦 Bundle path: \(Bundle.main.bundlePath)")
print("📄 AppConfig.json exists: \(Bundle.main.url(forResource: "AppConfig", withExtension: "json") != nil)")
print("📝 Model Store URL: \(AppConfig.modelStoreURL)")
print("📝 Plugin Market URL: \(AppConfig.mockServerURL)")
```

### 方案 3: 清除 URLCache

在应用启动时：

```swift
URLCache.shared.removeAllCachedResponses()
print("🗑️ URL cache cleared")
```

## 🚀 立即执行的调试

### 步骤 1: 添加启动日志

在 `@main` 入口添加：

```swift
init() {
    #if DEBUG
    print("✅ DEBUG mode is active")
    print("📍 Model Store URL: \(AppConfig.modelStoreURL)")
    print("📍 Plugin Market URL: \(AppConfig.mockServerURL)")
    #else
    print("⚠️ RELEASE mode is active")
    #endif
}
```

### 步骤 2: 查看 Xcode Console

在 Xcode 底部的 Console 中应该能看到这些日志。

### 步骤 3: 根据日志判断

**如果看到**：
```
✅ DEBUG mode is active
📍 Model Store URL: http://localhost:8080/api/models
```
→ 配置正常，问题是网络或解析

**如果看到**：
```
⚠️ RELEASE mode is active
```
→ DEBUG 宏未定义

**如果看到**：
```
📍 Model Store URL: 
```
→ AppConfig 读取失败

## 📊 最可能的问题

根据现象（显示 Gemma-2B 和暂无插件），最可能是：

**网络请求失败 → 走了 catch 分支 → 返回 fallback 数据**

原因可能是：
1. Info.plist 权限未生效（即使添加了）
2. 模拟器网络配置问题
3. ATS 有其他限制

## 🔧 最终解决方案

如果硬编码也不行，尝试：

```swift
// 完全禁用 ATS（仅用于调试）
// Info.plist
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

或者使用 `127.0.0.1` 替代 `localhost`。

---

**更新时间**: 2026-06-06 02:36
**建议**: 先添加启动日志，查看 Xcode Console 输出
