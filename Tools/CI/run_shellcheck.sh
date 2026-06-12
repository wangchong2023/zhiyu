#!/bin/bash
# 运行 ShellCheck 检查 Tools 目录下的所有 shell 脚本
# 从 .woodpecker.yml 的 static-analysis 步骤中抽取，
# 避免 Woodpecker 3.x YAML 解析器将分号误解析为键值分隔符

set -euo pipefail

if which shellcheck >/dev/null; then
    echo "===> Running ShellCheck for Tools..."
    shellcheck -x -S warning Tools/CI/*.sh
else
    echo "warning: shellcheck not installed, skipping"
fi
