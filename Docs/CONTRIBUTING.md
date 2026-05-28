# 智宇 (ZhiYu) 开发者贡献指南 (Contributing Guidelines)

本指南旨在帮助外部与内部开发者快速构建智宇应用，并遵循统一的开发、测试与代码审查流程。

---

## 1. 环境搭建 (Setup)

```bash
# 克隆仓库并进入物理路径
git clone <repo-url> && cd ZhiYu

# 安装 XcodeGen 与 SwiftLint 工具
brew install xcodegen swiftlint

# 从 project.yml 自动生成 Xcode 项目（所有配置变更后必须执行）
xcodegen generate

# 打开生成的 Xcode 工程
open ZhiYu.xcodeproj
```

**系统要求**：Xcode 16+，Swift 6 (开启严格并发检查)，macOS 14+。

---

## 2. 构建与测试 (Build & Test)

```bash
# 1. 构建 iOS 模拟器版本
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

# 2. 构建 macOS Catalyst 版本
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

# 3. 运行全部单元与集成测试套件并开启覆盖率生成
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES

# 4. 运行指定测试类 (例如 FTS 检索专项测试)
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ZhiYuTests/KnowledgeRepositoryTests

# 5. 执行静态代码分析
swiftlint --strict
```

---

## 3. 代码规范 (Coding Standards)

*   **垂直架构与归位**：遵循智宇垂直化功能架构 (L0 ──► L3)。Views 层严禁直接依赖 Infrastructure 层的实现，必须通过 DI 依赖注入在 `Protocols/` 定义的契约接口。
*   **并发安全 (Swift 6)**：启用 `SWIFT_STRICT_CONCURRENCY: complete`。优先使用 `async/await` 和 `actor`，严禁使用传统锁 (Locks) 或信号量同步阻塞主线程。UI 逻辑强制绑定 `@MainActor`。
*   **注释与文档**：
    *   **统一使用简体中文**书写所有注释。
    *   **/// 文档注释**：解释“为什么”，用于公开 API。
    *   **// 实现注释**：解释“怎么做”，用于复杂算法过程。
    *   使用 `// MARK: - 中文标题` 进行模块逻辑分区。
*   **UI 规范**：所有 SwiftUI 组件必须完美适配 Dark Mode，支持 Dynamic Type 动态字体缩放，并在 iPad/Mac 分屏视图中完成自适应布局测试。

---

## 4. 分支管理与 Git 工作流 (Git Flow)

*   `main`: 绝对稳定的生产发布分支。
*   `develop`: 主干合并分支，所有功能分支汇聚于此。
*   `feature/*`: 新增功能分支，完成后发起 Code Review 合入 develop。
*   `bugfix/*`: 缺陷修复分支。
*   `hotfix/*`: 紧急生产热修复分支。

---

## 5. 提交规范 (Commit Messages)

智宇强制采用 Conventional Commits 规范，所有 commit 必须使用如下前缀：
*   `feat:` 新功能的实装。
*   `fix:` 缺陷与闪退的修复。
*   `docs:` 文档及注释的变更。
*   `refactor:` 不改变业务行为的代码重构。
*   `perf:` 性能与算法瓶颈优化。
*   `test:` 测试用例的补齐与 UI 测试扩充。

---

## 6. 代码审查与合并门禁 (Code Review)

### 6.1 开发者自检清单
在提交 Pull Request (PR) 前，请开发者确保：
- [ ] 本地编译零 Error 且无任何 Static Concurrency Concurrency Conformance 警告。
- [ ] `swiftlint --strict` 零警报通过。
- [ ] 逻辑修改已补齐对应的 `XCTest` 单元测试或 `ZhiYuUITests` UI 冒烟测试。
- [ ] **流水线门禁校验**：核心领域层 (Domain) 的汇总测试覆盖率不低于 **85%**（合并前必须通过 `./env/venv/bin/python3 Tools/check_coverage.py` 熔断脚本校验）。
- [ ] 移除所有残留的调试用 `print()`。

### 6.2 门禁防线三阶段
PR 提交后，CI/CD 系统将自动拉起三阶段防御体系：
1. **L1 静态拦截**：执行静态 SwiftLint 代码审计和项目构建合法性检查。
2. **L2 单元与集成测试**：自动跑测 FTS5 混合召回、多金库 WAL 事务隔离测试，确保 100% 绿通。
3. **L3 覆盖率熔断门禁**：自动抽取最新的 `.xcresult`，验证领域层代码覆盖率是否通过 85% 门禁大关。
