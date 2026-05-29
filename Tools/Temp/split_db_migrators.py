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

extension DatabaseManager {{
""" + "".join(lines_subset) + "}\n"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(content)

# line numbers are 1-based, python array is 0-based
vault_start = 327
vault_end = 519
global_start = 519
global_end = 603

write_extension("VaultMigration", lines[vault_start:vault_end])
write_extension("GlobalMigration", lines[global_start:global_end])

main_lines = lines[:vault_start] + lines[global_end:]

with open(filepath, "w", encoding="utf-8") as f:
    f.writelines(main_lines)

print("Migration split completed.")
