#!/usr/bin/env python3
"""
Gatekeeper: 检查测试 DI 依赖注册完整性（两层防护）。

Phase 1 — 测试端：setUp() 访问 DI 单例但未调用 setupFullMockEnvironment()
Phase 2 — Mock 端：setupFullMockEnvironment() 缺失 @Inject 依赖的注册
"""

import re
import sys
from pathlib import Path

TESTS_DIR = Path("Tests")
SOURCES_DIR = Path("Sources")
MOCK_FILE = TESTS_DIR / "Shared" / "TestMocks.swift"

# 测试 setUp 中访问的高风险 DI 单例
DI_SINGLETON_PATTERNS = [
    (r"LLMService\.shared", "LLMService.shared"),
    (r"AppStore\(\)", "AppStore()"),
    (r"VaultService\.shared", "VaultService.shared"),
    (r"AIWorkflowStore\(\)", "AIWorkflowStore()"),
]

DI_SETUP_MARKERS = [
    r"setupFullMockEnvironment\(\)",
    r"ServiceContainer\.shared\.register\(.+for:",
]


# ── Phase 1: 测试端检查 ──────────────────────────────────────

def extract_setup_block(content: str) -> str:
    pattern = r"override\s+func\s+setUp\s*\([^)]*\)\s*(?:async\s+)?throws\s*\{"
    matches = list(re.finditer(pattern, content))
    if not matches:
        return ""
    blocks = []
    for m in matches:
        start = m.end()
        depth = 1
        i = start
        while i < len(content) and depth > 0:
            if content[i] == "{":
                depth += 1
            elif content[i] == "}":
                depth -= 1
            i += 1
        if depth == 0:
            blocks.append(content[start:i-1])
    return "\n".join(blocks)


def has_di_setup(content: str) -> bool:
    for marker in DI_SETUP_MARKERS:
        if re.search(marker, content):
            return True
    return False


def find_di_singletons(setup_block: str) -> list[tuple[str, str]]:
    findings = []
    for pattern, name in DI_SINGLETON_PATTERNS:
        if re.search(pattern, setup_block):
            findings.append((name, f"setupFullMockEnvironment() 或手动注册 {name} 所需依赖"))
    return findings


def phase1_check() -> list[str]:
    """检查测试文件 setUp 中 DI 单例访问是否有对应的注册。"""
    violations = []
    for fp in TESTS_DIR.rglob("*.swift"):
        if fp == MOCK_FILE:
            continue
        try:
            content = fp.read_text(encoding="utf-8")
        except Exception:
            continue
        setup_block = extract_setup_block(content)
        if not setup_block:
            continue
        findings = find_di_singletons(setup_block)
        if not findings:
            continue
        if has_di_setup(setup_block):
            continue
        for name, hint in findings:
            violations.append(
                f"  {fp}: setUp() 访问 {name}，未调用 setupFullMockEnvironment() 或手动注册\n"
                f"    修复: setUp() 开头添加 setupFullMockEnvironment() 或 {hint}"
            )
    return violations


# ── Phase 2: Mock 端完整性检查 ───────────────────────────────

def scan_inject_deps() -> dict[str, set[str]]:
    """扫描 Sources 中所有类的 @Inject 依赖。
    返回 {类名: {依赖类型集合}}。
    """
    deps: dict[str, set[str]] = {}
    # 匹配 class/actor 声明后的 @Inject 属性
    class_pattern = re.compile(
        r"(?:class|actor)\s+(\w+).*?\{", re.DOTALL
    )
    inject_pattern = re.compile(
        r"@Inject\s+(?:private\s+)?(?:var|let)\s+\w+\s*:\s*(?:any\s+)?(\w+(?:\.\w+)*)"
    )

    for fp in SOURCES_DIR.rglob("*.swift"):
        try:
            content = fp.read_text(encoding="utf-8")
        except Exception:
            continue

        # 找每个类声明
        for cm in re.finditer(class_pattern, content):
            class_name = cm.group(1)
            # 提取类体（简化：到下一个 class/extension 或文件末尾）
            body_start = cm.end()
            depth = 1
            i = body_start
            while i < len(content) and depth > 0:
                if content[i] == "{":
                    depth += 1
                elif content[i] == "}":
                    depth -= 1
                i += 1
            if depth != 0:
                continue
            body = content[body_start:i-1]

            # 找 @Inject 依赖
            for im in inject_pattern.finditer(body):
                dep_type = im.group(1)
                # 去掉 any/Some 前缀和协议限定
                dep_type = re.sub(r"^\s*any\s+", "", dep_type)
                if class_name not in deps:
                    deps[class_name] = set()
                deps[class_name].add(dep_type)

    return deps


def scan_shared_singletons() -> dict[str, str]:
    """找有 @Inject 依赖且定义了 static let shared 的类。
    返回 {类名: 文件名}。
    """
    inject_deps = scan_inject_deps()
    shared_map: dict[str, str] = {}

    # 找 class ClassName ... { ... static let shared = ClassName() ... }
    shared_pat = re.compile(r"static\s+let\s+shared\s*=\s*(\w+)\(\)")

    for fp in SOURCES_DIR.rglob("*.swift"):
        try:
            content = fp.read_text(encoding="utf-8")
        except Exception:
            continue

        # 找每个类声明
        for cm in re.finditer(r"(?:class|actor)\s+(\w+).*?\{", content, re.DOTALL):
            class_name = cm.group(1)
            # 提取类体
            body_start = cm.end()
            depth = 1
            i = body_start
            while i < len(content) and depth > 0:
                if content[i] == "{":
                    depth += 1
                elif content[i] == "}":
                    depth -= 1
                i += 1
            if depth != 0:
                continue
            body = content[body_start:i-1]

            # 检查类体内是否有 static let shared = ClassName()
            for sm in shared_pat.finditer(body):
                if sm.group(1) == class_name:
                    deps = inject_deps.get(class_name, set())
                    if deps:  # 只有有 @Inject 依赖的才报告
                        shared_map[class_name] = str(fp.relative_to(SOURCES_DIR))
                    break  # 找到即停止

    return shared_map


def scan_mock_registrations() -> set[str]:
    """扫描 setupFullMockEnvironment() 中注册的服务类型。"""
    if not MOCK_FILE.exists():
        return set()

    content = MOCK_FILE.read_text(encoding="utf-8")

    # 提取 setupFullMockEnvironment() 函数体
    m = re.search(r"func\s+setupFullMockEnvironment\s*\(\s*\)\s*\{", content)
    if not m:
        return set()

    start = m.end()
    depth = 1
    i = start
    while i < len(content) and depth > 0:
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
        i += 1
    body = content[start:i-1]

    # 匹配 register(xxx as any ProtocolType, for: ...)
    registered: set[str] = set()
    # 模式1: register(... as any ProtocolType, for: (any ProtocolType).self)
    for m in re.finditer(r"register\(.+?\bas\s+(?:any\s+)?(\w+)\s*[,\)]", body):
        registered.add(m.group(1))
    # 模式2: register(xxx, for: ConcreteType.self)
    for m in re.finditer(r"register\(.+?,\s*for:\s*(\w+)\.self\)", body):
        registered.add(m.group(1))
    # 模式3: register(xxx, for: (any ProtocolType).self)
    for m in re.finditer(r"for:\s*\(\s*any\s+(\w+)\s*\)", body):
        registered.add(m.group(1))

    return registered


def phase2_check() -> list[str]:
    """检查 setupFullMockEnvironment() 是否注册了所有 shared 单例的 @Inject 依赖。"""
    violations = []
    inject_deps = scan_inject_deps()
    shared_map = scan_shared_singletons()
    registered = scan_mock_registrations()

    for class_name, filename in shared_map.items():
        deps = inject_deps.get(class_name, set())
        missing = deps - registered
        if missing:
            violations.append(
                f"  {class_name} ({SOURCES_DIR / filename}): shared 单例的 @Inject 依赖未在 setupFullMockEnvironment() 中注册\n"
                f"    缺失: {', '.join(sorted(missing))}\n"
                f"    修复: 在 Tests/Shared/TestMocks.swift 的 setupFullMockEnvironment() 中添加对应 Mock 注册"
            )

    return violations


# ── 主入口 ────────────────────────────────────────────────────

def main() -> int:
    exit_code = 0

    # Phase 1
    p1 = phase1_check()
    if p1:
        print("=" * 72)
        print("❌ Phase 1: 测试文件 setUp() 缺少 DI 注册调用")
        print("=" * 72)
        for v in p1:
            print(v)
        print()
        exit_code = 1
    else:
        print("✅ Phase 1: 所有测试文件 setUp() 正确调用了 DI 注册")

    # Phase 2
    p2 = phase2_check()
    if p2:
        print("=" * 72)
        print("❌ Phase 2: setupFullMockEnvironment() 缺少 @Inject 依赖注册")
        print("=" * 72)
        print("以下 shared 单例的 @Inject 依赖未在 Mock 环境中注册：")
        print()
        for v in p2:
            print(v)
        print()
        print("⚠️  测试 setUp 调用 setupFullMockEnvironment() 后仍会 fatalError。")
        print("=" * 72)
        exit_code = 1
    else:
        print("✅ Phase 2: setupFullMockEnvironment() 所有 @Inject 依赖已注册")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
