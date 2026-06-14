#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: run_ui_tests.sh
# 脚本功能: UI 测试（并行多 Worker，独立阶段），失败时自动汇总错误。
# 用法: ./Tools/CI/run_ui_tests.sh
# ==============================================================================
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DEST="platform=iOS Simulator,name=iPhone 17 Pro"
DERIVED="build/DerivedData"
LOG_FILE="build/ui_test_output.log"

# ── 从 @flaky 注释自动收集不稳定测试 ─────────────────────────────
echo "🔍 收集 @flaky 标记的不稳定测试..."
FLAKY_ARGS=()
HAS_FLAKY=false
while IFS= read -r skip_arg; do
    if [ -n "$skip_arg" ]; then
        FLAKY_ARGS+=("$skip_arg")
        HAS_FLAKY=true
    fi
done < <(bash Tools/CI/collect_flaky_tests.sh)

# ── 构造 xcodebuild 参数 ──────────────────────────────────
XCODEBUILD_ARGS=(
    test-without-building
    -project "${PROJECT}"
    -scheme "${SCHEME}"
    -destination "${DEST}"
    -only-testing:ZhiYuUITests
    -enableCodeCoverage YES
    -derivedDataPath "${DERIVED}"
    -parallel-testing-enabled YES
    -parallel-testing-worker-count 4
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGNING_REQUIRED=NO
)

if $HAS_FLAKY; then
    for skip_arg in "${FLAKY_ARGS[@]}"; do
        XCODEBUILD_ARGS+=("$skip_arg")
    done
fi

set +e
set -o pipefail
xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee "$LOG_FILE"

UI_EXIT=${PIPESTATUS[0]}
set -e

if [ ${UI_EXIT} -ne 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ UI 测试失败 (exit=${UI_EXIT})"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  失败测试:"
  grep -E "failed" "$LOG_FILE" | grep -i "test" | tail -20 || echo "  (none)"
  echo ""
  echo "  编译/运行时错误:"
  grep -E "error:|fatal error" "$LOG_FILE" | grep -v "check_hardcoded" | tail -20 || echo "  (none)"
  echo ""
  echo "  日志尾部:"
  tail -15 "$LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  完整日志: ${LOG_FILE}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit ${UI_EXIT}
fi
