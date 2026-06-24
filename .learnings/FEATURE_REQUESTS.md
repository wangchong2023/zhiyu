# Feature Requests

Capabilities requested by the user.

---

## [FEAT-20260622-001] platform_os_macro_ci_gatekeeper

**Logged**: 2026-06-22T18:30:00+08:00
**Priority**: high
**Status**: pending
**Area**: infra

### Requested Capability
CI 门禁自动检测 Features/Domain 层的 `#if os()` 宏使用和跨层违规

### User Context
已完成全量审计和协议化，需要 CI 门禁防止问题复现

### Complexity Estimate
medium

### Suggested Implementation
1. 新增 `Tools/Gatekeeper/check_platform_macros.py` — 扫描 Features/Domain 层 `#if os()`
2. 新增 `Tools/Gatekeeper/check_magic_strings.py` — 扫描硬编码 URL/UserDefaults key
3. 新增 `Tools/Gatekeeper/check_file_headers.py` — 验证文件头 `系统层级` 标注
4. 集成到 `.github/workflows/` 或 Xcode Build Phase

### Metadata
- Frequency: recurring
- Related Features: swiftlint, check_magic_numbers_v2.py

---
