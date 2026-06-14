#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: build_platform.sh
# 脚本功能: 单平台编译验证，失败时自动汇总编译错误。
# 用法: ./Tools/CI/build_platform.sh <scheme> <destination> <label> [spm_cache_dir]
# 示例: ./Tools/CI/build_platform.sh ZhiYu 'generic/platform=iOS Simulator' iOS
# ==============================================================================
set -euo pipefail

SCHEME="${1:?缺少 scheme 参数}"
DEST="${2:?缺少 destination 参数}"
LABEL="${3:?缺少 label 参数}"
SPM_CACHE="${4:-${HOME}/.cache/zhiyu-spm}"
PROJECT="ZhiYu.xcodeproj"
LOG_FILE="build/${LABEL}_build.log"

mkdir -p build "$SPM_CACHE"

echo "===> Build ${LABEL}"
echo "     日志: ${LOG_FILE}"

set +e
set -o pipefail
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DEST" \
    -derivedDataPath "build/DerivedData-${LABEL}" \
    -clonedSourcePackagesDirPath "$SPM_CACHE" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ ${LABEL} Build Failed (exit=${EXIT_CODE})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  编译错误:"
    grep -E "^.*:[0-9]+:[0-9]+: error:" "$LOG_FILE" | sort -t: -k1,1 -k2,2n -u | head -20 || echo "  (未找到标准编译错误)"
    echo ""
    echo "  致命错误:"
    grep -i "fatal error" "$LOG_FILE" | head -10 || echo "  (none)"
    echo ""
    echo "  日志尾部:"
    tail -15 "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  完整日志: ${LOG_FILE}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit $EXIT_CODE
fi

echo "  ✅ ${LABEL} Build Passed"
