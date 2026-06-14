# 智宇 (ZhiYu) 持续集成与交付 (CI/CD) 规范

> 最后更新: 2026-06-14 (v5.0 — 四层纵深防御 + 根目录卫生 + 魔鬼数字审计)

---

## 1. CI 架构概览

```
┌──────────┐    push/webhook     ┌──────────────────┐    gRPC     ┌──────────────────────────┐
│  Gitea   │ ──────────────────→ │ Woodpecker Server │ ←───────── │ Woodpecker Agent (macOS) │
│ :3000    │                     │ :8000 (Web UI)    │            │ darwin/arm64 backend=local│
└──────────┘                     │ :9000 (gRPC)      │            │ healthcheck :3001         │
                                 └──────────────────┘            └──────────────────────────┘
                                           │                                 │
                                           │ gRPC                            │ 直接执行
                                           ↓                                 ↓
                                 ┌──────────────────┐            ┌──────────────────────────┐
                                 │ Woodpecker Agent │            │ xcodebuild + Gatekeeper  │
                                 │ (Docker 容器)    │            │ 脚本 (preBuildScripts)   │
                                 │ linux/arm64      │            └──────────────────────────┘
                                 │ backend=docker   │
                                 │ healthcheck :3002│
                                 └──────────────────┘
                                           │
                                           ↓
                                    ZhiYu-Backend 构建
```

| 组件 | 位置 | 端口 | 职责 |
|------|------|------|------|
| Gitea | `bin-gitea-1` (Docker) | `3000` (Web), `2222` (SSH) | 代码托管 + Webhook |
| Woodpecker Server | `bin-woodpecker-server-1` (Docker) | `8000` (Web), `9000` (gRPC) | 流水线调度 |
| iOS Agent | `launchd` 原生进程 | `3001` (健康检查) | ZhiYu iOS 构建 (backend=local) |
| Backend Agent | `launchd` 原生进程 | `3002` (健康检查) | ZhiYu-Backend 构建 (backend=docker) |

### Agent 配置

**iOS Agent** (`~/Library/LaunchAgents/com.zhiyu.woodpecker-agent.plist`):

| 环境变量 | 值 |
|----------|-----|
| `WOODPECKER_SERVER` | `localhost:9000` |
| `WOODPECKER_BACKEND` | `local` |
| `WOODPECKER_LABELS` | `platform=darwin/arm64,backend=local` |
| `WOODPECKER_HEALTHCHECK_ADDR` | `:3001` |

**Backend Agent** (`~/Library/LaunchAgents/com.zhiyu.woodpecker-agent-backend.plist`):

| 环境变量 | 值 |
|----------|-----|
| `WOODPECKER_SERVER` | `localhost:9000` |
| `WOODPECKER_BACKEND` | `docker` |
| `WOODPECKER_LABELS` | `platform=linux/arm64,backend=docker` |
| `WOODPECKER_HEALTHCHECK_ADDR` | `:3002` |

---

## 2. 主 CI 流水线 (`.woodpecker.yml`)

每次 push 到 `main` 分支通过 Gitea Webhook 自动触发，**11 步顺序执行**：

| # | 步骤 | 说明 |
|---|------|------|
| 1 | `clone-repo` | 从 Gitea 克隆代码到 Agent 工作空间 |
| 2 | `setup` | 安装 `xcbeautify`，准备构建环境 |
| 3 | `static-analysis` | 领域纯净度检查 + 分层标记审计 + String.Index 越界扫描 |
| 4 | `generate-project` | `xcodegen generate` 从 project.yml 生成 .xcodeproj |
| 5 | `check-test-compile` | 预编译测试套件 |
| 6 | `build-ios` | iOS Simulator 构建 |
| 7 | `build-macos` | macOS Catalyst 构建 |
| 8 | `build-watchos` | watchOS Simulator 构建 |
| 9 | `count-tests` | 统计测试用例数 |
| 10 | `run-tests` | `xcodebuild test` + `xcbeautify` JUnit 报告 |
| 11 | `coverage-check` | 覆盖率红线校验 |

流水线标签：`backend: local`（仅匹配 iOS Agent）

---

## 2.5. 四层纵深防御矩阵 (Defense-in-Depth)

| 检查项 | Layer 1: Pre-commit | Layer 2: Build Phase | Layer 3: Woodpecker CI | Layer 4: GitHub Actions |
|--------|:---:|:---:|:---:|:---:|
| 硬编码密钥扫描 | ✅ | ✅ | ✅ | ✅ |
| 本地化合规 | ✅ | ✅ | ❌ | ✅ |
| SwiftLint 严格模式 | ❌ | ✅ | ✅ | ✅ |
| 架构依赖 (L0-L3 分层) | ❌ | ✅ | ✅ | ✅ |
| 领域纯净度 | ❌ | ✅ | ✅ | ✅ |
| 魔鬼数字/字符串 | ❌ | ✅ | ✅ | ✅ |
| 根目录卫生 (临时文件+结构) | ❌ | ✅ | ✅ | ✅ |
| Storage 常量 | ❌ | ✅ | ❌ | ❌ |
| HIG 合规 | ❌ | ✅ | ❌ | ❌ |
| App Store 就绪 | ❌ | ✅ | ❌ | ❌ |
| DI 测试设置审计 | ❌ | ❌ | ✅ | ✅ |
| 文档完整性 | ❌ | ❌ | ✅ | ❌ |
| 配置完整性 | ❌ | ❌ | ✅ | ❌ |
| ShellCheck | ❌ | ❌ | ✅ | ❌ |
| SPM 依赖审计 | ❌ | ❌ | ❌ | ✅ |
| 代码覆盖率红线 | ❌ | ❌ | ✅ | ✅ |

**分层原则：**
- **Layer 1 (Pre-commit)**: 最快，只阻断密钥泄露，其余仅报告
- **Layer 2 (Build Phase)**: 每次本地构建运行，覆盖代码质量 + 魔鬼数字 + 架构分层
- **Layer 3 (Woodpecker)**: 自托管 CI，最全面，每次 push 触发
- **Layer 4 (GitHub Actions)**: 独立验证 + 产物上传 + 多平台矩阵

---

## 3. Build Phase 编译门禁 (Gatekeeper)

Xcode Build Phases 中为每个 target 配置的 `preBuildScripts`（定义于 `project.yml`）：

| 脚本 | 功能 | 阻断 |
|------|------|------|
| `Tools/Gatekeeper/check_domain_purity.py` | 领域层纯净度 | ERROR |
| `Tools/Gatekeeper/check_localization.py` | 硬编码中文 + 违规 tr() 调用 | ERROR |
| `Tools/Gatekeeper/check_storage_constants.py` | 数据库物理字段硬编码 | ERROR |
| `Tools/Gatekeeper/check_magic_numbers_v2.py` | 魔鬼数字检测 | ERROR |
| `Tools/Gatekeeper/check_hardcoded_secrets.py` | 密钥/Token/IP 扫描 | ERROR |

---

## 4. 提交前本地审计 (Pre-commit Hook)

`.git/hooks/pre-commit` 在 `git commit` 时自动执行：

| 检查项 | 工具 | 阻断条件 |
|--------|------|---------|
| 硬编码密钥扫描 | `Tools/Gatekeeper/check_hardcoded_secrets.py` | 命中即阻断 |
| 本地化合规 | `Tools/Gatekeeper/check_localization.py` | 仅报告，不阻断（编译时强制） |

---

## 5. 本地化强制网关

编译时通过 Build Phase 脚本执行：

| 检查项 | 级别 |
|--------|------|
| 硬编码中文字符串 | ERROR — 阻断编译 |
| 直接调用 `.tr("key")` 而非 `L10n.模块.属性` | ERROR |
| 翻译值等于 key（未翻译占位符） | ERROR |
| 跨文件 key 值不一致 | ERROR |

---

## 6. 代码覆盖率熔断

| 指标 | 阈值 |
|------|------|
| 覆盖率统计 | `xcrun xccov view --report` 解析 .xcresult |
| CI 检查 | `Tools/CI/check_coverage.py` |

---

## 7. 工具目录结构

```
Tools/
├── Gatekeeper/          # 编译门禁 (project.yml preBuildScripts)
│   ├── check_domain_purity.py
│   ├── check_localization.py
│   ├── check_storage_constants.py
│   ├── check_magic_numbers_v2.py
│   └── check_hardcoded_secrets.py
├── CI/                  # CI 流水线脚本
│   ├── audit_spm_dependencies.py
│   ├── check_coverage.py
│   └── ci-test-progress.sh
├── Lint/                # 手动代码质量检查
│   ├── audit_l10n.py
│   ├── lint_layer_markers.sh
│   └── scan_unsafe_string_index.py
├── Mock/                # Mock 服务器 + E2E 测试
│   ├── mock_llm_server.py
│   ├── mock_model_server.py
│   ├── mock_plugin_market.py
│   ├── test_mock_api.py
│   ├── test_plugin_e2e.py
│   └── MockServer/
├── Plugins/             # 插件 SDK + 源文件 + 测试
│   ├── copy_plugins_to_sim.sh
│   ├── validate_plugin.py
│   ├── test_plugin_and_model_features.sh
│   └── Local/ Remote/ community/ smart-cleaner/
├── Utils/               # 辅助脚本
│   ├── run_tests.sh
│   ├── sync_sql.py
│   └── update_snapshots.sh
└── README.md
```

---

## 8. GitHub Actions（辅助 CI）

`.github/workflows/ci.yml` 和 `security-scan.yml` 作为 GitHub 侧的辅助流水线。

### ci.yml (v3.0 — 2026-06-14)

| 阶段 | Job | 运行器 | 内容 |
|------|-----|--------|------|
| Stage 1 | `lint-and-audit` | `macos-15` | SPM 审计 → SwiftLint → 密钥扫描 → L10n 检查 |
| Stage 2 | `test` | `macos-15` | 构建 → 单元测试 → 覆盖率红线 → 失败时上传 .xcresult |
| Stage 3 | `ui-test` | `macos-15` | UI 测试（跳过 Monkey）→ 失败时上传日志 |
| Stage 4 | `multi-platform` | `macos-15` + 矩阵 | iOS / macOS / watchOS 三平台并行编译 |

**v3.0 增强项：**
- Xcode `15.4` → `latest-stable`，macOS runner `macos-14` → `macos-15`
- 多平台构建改为 `strategy.matrix` 并行，缩短约 40% 耗时
- 测试失败时自动上传 `.xcresult` + 原始日志（`actions/upload-artifact@v4`）
- Monkey 测试（`testWildMonkeyClickTraversal`）在 CI 中显式跳过

### security-scan.yml (v3.0)

- `macos-latest` → `macos-15`
- 每周一凌晨 2:00 定时运行 + push/PR 触发

---

## 9. 流水线故障排查

| 症状 | 可能原因 | 检查方式 |
|------|----------|---------|
| 推送未触发流水线 | Gitea Webhook 失效 | `curl localhost:3000/api/v1/repos/constantine/ZhiYu/hooks` |
| Agent 未接管任务 | 标签不匹配 | 确认 Agent plist `WOODPECKER_LABELS` 与 `.woodpecker.yml` `labels` 一致 |
| 端口冲突 | healthcheck 端口被占 | `lsof -i :3001` / `lsof -i :3002` |
| Woodpecker Server 无响应 | 容器未运行 | `docker ps \| grep woodpecker-server` |
