#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# 文件名: analyze_global_coverage.py
# 物理路径: Tools/Temp/analyze_global_coverage.py
#
# 作者: Antigravity (Senior Software Architect)
# 功能说明: 智宇 (ZhiYu) 全工程代码覆盖率深度分析与统计工具。
#          提取最新的 xcresult 测试结果集，调用 xccov 工具，抽取全工程 Sources/ 目录下
#          所有 Swift 源代码的可执行行和覆盖行数据。按照 L3 至 L0 的垂直化物理分层架构
#          进行精细化统计和可视化输出，帮助识别测试盲区，评估 95% 覆盖率目标的达成度。
#
# 版本: 1.0
# 日期: 2026-05-28
# 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import os
import sys
import glob
import json
import subprocess

def log_info(msg):
    """
    输出提示级别的日志信息。
    """
    print(f"\033[36m[INFO] {msg}\033[0m")

def log_success(msg):
    """
    输出成功级别的日志信息。
    """
    print(f"\033[32m[SUCCESS] ✓ {msg}\033[0m")

def log_warn(msg):
    """
    输出警告级别的日志信息。
    """
    print(f"\033[33m[WARNING] ⚠ {msg}\033[0m")

def log_error(msg):
    """
    输出错误级别的日志信息。
    """
    print(f"\033[31m[ERROR] ✗ {msg}\033[0m")

def find_latest_xcresults():
    """
    寻找所有的 .xcresult 测试结果集，按修改时间降序排序。
    优先搜索 Xcode 默认 DerivedData 路径，其次搜索本地 build 目录。
    """
    search_paths = [
        "/Users/constantine/Library/Developer/Xcode/DerivedData/ZhiYu-*/Logs/Test/*.xcresult",
        "build/DerivedData/**/*.xcresult",
        "build/derived_data/**/*.xcresult"
    ]
    
    results = []
    for path in search_paths:
        results.extend(glob.glob(path, recursive=True))
        
    if not results:
        return []
        
    # 按照修改时间降序排序，最新的排在最前
    results.sort(key=os.path.getmtime, reverse=True)
    return results

def recursive_find_files(node):
    """
    递归解析 xccov 的高维 JSON 树结构，寻找所有包含 path 和覆盖率指标的源文件节点。
    
    参数:
        node (dict|list): 当前解析的 JSON 节点
    
    返回:
        list: 所有源文件的覆盖率字典列表
    """
    files = []
    if isinstance(node, dict):
        if "path" in node and ("coveredLines" in node or "executableLines" in node):
            files.append(node)
        for key, value in node.items():
            files.extend(recursive_find_files(value))
    elif isinstance(node, list):
        for item in node:
            files.extend(recursive_find_files(item))
    return files

def classify_architecture_layer(path):
    """
    根据文件物理路径，将其归类到智宇的垂直化功能架构分层中。
    
    参数:
        path (str): 源文件的绝对或相对路径
        
    返回:
        str: 架构层级名称
    """
    normalized_path = path.replace("\\", "/")
    
    # 过滤出 Sources 目录下的 Swift 文件
    if "Sources/" not in normalized_path:
        return "Non-App-Sources"
        
    if "Sources/App" in normalized_path:
        return "L3 应用层 (App)"
    elif "Sources/Features" in normalized_path:
        return "L2 业务功能层 (Features)"
    elif "Sources/Domain" in normalized_path:
        return "L1.5 领域层 (Domain)"
    elif "Sources/Infrastructure" in normalized_path:
        return "L1 基础设施层 (Infra)"
    elif "Sources/Core/System" in normalized_path:
        return "L0.5 系统集成层 (System)"
    elif "Sources/Core/Base" in normalized_path:
        return "L0 底层基座层 (Base)"
    elif "Sources/Shared" in normalized_path:
        return "Shared 共享标准层 (Shared)"
    elif "Sources/Platforms" in normalized_path:
        return "Platforms 平台桥接层 (Platforms)"
    elif "Sources/Localization" in normalized_path:
        return "Localization 国际化层 (L10n)"
    else:
        return "Other-Sources (未归类)"

def main():
    log_info("启动智宇全工程代码覆盖率深度分析...")
    
    # 1. 寻找所有的测试结果包
    results = find_latest_xcresults()
    if not results:
        log_error("未检测到任何有效的 .xcresult 测试结果包，请确认是否已执行 xcodebuild test。")
        sys.exit(1)
        
    raw_json = None
    latest_result = None
    
    # 2. 依次尝试调用 xccov 提取 JSON 报告，直到有一个能够成功打开且包含完整数据
    for result_path in results:
        log_info(f"尝试加载测试结果包: {result_path}")
        try:
            cmd = ["xcrun", "xccov", "view", "--report", "--json", result_path]
            process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
            raw_json = process.stdout
            latest_result = result_path
            log_success(f"成功载入并提取覆盖率数据: {os.path.basename(result_path)}")
            break
        except subprocess.CalledProcessError as e:
            log_warn(f"测试结果包 {os.path.basename(result_path)} 无法读取或尚不完整。错误: {e.stderr.strip()[:100]}... 将尝试下一个结果包")
            continue
            
    if not raw_json:
        log_error("在所有检测到的 .xcresult 结果包中，均无法成功调用 xccov。请等待当前测试任务执行完毕。")
        sys.exit(1)
        
    # 3. 解析 JSON
    try:
        data = json.loads(raw_json)
    except json.JSONDecodeError as e:
        log_error("解析 JSON 报文失败，数据可能损坏。")
        sys.exit(1)
        
    # 4. 递归获取所有源文件
    all_raw_files = recursive_find_files(data)
    log_info(f"xccov 扫描完毕。全栈捕获到 {len(all_raw_files)} 个源文件覆盖率节点。")
    
    # 5. 过滤出工程内 Sources/ 下的 .swift 源代码，并进行去重（针对跨 target 引用带来的重复节点）
    unique_sources = {}
    for f in all_raw_files:
        path = f.get("path", "")
        # 只保留应用的核心业务代码，排除外部 checkout 包、Tests 目录等
        if "Sources/" in path and path.endswith(".swift"):
            # 如果同一个文件在多个 target 中被统计（比如 ZhiYu 和 ZhiYuTests），保留可执行行数和覆盖行数最大的一组
            exec_lines = f.get("executableLines", 0)
            if path not in unique_sources or exec_lines > unique_sources[path].get("executableLines", 0):
                unique_sources[path] = f
                
    log_success(f"精细过滤去重完成。捕获属于本地工程 Sources/ 的 Swift 源文件共: {len(unique_sources)} 个。")
    
    # 6. 按架构分层进行累加统计
    architecture_stats = {
        "L3 应用层 (App)": {"covered": 0, "executable": 0, "files": []},
        "L2 业务功能层 (Features)": {"covered": 0, "executable": 0, "files": []},
        "L1.5 领域层 (Domain)": {"covered": 0, "executable": 0, "files": []},
        "L1 基础设施层 (Infra)": {"covered": 0, "executable": 0, "files": []},
        "L0.5 系统集成层 (System)": {"covered": 0, "executable": 0, "files": []},
        "L0 底层基座层 (Base)": {"covered": 0, "executable": 0, "files": []},
        "Shared 共享标准层 (Shared)": {"covered": 0, "executable": 0, "files": []},
        "Platforms 平台桥接层 (Platforms)": {"covered": 0, "executable": 0, "files": []},
        "Localization 国际化层 (L10n)": {"covered": 0, "executable": 0, "files": []},
        "Other-Sources (未归类)": {"covered": 0, "executable": 0, "files": []}
    }
    
    global_covered = 0
    global_executable = 0
    
    for path, f in unique_sources.items():
        layer = classify_architecture_layer(path)
        covered = f.get("coveredLines", 0)
        executable = f.get("executableLines", 0)
        
        # 排除完全不可执行的空声明文件
        if executable == 0:
            continue
            
        architecture_stats[layer]["covered"] += covered
        architecture_stats[layer]["executable"] += executable
        architecture_stats[layer]["files"].append((os.path.basename(path), covered, executable))
        
        global_covered += covered
        global_executable += executable

    # 7. 可视化渲染分析大盘
    print("\n" + "="*80)
    print("                      智宇 (ZhiYu) 全工程代码覆盖率深度分析大盘")
    print("="*80)
    print(f" 数据来源包: {os.path.basename(latest_result)}")
    print(f" 核心源文件: {len(unique_sources)} 个 Swift 源文件")
    print(f" 全局总指标: 覆盖行数 {global_covered} / 可执行总行数 {global_executable}")
    
    global_pct = (global_covered / global_executable * 100) if global_executable > 0 else 0.0
    print(f" 全局总覆盖率: {global_pct:.2f}%")
    print("-"*80)
    
    # 逐层打印
    for layer, stats in architecture_stats.items():
        exec_lines = stats["executable"]
        if exec_lines == 0:
            continue
        cov_lines = stats["covered"]
        pct = (cov_lines / exec_lines) * 100
        file_count = len(stats["files"])
        
        # 决定前缀指示符
        if pct >= 95.0:
            indicator = "🟢 [卓越]"
        elif pct >= 85.0:
            indicator = "🔵 [优秀]"
        elif pct >= 70.0:
            indicator = "🟡 [良]"
        else:
            indicator = "🔴 [欠覆盖]"
            
        print(f" {indicator} {layer:<28} | 文件数: {file_count:<3} | 覆盖率: {pct:6.2f}% ({cov_lines:<4}/{exec_lines:<4})")
        
    print("="*80)
    
    # 8. 找出未覆盖率最低、最需要补充用例的前 10 个核心关键文件
    low_coverage_files = []
    for layer, stats in architecture_stats.items():
        # 排除 L3 (App) 和 Shared UI 层，主攻高密度业务逻辑层 (Domain, Infra, Core)
        if layer in ["L3 应用层 (App)", "Shared 共享标准层 (Shared)", "Localization 国际化层 (L10n)", "Other-Sources (未归类)"]:
            continue
        for name, covered, executable in stats["files"]:
            if executable > 10: # 忽略只有几行的小代码块文件
                pct = (covered / executable) * 100
                low_coverage_files.append((name, pct, covered, executable, layer))
                
    low_coverage_files.sort(key=lambda x: x[1]) # 按覆盖率升序排序
    
    print("\n------------------------- 核心逻辑层重点攻坚文件 Top 10 -------------------------")
    for i, (name, pct, cov, exec_l, layer) in enumerate(low_coverage_files[:10], 1):
        print(f" #{i:<2} {name:<35} | {layer:<20} | 覆盖率: {pct:6.2f}% ({cov}/{exec_l})")
    print("--------------------------------------------------------------------------------\n")

    # 9. 最终判定与输出
    target_threshold = 95.0
    if global_pct >= target_threshold:
        log_success(f"分析结论: 全工程代码覆盖率已达到 {global_pct:.2f}%，物理上【已超过】95% 卓越标准！")
    else:
        log_warn(f"分析结论: 全工程代码覆盖率当前为 {global_pct:.2f}%，物理上【未超过】95% 卓越红线。")
        
if __name__ == "__main__":
    main()
