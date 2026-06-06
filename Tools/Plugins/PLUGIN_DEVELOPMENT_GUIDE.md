# ZhiYu 插件开发指南

> 完整的插件开发教程，从零开始构建你的第一个插件

## 📚 目录

1. [快速开始](#快速开始)
2. [插件交付件要求](#插件交付件要求)
3. [插件结构](#插件结构)
4. [API 文档](#api-文档)
5. [开发流程](#开发流程)
6. [示例插件说明](#示例插件说明)
7. [校验和测试](#校验和测试)
8. [发布流程](#发布流程)

---

## 🚀 快速开始

### 5 分钟创建你的第一个插件

```bash
# 1. 创建插件目录
mkdir my-first-plugin
cd my-first-plugin

# 2. 创建 manifest.json
cat > manifest.json << 'JSON'
{
  "id": "com.yourname.plugin.my-first",
  "version": "1.0.0",
  "author": "Your Name",
  "permissions": ["log"],
  "allowedDomains": [],
  "names": {
    "en": "My First Plugin",
    "zh-Hans": "我的第一个插件"
  },
  "descriptions": {
    "en": "A simple hello world plugin",
    "zh-Hans": "一个简单的 Hello World 插件"
  }
}
JSON

# 3. 创建 index.js
cat > index.js << 'JS'
function onLoad() {
    ZhiYu.log('[My First Plugin] Hello, ZhiYu!');
    ZhiYu.registerCommand('say-hello', 'sayHello');
}

function onUnload() {
    ZhiYu.log('[My First Plugin] Goodbye!');
}

function sayHello() {
    ZhiYu.showMessage('Hello from my plugin!');
}
JS

# 4. 打包插件
zip -r my-first-plugin.zyplugin .

# 5. 在 ZhiYu 中加载测试
```

---

## 📦 插件交付件要求

### 必需文件 (Must Have)

#### 1. manifest.json
插件元数据文件，包含插件的基本信息。

```json
{
  "id": "com.yourname.plugin.name",
  "version": "1.0.0",
  "author": "Your Name",
  "permissions": ["readContent", "writeContent", "log"],
  "allowedDomains": ["example.com"],
  "names": {
    "en": "Plugin Name",
    "zh-Hans": "插件名称"
  },
  "descriptions": {
    "en": "Plugin description",
    "zh-Hans": "插件描述"
  }
}
```

**必填字段：**
- `id` (string): 唯一标识符，建议使用反向域名格式
- `version` (string): 语义化版本号 (semver)
- `author` (string): 作者名称
- `permissions` (array): 权限列表
- `names` (object): 多语言名称
- `descriptions` (object): 多语言描述

**可选字段：**
- `allowedDomains` (array): 网络访问白名单

#### 2. index.js
插件逻辑代码，必须包含生命周期函数。

```javascript
// 必需函数
function onLoad() {
    // 插件加载时调用
}

function onUnload() {
    // 插件卸载时调用
}

// 可选钩子
function preProcess(content) {
    // 文档保存前处理
    return content;
}

function postProcess(content) {
    // 文档保存后处理
    return content;
}
```

#### 3. README.md（中英文双版）

完整的插件说明文档，面向最终用户，仅保留 5 个必要章节：

**必需章节（中英文一致）：**
1. **简介** — 一句话描述插件功能
2. **功能特性** — 3-5 条核心功能要点
3. **使用方法** — 简洁的操作说明
4. **所需权限** — 每项权限的用途说明
5. **更新日志** — 版本号和发布日期

**禁止章节（面向开发者，应从 README 移除）：**
- ❌ 安装说明
- ❌ 配置选项
- ❌ 开发指南
- ❌ 开源协议（单独 LICENSE 文件）
- ❌ 支持/赞助链接

**国际化要求：**
- ✅ 必须提供 `README.md`（英文版）
- ✅ 必须提供 `README.zh-Hans.md`（简体中文版）
- ✅ 在 manifest.json 的 `readmeFiles` 字段声明：`{"en":"README.md","zh-Hans":"README.zh-Hans.md"}`

使用 [README 模板](README_TEMPLATE.md) 快速创建。

### 推荐文件 (Should Have)

#### 4. LICENSE
开源协议文件，推荐使用 MIT License。

```
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge...
```

#### 5. CHANGELOG.md
版本历史记录。

```markdown
# Changelog

## [1.0.0] - 2026-06-06
### Added
- Initial release
```

---

## 🏗️ 插件结构

### 标准目录结构

```
my-plugin/
├── index.js          # 必需：插件代码
├── manifest.json     # 必需：插件元数据
├── README.md         # 必需：说明文档
├── LICENSE           # 推荐：开源协议
├── CHANGELOG.md      # 推荐：版本历史
└── assets/           # 可选：资源文件（未来支持）
    ├── icon.png
    └── screenshot.png
```

### 打包格式

插件必须打包为 `.zyplugin` 格式（标准 ZIP 压缩）：

```bash
# 打包命令
zip -r my-plugin.zyplugin .

# 验证打包
unzip -l my-plugin.zyplugin
```

**打包规则：**
- 文件扩展名必须是 `.zyplugin`
- 使用标准 ZIP 格式
- 所有文件放在根目录（不要嵌套文件夹）
- 文件名使用小写字母和连字符

---

## 📖 API 文档

### 全局对象：ZhiYu

所有插件通过 `ZhiYu` 全局对象与应用交互。

### 生命周期 API

```javascript
// 插件加载
function onLoad() {
    // 注册命令、工具栏按钮等
}

// 插件卸载
function onUnload() {
    // 清理资源、保存数据
}
```

### 内容处理 API

```javascript
// 保存前处理（同步）
function preProcess(content) {
    // 修改内容
    return modifiedContent;
}

// 保存后处理（异步）
function postProcess(content) {
    // 后处理逻辑
    return content;
}
```

### 日志 API

```javascript
// 记录日志
ZhiYu.log(message);

// 示例
ZhiYu.log('[MyPlugin] Plugin loaded successfully');
```

**权限要求：** `log`

### UI 交互 API

```javascript
// 显示消息提示
ZhiYu.showMessage(message);

// 示例
ZhiYu.showMessage('操作完成！');
```

### 命令注册 API

```javascript
// 注册命令
ZhiYu.registerCommand(commandId, handlerFunctionName);

// 示例
function onLoad() {
    ZhiYu.registerCommand('my-command', 'handleMyCommand');
}

function handleMyCommand() {
    ZhiYu.showMessage('Command executed!');
}
```

### 工具栏 API

```javascript
// 注册工具栏按钮
ZhiYu.registerRibbonItem(iconName, tooltip, handlerFunctionName);

// 示例
ZhiYu.registerRibbonItem('star', '收藏', 'handleFavorite');
```

**图标名称：** 使用 SF Symbols 名称（如 `star`, `heart`, `gear`）

### 存储 API

```javascript
// 保存数据
ZhiYu.saveData(key, value);

// 加载数据
var data = ZhiYu.loadData(key);

// 示例
function onLoad() {
    var config = ZhiYu.loadData('config');
    if (config) {
        // 使用配置
    }
}

function onUnload() {
    ZhiYu.saveData('config', JSON.stringify(myConfig));
}
```

**限制：**
- Key 长度：最大 256 字符
- Value 大小：最大 5 MB
- 数据会自动加密存储

**权限要求：** 自动授予（无需声明）

### 网络 API

```javascript
// HTTP 请求（同步）
var response = ZhiYu.fetch(url);

// 示例
var html = ZhiYu.fetch('https://example.com');
if (html) {
    // 处理响应
}
```

**权限要求：** `network` + 域名必须在 `allowedDomains` 白名单中

**安全限制：**
- 仅支持 HTTPS（除 localhost）
- 必须在白名单中声明域名
- 请求超时：30 秒

### AI 服务 API

```javascript
// 调用 AI 服务（异步）
var result = ZhiYu.requestAI(prompt);

// 示例
var translation = ZhiYu.requestAI('Translate to English: 你好');
```

**权限要求：** `aiAccess`

---

## 🔒 权限系统

### 权限列表

| 权限 | 说明 | API |
|-----|------|-----|
| `readContent` | 读取文档内容 | `preProcess`, `postProcess` |
| `writeContent` | 修改文档内容 | `preProcess`, `postProcess` |
| `network` | 网络访问 | `ZhiYu.fetch()` |
| `aiAccess` | AI 服务访问 | `ZhiYu.requestAI()` |
| `log` | 记录日志 | `ZhiYu.log()` |

### 最小权限原则

只申请必需的权限：

```json
{
  "permissions": ["log"]  // ✅ 仅记录日志
}
```

```json
{
  "permissions": ["readContent", "writeContent", "network", "aiAccess"]  // ⚠️ 请慎重
}
```

### 域名白名单

使用网络权限时必须声明域名：

```json
{
  "permissions": ["network"],
  "allowedDomains": [
    "api.example.com",
    "cdn.example.com"
  ]
}
```

**通配符：**
- `*` - 允许所有域名（不推荐）
- `*.example.com` - 允许所有子域名（未来支持）

---

## 🛠️ 开发流程

### 1. 创建插件

使用快速开始模板或手动创建文件。

### 2. 本地开发

```bash
# 编辑代码
vim index.js

# 打包测试
zip -r my-plugin.zyplugin .

# 在 ZhiYu 中加载
# 设置 → 插件中心 → 我的插件 → 加载本地插件
```

### 3. 调试技巧

```javascript
// 使用日志调试
ZhiYu.log('[Debug] Variable value: ' + myVar);

// 使用消息提示
ZhiYu.showMessage('Debug: ' + JSON.stringify(data));

// 错误处理
try {
    // 你的代码
} catch (e) {
    ZhiYu.log('[Error] ' + e.toString());
}
```

### 4. 测试清单

- [ ] 插件能否正常加载
- [ ] 命令是否注册成功
- [ ] 工具栏按钮是否显示
- [ ] 内容处理是否正确
- [ ] 数据持久化是否工作
- [ ] 网络请求是否成功（如有）
- [ ] 权限声明是否完整
- [ ] 卸载后是否清理干净

---

## 📘 示例插件说明

### 示例 1：[本地] TOC 生成器

**功能：** 自动为 Markdown 文档生成目录索引

**文件位置：** `Tools/Plugins/Local/toc-generator/`

**核心功能：**
- 扫描 H1-H6 标题
- 生成层级缩进的目录
- 支持增量更新
- 统计生成次数

**技术要点：**
- 使用正则表达式匹配标题
- 使用 `<!-- TOC -->` 标记定位目录位置
- 使用 `preProcess` 钩子在保存前处理
- 使用 `ZhiYu.saveData` 持久化统计

**权限：** `writeContent`, `log`

**学习价值：**
- ✅ 文本处理和正则表达式
- ✅ 内容钩子使用
- ✅ 数据持久化

### 示例 2：[本地] 字数统计

**功能：** 实时统计文档字数、字符数、段落数

**文件位置：** `Tools/Plugins/Local/word-counter/`

**核心功能：**
- 中英文混合统计
- 过滤 Markdown 语法
- 保存历史记录
- 显示统计信息

**技术要点：**
- 使用正则表达式过滤语法
- 区分中文字符和英文单词
- 使用 `postProcess` 钩子后台统计
- 使用工具栏按钮显示结果

**权限：** `readContent`, `log`

**学习价值：**
- ✅ 文本分析和统计
- ✅ 中文处理
- ✅ UI 交互

### 示例 3：[远程] 链接预览

**功能：** 自动获取 URL 的 meta 信息并生成预览卡片

**文件位置：** `Tools/Plugins/Remote/link-preview/`

**核心功能：**
- 检测文档中的 URL
- 抓取网页 Open Graph 元数据
- 生成富文本预览卡片
- 本地缓存优化

**技术要点：**
- 使用 `ZhiYu.fetch` 获取网页内容
- 解析 HTML meta 标签
- 使用 `postProcess` 钩子添加预览
- 缓存机制减少网络请求

**权限：** `readContent`, `writeContent`, `network`, `log`

**学习价值：**
- ✅ 网络请求
- ✅ HTML 解析
- ✅ 缓存策略

### 示例 4：[远程] AI 翻译器

**功能：** 使用 AI 服务自动翻译文本

**文件位置：** `Tools/Plugins/Remote/ai-translator/`

**核心功能：**
- 标记语法触发翻译
- 支持多语言互译
- 自动检测源语言
- 翻译统计

**技术要点：**
- 使用 `ZhiYu.requestAI` 调用 AI 服务
- 使用正则表达式解析标记
- 使用 `postProcess` 钩子自动翻译
- 构建合适的提示词

**权限：** `readContent`, `writeContent`, `aiAccess`, `log`

**学习价值：**
- ✅ AI 服务集成
- ✅ 提示词工程
- ✅ 异步处理

---

## ✅ 校验和测试

### 插件完整性校验

ZhiYu 在加载插件时会执行以下校验：

#### 1. 文件格式校验
- ✅ 文件扩展名必须是 `.zyplugin`
- ✅ 必须是有效的 ZIP 压缩包
- ✅ 压缩包不能为空

#### 2. 必需文件校验
- ✅ `manifest.json` 必须存在
- ✅ `index.js` 必须存在
- ⚠️ `README.md` 推荐存在（未来可能要求）

#### 3. manifest.json 校验
- ✅ 必须是有效的 JSON 格式
- ✅ 必填字段完整：`id`, `version`, `author`, `permissions`, `names`, `descriptions`
- ✅ `id` 格式正确（反向域名）
- ✅ `version` 符合 semver 规范
- ✅ `permissions` 是有效的权限列表
- ✅ `names` 至少包含 `en` 或 `zh-Hans`

#### 4. index.js 校验
- ✅ 文件内容非空
- ✅ JavaScript 语法有效
- ✅ 包含 `onLoad` 函数
- ⚠️ 包含 `onUnload` 函数（推荐）

#### 5. 安全校验
- ✅ 代码沙盒隔离
- ✅ 权限验证
- ✅ 域名白名单验证
- ✅ 执行超时保护（0.5 秒）

### 手动验证工具

```bash
# 验证压缩包格式
unzip -t my-plugin.zyplugin

# 查看文件列表
unzip -l my-plugin.zyplugin

# 验证 manifest.json
unzip -p my-plugin.zyplugin manifest.json | python3 -m json.tool

# 检查文件大小
ls -lh my-plugin.zyplugin
```

### 测试清单

#### 基础测试
- [ ] 插件能够成功加载
- [ ] `onLoad` 函数被调用
- [ ] 日志输出正常
- [ ] 命令注册成功
- [ ] 工具栏按钮显示

#### 功能测试
- [ ] 内容处理正确（preProcess/postProcess）
- [ ] 数据持久化工作
- [ ] 网络请求成功（如有）
- [ ] AI 调用正常（如有）
- [ ] 错误处理健壮

#### 卸载测试
- [ ] `onUnload` 函数被调用
- [ ] 数据正确保存
- [ ] 资源完全释放
- [ ] 重新加载正常

---

## 🚀 发布流程

### 1. 准备发布

```bash
# 确保所有文件完整
ls -la my-plugin/
# 应该包含：index.js, manifest.json, README.md, LICENSE, CHANGELOG.md

# 更新版本号
vim manifest.json  # 修改 version

# 更新 CHANGELOG
vim CHANGELOG.md
```

### 2. 打包插件

```bash
cd my-plugin
zip -r ../my-plugin.zyplugin .
cd ..

# 验证打包
unzip -l my-plugin.zyplugin
```

### 3. 本地测试

在 ZhiYu 中完整测试一遍所有功能。

### 4. 发布到社区（未来）

目前通过以下方式分发：
- 个人网站
- GitHub Releases
- 社区论坛

未来将支持：
- ZhiYu 官方插件市场
- 自动更新机制

---

## 📝 最佳实践

### 代码规范

```javascript
// ✅ 好的做法
function onLoad() {
    ZhiYu.log('[MyPlugin] v1.0.0 loaded');
    
    // 恢复配置
    var config = ZhiYu.loadData('config');
    if (config) {
        try {
            myConfig = JSON.parse(config);
        } catch (e) {
            ZhiYu.log('[MyPlugin] Config parse error: ' + e);
        }
    }
}

// ❌ 不好的做法
function onLoad() {
    // 没有日志
    myConfig = JSON.parse(ZhiYu.loadData('config')); // 可能崩溃
}
```

### 错误处理

```javascript
// 始终使用 try-catch
function postProcess(content) {
    try {
        return processContent(content);
    } catch (e) {
        ZhiYu.log('[MyPlugin] Error: ' + e.toString());
        return content; // 返回原始内容
    }
}
```

### 性能优化

```javascript
// 使用缓存避免重复计算
var cache = {};

function expensiveOperation(key) {
    if (cache[key]) {
        return cache[key];
    }
    
    var result = doExpensiveWork(key);
    cache[key] = result;
    return result;
}
```

---

## 🔗 相关资源

- [README 模板](README_TEMPLATE.md)
- [插件归档总结](../PLUGINS_ARCHIVE_SUMMARY.md)
- [与 Obsidian 对比](../PLUGIN_DEVELOPMENT_COMPARISON.md)
- [示例插件源码](Local/ 和 Remote/)

---

**版本**: 1.0.0  
**更新**: 2026-06-06  
**作者**: ZhiYu Team
