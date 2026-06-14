#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  check_coverage.py
#  ZhiYu
#
#  Created by Antigravity on 2026/06/12.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：[Tools/Gatekeeper] 守卫网关
#  核心职责：单元测试覆盖率红线守卫。
#           解析苹果 `.xcresult` 测试结果，提取指定架构层级的代码覆盖率，
#           并强制进行红线拦截（Domain >= 80%, Core/Infra >= 75%, 整体 >= 60%）。
#

import os
import sys
import json
import subprocess
import argparse

# ==============================================================================
# MARK: - 全局配置区
# ==============================================================================

# 覆盖率拦截门禁红线定义
COVERAGE_THRESHOLDS = {
    "Domain": 0.80,         # Domain 层覆盖率必须 >= 80%
    "Core": 0.75,           # Core 层覆盖率必须 >= 75%
    "Infrastructure": 0.75, # Infrastructure 层覆盖率必须 >= 75%
    "Overall": 0.60         # 整体项目覆盖率必须 >= 60%
}

# 百分比换算乘数
PERCENT_MULTIPLIER = 100

# 模拟测试数据专用的行数和覆盖行数常量
MOCK_DOMAIN_LINES = 100
MOCK_DOMAIN_COVERED = 85
MOCK_CORE_LINES = 100
MOCK_CORE_COVERED = 70
MOCK_INFRA_LINES = 200
MOCK_INFRA_COVERED = 160
MOCK_FEATURE_LINES = 15

# 物理模块分类的匹配标识（基于文件绝对路径片段识别）
LAYER_FRAGMENTS = {
    "Domain": "Sources/Domain",
    "Core": "Sources/Core",
    "Infrastructure": "Sources/Infrastructure"
}

# ==============================================================================
# MARK: - 核心解析与度量逻辑
# ==============================================================================

def execute_xccov(xcresult_path):
    """
    调用系统 xcrun xccov 工具提取 xcresult 中的覆盖率报告。
    
    参数:
        xcresult_path (str): .xcresult 包的绝对路径
        
    返回:
        dict: 转换后的 JSON 字典。若执行失败则返回 None
    """
    cmd = ["xcrun", "xccov", "view", "--report", "--json", xcresult_path]
    try:
        # 执行命令并捕获标准输出
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"error: [Coverage Guard] 调用 xccov 失败: {e.stderr}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"error: [Coverage Guard] 解析覆盖率 JSON 报告发生异常: {str(e)}", file=sys.stderr)
        return None


def get_mock_data():
    """
    提供测试专用的模拟 xccov JSON 报告，以验证门禁熔断机制。
    
    返回:
        dict: 模拟的 xccov 报告数据结构
    """
    return {
        "targets": [
            {
                "name": "ZhiYu",
                "files": [
                    # Domain 示例：共 100 行，覆盖 85 行 -> 85%（达标）
                    {"path": "/Users/test/Sources/Domain/Models/Page.swift", "executableLines": MOCK_DOMAIN_LINES, "coveredLines": MOCK_DOMAIN_COVERED},
                    # Core 示例：共 100 行，覆盖 70 行 -> 70%（低于 75%，应拦截）
                    {"path": "/Users/test/Sources/Core/Base/ServiceContainer.swift", "executableLines": MOCK_CORE_LINES, "coveredLines": MOCK_CORE_COVERED},
                    # Infrastructure 示例：共 200 行，覆盖 160 行 -> 80%（达标）
                    {"path": "/Users/test/Sources/Infrastructure/Storage/SQLiteStore.swift", "executableLines": MOCK_INFRA_LINES, "coveredLines": MOCK_INFRA_COVERED},
                    # 表现层/其他：不设具体线，只计入整体 -> 76% (315/415)，低于 60% 则整体拦截
                    {"path": "/Users/test/Sources/Features/AI/ChatView.swift", "executableLines": MOCK_FEATURE_LINES, "coveredLines": 0}
                ]
            }
        ]
    }


def parse_coverage_report(report_data):
    """
    静态解析覆盖率报告字典，按 Domain、Core、Infrastructure 以及 Overall 汇总 executable 和 covered 行数。
    
    参数:
        report_data (dict): 包含覆盖率详情的 JSON 数据字典
        
    返回:
        dict: 包含各层级覆盖率结果的字典，格式如 {"Domain": {"covered": 85, "total": 100, "rate": 0.85}, ...}
    """
    metrics = {
        "Domain": {"covered": 0, "total": 0},
        "Core": {"covered": 0, "total": 0},
        "Infrastructure": {"covered": 0, "total": 0},
        "Overall": {"covered": 0, "total": 0}
    }
    
    targets = report_data.get("targets", [])
    for target in targets:
        # 仅统计主 App 目标（排除外部依赖包，仅审计 Sources 下源文件）
        if target.get("name") in ["GRDB", "Lottie", "ZIPFoundation", "SnapshotTesting"]:
            continue
            
        files = target.get("files", [])
        for file in files:
            path = file.get("path", "")
            
            # 过滤只审计项目中的 Sources 源文件目录，防止把单元测试文件本身或外部脚本也计入
            if "Sources/" not in path:
                continue
                
            total_lines = file.get("executableLines", 0)
            covered_lines = file.get("coveredLines", 0)
            
            # 累加至整体项目 (Overall)
            metrics["Overall"]["total"] += total_lines
            metrics["Overall"]["covered"] += covered_lines
            
            # 判断归属于哪个物理层级
            for layer_name, frag in LAYER_FRAGMENTS.items():
                if frag in path:
                    metrics[layer_name]["total"] += total_lines
                    metrics[layer_name]["covered"] += covered_lines
                    break # 一个文件只归属一个层级

    # 计算最终覆盖率比率 (Rate)
    for layer, data in metrics.items():
        total = data["total"]
        covered = data["covered"]
        rate = (covered / total) if total > 0 else 0.0
        metrics[layer]["rate"] = rate

    return metrics


# ==============================================================================
# MARK: - 主程序执行与阻断熔断
# ==============================================================================

def main():
    """
    主控制程序。解析命令行参数，对覆盖率结果执行断言红线比对。
    """
    parser = argparse.ArgumentParser(description="ZhiYu 单元测试覆盖率红线守卫门禁")
    parser.add_argument("xcresult_path", nargs="?", help="测试生成的 .xcresult 包文件路径")
    parser.add_argument("--test-mock", action="store_true", help="开启测试模拟模式，验证门禁拦截机制")
    args = parser.parse_args()

    print("🔍 [Coverage Guard] 开始执行代码测试覆盖率红线静态审计...")

    # 1. 提取报告数据
    if args.test_mock:
        print("ℹ️ [Coverage Guard] 启用模拟测试数据模式。")
        report = get_mock_data()
    else:
        if not args.xcresult_path:
            print("error: [Coverage Guard] 未提供 .xcresult 路径。请以: python3 check_coverage.py <path> 执行。", file=sys.stderr)
            sys.exit(1)
            
        if not os.path.exists(args.xcresult_path):
            print(f"error: [Coverage Guard] 找不到指定的测试结果包: {args.xcresult_path}", file=sys.stderr)
            sys.exit(1)
            
        report = execute_xccov(args.xcresult_path)
        if not report:
            sys.exit(1)

    # 2. 分析度量指标
    metrics = parse_coverage_report(report)
    
    total_violations = 0
    print("\n📊 [Coverage Guard] 覆盖率审计结果摘要:")
    print("--------------------------------------------------")
    
    for layer, threshold in COVERAGE_THRESHOLDS.items():
        data = metrics[layer]
        rate = data["rate"]
        percent = rate * PERCENT_MULTIPLIER
        threshold_percent = threshold * PERCENT_MULTIPLIER
        
        status_symbol = "🟢 [PASS]"
        is_violation = rate < threshold
        
        if is_violation:
            # 只有在有代码的情况下，低于红线才判定为违规；若该层代码行数为 0，则忽略
            if data["total"] > 0:
                status_symbol = "🔴 [FAIL]"
                total_violations += 1
            else:
                status_symbol = "⚪ [N/A] (无代码)"
        
        print(f"  {status_symbol} {layer:<15} : {percent:>6.2f}% (红线: {threshold_percent:>5.2f}%, 覆盖行数: {data['covered']}/{data['total']})")

    print("--------------------------------------------------")

    # 3. 熔断判断
    if total_violations > 0:
        print(f"🔴 [Coverage Guard] 失败: 发现 {total_violations} 处架构层级覆盖率低于安全红线。构建已熔断！", file=sys.stderr)
        sys.exit(1)
    else:
        print("🟢 [Coverage Guard] 成功: 架构所有分层代码覆盖率 100% 越过安全红线！")
        sys.exit(0)


if __name__ == "__main__":
    main()
