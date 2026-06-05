# 插件压缩包归档总结

## 📦 插件归档概览

### 插件格式
- **文件扩展名**: `.zyplugin`
- **压缩格式**: ZIP (标准格式)
- **包含文件**: 
  - `manifest.json` - 插件元数据
  - `index.js` - 插件逻辑代码

---

## 🏠 本地插件（Local Plugins）

**用途**: 本地加载，无需网络权限，适合离线使用

### 1. [本地] TOC 生成器
- **文件**: `Tools/Plugins/Local/toc-generator-local.zyplugin`
- **ID**: `com.zhiyu.plugin.local.toc-generator`
- **大小**: 1.9 KB
- **功能**: 
  - 自动扫描 Markdown 文档中的所有标题
  - 生成目录索引（TOC）
  - 支持自动更新现有目录
  - 统计生成次数
- **权限**: `writeContent`, `log`
- **钩子**: `preProcess`
- **命令**: 
  - `generate-toc` - 生成目录
- **工具栏**: "生成目录" 按钮

### 2. [本地] 字数统计
- **文件**: `Tools/Plugins/Local/word-counter-local.zyplugin`
- **ID**: `com.zhiyu.plugin.local.word-counter`
- **大小**: 1.9 KB
- **功能**:
  - 实时统计字数、字符数
  - 统计段落数和行数
  - 支持中英文混合
  - 保留最近 10 次统计记录
- **权限**: `readContent`, `log`
- **钩子**: `postProcess`
- **命令**: 
  - `count-words` - 显示统计
- **工具栏**: "字数统计" 按钮

### 3. [本地] 智能清洗器（已存在）
- **文件**: `Tools/Plugins/smart-cleaner.zyplugin`
- **ID**: `com.zhiyu.plugin.smart-cleaner`
- **大小**: 1.9 KB
- **功能**:
  - 清理冗余空行
  - 规范化空格
  - 优化 Markdown 格式
- **权限**: `writeContent`, `log`
- **钩子**: `preProcess`

---

## 🌐 远程插件（Remote Plugins）

**用途**: 从插件市场下载，需要网络权限，功能更丰富

### 1. [远程] 链接预览
- **文件**: `Tools/Plugins/Remote/link-preview-remote.zyplugin`
- **ID**: `com.zhiyu.plugin.remote.link-preview`
- **大小**: 2.1 KB
- **功能**:
  - 自动获取 URL 的 meta 信息
  - 生成富文本预览卡片
  - 提取标题、描述、图片
  - 本地缓存优化
- **权限**: `readContent`, `writeContent`, `network`, `log`
- **允许域名**: `*`（所有域名）
- **钩子**: `postProcess`
- **下载URL**: `http://localhost:9091/plugins/link-preview-remote.zyplugin`

### 2. [远程] AI 翻译器
- **文件**: `Tools/Plugins/Remote/ai-translator-remote.zyplugin`
- **ID**: `com.zhiyu.plugin.remote.ai-translator`
- **大小**: 1.9 KB
- **功能**:
  - 使用 AI 服务翻译文本
  - 支持多语言互译
  - 自动检测源语言
  - 翻译统计和历史
- **权限**: `readContent`, `writeContent`, `aiAccess`, `log`
- **钩子**: `postProcess`
- **命令**:
  - `translate-to-en` - 翻译为英文
  - `translate-to-zh` - 翻译为中文
- **下载URL**: `http://localhost:9091/plugins/ai-translator-remote.zyplugin`

---

## 🔄 本地 vs 远程插件对比

| 特性 | 本地插件 | 远程插件 |
|-----|---------|---------|
| **安装方式** | 手动导入 `.zyplugin` | 插件市场下载 |
| **网络需求** | ❌ 无需网络 | ✅ 需要网络 |
| **权限范围** | 基础权限 | 扩展权限（网络、AI） |
| **名称标识** | `[本地]` / `[Local]` | `[远程]` / `[Remote]` |
| **ID 前缀** | `.local.` | `.remote.` |
| **作者标识** | "Local Team" | "Remote Team" |
| **下载URL** | - | 包含 `downloadURL` |
| **更新方式** | 手动替换 | 市场自动更新 |
| **使用场景** | 离线环境、隐私优先 | 需要外部服务、功能丰富 |

---

## 📊 插件市场数据

### Mock 服务器配置
- **URL**: `http://localhost:9091/api/plugins`
- **插件总数**: 5 个
  - 2 个远程插件（可下载）
  - 3 个社区插件

### API 端点
```bash
# 获取插件列表
GET http://localhost:9091/api/plugins

# 获取插件详情
GET http://localhost:9091/api/plugins/{plugin_id}

# 下载插件
GET http://localhost:9091/plugins/{filename}.zyplugin
```

---

## 🧪 测试验证

### 测试插件压缩包
```bash
# 查看压缩包内容
unzip -l Tools/Plugins/Local/toc-generator-local.zyplugin

# 测试下载远程插件
curl -O http://localhost:9091/plugins/link-preview-remote.zyplugin

# 验证压缩包完整性
file Tools/Plugins/Remote/ai-translator-remote.zyplugin
```

### 测试 Mock API
```bash
# 运行自动化测试
python3 Tools/test_mock_api.py

# 测试插件下载
curl -I http://localhost:9091/plugins/link-preview-remote.zyplugin
```

---

## 📁 目录结构

```
Tools/Plugins/
├── Local/                              # 本地插件
│   ├── toc-generator/
│   │   ├── index.js
│   │   └── manifest.json
│   ├── word-counter/
│   │   ├── index.js
│   │   └── manifest.json
│   ├── toc-generator-local.zyplugin    # 打包文件
│   └── word-counter-local.zyplugin     # 打包文件
│
├── Remote/                             # 远程插件
│   ├── link-preview/
│   │   ├── index.js
│   │   └── manifest.json
│   ├── ai-translator/
│   │   ├── index.js
│   │   └── manifest.json
│   ├── link-preview-remote.zyplugin    # 打包文件
│   └── ai-translator-remote.zyplugin   # 打包文件
│
├── smart-cleaner.zyplugin              # 原有示例
├── smart-cleaner/
│   ├── index.js
│   └── manifest.json
│
└── PLUGIN_SDK.d.ts                     # TypeScript 类型定义
```

---

## ✅ 归档状态

| 插件 | 源代码 | 压缩包 | Mock 服务器 | 测试 |
|-----|-------|-------|------------|-----|
| [本地] TOC 生成器 | ✅ | ✅ | - | ✅ |
| [本地] 字数统计 | ✅ | ✅ | - | ✅ |
| [本地] 智能清洗器 | ✅ | ✅ | ✅ | ✅ |
| [远程] 链接预览 | ✅ | ✅ | ✅ | ✅ |
| [远程] AI 翻译器 | ✅ | ✅ | ✅ | ✅ |

---

## 🎯 区分度总结

### 命名区分
- ✅ **名称前缀**: `[本地]` / `[远程]` 明确标识
- ✅ **ID 格式**: `.local.` / `.remote.` 命名空间隔离
- ✅ **作者标识**: "Local Team" / "Remote Team"

### 功能区分
- ✅ **本地插件**: 文档处理、格式化、统计等离线功能
- ✅ **远程插件**: 网络请求、AI 服务等在线功能

### 权限区分
- ✅ **本地插件**: 基础读写权限
- ✅ **远程插件**: 扩展网络和 AI 权限

### 分发区分
- ✅ **本地插件**: 手动导入，无 `downloadURL`
- ✅ **远程插件**: 市场下载，包含 `downloadURL`

---

## 📝 结论

**所有插件已成功归档并具有明确区分度：**

1. ✅ 本地插件 (3 个) - 离线可用，隐私安全
2. ✅ 远程插件 (2 个) - 功能丰富，需要网络
3. ✅ 压缩包格式统一 - `.zyplugin` (ZIP)
4. ✅ Mock 服务器支持下载
5. ✅ 命名和功能完全区分
6. ✅ 测试用例完备
