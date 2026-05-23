# -*- coding: utf-8 -*-
# parse_coverage.py
#
# 作者: Wang Chong
# 功能说明: [Tools/Temp] 解析 xccov 导出的 JSON 覆盖率报告，精确查找指定文件的未覆盖行和函数。
# 版本: 1.0
# 修改记录:
#   - 创建: 2026-05-23
# 日期: 2026-05-23
# 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import sys
import json
import subprocess

def main():
    print("正在获取最新的 xcresult 路径...")
    try:
        # 获取最新的 xcresult 路径
        result = subprocess.run(
            'ls -td build/derived_data/Logs/Test/*.xcresult | head -n 1',
            shell=True, capture_output=True, text=True, check=True
        )
        xcresult_path = result.stdout.strip()
        print(f"最新测试结果包: {xcresult_path}")
        
        # 运行 xccov 获取完整报告
        print("正在导出完整的 xccov JSON 覆盖率数据...")
        xccov_res = subprocess.run(
            ['xcrun', 'xccov', 'view', '--report', '--json', xcresult_path],
            capture_output=True, text=True, check=True
        )
        data = json.loads(xccov_res.stdout)
    except Exception as e:
        print(f"执行 xccov 失败: {e}", file=sys.stderr)
        sys.exit(1)

    targets = ["watchOS", "Watch"]
    
    # 递归查找文件
    def find_files(node):
        found = []
        if isinstance(node, dict):
            if "name" in node and any(t.lower() in node["name"].lower() for t in targets):
                found.append(node)
            elif "path" in node and any(t.lower() in node["path"].lower() for t in targets):
                found.append(node)
            for k, v in node.items():
                found.extend(find_files(v))
        elif isinstance(node, list):
            for item in node:
                found.extend(find_files(item))
        return found

    found_files = find_files(data)
    if not found_files:
        print("未在报告中找到 watchOS 相关文件！")
        return

    # 去重
    unique_files = {}
    for f in found_files:
        path = f.get("path", "")
        if path and path not in unique_files:
            unique_files[path] = f

    print("="*60)
    print("watchOS 平台相关文件覆盖率汇总:")
    for path, file_node in unique_files.items():
        name = file_node.get("name", "")
        line_cov = file_node.get("lineCoverage", 0.0) * 100
        exec_lines = file_node.get("executableLines", 0)
        cov_lines = file_node.get("coveredLines", 0)
        print(f"- {name}: {line_cov:.2f}% ({cov_lines}/{exec_lines}) | 路径: {path}")


if __name__ == "__main__":
    main()
