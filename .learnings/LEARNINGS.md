# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice

---

## [LRN-20260622-001] best_practice

**Logged**: 2026-06-22T18:00:00+08:00
**Priority**: high
**Status**: pending
**Area**: infra

### Summary
`#if os()` 宏不应出现在 Features 业务层（L2/L3），应通过 L0 协议 + PlatformRegistrar DI 注入替代

### Details
审计发现 Features 层 30 个文件存在 `#if os(iOS/macOS/watchOS)` 宏，违反平台解耦原则。正确的架构模式是：
1. 在 L0 (`Core/Base/Protocols/`) 定义跨平台协议
2. 在 `Platforms/{platform}/Services/` 实现具体平台逻辑
3. 通过 `PlatformRegistrar.registerServices(in:)` 注册
4. 业务层通过 `@Inject` 消费

### Suggested Action
- CI 中添加 Gatekeeper 检查：`grep -rn '#if os(' Sources/Features` 应返回空
- File-header-template.md 中明确禁止 Features/Domain 层使用平台宏

### Metadata
- Source: audit | correction
- Related Files: Sources/Features/ (30 files)
- Tags: platform-decoupling, protocol, architecture
- Pattern-Key: platform.no_os_macro_in_features

---

## [LRN-20260622-002] correction

**Logged**: 2026-06-22T18:10:00+08:00
**Priority**: high
**Status**: resolved
**Area**: docs

### Summary
View 文件必须标注 `[L3] 表现层`，不是 `[L2] 业务功能层`

### Details
审计发现 100 个 View 文件错误标注为 [L2]。根据架构文档，L2 是业务逻辑层（Service/ViewModel），L3 是表现层（View）。区分规则：有 `import SwiftUI` 且定义 `struct Xxx: View` 的文件标注为 [L3]。

### Resolution
- **Resolved**: 2026-06-22T18:30:00+08:00
- **Notes**: 98 个 View 文件 + 2 个 ViewModel 保留 L2，全部修正完成

### Metadata
- Source: audit | correction
- Related Files: 100 files in Sources/Features/**/View/
- Tags: file-header, layering, naming
- Pattern-Key: layering.view_must_be_l3

---

## [LRN-20260622-003] best_practice

**Logged**: 2026-06-22T18:20:00+08:00
**Priority**: medium
**Status**: pending
**Area**: docs

### Summary
文件头 `核心职责` 描述必须每文件独有，禁止模板化复制粘贴

### Details
审计发现 11 个 `Domain/Models/` 文件共享相同的通用描述。正确的做法是根据文件实际定义的领域模型写独有的职责描述。

### Suggested Action
- CI 中添加检查：同一目录下不应有 >3 个文件共享相同的 `核心职责` 描述
- file-header-template.md 已包含正确示例和错误示例

### Metadata
- Source: audit | correction
- Related Files: 11 files in Sources/Domain/Models/
- Tags: file-header, deduplication
- Pattern-Key: docs.unique_file_description

---

## [LRN-20260622-004] insight

**Logged**: 2026-06-22T18:30:00+08:00
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
硬编码 URL 和 UserDefaults key 应集中到 `AppConstants` 统一管理

### Details
审计发现 30 处硬编码 URL、11 处硬编码 UserDefaults key。已全部迁移：URL → `AppConstants.URLs`（新增 18 个常量），UserDefaults key → `AppConstants.Keys.Storage`（新增 7 个 key）。

### Suggested Action
- CI 中添加检查：`grep -rn '"https\?://' Sources --include="*.swift" | grep -v 'AppConstants\|PPTXProcessor'` 应返回空（排除 XML 命名空间）
- CI 中添加检查：`grep -rn 'UserDefaults.*forKey:\s*"' Sources/Features Sources/Platforms --include="*.swift" | grep -v 'AppConstants'` 应返回空

### Metadata
- Source: audit | correction
- Related Files: AppConstants.swift, 13 source files
- Tags: magic-strings, constants, URL
- Pattern-Key: config.no_hardcoded_url_or_key

---
