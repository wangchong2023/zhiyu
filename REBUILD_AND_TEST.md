# 重新编译和测试指南

## 🎯 问题原因

应用当前运行的是**旧版本代码**，还没有包含以下修改：
1. ❌ `RemoteConfigService` 使用硬编码的 URL
2. ❌ `PluginMarketService` 可能没有正确使用 DEBUG URL

## ✅ 需要的修改

### 1. RemoteConfigService (模型商店)
```swift
// 修改前
let remoteURLString = AppConfig.backendBaseURL + "/api/ai/models/allowlist"

// 修改后
let remoteURLString = AppConfig.modelStoreURL
```

### 2. AppConfig (URL 配置)
```swift
// 新增
static var modelStoreURL: String {
    #if DEBUG
    return getNetwork(.modelStoreDebug)  // http://localhost:8080/api/models
    #else
    return getNetwork(.modelStoreProduction)
    #endif
}
```

## 🛠️ 重新编译步骤

### 方式 1: 使用 Xcode（推荐）

1. **打开 Xcode**
   ```bash
   open ZhiYu.xcodeproj
   ```

2. **清理构建**
   - 菜单: Product → Clean Build Folder
   - 快捷键: ⇧⌘K (Shift+Cmd+K)

3. **选择目标**
   - Scheme: ZhiYu
   - Destination: iPhone 17 Pro (模拟器)

4. **运行应用**
   - 菜单: Product → Run
   - 快捷键: ⌘R (Cmd+R)

### 方式 2: 使用命令行

```bash
# 1. 清理构建
xcodebuild clean -project ZhiYu.xcodeproj -scheme ZhiYu

# 2. 编译并运行
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 3. 启动模拟器中的应用
xcrun simctl launch booted com.zhiyu.app
```

## ✅ 验证清单

### 启动前检查
- [ ] Mock 插件市场服务器运行中 (9091 端口)
- [ ] Mock 模型商店服务器运行中 (8080 端口)
- [ ] 代码已包含最新修改
- [ ] 构建配置为 Debug 模式

### 测试 Mock 服务器
```bash
# 插件市场
curl http://localhost:9091/api/plugins | python3 -m json.tool | head -20

# 模型商店
curl http://localhost:8080/api/models | python3 -m json.tool | head -20
```

### 运行后验证
- [ ] 打开「AI」→「模型商店」
- [ ] 应该显示 4 个模型（Llama 3.2 3B、Qwen 2.5 7B、DeepSeek R1 8B、Gemma 2 9B）
- [ ] 打开「设置」→「插件中心」→「社区市场」
- [ ] 应该显示 5 个插件

## 🐛 如果还是不显示

### 1. 检查构建模式
```bash
# 确认是 Debug 模式
xcodebuild -showBuildSettings -project ZhiYu.xcodeproj -scheme ZhiYu | grep CONFIGURATION
```

应该输出: `CONFIGURATION = Debug`

### 2. 查看应用日志
```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -E "URL|fetch|plugin|model"
```

### 3. 验证 AppConfig 读取
在 `RemoteConfigService.swift` 的 `fetchLLMManifests` 方法中添加日志：

```swift
let remoteURLString = AppConfig.modelStoreURL
print("🔍 [DEBUG] Model Store URL: \(remoteURLString)")
```

### 4. 检查网络权限
确认 Info.plist 中有以下配置：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 📱 模拟器网络说明

iOS 模拟器访问 Mac 本机服务：
- ✅ `localhost` → Mac 的 localhost
- ✅ `127.0.0.1` → Mac 的 127.0.0.1
- ❌ 不要使用具体 IP（10.x.x.x）

## 🎯 期望结果

### 模型商店页面
```
AI
├── 模型商店 ✓
│   ├── Llama 3.2 3B (Meta) - 2.0 GB
│   ├── Qwen 2.5 7B (Alibaba) - 4.3 GB
│   ├── DeepSeek R1 8B (DeepSeek) - 4.6 GB
│   └── Gemma 2 9B (Google) - 5.4 GB
└── 参数调优
```

### 插件市场页面
```
插件中心
├── 社区市场 ✓
│   ├── [远程] 链接预览
│   ├── [远程] AI 翻译器
│   ├── Markdown 美化器
│   ├── AI 摘要生成
│   └── 代码高亮
└── 我的插件
    ├── [本地] TOC 生成器
    ├── [本地] 字数统计
    └── [本地] 智能清洗器
```

---

**更新时间**: 2026-06-06 02:09  
**状态**: 等待重新编译测试
