# 下一步操作

## ✅ 已完成

1. ✅ 临时硬编码 URL 为 `http://127.0.0.1:8080/api/models` 和 `http://127.0.0.1:9091/api/plugins`
2. ✅ 添加详细调试日志
3. ✅ 验证配置文件正确
4. ✅ 验证 Mock 服务器运行正常
5. ✅ 代码已提交

## 📋 现在需要你做的

### 步骤 1: 重新运行应用

在 Xcode 中：
- Product → Run (⌘R)
- 等待编译完成

### 步骤 2: 测试模型商店

1. 在模拟器中打开「AI」→「模型商店」
2. 观察显示什么

### 步骤 3: 测试插件市场

1. 在模拟器中打开「设置」→「插件中心」→「社区市场」
2. 观察显示什么

### 步骤 4: 查看 Xcode Console

在 Xcode 底部的 Console 面板中，搜索：
- `DEBUG`
- `Model Store URL`
- `Plugin Market URL`

### 步骤 5: Safari 测试（可选但重要）

1. 在模拟器中打开 Safari
2. 访问 `http://127.0.0.1:8080/api/models`
3. 看是否能看到 JSON 数据

## 📊 根据结果判断

### 场景 A: 现在可以显示 Mock 数据了 ✅

**说明**: 网络正常，问题是之前的配置逻辑

**下一步**: 
- 恢复使用 AppConfig
- 修复 DEBUG 模式判断
- 确保配置正确读取

### 场景 B: 还是显示 "Gemma-2B" 和 "暂无插件" ❌

**说明**: 硬编码也不行，是网络权限问题

**下一步**:
1. 检查 Safari 能否访问（关键测试）
2. 检查 Info.plist 是否真的打包到应用
3. 尝试完全禁用 ATS
4. 检查 Mac 防火墙设置

### 场景 C: 应用崩溃或报错 ⚠️

**说明**: 代码有问题

**下一步**: 查看 Xcode Console 的错误信息

## 🔍 关键诊断点

### Console 日志应该显示

```
🔍 [DEBUG] Model Store URL: http://127.0.0.1:8080/api/models
✅ [DEBUG] Response: 200, bytes: XXXX
📦 [DEBUG] Models count: 4
```

或者显示错误：

```
❌ [DEBUG] Network error: ..., using fallback
```

### Safari 测试的重要性

Safari 测试可以确定：
- ✅ 如果 Safari 可以访问 → 是应用的 ATS 问题
- ❌ 如果 Safari 也不行 → 是模拟器网络配置问题

## 📱 请告诉我

测试完成后，请告诉我：

1. **模型商店显示什么？**
   - [ ] 4 个模型（成功）
   - [ ] Gemma-2B（失败）
   - [ ] 其他

2. **插件市场显示什么？**
   - [ ] 5 个插件（成功）
   - [ ] 暂无插件（失败）
   - [ ] 其他

3. **Xcode Console 有什么日志？**
   - 复制粘贴关键日志

4. **Safari 能访问 Mock API 吗？**
   - [ ] 能看到 JSON
   - [ ] 无法加载
   - [ ] 未测试

---

**当前状态**: 等待测试结果
**硬编码 URL**: 已激活
**Mock 服务器**: 运行中
