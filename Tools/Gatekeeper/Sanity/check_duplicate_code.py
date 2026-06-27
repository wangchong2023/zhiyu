#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  check_duplicate_code.py
#  ZhiYu
#
#  Created by Antigravity on 2026/06/27.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：[Tools/Gatekeeper] CI 质量门禁
#  核心职责：集成 jscpd 检测项目中跨文件的重复/相似代码块，
#           支持 Swift/Python/Shell/YAML/Markdown/JSON，
#           本地模式与 CI 模式采用不同容忍阈值。
#
"""重复代码检测门禁：集成 jscpd，检测跨文件重复代码块。

退出码: 0=通过, 1=发现重复代码超过阈值, 2=工具未安装（非阻断）
"""

import subprocess
import sys
import json
import shutil
from pathlib import Path

# ── 常量 ──

MAX_DISPLAY_CLONES = 20

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
JSCPD_CONFIG = PROJECT_ROOT / ".jscpd.json"
JSCPD_REPORT = PROJECT_ROOT / "build" / "jscpd" / "jscpd-report.json"

# 本地模式覆盖阈值（jscpd 阈值单位为百分比：5 = 5%）
LOCAL_THRESHOLD = 5           # 5% 容忍度（开发中允许更多重复）
LOCAL_MIN_TOKENS = 80         # 较大的最小块大小（减少误报）
CI_THRESHOLD = 1              # 1% 容忍度（CI 严格红线）


def _find_jscpd() -> str | None:
    """查找 jscpd 可执行文件路径。

    依次尝试:
        1. npx（免安装，自动下载运行）
        2. jscpd（全局安装）
        3. node_modules/.bin/jscpd（项目本地）

    Returns:
        可执行文件路径，或 None 表示未找到
    """
    # 优先 npx：无需全局安装
    if shutil.which("npx"):
        return "npx"

    # 全局安装
    if shutil.which("jscpd"):
        return "jscpd"

    # 项目本地 node_modules
    local_bin = PROJECT_ROOT / "node_modules" / ".bin" / "jscpd"
    if local_bin.exists():
        return str(local_bin)

    return None


def _run_jscpd(local_mode: bool = False) -> subprocess.CompletedProcess:
    """运行 jscpd 扫描并返回结果。

    Args:
        local_mode: 是否本地开发模式（使用宽松阈值）

    Returns:
        subprocess.CompletedProcess 实例
    """
    jscpd_path = _find_jscpd()

    if jscpd_path == "npx":
        # npx 模式：自动下载后运行，无需预安装
        cmd = ["npx", "--yes", "jscpd", "--config", str(JSCPD_CONFIG)]
    else:
        cmd = [jscpd_path, "--config", str(JSCPD_CONFIG)]

    # 本地模式：通过命令行覆盖阈值（优先级高于配置文件）
    if local_mode:
        cmd.extend([
            "--threshold", str(LOCAL_THRESHOLD),
            "--min-tokens", str(LOCAL_MIN_TOKENS),
        ])

    # jscpd 默认扫描当前目录，ignore 规则在配置文件中定义
    cmd.append(".")

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
    )
    return result


def _parse_report() -> dict:
    """解析 jscpd JSON 报告，提取摘要信息。

    Returns:
        {
            "total_clones": int,           # 克隆块总数
            "duplication_percentage": float, # 重复率百分比
            "clones": list[dict],           # 每个克隆块的详细信息
        }
    """
    if not JSCPD_REPORT.exists():
        return {"total_clones": 0, "duplication_percentage": 0.0, "clones": []}

    try:
        with open(JSCPD_REPORT, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return {"total_clones": 0, "duplication_percentage": 0.0, "clones": []}

    stats = data.get("statistics", {})
    total = stats.get("total", {})

    return {
        "total_clones": total.get("clones", 0),
        # jscpd 的 percentage 已是百分比值（如 1.39 表示 1.39%）
        "duplication_percentage": round(total.get("percentage", 0.0), 2),
        "clones": data.get("duplicates", []),
    }


def _format_clone(clone: dict) -> str:
    """将单个克隆块格式化为可读的单行描述。

    输出格式:
        [swift] 12行 / 85 tokens | Sources/.../FileA.swift:L42 ↔ Sources/.../FileB.swift:L128

    Args:
        clone: jscpd report 中的单个 duplicate 条目

    Returns:
        格式化后的单行字符串
    """
    fmt = clone.get("format", "unknown")
    lines = clone.get("lines", 0)
    tokens = clone.get("tokens", 0)

    # jscpd v4+ 使用 firstFile/secondFile 结构
    first = clone.get("firstFile", {})
    second = clone.get("secondFile", {})
    file_a = first.get("name", "?")
    line_a = first.get("startLoc", {}).get("line", "?")
    file_b = second.get("name", "?")
    line_b = second.get("startLoc", {}).get("line", "?")

    # 截取相对路径
    try:
        file_a = str(Path(file_a).relative_to(PROJECT_ROOT))
    except ValueError:
        pass
    try:
        file_b = str(Path(file_b).relative_to(PROJECT_ROOT))
    except ValueError:
        pass

    return (
        f"  [{fmt}] {lines}行 / {tokens} tokens | "
        f"{file_a}:L{line_a} ↔ {file_b}:L{line_b}"
    )


def main() -> int:
    """主入口。

    Returns:
        退出码: 0=通过, 1=发现重复代码, 2=工具未安装
    """
    local_mode = "--local" in sys.argv

    mode_label = "本地宽松模式" if local_mode else "CI 严格模式"
    threshold = LOCAL_THRESHOLD if local_mode else CI_THRESHOLD

    print(f"🔍 运行 jscpd 重复代码扫描（{mode_label}，阈值 {threshold:.0f}%）...")
    print()

    jscpd_path = _find_jscpd()
    if not jscpd_path:
        print("⚠️  jscpd 未安装。通过以下任一方式安装：")
        print("     npm install -g jscpd")
        print("     或")
        print("     brew install jscpd")
        print()
        print("✅ 跳过重复代码检测（工具未安装，非阻断）")
        # 非阻断：工具未安装时不阻断流程（与 Periphery 行为一致）
        return 0

    result = _run_jscpd(local_mode=local_mode)

    # 输出 jscpd 控制台报告
    if result.stdout:
        # 选择性地输出关键行，避免终端刷屏
        for line in result.stdout.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            # jscpd 的控制台输出包含进度信息和摘要，全部输出
            print(stripped)
    if result.stderr:
        # stderr 中的警告也输出
        for line in result.stderr.splitlines():
            stripped = line.strip()
            if stripped:
                print(stripped, file=sys.stderr)

    report = _parse_report()
    total_clones = report["total_clones"]
    dup_pct = report["duplication_percentage"]

    if total_clones > 0 and dup_pct > threshold:
        print()
        print(
            f"⚠️  发现 {total_clones} 处重复代码块"
            f"（重复率 {dup_pct}%，超过阈值 {threshold:.0f}%）:"
        )
        print()

        clones = report["clones"]
        for clone in clones[:MAX_DISPLAY_CLONES]:
            print(_format_clone(clone))

        if len(clones) > MAX_DISPLAY_CLONES:
            print(f"  ... 及其他 {len(clones) - MAX_DISPLAY_CLONES} 处重复")
            print()

        print(f"💡 完整 JSON 报告: build/jscpd/jscpd-report.json")
        print("💡 提示：请提取公共方法/协议/基类消除重复代码。")
        return 1

    print()
    if total_clones == 0:
        print(f"✅ 重复代码检测通过（重复率 0%，0 处重复）")
    else:
        print(
            f"✅ 重复代码检测通过"
            f"（重复率 {dup_pct}%，在阈值 {threshold:.0f}% 以内）"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
