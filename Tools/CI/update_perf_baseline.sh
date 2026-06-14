#!/bin/bash
set -euo pipefail
BASELINE_DIR="$(cd "$(dirname "$0")/../../build/.perf_baselines" && pwd)"
mkdir -p "$BASELINE_DIR"
echo "📊 性能基线目录已准备: $BASELINE_DIR"
echo "请运行一次全量性能测试后手动调用此脚本更新基线"
