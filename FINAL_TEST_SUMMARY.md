# 最终测试总结

## 🎯 当前状态

### ✅ 已完成
1. **Mock 服务器** - 运行正常
   - 插件市场 (9091): 5 个插件
   - 模型商店 (8080): 4 个模型

2. **本地插件** - 已复制到模拟器
   - TOC 生成器 (4.7 KB)
   - 字数统计 (4.5 KB)
   - 智能清洗器 (1.9 KB)

3. **代码修改** - 已提交
   - AppConfig.swift - 添加 modelStoreURL
   - RemoteConfigService.swift - 使用配置 URL

### ⏳ 待完成
**重新编译应用** - 需要使用 Xcode

---

## 📱 测试步骤

### 第 1 步：使用 Xcode 编译（必须）

```bash
# 打开项目
open ZhiYu.xcodeproj
```

在 Xcode 中：
1. **清理构建**
   - 菜单: Product → Clean Build Folder
   - 快捷键: ⇧⌘K

2. **运行应用**
   - 菜单: Product → Run
   - 快捷键: ⌘R

3. **等待编译完成**
   - 自动在模拟器中启动应用

---

### 第 2 步：测试模型商店

打开「AI」→「模型商店」标签

**期望结果：**
```
✅ 应该显示 4 个模型：

📦 Llama 3.2 3B
   提供商: Meta
   大小: 2.0 GB
   内存: 4GB
   
📦 Qwen 2.5 7B
   提供商: Alibaba
   大小: 4.3 GB
   内存: 8GB

📦 DeepSeek R1 8B
   提供商: DeepSeek
   大小: 4.6 GB
   内存: 8GB

📦 Gemma 2 9B
   提供商: Google
   大小: 5.4 GB
   内存: 10GB
```

**如果还是显示 "Gemma-2B"：**
- ❌ 应用未重新编译
- ❌ 使用的是旧版本代码

---

### 第 3 步：测试插件市场

打开「设置」→「插件中心」→「社区市场」标签

**期望结果：**
```
✅ 应该显示 5 个插件：

🌐 [远程] 链接预览
   作者: ZhiYu Remote Team
   下载: 8,500
   评分: 4.7⭐

🌐 [远程] AI 翻译器
   作者: ZhiYu Remote Team
   下载: 12,300
   评分: 4.9⭐

📝 Markdown 美化器
   作者: ZhiYu Team
   下载: 12,500
   评分: 4.8⭐

✨ AI 摘要生成
   作者: Community
   下载: 8,300
   评分: 4.6⭐

💻 代码高亮
   作者: DevTools
   下载: 15,600
   评分: 4.9⭐
```

**如果显示 "暂无上架插件"：**
- ❌ 应用未重新编译
- ❌ 或 DEBUG 模式未生效

---

### 第 4 步：测试本地插件

切换到「我的插件」标签

**期望结果：**
```
✅ 应该显示 3 个本地插件：

📋 [本地] TOC 生成器
   版本: 1.0.0
   作者: ZhiYu Local Team
   状态: 已加载

🔢 [本地] 字数统计
   版本: 1.0.0
   作者: ZhiYu Local Team
   状态: 已加载

🧹 [本地] 智能清洗器
   版本: 1.0.0
   作者: ZhiYu Team
   状态: 已加载
```

**如果没有显示：**
- 重启应用
- 检查插件文件是否在 Documents/Plugins/ 目录

---

## 🐛 故障排查

### 问题 1: 模型商店还是显示 "Gemma-2B"

**原因:** 应用使用旧版本代码

**解决:**
1. 确认在 Xcode 中编译（不要用命令行）
2. 确认是 Debug 配置
3. 检查日志中的 URL

```bash
# 查看应用日志
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -i "model\|url"
```

### 问题 2: 插件市场显示 "暂无上架插件"

**原因:** DEBUG 模式未生效或 URL 不对

**解决:**
1. 检查 Build Configuration = Debug
2. 验证 PluginMarketService 的 targetURL

### 问题 3: 本地插件未显示

**原因:** 插件文件未加载或格式错误

**解决:**
```bash
# 1. 验证文件存在
DEVICE_ID="9ABEC5B9-E952-422A-A0AB-E2B785C1B36C"
ls -lh ~/Library/Developer/CoreSimulator/Devices/$DEVICE_ID/data/Containers/Data/Application/*/Documents/Plugins/

# 2. 验证插件完整性
python3 Tools/validate_plugin.py Tools/Plugins/Local/toc-generator-local.zyplugin

# 3. 重启应用
xcrun simctl terminate $DEVICE_ID com.zhiyu.app
xcrun simctl launch $DEVICE_ID com.zhiyu.app
```

---

## 📋 测试清单

### 编译前
- [x] Mock 服务器运行中
- [x] 本地插件已复制
- [x] 代码修改已完成
- [ ] **在 Xcode 中重新编译**

### 编译后
- [ ] 模型商店显示 4 个模型
- [ ] 插件市场显示 5 个插件
- [ ] 我的插件显示 3 个本地插件
- [ ] 可以启用/禁用插件
- [ ] 插件功能正常运行

---

## 🎯 验证标准

### 成功标准
- ✅ 模型商店不再显示 "Gemma-2B"，而是显示 4 个模型
- ✅ 插件市场不再显示 "暂无上架插件"，而是显示 5 个插件
- ✅ 我的插件显示 3 个本地加载的插件
- ✅ 所有插件可以正常启用和使用

### 失败标准
- ❌ 还是显示旧数据
- ❌ 空白或加载失败
- ❌ 插件无法加载

---

## 📞 需要帮助？

### 查看详细日志
```bash
# 实时查看应用日志
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug

# 查看网络请求
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -i "http\|url\|fetch"

# 查看插件加载
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.zhiyu.app"' --level debug | grep -i "plugin"
```

### 验证 Mock 服务器
```bash
# 插件市场
curl http://localhost:9091/api/plugins | python3 -m json.tool

# 模型商店
curl http://localhost:8080/api/models | python3 -m json.tool
```

---

**更新时间**: 2026-06-06 02:14  
**状态**: 等待 Xcode 重新编译  
**模拟器**: iPhone 17 Pro (9ABEC5B9-E952-422A-A0AB-E2B785C1B36C)  
**Bundle ID**: com.zhiyu.app
