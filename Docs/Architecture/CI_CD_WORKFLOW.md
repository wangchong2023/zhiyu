# 智宇 (ZhiYu) 持续集成与交付 (CI/CD) 规范

> 最后更新: 2026-06-07 (v2.0 — CI 流水线重构)

---

## 1. 提交前本地审计 (Pre-commit Hook)

Git Pre-commit 钩子自动执行：

| 检查项 | 工具 | 阻断条件 |
|--------|------|---------|
| 文件头中文注释 | 自定义脚本 | 缺失标准文件头 |
| 函数文档注释 | `check_coverage.py` 改编 | 非私有函数缺少 `///` |
| SwiftLint | `.swiftlint.yml` | 任何 serious 违规 |

推荐开发者在 push 前执行：
```bash
xcodegen generate
swiftlint lint                    # 确认 0 serious
xcodebuild build -scheme ZhiYu    # 确认编译通过
```

---

## 2. 主 CI 流水线 (`.github/workflows/ci.yml`)

每次 push/PR 到 `main`/`develop` 触发，**11 步顺序执行**：

| # | 步骤 | 说明 |
|---|------|------|
| 1 | Checkout | 检出代码 |
| 2 | Xcode 15.4 | 挂载编译环境 |
| 3 | 安装工具链 | `brew install xcodegen swiftlint` |
| 4 | xcodegen generate | 从 project.yml 生成 .xcodeproj |
| 5 | **SPM 依赖审计** | `audit_spm_dependencies.py` — 阻断已知漏洞版本 |
| 6 | **SwiftLint --strict** | 所有 warning → error，任何违规阻断 |
| 7 | **密钥扫描** | `check_hardcoded_secrets.py` — 白名单豁免机制 |
| 8 | **本地化合规** | `check_localization.py` — 阻断硬编码中文/未翻译 key |
| 9 | **构建 + 全量测试** | `xcodebuild test -enableCodeCoverage YES` |
| 10 | **覆盖率红线** | `check_coverage.py` — Domain 层 ≥ 85% |
| 11 | **多平台编译验证** | iOS/macOS/watchOS 三平台 build |

> **顺序设计原则**: 快速静态检查(5-8)优先于耗时的编译测试(9-10)，避免浪费 CI 时间。

---

## 3. 安全扫描流水线 (`.github/workflows/security-scan.yml`)

| 触发 | 频率 |
|------|------|
| push/PR to main/develop | 每次 |
| cron | 每周一 02:00 |
| workflow_dispatch | 手动 |

步骤：密钥扫描 → 本地化检查 → SPM 审计 → iOS/macOS/watchOS 构建验证

---

## 4. 本地化强制网关

编译时通过 Build Phase 脚本执行 `check_localization.py`：

| 检查项 | 级别 |
|--------|------|
| 硬编码中文字符串 | ERROR — 阻断编译 |
| 直接调用 `.tr("key")` 而非 `L10n.模块.属性` | ERROR |
| 翻译值等于 key（未翻译占位符） | ERROR |
| 跨文件 key 值不一致 | ERROR |
| 源码硬编码英文句子（Logger 除外） | WARNING |

---

## 5. 代码覆盖率熔断

| 指标 | 阈值 |
|------|------|
| Domain 层覆盖率 | ≥ 85% |
| 统计方式 | `xcrun xccov view --report` 解析 .xcresult |

---

## 6. 审计工具清单

| 工具 | 用途 |
|------|------|
| `Tools/check_hardcoded_secrets.py` | 硬编码密钥/Token/IP 扫描（含白名单） |
| `Tools/check_localization.py` | 本地化合规 + xcstrings 完整性 |
| `Tools/audit_spm_dependencies.py` | SPM 依赖版本安全审计 |
| `Tools/check_coverage.py` | 覆盖率红线校验 |
| `Tools/check_magic_numbers_v2.py` | 魔鬼数字检测 |
| `Tools/ci-test-progress.sh` | CI 测试进度实时输出 |
| `Tools/run_tests.sh` | 智能模拟器定位 + 全量测试 |

---

## 7. SwiftLint 配置概要 (`.swiftlint.yml` v2.0)

| 规则 | 配置 |
|------|------|
| `force_cast` | error |
| `force_try` | error |
| `force_unwrapping` | warning (opt-in) |
| `identifier_name` | min_length: 2, 28 个例外 |
| `type_name` | 110+ 个 iOS/iCloud/L10n/嵌套类型例外 |
| `nesting` | type_level: 3 |
| `cyclomatic_complexity` | warning: 10, error: 16 |
| `function_body_length` | warning: 100, error: 150 |
| `function_parameter_count` | warning: 8, error: 15 |
| `large_tuple` | warning: 2, error: 4 |

Tests 目录独立配置 `Tests/.swiftlint.yml`: 豁免 `cyclomatic_complexity` + `function_body_length`

---

## 8. 自动化发布流水线 (Release Pipeline)

- **TestFlight 灰度分发**: 触发构建脚本 → 打包 → 上传 TestFlight
- **插件兼容性扫描**: 检查 `minAppVersion` 约束，通知插件开发者

---

## 9. 生产监控 (Observability)

- **崩溃日志**: `LocalAnalyticsService` 汇集异常堆栈
- **熔断机制**: Crash Free Rate < 99.9% → 自动告警 + 回滚通知
