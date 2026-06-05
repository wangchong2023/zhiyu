# 插件开发规范对比：ZhiYu vs Obsidian

## 📋 插件交付件对比

### Obsidian 插件标准交付件
```
my-plugin/
├── manifest.json       # 必需：插件元数据
├── main.js            # 必需：编译后的插件代码
├── styles.css         # 可选：自定义样式
├── README.md          # 必需：插件说明文档
├── LICENSE            # 推荐：开源协议
├── .github/           # 推荐：CI/CD 配置
│   └── workflows/
└── package.json       # 开发时需要
```

### ZhiYu 插件当前交付件
```
my-plugin.zyplugin     # 压缩包
└── (包含以下文件)
    ├── manifest.json   # ✅ 必需：插件元数据
    └── index.js        # ✅ 必需：插件代码
    
❌ 缺失：README.md
❌ 缺失：LICENSE
❌ 缺失：CHANGELOG.md
❌ 缺失：样式文件支持
```

---

## 🔍 详细差异分析

### 1. 插件元数据 (manifest.json)

#### Obsidian
```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "minAppVersion": "0.15.0",
  "description": "Plugin description",
  "author": "Your Name",
  "authorUrl": "https://...",
  "isDesktopOnly": false,
  "fundingUrl": "https://..."
}
```

#### ZhiYu (当前)
```json
{
  "id": "com.zhiyu.plugin.name",
  "version": "1.0.0",
  "author": "Your Name",
  "permissions": ["readContent", "writeContent"],
  "allowedDomains": ["example.com"],
  "names": {
    "en": "My Plugin",
    "zh-Hans": "我的插件"
  },
  "descriptions": {
    "en": "Plugin description",
    "zh-Hans": "插件描述"
  }
}
```

**ZhiYu 优势：**
- ✅ 多语言支持（内置 i18n）
- ✅ 细粒度权限控制
- ✅ 域名白名单安全机制

**ZhiYu 缺失：**
- ❌ 最小 App 版本要求
- ❌ 作者主页链接
- ❌ 赞助链接
- ❌ 平台兼容性标识

---

### 2. README.md 文档

#### Obsidian 标准
```markdown
# Plugin Name

## Description
What does this plugin do?

## Features
- Feature 1
- Feature 2

## Installation
### From Obsidian Community Plugins
1. Open Settings
2. Go to Community Plugins
3. Search for "Plugin Name"
4. Install and enable

### Manual Installation
1. Download the latest release
2. Extract to .obsidian/plugins/
3. Reload Obsidian

## Usage
How to use this plugin...

## Settings
Available settings...

## Development
```bash
npm install
npm run dev
```

## Support
- Report bugs: [Issues](link)
- Donate: [Buy me a coffee](link)

## License
MIT License
```

#### ZhiYu (当前缺失)
❌ 没有 README.md 标准规范

---

### 3. 插件代码结构

#### Obsidian
```javascript
// 使用 TypeScript + Obsidian API
import { Plugin, Notice } from 'obsidian';

export default class MyPlugin extends Plugin {
    async onload() {
        console.log('Loading plugin');
        
        // 注册命令
        this.addCommand({
            id: 'my-command',
            name: 'My Command',
            callback: () => {
                new Notice('Hello!');
            }
        });
        
        // 注册设置 Tab
        this.addSettingTab(new MySettingTab(this.app, this));
    }
    
    onunload() {
        console.log('Unloading plugin');
    }
}
```

#### ZhiYu
```javascript
// 使用纯 JavaScript + ZhiYu SDK
function onLoad() {
    ZhiYu.log('Loading plugin');
    
    // 注册命令
    ZhiYu.registerCommand('my-command', 'myCallback');
    
    // 注册工具栏按钮
    ZhiYu.registerRibbonItem('icon', 'My Command', 'myCallback');
}

function onUnload() {
    ZhiYu.log('Unloading plugin');
}

function myCallback() {
    ZhiYu.showMessage('Hello!');
}

// 内容钩子
function preProcess(content) {
    return content;
}

function postProcess(content) {
    return content;
}
```

**ZhiYu 优势：**
- ✅ 更简单的函数式 API
- ✅ 内置内容处理钩子（preProcess/postProcess）
- ✅ 沙盒安全隔离

**ZhiYu 劣势：**
- ❌ 没有 TypeScript 支持
- ❌ API 文档不够完善
- ❌ 缺少设置 UI 机制

---

### 4. 插件发布流程

#### Obsidian
1. **开发阶段**
   - 使用 TypeScript 开发
   - 本地调试（热重载）
   - 编写单元测试
   
2. **打包阶段**
   - `npm run build` 编译
   - 生成 `main.js`, `manifest.json`, `styles.css`
   - 创建 GitHub Release
   
3. **发布阶段**
   - 提交 PR 到 obsidianmd/obsidian-releases
   - 等待审核（2-7 天）
   - 发布到社区插件市场
   
4. **更新阶段**
   - 更新 manifest.json 版本号
   - 创建新的 GitHub Release
   - 自动同步到插件市场

#### ZhiYu (当前)
1. **开发阶段**
   - 使用 JavaScript 开发
   - 手动测试
   - ❌ 缺少调试工具
   
2. **打包阶段**
   - 手动 zip 压缩
   - 命名为 `.zyplugin`
   - ❌ 缺少自动化脚本
   
3. **发布阶段**
   - ❌ 没有官方市场
   - ❌ 没有审核流程
   - 手动分发
   
4. **更新阶段**
   - ❌ 没有版本管理
   - ❌ 没有自动更新机制

---

### 5. 插件市场对比

#### Obsidian Community Plugins
- ✅ 官方市场（1000+ 插件）
- ✅ 分类和标签
- ✅ 搜索和过滤
- ✅ 评分和下载量
- ✅ 自动更新
- ✅ 插件依赖管理
- ✅ 插件兼容性检查

#### ZhiYu (当前)
- ✅ Mock 市场服务器
- ✅ 基础插件列表
- ✅ 下载功能
- ❌ 没有评分系统
- ❌ 没有自动更新
- ❌ 没有依赖管理
- ❌ 没有兼容性检查

---

## 📝 ZhiYu 插件标准改进建议

### 建议的插件结构
```
my-plugin/
├── README.md              # 新增：插件说明
├── README.zh-Hans.md      # 新增：中文说明
├── manifest.json          # 现有
├── index.js               # 现有
├── styles.css             # 新增：可选样式
├── LICENSE                # 新增：开源协议
├── CHANGELOG.md           # 新增：版本历史
├── assets/                # 新增：资源文件
│   ├── icon.png          # 插件图标
│   └── screenshot.png    # 截图
└── .zyplugin.build        # 新增：构建配置
```

### 改进的 manifest.json
```json
{
  "id": "com.zhiyu.plugin.name",
  "version": "1.0.0",
  "minAppVersion": "1.0.0",
  "author": "Your Name",
  "authorUrl": "https://...",
  "repositoryUrl": "https://github.com/...",
  "fundingUrl": "https://...",
  "permissions": ["readContent", "writeContent"],
  "allowedDomains": ["example.com"],
  "names": {
    "en": "My Plugin",
    "zh-Hans": "我的插件"
  },
  "descriptions": {
    "en": "Plugin description",
    "zh-Hans": "插件描述"
  },
  "categories": ["productivity", "content"],
  "platforms": ["iOS", "macOS", "watchOS"],
  "dependencies": [],
  "monetization": {
    "model": "free",
    "supportURL": "https://..."
  }
}
```

---

## 🛠️ 建议的开发工具链

### 1. 插件脚手架
```bash
# 创建新插件
zhiyu-plugin create my-plugin

# 本地开发（热重载）
zhiyu-plugin dev

# 构建插件
zhiyu-plugin build

# 发布插件
zhiyu-plugin publish
```

### 2. 插件打包脚本
```bash
#!/bin/bash
# build-plugin.sh

PLUGIN_DIR=$1
OUTPUT_DIR=${2:-dist}

# 验证必需文件
if [ ! -f "$PLUGIN_DIR/manifest.json" ]; then
    echo "❌ 缺少 manifest.json"
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/index.js" ]; then
    echo "❌ 缺少 index.js"
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/README.md" ]; then
    echo "⚠️  建议添加 README.md"
fi

# 创建压缩包
PLUGIN_NAME=$(basename $PLUGIN_DIR)
cd $PLUGIN_DIR
zip -r "../$OUTPUT_DIR/${PLUGIN_NAME}.zyplugin" .
echo "✅ 插件已打包: ${PLUGIN_NAME}.zyplugin"
```

### 3. 插件验证工具
```bash
# 验证插件完整性
zhiyu-plugin validate my-plugin.zyplugin

# 检查输出：
# ✅ manifest.json: 有效
# ✅ index.js: 有效
# ✅ README.md: 存在
# ⚠️  LICENSE: 缺失（建议添加）
# ✅ 权限声明: 合理
# ✅ 代码安全: 通过
```

---

## 📊 功能完整度对比

| 功能 | Obsidian | ZhiYu (当前) | 建议 |
|-----|----------|-------------|------|
| manifest.json | ✅ | ✅ | - |
| 插件代码 | ✅ | ✅ | - |
| README.md | ✅ | ❌ | ⭐ 必需 |
| LICENSE | ✅ | ❌ | ⭐ 推荐 |
| CHANGELOG.md | ✅ | ❌ | ⭐ 推荐 |
| 样式文件 | ✅ | ❌ | 考虑支持 |
| 图标资源 | ✅ | ❌ | 考虑支持 |
| TypeScript | ✅ | ❌ | 未来考虑 |
| 热重载调试 | ✅ | ❌ | ⭐ 重要 |
| 自动化打包 | ✅ | ❌ | ⭐ 重要 |
| 版本管理 | ✅ | ❌ | ⭐ 必需 |
| 插件市场 | ✅ | 部分 | ⭐ 重要 |
| 自动更新 | ✅ | ❌ | 推荐 |
| 评分系统 | ✅ | ❌ | 推荐 |
| 依赖管理 | ✅ | ❌ | 未来考虑 |

---

## ✅ 优先级改进建议

### 高优先级（P0）
1. ⭐ **添加 README.md 标准规范**
2. ⭐ **改进 manifest.json 字段**
3. ⭐ **提供插件打包脚本**
4. ⭐ **完善 API 文档**

### 中优先级（P1）
5. 添加 LICENSE 支持
6. 添加 CHANGELOG.md 规范
7. 提供插件验证工具
8. 支持插件热重载调试

### 低优先级（P2）
9. 支持样式文件 (styles.css)
10. 支持图标和截图
11. TypeScript 支持
12. 插件依赖管理

---

## 📝 结论

**ZhiYu 插件系统当前状态：**
- ✅ 核心功能完整（JavaScript 插件、沙盒隔离）
- ✅ 安全机制领先（权限控制、域名白名单）
- ⚠️  开发者体验需改进（缺少文档和工具）
- ❌ 生态建设待完善（市场、版本管理）

**最紧急补充：README.md 标准规范**
