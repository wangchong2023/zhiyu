# -*- coding: utf-8 -*-
#
#  check_dead_code.py
#  ZhiYu
#
#  Created by Antigravity on 2026/06/24.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：[Tools/Gatekeeper] CI 质量门禁
#  核心职责：集成 Periphery 检测未使用的类型/方法/属性，仅报告真正死代码（排除跨模块公开 API）。
#
"""死代码检测门禁：集成 Periphery，检测未使用的类型/方法/属性。

仅报告真正未使用的声明（排除 "declared public, but not used outside" 这类跨 target API）。
退出码: 0=通过, 非0=发现死代码
"""

import subprocess
import sys
import re
from pathlib import Path

# ── 常量 ──
MAX_DISPLAY_LINES = 30

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent

# 基线：忽略已存在的无害模式
IGNORE_PATTERNS = [
    r"is declared public, but not used outside",      # 跨模块公开 API
    r"protocol .* conformance is redundant",           # 协议冗余声明
    r"retained, but never used",                       # 保留字段
]

def _run_periphery() -> str:
    """运行 Periphery 扫描并返回原始输出。"""
    cmd = [
        "periphery", "scan",
        "--project", str(PROJECT_ROOT / "ZhiYu.xcodeproj"),
        "--schemes", "ZhiYu",
        "--targets", "ZhiYu",
        "--disable-update-check",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout + result.stderr


def _filter_findings(raw_output: str) -> list[str]:
    """过滤 Periphery 输出，只保留真正未使用的声明。"""
    findings = []
    for line in raw_output.splitlines():
        if "warning:" not in line:
            continue
        if any(re.search(p, line) for p in IGNORE_PATTERNS):
            continue
        findings.append(line.strip())
    return findings


def main():
    """主入口。"""
    print("🔍 运行 Periphery 死代码扫描...")
    raw = _run_periphery()

    findings = _filter_findings(raw)
    total_all = len(raw.splitlines())

    if findings:
        print(f"⚠️  发现 {len(findings)} 处死代码（总警告 {total_all}，已过滤跨模块 API）:")
        for f in findings[:MAX_DISPLAY_LINES]:
            print(f"  {f}")
        if len(findings) > MAX_DISPLAY_LINES:
            print(f"  ... 及其他 {len(findings) - MAX_DISPLAY_LINES} 条")
        return 1
    else:
        print(f"✅ 死代码检测通过（扫描 {total_all} 项, 0 项需处理）")
        return 0


if __name__ == "__main__":
    sys.exit(main())
