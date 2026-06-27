#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: run_tests_and_coverage.sh
# 脚本功能: 集合执行测试计数、单元测试执行、代码覆盖率阈值审计、性能回归比对。
# ==============================================================================
set -euo pipefail

# ── 打印构建版本信息 ──
PLIST="Sources/Info.plist"
if [ -f "$PLIST" ]; then
    ver=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo "N/A")
    build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "N/A")
    hash=$(/usr/libexec/PlistBuddy -c "Print :GIT_SHORT_HASH" "$PLIST" 2>/dev/null || echo "N/A")
    ts=$(/usr/libexec/PlistBuddy -c "Print :BUILD_TIMESTAMP" "$PLIST" 2>/dev/null || echo "N/A")
    echo "📦 版本: ${ver} (build ${build}) | commit: ${hash} | 构建时间: ${ts}"
fi

# 1. 统计测试用例总数
echo "===> Count Test Cases"
TEST_COUNT=0
if [ -d "Tests" ]; then
    TEST_COUNT=$(grep -r "^    func test" Tests/ --include="*.swift" | wc -l | tr -d ' ')
fi
echo "  Total Tests Counted: $TEST_COUNT"
mkdir -p build
echo "$TEST_COUNT" > build/.test_count

# 2. 执行单元测试 (CI 模式下执行)
echo "===> Run Unit Tests"
bash Tools/CI/Test/run_unit_tests.sh --ci

# 3. 代码覆盖率门禁熔断校验
echo "===> Code Coverage Check"
python3 Tools/CI/Test/check_coverage.py

# 4. 性能回归阻断校验
echo "===> Performance Regression Check"
python3 Tools/CI/Perf/check_perf_regression.py

echo "✅ 跑测、覆盖率门禁及性能回归校验全部通过！"

# ── 打印构建版本信息 ──
if [ -f "$PLIST" ]; then
    ver=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo "N/A")
    build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "N/A")
    hash=$(/usr/libexec/PlistBuddy -c "Print :GIT_SHORT_HASH" "$PLIST" 2>/dev/null || echo "N/A")
    ts=$(/usr/libexec/PlistBuddy -c "Print :BUILD_TIMESTAMP" "$PLIST" 2>/dev/null || echo "N/A")
    echo "📦 版本: ${ver} (build ${build}) | commit: ${hash} | 构建时间: ${ts}"
fi
