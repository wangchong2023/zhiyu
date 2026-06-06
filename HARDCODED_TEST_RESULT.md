# 硬编码测试结果分析

## 🔥 当前测试

已临时硬编码 URL：
- 模型商店: `http://127.0.0.1:8080/api/models`
- 插件市场: `http://127.0.0.1:9091/api/plugins`

## 📊 可能的结果

### 结果 A: ✅ 现在可以显示 Mock 数据了

**说明**：
- 网络连接正常
- Info.plist 权限生效
- 问题在于配置逻辑

**根本原因**：
1. AppConfig.modelStoreURL 返回了错误的值
2. DEBUG 宏未定义或条件判断有问题
3. AppConfig.json 读取失败

**解决方案**：
修复配置读取逻辑，确保 DEBUG 模式下返回正确的 URL。

---

### 结果 B: ❌ 还是显示 "Gemma-2B" 和 "暂无插件"

**说明**：
- 硬编码也不行
- 网络请求失败
- 走了 fallback 逻辑

**根本原因**：
1. Info.plist 网络权限未真正生效
2. iOS 模拟器的 ATS 有其他限制
3. 模拟器网络配置问题
4. Mock 服务器无法从模拟器访问

**解决方案**：
1. 检查 Info.plist 是否真的打包到应用
2. 尝试完全禁用 ATS
3. 在模拟器的 Safari 中测试能否访问 http://127.0.0.1:8080/api/models
4. 检查 Mac 防火墙设置

---

### 结果 C: ⚠️ 应用崩溃或报错

**说明**：
- URL 格式问题
- 网络请求抛出异常

**查看**：
Xcode Console 中的错误信息

---

## 🔍 进一步调试

### 如果结果是 B（还是不行）

#### 步骤 1: 在模拟器 Safari 中测试

1. 在模拟器中打开 Safari
2. 访问: `http://127.0.0.1:8080/api/models`
3. 看是否能看到 JSON 数据

**如果 Safari 可以访问**：
→ 说明模拟器网络正常，是应用权限问题

**如果 Safari 也无法访问**：
→ 说明模拟器无法访问 Mac localhost

#### 步骤 2: 检查 Info.plist 是否打包

```bash
# 解压应用查看
DEVICE_ID="9ABEC5B9-E952-422A-A0AB-E2B785C1B36C"
APP_PATH=$(xcrun simctl get_app_container $DEVICE_ID com.zhiyu.app)
unzip -l "$APP_PATH/ZhiYu.app" | grep Info.plist

# 检查 Info.plist 内容
plutil -p "$APP_PATH/ZhiYu.app/Info.plist" | grep -A 3 NSAppTransportSecurity
```

#### 步骤 3: 完全禁用 ATS

修改 Info.plist，只保留：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

#### 步骤 4: 添加异常域

如果上面都不行，尝试：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>127.0.0.1</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

## 📋 测试清单

现在请测试并告诉我：

- [ ] 重新运行应用
- [ ] 打开模型商店 - 看到什么？
- [ ] 打开插件市场 - 看到什么？
- [ ] Xcode Console 有什么日志？
- [ ] 模拟器 Safari 能否访问 Mock API？

---

**更新时间**: 2026-06-06 02:38
**状态**: 等待硬编码测试结果
