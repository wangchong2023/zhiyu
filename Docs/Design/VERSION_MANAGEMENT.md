# 智宇 (ZhiYu) 版本管理规范

> 最后更新: 2026-06-27 (v1.0 — 初始版本，基于 Git Tag + CI 注入方案)

---

## 1. 版本号体系

### 1.1 版本字段

| 字段 | 来源 | 写入位置 | 示例 | 说明 |
|------|------|---------|------|------|
| `CFBundleShortVersionString` | `git describe --tags --abbrev=0` | Info.plist | `1.2.3` | SemVer 语义化版本，发布时通过 git tag 确定 |
| `CFBundleVersion` | `git rev-list --count HEAD` | Info.plist | `342` | 构建号，提交总数，单调递增，跨 CI 系统一致 |
| `GIT_SHORT_HASH` | `git rev-parse --short HEAD` | Info.plist (自定义键) | `abc1234` | 短提交哈希，用于精确追溯 |

### 1.2 版本展示格式

**关于页面**：`1.2.3 (342 · abc1234)`

**反馈页面**（已有）：`1.2.3` — 当前 FeedbackView 已从 `Bundle.main.infoDictionary` 读取 `CFBundleShortVersionString`，无需改动。

**App Store Connect**：`CFBundleShortVersionString` = `1.2.3`，`CFBundleVersion` = `342`

### 1.3 无 Tag 的 Fallback

开发分支或 PR 构建无 git tag 时：

| 字段 | Fallback 值 |
|------|------------|
| `CFBundleShortVersionString` | `"0.0.0-dev"` |
| `CFBundleVersion` | 正常计算（`git rev-list --count HEAD`） |
| `GIT_SHORT_HASH` | 正常计算（`git rev-parse --short HEAD`） |

关于页面展示示例：`0.0.0-dev (342 · abc1234)`

---

## 2. 版本注入脚本

### 2.1 脚本路径

`Tools/CI/Build/inject_version.sh`

### 2.2 用法

```bash
./inject_version.sh <info_plist_path>
```

典型 CI 调用：

```bash
bash Tools/CI/Build/inject_version.sh Sources/Info.plist
```

### 2.3 核心逻辑

```bash
#!/bin/bash
# 注入版本号到 Info.plist（双 CI 通用：Woodpecker + GitHub Actions）

set -euo pipefail

PLIST="${1:?用法: $0 <info_plist_path>}"

# ── 1. SemVer ──
TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$TAG" ]; then
    VERSION="${TAG#v}"          # v1.2.3 → 1.2.3
else
    VERSION="0.0.0-dev"         # 无 tag 时 fallback
fi

# ── 2. 构建号 ──
BUILD=$(git rev-list --count HEAD)

# ── 3. 短哈希 ──
HASH=$(git rev-parse --short HEAD)

# ── 4. 写入 Info.plist ──
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PLIST"

# 自定义键（Info.plist 无标准 GIT_HASH 字段）
if /usr/libexec/PlistBuddy -c "Print :GIT_SHORT_HASH" "$PLIST" &>/dev/null; then
    /usr/libexec/PlistBuddy -c "Set :GIT_SHORT_HASH $HASH" "$PLIST"
else
    /usr/libexec/PlistBuddy -c "Add :GIT_SHORT_HASH string $HASH" "$PLIST"
fi

echo "[inject_version] CFBundleShortVersionString=$VERSION  CFBundleVersion=$BUILD  HASH=$HASH"
```

### 2.4 设计决策

| 决策 | 理由 |
|------|------|
| `git describe --tags --abbrev=0` | 取最近祖先 tag，即使当前 commit 没有自身 tag 也能找到版本号 |
| 构建号用 `git rev-list --count HEAD` | 单调递增，不依赖特定 CI 系统。App Store 要求 `CFBundleVersion` 单调递增即可满足 |
| `PlistBuddy` 而非 `agvtool` | macOS 原生自带，零依赖；agvtool 需要 Xcode 工程额外配置 |
| `GIT_SHORT_HASH` 写在 Info.plist 自定义键 | 避免污染 Apple 保留字段；运行时可通过 `Bundle.main.infoDictionary` 读取 |

---

## 3. CI 集成

### 3.1 Woodpecker 流水线

在 `prepare-dependencies` 步骤（xcodegen 生成 Info.plist）之后、`build-ios` 之前插入版本注入：

```
clone-repo ──┬─→ static-analysis
             └─→ prepare-dependencies → inject-version → build-ios → ...
```

新增步骤定义：

```yaml
inject-version:
  image: *xcode_image
  commands:
    - bash Tools/CI/Build/inject_version.sh Sources/Info.plist
  depends_on:
    - prepare-dependencies
  when:
    - path:
        include: ["Sources/**"]
```

`build-ios`、`build-macos`、`build-watchos` 的 `depends_on` 从 `prepare-dependencies` 改为 `inject-version`。

### 3.2 GitHub Actions

在构建矩阵的 `Prepare Build Environment` step 之后插入版本注入：

```yaml
- name: Inject Version
  run: bash Tools/CI/Build/inject_version.sh Sources/Info.plist
```

对所有构建 job（`build-ios`、`build-macos`、`build-watchos`）均执行。

### 3.3 本地开发

`inject_version.sh` 可随时在本地运行：

```bash
bash Tools/CI/Build/inject_version.sh Sources/Info.plist
xcodegen generate  # 重新生成 Xcode 工程（若 Info.plist 被覆盖需重新注入）
```

本地开发无需手动维护版本号。发布时打 tag 即可。

---

## 4. 发布流程

### 4.1 完整发布步骤

```
1. 确定版本号              → 决定下一 SemVer（如 1.3.0）
2. git tag                 → git tag -a v1.3.0 -m "Release v1.3.0"
3. git push --tags         → 推送 tag 到远程
4. CI 自动触发             → Woodpecker 读到 tag，注入版本，构建
5. fastlane canary         → 上传 TestFlight（现有 lane 已就绪）
6. App Store Connect       → 提交审核
```

### 4.2 与 ROADMAP 的对应关系

| 阶段 | 版本 | 标签 | 说明 |
|------|------|------|------|
| MVP | 0.x | `v0.x.0` | 内部验证 |
| 阶段一 (当前) | 1.0.x | `v1.0.x` | Swift 6 并发 + 三端 |
| 阶段二 | 1.5.x | `v1.5.x` | 架构拆分 + 85% 覆盖熔断 |
| 阶段三 | 2.0.x | `v2.0.x` | iCloud 同步 + 插件生态 |

---

## 5. 代码层改动

### 5.1 AboutView

`Sources/App/Scenes/AboutView.swift` 第 52 行：

```swift
// 前: infoRow(title: L10n.Settings.About.version, value: "1.0.0 (20260512)")
// 后: infoRow(title: L10n.Settings.About.version, value: versionDisplayString)

// 新增 computed property
private var versionDisplayString: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    let hash = info?["GIT_SHORT_HASH"] as? String ?? "unknown"
    return "\(version) (\(build) · \(hash))"
}
```

### 5.2 project.yml

新增以下设置以声明版本占位（CI 在构建前覆盖实际值）：

```yaml
settings:
  base:
    MARKETING_VERSION: "0.0.0-dev"
    CURRENT_PROJECT_VERSION: "0"
```

xcodegen 生成工程时使用占位值，CI 的 `inject_version.sh` 在实际构建前覆盖。

---

## 6. 测试

### 6.1 inject_version.sh 单元测试

测试脚本：`Tests/Unit/CI/inject_version_test.sh`

| 测试场景 | 输入 | 预期输出 |
|---------|------|---------|
| 正常 tag | `git tag v1.2.3` | `CFBundleShortVersionString=1.2.3` |
| 无 tag | 无 tag 的 git 历史 | `CFBundleShortVersionString=0.0.0-dev` |
| 构建号递增 | 两次注入（tag 不变） | `CFBundleVersion` 数值单调递增 |
| 短哈希格式 | 正常 git 仓库 | 7 字符 hex 字符串 |

### 6.2 AboutView 快照测试

注入已知版本号到模拟的 `Info.plist`，验证展示格式正确：`1.2.3 (342 · abc1234)`。

### 6.3 已有门禁关联

`check_appstore_readiness.py` 已对 `CFBundleShortVersionString` 和 `CFBundleVersion` 做格式校验，注入脚本的输出通过此门禁自然验证。

---

## 7. 参考

- [CI/CD 工作流规范](../Architecture/CI_CD_WORKFLOW.md) — 双引擎 CI 架构与纵深防御矩阵
- [Apple 技术说明 TN2420](https://developer.apple.com/documentation/technotes/tn2420-version-numbers-and-build-numbers) — 版本号与构建号官方指南
- [Semantic Versioning 2.0.0](https://semver.org/) — SemVer 规范
