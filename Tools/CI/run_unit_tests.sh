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
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
DERIVED_DATA_PATH="build/DerivedData-ios"
SPM_CACHE_DIR="${HOME}/.cache/zhiyu-spm"

# ── 2. 测试排除列表 (跳过不稳定、UI交互及超大规模压力测试) ──────────────────
SKIP_TESTS=(
    "ZhiYuUITests/ZhiYuUITests/testChatAISkeletonLoadingState"
    "ZhiYuUITests/IngestTests/testManualEntrySectionExists"
    "ZhiYuUITests/IngestTests/testURLImportButton"
    "ZhiYuTests/ComponentSnapshots/testAdaptiveSidebarView"
    "ZhiYuUITests/ZhiYuMonkeyTests/testWildMonkeyClickTraversal"
    "ZhiYuTests/AuthServiceTests/testLogoutClearsGuestFlag"
    "ZhiYuTests/AuthServiceTests/testLogoutClearsState"
    "ZhiYuTests/KnowledgeStorePerformanceTests/testOneHundredThousandNodesFTSRetrievalLatency"
)

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

# 动态组装跳过的测试参数
for test_item in "${SKIP_TESTS[@]}"; do
    XCODEBUILD_ARGS+=("-skip-testing:${test_item}")
done

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
    echo "❌ 单元测试执行失败 (错误码: ${TEST_EXIT_CODE})"
    exit ${TEST_EXIT_CODE}
fi
