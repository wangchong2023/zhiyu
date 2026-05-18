#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
本脚本用于移除 Common.xcstrings 中与其他垂直功能表完全重复的“影子键值”。
作为本地化瘦身计划任务 1 的一部分。
"""

import os
import json

def remove_shadow_keys():
    catalog_dir = "Sources/Localization/Catalogs"
    files = [f for f in os.listdir(catalog_dir) if f.endswith(".xcstrings")]

    # 加载所有键值数据
    # key_data 结构: {(table, key): (en_val, zh_val)}
    key_data = {}
    for filename in files:
        table = filename[:-10]
        path = os.path.join(catalog_dir, filename)
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            for key, info in data.get("strings", {}).items():
                localizations = info.get("localizations", {})
                en_val = localizations.get("en", {}).get("stringUnit", {}).get("value", "")
                zh_val = localizations.get("zh-Hans", {}).get("stringUnit", {}).get("value", "")
                key_data[(table, key)] = (en_val, zh_val)

    # 识别 Common 中的键
    common_keys = {k for t, k in key_data.keys() if t == "Common"}
    to_remove = set()

    for k in common_keys:
        # 查找该键在哪些表中出现
        tables = [t for t, key in key_data.keys() if key == k]
        if len(tables) > 1:
            common_val = key_data[("Common", k)]
            other_tables = [t for t in tables if t != "Common"]
            for t in other_tables:
                # 如果在其他垂直表中发现了完全一致的翻译，则标记为待移除
                if key_data[(t, k)] == common_val:
                    to_remove.add(k)
                    break

    # 执行移除操作
    common_path = os.path.join(catalog_dir, "Common.xcstrings")
    with open(common_path, "r", encoding="utf-8") as f:
        common_data = json.load(f)

    removed_count = 0
    for k in to_remove:
        if k in common_data.get("strings", {}):
            del common_data["strings"][k]
            removed_count += 1

    # 写回文件
    with open(common_path, "w", encoding="utf-8") as f:
        json.dump(common_data, f, indent=2, ensure_ascii=False)

    print(f"从 Common.xcstrings 中移除了 {removed_count} 个影子键值。")

if __name__ == "__main__":
    remove_shadow_keys()
