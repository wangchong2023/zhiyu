# Localization Audit Upgrade & Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the localization audit tool, clean up legacy references and scripts, and ensure a zero-warning build state.

**Architecture:** 
1. Enhance `check_localization.py` to support the new multi-file `L10n` extension architecture (supporting `enum` and `static let t`).
2. Synchronize the Python audit routing logic with the Swift `resolveTableName` logic.
3. Clean up `project.yml` and `Tools/Temp/`.
4. Finalize with a `walkthrough.md` report.

**Tech Stack:** Python 3, Swift 6, XcodeGen, Shell.

---

### Task 1: Upgrade `Tools/check_localization.py`

**Files:**
- Modify: `Tools/check_localization.py`

- [x] **Step 1: Update Regex and Routing Logic**

Modify `Tools/check_localization.py` to support `enum`, `static let t`, and dynamic routing.

```python
<<<<
def resolve_table_name(key, table):
    """
    解析表名。由于已物理裁撤 Localizable.xcstrings，
    现在直接返回请求的原始表名（如 Common, Editor 等）。
    """
    return table
====
def resolve_table_name(key, table):
    """
    解析表名。同步 Swift 层 resolveTableName 的路由逻辑。
    """
    table_map = {
        "AITasks": "AI",
        "Localizable": "Common",
        "KnowledgeBase": "Knowledge"
    }
    if table in table_map:
        return table_map[table]
    
    # 特定 Key 路由逻辑
    if table == "Common":
        if key.startswith("prompt."): return "AI"
        if key.startswith("ingest."): return "Ingest"
        if key.startswith("settings."): return "Settings"
        if key.startswith("chat."): return "Chat"
        if key.startswith("vault."): return "Vault"
        
    return table
>>>>
```

And update the scanning patterns:

```python
<<<<
    struct_pat = re.compile(r'\bstruct\s+([a-zA-Z0-9_]+)')
    t_pat = re.compile(r'\blet\s+t\s*=\s*"([^"]+)"')
====
    struct_pat = re.compile(r'\b(?:struct|enum)\s+([a-zA-Z0-9_]+)')
    t_pat = re.compile(r'\b(?:public\s+|static\s+)*let\s+t\s*=\s*"([^"]+)"')
>>>>
```

Also, in `scan_other_swift_files`, change the hardcoded "Common" to "Localizable" so it passes through the routing:

```python
<<<<
                            if prefix == "Localized":
                                t = "Common"
====
                            if prefix == "Localized":
                                t = "Localizable"
>>>>
```

- [x] **Step 2: Run the audit and verify results**

Run: `./env/venv/bin/python3 Tools/check_localization.py`
Expected: "L10n Static Audit Finished: Found 0 error(s)"

- [x] **Step 3: Commit**

```bash
git add Tools/check_localization.py
git commit -m "tool: upgrade localization audit radar to support decentralized architecture and dynamic routing"
```

### Task 2: Project Configuration & Build Cleanup

**Files:**
- Modify: `project.yml`
- Delete: `Tools/Temp/*.py`

- [x] **Step 1: Verify `project.yml` and regenerate**

Ensure no stale references to `Localizable.xcstrings`.

Run: `xcodegen generate`

- [x] **Step 2: Clean Derived Data and Build**

Run: `rm -rf build/* && xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/ios_build.log 2>&1`

- [x] **Step 3: Verify zero errors/warnings**

Check `build/ios_build.log`.

- [x] **Step 4: Cleanup Temp Scripts**

Run: `rm Tools/Temp/*.py`

- [x] **Step 5: Commit changes**

```bash
git add project.yml
git commit -m "chore: cleanup project configuration and temporary migration scripts"
```

### Task 3: Documentation

**Files:**
- Create: `walkthrough.md`

- [x] **Step 1: Write `walkthrough.md`**

Summarize the refactoring results, architecture changes, and verification status.

- [x] **Step 2: Commit**

```bash
git add walkthrough.md
git commit -m "docs: add walkthrough.md summarizing the architecture refactoring outcome"
```
