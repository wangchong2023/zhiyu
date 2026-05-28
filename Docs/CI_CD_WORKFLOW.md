# 智宇 (ZhiYu) 持续集成与交付 (CI/CD) 规范

为了确保“智宇”在快速迭代与功能重构中始终保持“工业级稳健性”与“极致的用户体验”，我们实施并定义以下规范化的自动化集成与持续交付流水线。

---

## 1. 提交前本地审计 (Pre-commit Audit)

开发者在将代码 Push 至远端仓库前，应在本地开发机执行前置自测：
*   **编译一致性**：运行 `xcodegen generate` 生成项目，并执行编译，确保在 Swift 6 严格并发（Strict Concurrency: Complete）模式下无任何 Error。
*   **静态代码规范**：本地执行 `SwiftLint` 审查，确保无任何严重警告。

---

## 2. 自动化集成流水线 (CI Pipeline)

每次发起 Pull Request 合并请求时，GitHub Actions/物理流水线将自动拉起以下高强度校验，任何一项未通过均会直接阻断代码合并：

### 2.1 编译与静态规范检查 (Build & Lint Audit)
*   **Linting 强校验**：使用 `swiftlint --strict` 强制执行代码风格规范，任何 Warning 都将被提升为 Error 并阻断构建。
*   **Strict Concurrency 审核**：开启 `-Xfrontend -strict-concurrency=complete` 选项进行全编译审查，Data Race 零容忍。

### 2.2 全量单元测试门禁 (Unit Testing Gates)
*   **用例回归**：自动执行全量单元测试套件（如 `AppStoreTests`, `ServiceTests`, `KnowledgeRepositoryTests`）。核心算法（LWW-Element-Set、RAG 递归分块、物理指纹校验等）必须 100% 成功通过。
*   **代码覆盖率熔断门禁**：通过流水线脚本 `check_coverage.py` 统计覆盖率，强制要求核心领域层 (`Sources/Domain`) 整体物理行覆盖率不得低于 **85%**。对新增模型或核心数据库的覆盖率做无漏洞扫描。

### 2.3 UI 自动化与冒烟测试 (UI Testing Gates)
*   **用例执行**：执行 `ZhiYuUITests` 自动化套件（覆盖侧边栏导航、对话骨架屏、多 Vault 并发隔离切换等核心路径自动化）。
*   **健壮性断言**：在冷启动、时序延迟和网络切换等边界用例上执行自愈断言。

### 2.4 性能红线基准度量 (Performance Benchmark)
*   **基准比对**：自动运行性能跑测套件，并对比 `Docs/Testing/PERFORMANCE_BENCHMARK.md` 中的历史基准数据。
*   **时延硬指标**：在 1,000 篇基准文档载荷下，本地检索首字时延增量不得超过 5%，冷启动时间不得发生退化。

---

## 3. 自动化发布流水线 (Release Pipeline)

当主分支通过 CI 测试并触发 Release 合并后：
*   **TestFlight 自动化灰度分发**：自动触发构建脚本，打包生成 Beta 安装包并自动上传至 TestFlight “专家测试组”。
*   **第三方插件兼容性扫描**：扫描官方及社区注册的插件清单，对设置有 `minAppVersion` 兼容限制的第三方插件进行 API 签名审查，提前标记并通知插件开发者潜在的兼容风险。

---

## 4. 生产监控与回滚 (Observability & Fallback)

发布后的健康度监控：
*   **崩溃日志回传**：利用系统内置的离线 `LocalAnalyticsService` 安全汇集异常与崩溃堆栈。
*   **高危熔断机制**：当灰度阶段的实时 Crash Free Rate 低于 99.9%（即崩溃率超过 0.1%）时，自动触发报警警示并向管理员发送回滚通知。
