#!/usr/bin/env python3
"""
Gatekeeper: 检查测试文件中 DI 依赖注册的完整性。

核心规则：
  测试 setUp 中访问了依赖 ServiceContainer 的共享单例（如 LLMService.shared），
  则必须在 setUp 中调用 setupFullMockEnvironment() 或手动 register() 注册 Mock 服务。

违反后果：运行时 fatalError — ServiceContainer.resolve() 在空容器中解析失败。
"""

import re
import sys
from pathlib import Path

# ── 配置 ──────────────────────────────────────────────────────
TESTS_DIR = Path("Tests")

# 需要在 setUp 中有对应 DI 注册的"高风险"模式
DI_SINGLETON_PATTERNS = [
    # 模式: (正则, 描述, 所需注册方式)
    (r"LLMService\.shared", "LLMService.shared", "setupFullMockEnvironment() 或注册 LLMConfigManager 等 5 个依赖"),
    (r"AppStore\(\)", "AppStore()", "setupFullMockEnvironment() 或注册所有 AppStore 依赖"),
]

# setUp 中存在即视为"已妥善处理 DI"的标记
DI_SETUP_MARKERS = [
    r"setupFullMockEnvironment\(\)",
    r"ServiceContainer\.shared\.register\(.+for:",
]


def extract_setup_block(content: str) -> str:
    """提取 override func setUp 到下一个 func/闭包结束 之间的代码块。"""
    # 匹配 setUp 函数体
    pattern = r"override\s+func\s+setUp\s*\([^)]*\)\s*(?:async\s+)?throws\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}"
    matches = re.findall(pattern, content, re.DOTALL)
    return "\n".join(matches)


def has_di_setup(content: str) -> bool:
    """检查 setUp 块是否包含 DI 注册逻辑。"""
    for marker in DI_SETUP_MARKERS:
        if re.search(marker, content):
            return True
    return False


def find_di_singletons_in_setup(setup_block: str):
    """在 setUp 块中查找高风险 DI 单例访问。"""
    findings = []
    for pattern, name, fix_hint in DI_SINGLETON_PATTERNS:
        if re.search(pattern, setup_block):
            findings.append((name, fix_hint))
    return findings


def check_file(filepath: Path) -> list[str]:
    """检查单个测试文件，返回违规信息列表。"""
    violations = []
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return violations

    # 提取 setUp 块
    setup_block = extract_setup_block(content)
    if not setup_block:
        return violations

    # 查找高风险单例访问
    findings = find_di_singletons_in_setup(setup_block)
    if not findings:
        return violations

    # 检查是否有 DI 注册
    if has_di_setup(setup_block):
        return violations

    # 违规
    for name, fix_hint in findings:
        violations.append(
            f"  {filepath}: setUp() 中访问了 {name}，但未调用 setupFullMockEnvironment() 或手动注册依赖\n"
            f"    修复建议: 在 setUp() 开头添加 setupFullMockEnvironment() 或 {fix_hint}"
        )
    return violations


def main() -> int:
    """主入口。返回 0=通过, 1=发现违规。"""
    if not TESTS_DIR.exists():
        print(f"⚠️  [DI Setup Check] Tests 目录不存在: {TESTS_DIR}")
        return 0

    all_violations = []
    test_files = list(TESTS_DIR.rglob("*.swift"))

    for fp in test_files:
        all_violations.extend(check_file(fp))

    if all_violations:
        print("=" * 72)
        print("❌ [DI Setup Check] 测试文件 DI 依赖注册不完整！")
        print("=" * 72)
        print("以下测试在 setUp() 中访问了依赖 ServiceContainer 的共享单例，")
        print("但未调用 setupFullMockEnvironment() 或手动注册 Mock 服务：")
        print()
        for v in all_violations:
            print(v)
        print()
        print("⚠️  这将在运行时导致 fatalError — ServiceContainer.resolve() 失败。")
        print("=" * 72)
        return 1

    print("✅ [DI Setup Check] 所有测试文件的 DI 依赖注册完整")
    return 0


if __name__ == "__main__":
    sys.exit(main())
