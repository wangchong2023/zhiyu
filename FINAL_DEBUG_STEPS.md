# 最终调试步骤

## 🎯 当前状态

已添加详细的网络请求日志到：
1. `PluginMarketService.swift` - 插件市场
2. `RemoteConfigService.swift` - 模型商店

## 📋 操作步骤

### 步骤 1: 重新编译应用

在 Xcode 中：
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Run (⌘R)

### 步骤 2: 启动日志监控

在终端中运行：

```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -E "DEBUG|PluginMarket|RemoteConfigService"
```

### 步骤 3: 触发网络请求

在模拟器中：
1. **测试模型商店**：打开「AI」→「模型商店」
2. **测试插件市场**：打开「设置」→「插件中心」→「社区市场」

### 步骤 4: 观察日志输出

#### 正常情况下应该看到：

**模型商店日志：**
```
🔍 [DEBUG] Model Store URL: http://localhost:8080/api/models
✅ [DEBUG] Response: 200, bytes: XXXX
📦 [DEBUG] Models count: 4
✅ [RemoteConfigService] Success! Returning 4 models
```

**插件市场日志：**
```
🔍 [DEBUG] Plugin Market URL: http://localhost:9091/api/plugins
✅ [DEBUG] Plugin response: 200, bytes: XXXX
```

#### 异常情况：

**如果看到 fallback：**
```
❌ [DEBUG] Network error: ..., using fallback
```
说明网络请求失败，返回了 Gemma-2B 兜底数据。

**如果看到错误的 URL：**
```
🔍 [DEBUG] Model Store URL: http://10.211.55.4:30080/...
```
说明配置未生效，还在使用生产 URL。

## 🔍 诊断逻辑

根据日志输出，我们可以确定：

### 情况 A: 看到 localhost URL 但网络失败
→ **原因**：Info.plist 网络权限未生效或模拟器网络问题
→ **解决**：检查 Info.plist 是否正确打包到应用中

### 情况 B: 看到错误的 URL
→ **原因**：AppConfig.modelStoreURL 未返回正确的值
→ **解决**：检查 DEBUG 宏是否定义

### 情况 C: 网络成功但数据未显示
→ **原因**：JSON 解析失败或 UI 更新问题
→ **解决**：检查 Mock 数据格式是否匹配

### 情况 D: 完全没有日志
→ **原因**：应用未触发网络请求
→ **解决**：检查 ViewModel 初始化逻辑

## 📊 Mock 服务器验证

确保 Mock 服务器正常：

```bash
# 测试插件市场
curl http://localhost:9091/api/plugins | python3 -m json.tool | head -30

# 测试模型商店  
curl http://localhost:8080/api/models | python3 -m json.tool | head -30
```

## 🎯 期望结果

日志应该显示：
1. ✅ URL 是 `localhost:8080` 和 `localhost:9091`
2. ✅ HTTP 状态码是 200
3. ✅ 数据大小不为 0
4. ✅ 解析出 4 个模型和 5 个插件

然后 UI 应该显示正确的数据。

---

**更新时间**: 2026-06-06 02:33
**状态**: 等待日志输出以诊断问题
