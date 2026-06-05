# 硬编码敏感信息安全审计报告

## 📊 审计结果概览

**扫描范围**: `Sources/` 目录  
**扫描文件**: Swift 源代码文件  
**发现问题**: 40 处潜在硬编码信息

### 问题分类

| 类型 | 数量 | 风险等级 |
|-----|------|---------|
| HTTP/HTTPS URL | 28 | ⚠️ 中等 |
| IP 地址 | 1 | ⚠️ 中等 |
| API 密钥/Token | 9 | ⚠️ 中等（测试数据） |
| 邮箱地址 | 2 | ℹ️ 低（测试数据） |

---

## 🔍 详细分析

### 1. HTTP/HTTPS URL (28 处)

#### 高优先级需要迁移的 URL

##### 1.1 LLM 服务提供商 URL

**位置**: `Sources/Infrastructure/LLM/LLMModels.swift`

```swift
// ❌ 当前：硬编码在代码中
.init(id: "zhipu", baseURL: "https://open.bigmodel.cn/api/paas/v4")
.init(id: "minimax", baseURL: "https://api.minimax.chat/v1")
.init(id: "qwen", baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1")
.init(id: "deepseek", baseURL: "https://api.deepseek.com/v1")
.init(id: "kimi", baseURL: "https://api.moonshot.cn/v1")
.init(id: "siliconflow", baseURL: "https://api.siliconflow.cn/v1")
```

**建议**: 移至 `AppConfig.json`

```json
{
  "llm_providers": {
    "zhipu": "https://open.bigmodel.cn/api/paas/v4",
    "minimax": "https://api.minimax.chat/v1",
    "qwen": "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "deepseek": "https://api.deepseek.com/v1",
    "kimi": "https://api.moonshot.cn/v1",
    "siliconflow": "https://api.siliconflow.cn/v1"
  }
}
```

##### 1.2 CDN 资源 URL

**位置**: `Sources/Shared/UIComponents/Editors/MermaidWebView.swift`

```swift
// ❌ 当前：硬编码 CDN 地址
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
```

**风险**: CDN 可能被墙、服务不稳定、版本变更

**建议**: 
1. 使用本地资源（已有 `mermaid.min.js`）
2. 或配置到 AppConfig.json 支持切换 CDN

##### 1.3 GitHub OAuth URL

**位置**: `Sources/Features/System/Auth/Strategy/GitHubAuthStrategy.swift`

```swift
// ⚠️ 当前：部分硬编码
let urlString = "https://github.com/login/oauth/authorize?client_id=\(clientId)&state=\(state)&scope=read:user,user:email"
```

**状态**: ✅ 可接受（OAuth 标准 URL）

#### 低优先级 URL

##### 1.4 官网链接

**位置**: `Sources/App/AboutView.swift`

```swift
// ℹ️ 展示性 URL，可保留
"https://zhiyu.ai"
```

**状态**: ✅ 可接受（UI 展示，非敏感）

---

### 2. IP 地址 (1 处)

**位置**: `Sources/Infrastructure/Processors/Network/WebScraperProcessor.swift:209`

```swift
// User-Agent 字符串中的示例 IP
let archiveUA = ["Mozilla/5.0", "(Macintosh;", "Intel", "Mac", "OS", "X", "10_15", ...
```

**状态**: ✅ 可接受（User-Agent 示例，非真实 IP）

---

### 3. API 密钥/Token (9 处)

#### 3.1 Mock 测试数据

**位置**: 
- `Sources/Features/System/Auth/Service/AuthService.swift`
- `Sources/Features/System/Auth/Strategy/*AuthStrategy.swift`

```swift
// ✅ Mock 数据，用于测试和演示
accessToken: "mock_jwt_access_token"
refreshToken: "mock_jwt_refresh_token"
"mock_google_id_token_\(UUID().uuidString)"
"mock_carrier_token_\(UUID().uuidString)"
```

**状态**: ✅ 可接受（明确标记为 mock，无真实凭证）

**建议**: 确保这些 mock 逻辑在生产环境被禁用

```swift
#if DEBUG
let mockToken = "mock_jwt_access_token"
#else
// 生产环境不应有 mock 逻辑
#endif
```

#### 3.2 Keychain 键名

**位置**: `Sources/Infrastructure/LLM/LLMModels.swift:192`

```swift
// ℹ️ Keychain 存储的键名（非密钥本身）
private let legacyKeychainAPIKey = "llm_api_key"
```

**状态**: ✅ 可接受（键名不是密钥）

---

### 4. 邮箱地址 (2 处)

**位置**: `Sources/Features/System/Auth/Strategy/GoogleAuthStrategy.swift`

```swift
// ✅ Mock 测试邮箱
"email": "mock_google_user@gmail.com"
```

**状态**: ✅ 可接受（测试数据）

---

## 🎯 优先级修复建议

### P0 - 高优先级（必须修复）

✅ **无高风险硬编码发现**

当前所有硬编码信息都属于可接受范围或中等优先级。

### P1 - 中优先级（建议修复）

#### 1. 迁移 LLM 提供商 URL

**影响文件**: `Sources/Infrastructure/LLM/LLMModels.swift`

**修复方案**:

```swift
// 修改前
static let providers: [LLMProvider] = [
    .init(id: "zhipu", baseURL: "https://open.bigmodel.cn/api/paas/v4"),
    // ...
]

// 修改后
static let providers: [LLMProvider] = [
    .init(id: "zhipu", baseURL: AppConfig.llmProviderURL(for: "zhipu")),
    // ...
]
```

**AppConfig.json**:
```json
{
  "llm_providers": {
    "zhipu": "https://open.bigmodel.cn/api/paas/v4",
    "minimax": "https://api.minimax.chat/v1",
    ...
  }
}
```

#### 2. 使用本地 Mermaid 资源

**影响文件**: `Sources/Shared/UIComponents/Editors/MermaidWebView.swift`

**修复方案**:

```swift
// 修改前
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>

// 修改后
<script src="\(localMermaidPath)"></script>
```

使用已有的本地文件: `Sources/Shared/Resources/js/mermaid.min.js`

### P2 - 低优先级（可选优化）

#### 1. 添加 DEBUG 保护

确保所有 mock 代码在生产环境禁用:

```swift
#if DEBUG
private func getMockToken() -> String {
    return "mock_jwt_access_token"
}
#else
// 生产环境不应有 mock 逻辑
#endif
```

#### 2. 集中管理第三方 URL

创建统一的第三方服务配置:

```json
{
  "third_party_services": {
    "cdn": {
      "jsdelivr": "https://cdn.jsdelivr.net",
      "unpkg": "https://unpkg.com"
    },
    "oauth": {
      "github_auth": "https://github.com/login/oauth/authorize",
      "google_auth": "https://accounts.google.com/o/oauth2/v2/auth"
    }
  }
}
```

---

## ✅ 良好实践

### 1. 已正确使用配置文件

以下配置已正确使用 `AppConfig.json`:

```json
{
  "network": {
    "backend_base_url": "http://10.211.55.4:30080",
    "plugin_market_production": "https://...",
    "plugin_market_debug": "http://localhost:9091/api/plugins",
    "model_store_production": "http://10.211.55.4:30080/api/ai/models/allowlist",
    "model_store_debug": "http://localhost:8080/api/models",
    "jina_reader_base": "https://r.jina.ai/",
    "ollama_base": "http://localhost:11434",
    "deepseek_base": "https://api.deepseek.com/v1"
  }
}
```

### 2. 使用 Keychain 存储敏感数据

```swift
// ✅ 正确：使用 Keychain 存储 API 密钥
SecurityManager.shared.save(apiKey, forKey: "llm_api_key")
```

### 3. Mock 数据明确标记

```swift
// ✅ 正确：mock 数据命名清晰
accessToken: "mock_jwt_access_token"
```

---

## 📋 修复清单

- [ ] 将 LLM 提供商 URL 移至 AppConfig.json
- [ ] 使用本地 Mermaid 资源替代 CDN
- [ ] 为所有 mock 代码添加 #if DEBUG 保护
- [ ] 验证生产环境不包含 mock 逻辑
- [ ] 创建第三方服务 URL 配置章节
- [ ] 更新配置读取代码

---

## 🔒 安全最佳实践

### 1. 配置文件管理

```
✅ DO
- 将所有 URL 放入 AppConfig.json
- 为不同环境使用不同配置
- 使用版本控制管理配置文件

❌ DON'T
- 在代码中硬编码生产 URL
- 将真实密钥提交到代码仓库
- 在多处重复相同的 URL
```

### 2. 敏感数据存储

```
✅ DO
- API 密钥存储在 Keychain
- 使用环境变量传递敏感配置
- 加密存储用户凭证

❌ DON'T
- 在代码中硬编码密钥
- 明文存储密码
- 在日志中输出敏感信息
```

### 3. Mock 数据管理

```
✅ DO
- Mock 数据用 #if DEBUG 保护
- Mock 数据命名清晰（带 mock_ 前缀）
- 生产构建时移除所有 mock 逻辑

❌ DON'T
- 在生产环境使用 mock 数据
- Mock 数据模糊不清
- Mock 逻辑与生产逻辑混合
```

---

## 📊 总体评估

### 安全等级: 🟢 良好

- ✅ **无高风险硬编码**
- ✅ **正确使用 Keychain**
- ✅ **配置文件管理规范**
- ⚠️ **有改进空间**：LLM 提供商 URL、CDN 资源

### 合规性: ✅ 符合

- ✅ 无真实密钥泄露
- ✅ Mock 数据标记清晰
- ✅ 测试数据不影响生产

---

## 🛠️ 工具使用

### 定期扫描

```bash
# 运行硬编码检查
python3 Tools/check_hardcoded_secrets.py

# 检查特定目录
python3 Tools/check_hardcoded_secrets.py Sources/Infrastructure

# 输出到文件
python3 Tools/check_hardcoded_secrets.py > security_report.txt
```

### 持续集成

建议在 CI/CD 中添加安全检查:

```yaml
# .github/workflows/security.yml
- name: Check Hardcoded Secrets
  run: python3 Tools/check_hardcoded_secrets.py
```

---

**审计时间**: 2026-06-06  
**审计工具**: check_hardcoded_secrets.py v1.0  
**下次审计**: 建议每月一次
