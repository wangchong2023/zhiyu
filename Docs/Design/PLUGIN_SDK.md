# 智宇 (ZhiYu) 插件开发指南

本文档为第三方开发者提供智宇插件生态的深度指导，涵盖底层原理、API 规范、全球化 (i18n) 以及与 Obsidian 的深度对标。

---

## 1. 核心架构原理 (Architecture)

智宇采用**受限沙箱隔离架构**。所有插件代码（`.js` 格式）均运行在系统原生的 `JavaScriptCore` 虚拟机中，与主程序物理隔离。

### 为什么选择 JavaScriptCore 而非 Node.js？
不同于 Obsidian (基于 Electron/Node.js)，智宇是一个**高性能原生应用**：
*   **安全性**：插件无法直接调用 OS API（如文件删除、静默联网），必须通过智宇定义的受限桥接对象 `ZhiYu` 进行。符合 Apple App Store 的沙盒审核要求。
*   **性能**：极轻量化，启动速度比 Electron 插件快 5-10 倍，且能充分利用 Apple 芯片的硬件加速。

---

## 2. API 参考 (Advanced JS API)

智宇提供了一套对标 Obsidian 的 API 集合，确保开发者能快速构建功能丰富的扩展。

| 扩展维度 | 智宇 (ZhiYu) JS API | 参数说明 |
| :--- | :--- | :--- |
| **日志** | `ZhiYu.log(msg)` | 在宿主控制台打印调试日志 |
| **全局指令** | `registerCommand(id, name, func)` | 注册到 `Cmd+K` 指令面板 |
| **侧边栏入口** | `registerRibbonItem(icon, title, func)` | 注册图标到侧边栏 Ribbon |
| **配置面板** | `registerSettingTab(name, schema, func)` | 支持通过 JSON Schema 自动渲染原生设置页 |
| **自定义视图** | `registerView(id, title, icon, func)` | 注册独立的侧边栏 Tab 功能页 |
| **系统事件** | `addEventListener(event, func)` | 监听 `onFileOpen`, `onPageSave` 等 |
| **持久化存储** | `saveData(key, value)` / `loadData(key)` | 为插件提供独立的私有存储空间 (Phase 2) |
| **安全网络** | `fetch(url, callback)` | 基于 `allowedDomains` 白名单发起请求 (Phase 1) |
| **AI 介入** | `requestAIAccess(prompt)` | 调用系统级大模型能力 (需权限) |
| **内容拦截** | `preProcess(content)` | 内容持久化前的实时修改钩子 |

---

## 3. 全球化与安全清单 (i18n & Security)

### 3.1 i18n manifest.json
智宇插件原生支持全球化。在 `manifest.json` 中使用字典结构定义多语言文本：

```json
{
  "id": "com.developer.cleaner",
  "version": "1.0.0",
  "author": "ZhiYu Team",
  "permissions": ["writeContent", "log"],
  "allowedDomains": ["api.example.com"],
  "names": {
    "en": "Smart Cleaner",
    "zh-Hans": "智能清洗器"
  },
  "descriptions": {
    "en": "Cleans redundant lines and optimizes Markdown.",
    "zh-Hans": "自动清理冗余空行并优化格式。"
  }
}
```

### 3.2 Security Watchdog (安全守护者)
为了保证宿主应用的流畅度，智宇实施了严格的**熔断机制**：
*   **物理挂起**: 如果插件在单次 Hook 中的执行时间超过 **500ms**（例如死循环），系统将立即物理挂起该插件，停止其后续所有回调。
*   **流量审计**: `fetch` 请求受 `allowedDomains` 白名单限制，防止数据非法外泄 (DLP)。

---

## 4. 如何开发 1 个插件：功能增强示例

以下示例展示了如何使用 **Phase 2 (存储)** 和 **Phase 3 (声明式 UI)** API：

```javascript
// AdvancedPlugin.js

function onLoad() {
    // 注册带 UI Schema 的设置面板
    const schema = [
        { "key": "isAutoSave", "type": "toggle", "label": "自动保存修改", "header": "通用配置" },
        { "key": "apiKey", "type": "text", "label": "第三方 API Key" }
    ];

    ZhiYu.registerSettingTab("增强配置", JSON.stringify(schema), "onConfigChanged");

    // 加载先前保存的数据
    const savedKey = ZhiYu.loadData("apiKey");
    ZhiYu.log("当前 API Key: " + (savedKey || "未设置"));
}

function onConfigChanged(updatedJson) {
    ZhiYu.log("用户修改了插件配置");
    // 如果提供了回调参数，可在此处理变更
}

function preProcess(content) {
    // 业务逻辑...
    return content;
}
```
