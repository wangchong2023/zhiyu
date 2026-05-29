import os

filepath = "Sources/Shared/DesignSystem/DesignSystem.swift"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

out_dir = "Sources/Shared/DesignSystem/Tokens"

current_enum = None
brace_count = 0
enum_lines = []

main_file_lines = []

in_main_enum = False
main_brace_count = 0

i = 0
while i < len(lines):
    line = lines[i]
    
    if not in_main_enum:
        main_file_lines.append(line)
        if "public enum DesignSystem {" in line:
            in_main_enum = True
            main_brace_count = 1
        i += 1
        continue
    
    if current_enum is None:
        if "public enum " in line:
            parts = line.strip().split()
            idx = parts.index("enum")
            enum_name = parts[idx+1].split("{")[0].split(":")[0].strip()
            
            # Extract previous comments
            j = len(main_file_lines) - 1
            comments = []
            while j >= 0 and (main_file_lines[j].strip().startswith("//") or main_file_lines[j].strip() == ""):
                comments.insert(0, main_file_lines.pop(j))
                j -= 1
                
            current_enum = enum_name
            enum_lines = comments + [line]
            brace_count = line.count("{") - line.count("}")
        else:
            main_file_lines.append(line)
            main_brace_count += line.count("{") - line.count("}")
            if main_brace_count == 0:
                in_main_enum = False
    else:
        enum_lines.append(line)
        brace_count += line.count("{") - line.count("}")
        if brace_count == 0:
            # write enum to file
            filename = f"DesignSystem+{current_enum}.swift"
            out_path = os.path.join(out_dir, filename)
            
            content = f"""//
//  DesignSystem+{current_enum}.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//

import SwiftUI
import CoreGraphics

extension DesignSystem {{
""" + "".join(enum_lines) + "}\n"
            
            with open(out_path, "w", encoding="utf-8") as out_f:
                out_f.write(content)
                
            current_enum = None
            enum_lines = []
            
    i += 1

with open(filepath, "w", encoding="utf-8") as f:
    f.writelines(main_file_lines)

print("Split DesignSystem completed!")
