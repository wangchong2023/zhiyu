import re
import os

filepath = "Sources/Infrastructure/Storage/Persistence/DatabaseManager.swift"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

def write_extension(name, lines_subset):
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
""" + "".join(lines_subset) + "}\n"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(content)

# Define sections
sections = {
    "HMAC": (168, 297), # -1 for 0-index
    "Config": (297, 327),
    "VaultMigration": (327, 519),
    "GlobalMigration": (519, 603)
}

main_lines = []

i = 0
while i < len(lines):
    line = lines[i]
    if i >= 168 and i < 297:
        pass
    elif i >= 297 and i < 327:
        pass
    elif i >= 327 and i < 519:
        pass
    elif i >= 519 and i < 603:
        pass
    else:
        main_lines.append(line)
    i += 1

write_extension("Security", lines[168:297])
write_extension("Configuration", lines[297:327])
write_extension("VaultMigration", lines[327:519])
write_extension("GlobalMigration", lines[519:603])

with open(filepath, "w", encoding="utf-8") as f:
    f.writelines(main_lines)

print("Split DatabaseManager completed!")
