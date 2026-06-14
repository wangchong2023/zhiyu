#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: prepare_build_environment.sh
# 脚本功能: 生成 Xcode 工程结构文件，拉取并编译 SPM 包以预热测试与编译环境。
#           构建失败时自动提取并汇总错误信息。
# ==============================================================================
set -euo pipefail

# 1. 常量定义
PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DESTINATION="generic/platform=iOS Simulator"
SPM_CACHE_DIR="${HOME}/.cache/zhiyu-spm"
LOG_FILE="build/test_compile.log"
ERROR_SUMMARY="build/test_compile_errors.txt"

# 2. 生成 Xcode 项目文件
echo "===> xcodegen generate"
xcodegen generate

# 3. 预热测试依赖环境
echo "===> Build-for-testing (SPM + compile)"
mkdir -p build "$SPM_CACHE_DIR"

set +e
set -o pipefail
xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -clonedSourcePackagesDirPath "$SPM_CACHE_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee "$LOG_FILE"
BUILD_EXIT_CODE=${PIPESTATUS[0]}
set -e

# 4. 错误汇总（构建失败时）
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ❌ BUILD FAILED                          ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Error Summary (full log: ${LOG_FILE})"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # 提取 Swift/Clang 编译错误（按文件分组，去重计数）
    {
        echo "=== Compile Errors ==="
        grep -E "^.*:[0-9]+:[0-9]+: error:" "$LOG_FILE" | sort -t: -k1,1 -k2,2n -u || echo "  (none)"
        echo ""
        echo "=== Swift Compile Errors (abbreviated) ==="
        grep -E "error:" "$LOG_FILE" | grep -v "check_hardcoded\|L10n Audit\|Hardcoded " | head -50 || echo "  (none)"
        echo ""
        echo "=== Fatal Errors ==="
        grep -i "fatal error" "$LOG_FILE" || echo "  (none)"
        echo ""
        echo "=== Build Failure Context (last 20 lines before failure) ==="
        grep -n "BUILD FAILED\|error:\|fatal error\|failed\|Failed" "$LOG_FILE" | tail -20
        echo ""
        echo "=== Raw tail (last 15 lines) ==="
        tail -15 "$LOG_FILE"
    } | tee "$ERROR_SUMMARY"

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "❌ prepare 失败：编译错误汇总已保存至 $ERROR_SUMMARY"
    echo "   完整日志: $LOG_FILE ($(wc -l < "$LOG_FILE" | tr -d ' ') lines)"
    echo "═══════════════════════════════════════════════════════════════"
    exit $BUILD_EXIT_CODE
fi

echo "✅ 编译预热与环境依赖加载就绪"
