# [远程] 链接预览

> 自动获取 URL 的 meta 信息并生成富文本预览卡片

## 📖 简介

链接预览是一个远程插件，能够自动抓取网页的 Open Graph 元数据，生成包含标题、描述、图片的精美预览卡片。支持本地缓存，提升加载速度。

## ✨ 功能特性

- **自动抓取**：检测文档中的 URL 并自动获取网页信息
- **Open Graph 支持**：解析 og:title、og:description、og:image
- **富文本卡片**：生成美观的预览卡片
- **智能缓存**：本地缓存已抓取的链接，减少网络请求
- **异步处理**：不阻塞文档保存

## 📦 安装

### 从插件市场安装（推荐）

1. 打开 ZhiYu 应用
2. 进入「设置」→「插件中心」
3. 切换到「社区市场」标签
4. 搜索「链接预览」
5. 点击「安装」并启用

### 手动安装

1. 下载 `link-preview-remote.zyplugin` 文件
2. 打开 ZhiYu 应用
3. 进入「设置」→「插件中心」→「我的插件」
4. 点击「加载本地插件」按钮
5. 选择下载的 `.zyplugin` 文件
6. 启用插件

## 🚀 使用方法

### 自动生成预览

1. 在 Markdown 文档中粘贴 URL
2. 保存文档
3. 插件自动在文档末尾添加预览卡片

**示例：**

输入：
```markdown
https://github.com/zhiyu-app/plugins
```

输出：
```markdown
https://github.com/zhiyu-app/plugins

---

🔗 **链接预览**

**ZhiYu Plugins - GitHub**

Powerful plugins ecosystem for ZhiYu knowledge management app...

![预览图](https://repository-images.github.com/...)

🌐 [访问链接](https://github.com/zhiyu-app/plugins)

---
```

### 命令列表

| 命令 ID | 命令名称 | 功能说明 |
|---------|---------|---------|
| `preview-link` | 预览链接 | 显示使用说明 |

### 工具栏按钮

- 🔗 **链接预览**：点击查看缓存统计

## ⚙️ 配置选项

本插件无需配置，开箱即用。

## 🔒 权限说明

本插件需要以下权限：

- **readContent**: 读取文档内容以检测 URL
- **writeContent**: 添加预览卡片到文档
- **network**: 访问网络以获取网页信息
- **log**: 记录日志信息

## 🌐 网络请求

⚠️ 本插件需要访问您文档中包含的 URL 以获取预览信息。

### 允许的域名
- `*`（所有域名）

### 隐私说明
- 插件仅在您保存文档时访问 URL
- 不会收集或上传您的文档内容
- 预览信息缓存在本地

## 💡 使用技巧

### 手动控制预览

如果不想自动生成预览，可以删除已生成的预览卡片（以 `<!-- link-preview:... -->` 标记开始）。

### 清除缓存

重新安装插件可清除所有缓存。

## 🐛 已知限制

- 仅处理文档中的第一个 URL
- 某些网站可能阻止爬虫访问
- 需要稳定的网络连接

## 📝 更新日志

### v1.0.0 (2026-06-06)
- ✨ 初始版本发布
- 支持 Open Graph 元数据解析
- 支持本地缓存
- 生成富文本预览卡片

## 📄 开源协议

本插件使用 MIT License 开源。

## 🔗 相关链接

- 类型：远程插件（Remote Plugin）
- 大小：2.1 KB
- ID：`com.zhiyu.plugin.remote.link-preview`
- 下载：http://localhost:9091/plugins/link-preview-remote.zyplugin

---

**作者**: ZhiYu Remote Team  
**版本**: 1.0.0  
**更新**: 2026-06-06
