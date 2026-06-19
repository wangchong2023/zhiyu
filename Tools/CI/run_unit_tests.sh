#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: run_unit_tests.sh
# 脚本功能: 构建、执行单元测试并收集覆盖率。支持本地及 CI 两种模式，可自动过滤指定不稳定/耗时测试。
# 调用方式:
#   本地运行: ./Tools/CI/run_unit_tests.sh
#   CI 运行:  ./Tools/CI/run_unit_tests.sh --ci
# ==============================================================================

set -euo pipefail

# ── 1. 常量与环境配置 ──────────────────────────────────────────
PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DERIVED_DATA_PATH="build/DerivedData-ios"
SPM_CACHE_DIR="${HOME}/.cache/zhiyu-spm"

# 动态查找可用模拟器：优先 iPhone 17 Pro，回退到任意可用 iPhone 模拟器
# 确保在 GitHub Actions macos-15 runner 上也能找到有效目标
find_simulator() {
    # 优先精确匹配 iPhone 17 Pro
    local sim
    sim=$(xcrun simctl list devices available -j 2>/dev/null \
        | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if 'iPhone 17 Pro' in d.get('name','') and d.get('isAvailable', False):
            print(d['name']); exit()
" 2>/dev/null)
    if [ -n "${sim}" ]; then
        echo "${sim}"
        return
    fi
    # 回退：查找任意可用的最新 iPhone 模拟器
    sim=$(xcrun simctl list devices available -j 2>/dev/null \
        | python3 -c "
import json, sys
data = json.load(sys.stdin)
candidates = []
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime and 'iPhone' not in runtime:
        continue
    for d in devices:
        name = d.get('name', '')
        if 'iPhone' in name and d.get('isAvailable', False):
            candidates.append((runtime, name))
candidates.sort(reverse=True)
if candidates:
    print(candidates[0][1])
" 2>/dev/null)
    echo "${sim:-iPhone 16}"
}

SIM_NAME=$(find_simulator)
DESTINATION="platform=iOS Simulator,name=${SIM_NAME}"
echo "📱 使用模拟器: ${SIM_NAME}"

# ── 2. 从 @flaky 注释自动收集不稳定测试 ─────────────────────────────
echo "🔍 收集 @flaky 标记的不稳定测试..."
FLAKY_ARGS=()
HAS_FLAKY=false
while IFS= read -r skip_arg; do
    if [ -n "$skip_arg" ]; then
        FLAKY_ARGS+=("$skip_arg")
        HAS_FLAKY=true
    fi
done < <(bash Tools/CI/collect_flaky_tests.sh)

# ── 3. 模式解析 ──────────────────────────────────────────────
CI_MODE="false"
if [ "${1:-}" = "--ci" ] || [ "${CI:-}" = "true" ]; then
    CI_MODE="true"
fi

# ── 4. 构造 xcodebuild 参数 ──────────────────────────────────
XCODEBUILD_ARGS=(
    test
    -project "${PROJECT}"
    -scheme "${SCHEME}"
    -destination "${DESTINATION}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -enableCodeCoverage YES
    -parallel-testing-enabled YES
    -parallel-testing-worker-count 4
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGNING_REQUIRED=NO
)

# 追加不稳定测试跳过参数（用 flag 守护，避免 bash 3.2 空数组触发 set -u）
if $HAS_FLAKY; then
    for skip_arg in "${FLAKY_ARGS[@]}"; do
        XCODEBUILD_ARGS+=("$skip_arg")
    done
fi

# 如果是 CI 模式，指定共享的 SPM 缓存目录以提速构建
if [ "${CI_MODE}" = "true" ]; then
    XCODEBUILD_ARGS+=("-clonedSourcePackagesDirPath" "${SPM_CACHE_DIR}")
fi

# 确保 build 目录存在
mkdir -p build

# ── 5. 执行测试逻辑 ──────────────────────────────────────────
echo "===> 开始运行单元测试..."
echo "模式: $([ "${CI_MODE}" = "true" ] && echo "CI 自动化模式" || echo "本地开发模式")"

set +e
if [ "${CI_MODE}" = "true" ]; then
    # CI 模式下，使用管道流进行进度统计并用 xcbeautify 生成 JUnit 报告
    set -o pipefail
    xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 \
        | tee build/test_raw.log \
        | Tools/CI/ci-test-progress.sh \
        | xcbeautify --report junit --report-path build/test_report.junit
    TEST_EXIT_CODE=${PIPESTATUS[0]}
else
    # 本地模式直接在前台输出，方便查看详细堆栈
    xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee build/test_raw.log
    TEST_EXIT_CODE=${PIPESTATUS[0]}
fi
set -e

# ── 6. 结果判定 ──────────────────────────────────────────────
if [ ${TEST_EXIT_CODE} -eq 0 ]; then
    echo "✓ 所有单元测试通过！"
    exit 0
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 单元测试执行失败 (错误码: ${TEST_EXIT_CODE})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  编译错误:"
    grep -E "^.*:[0-9]+:[0-9]+: error:" build/test_raw.log | sort -t: -k1,1 -k2,2n -u || echo "  (none)"
    echo ""
    echo "  致命错误:"
    grep -i "fatal error" build/test_raw.log || echo "  (none)"
    echo ""
    echo "  失败测试:"
    grep -E "Test case.*failed|Test Suite.*failed" build/test_raw.log | tail -20 || echo "  (none)"
    echo ""
    echo "  日志尾部:"
    tail -15 build/test_raw.log
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  完整日志: build/test_raw.log"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit ${TEST_EXIT_CODE}
fi
