import re
import os

filepath = "Sources/Infrastructure/Storage/Persistence/DatabaseManager.swift"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

def write_extension(name, start, end):
    out_path = f"Sources/Infrastructure/Storage/Persistence/DatabaseManager+{name}.swift"
    content = f"""//
//  DatabaseManager+{name}.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//

import Foundation
import GRDB
import CryptoKit

extension DatabaseManager {{
""" + "".join(lines[start:end]) + "}\n"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(content)

# Start and end lines for each section
# Note: Python uses 0-based indexing. Line 169 is index 168.
write_extension("Security", 168, 297)
write_extension("Configuration", 297, 327)
write_extension("VaultMigration", 327, 519)
write_extension("GlobalMigration", 519, 602)

# Rebuild DatabaseManager.swift
main_lines = lines[:168] + lines[602:]

with open(filepath, "w", encoding="utf-8") as f:
    f.writelines(main_lines)

print("Split completed.")
