#!/bin/bash
# ==============================================================================
# 脚本名称: pre_push_check.sh
# 核心职责: Git 推送前统一门禁——串联所有必要检查，任一失败则阻断推送。
# 调用方式:
#   ./Tools/pre_push_check.sh          # 默认：静态检查 + 编译校验
#   ./Tools/pre_push_check.sh --full   # 完整：静态 + 编译 + 单元测试 + 覆盖率
#   ./Tools/pre_push_check.sh --quick  # 快速：仅静态检查（不编译）
#   ./Tools/pre_push_check.sh --help   # 查看帮助
#
# 设计原则:
#   - 与 CI 流水线 Stage 1-2 检查项严格对齐，本地提前拦截
#   - 分层熔断：静态 → 编译 → 测试，逐层通过才进入下一层
#   - 所有 Gatekeeper 检查与 Xcode Build Phases 保持一致
# ==============================================================================

set -euo pipefail

# ==============================================================================
# MARK: - 颜色与输出辅助
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
SKIP="${YELLOW}⊘${NC}"

SECTION_PREFIX="${CYAN}━━━${NC}"
CHECK_PREFIX="  ${CYAN}▸${NC}"

check_failed() {
    local total=$1
    local passed=$2
    local failed=$3
    local skipped=$4

    echo ""
    echo -e "${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}"
    echo -e "  ${BOLD}检查汇总${NC}: 总计 ${total} | ${GREEN}通过 ${passed}${NC} | ${RED}失败 ${failed}${NC} | ${YELLOW}跳过 ${skipped}${NC}"
    echo -e "${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}${SECTION_PREFIX}"
}

phase_header() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║  $1${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

run_check() {
    local name="$1"
    local cmd="$2"
    local blocking="${3:-true}"

    echo -e "${CHECK_PREFIX} ${name}..."

    local exit_code=0
    eval "$cmd" 2>&1 | sed 's/^/       │ /' || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "     ${PASS} ${name} — 通过"
        PASSED=$((PASSED + 1))
    elif [ "$blocking" = "false" ]; then
        echo -e "     ${SKIP} ${name} — 未通过（非阻断）"
        SKIPPED=$((SKIPPED + 1))
    else
        echo -e "     ${FAIL} ${name} — ${RED}失败${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
    TOTAL=$((TOTAL + 1))
    return 0
}

# ==============================================================================
# MARK: - 帮助信息
# ==============================================================================

show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "Git 推送前统一门禁脚本。串联静态分析、编译校验、单元测试与覆盖率检查。"
    echo ""
    echo "选项:"
    echo "  (无参数)     默认模式：静态检查 + 编译校验"
    echo "  --full       完整模式：静态 + 编译 + 单元测试 + 覆盖率红线"
    echo "  --quick      快速模式：仅静态检查（不编译、不测试）"
    echo "  --help       显示此帮助信息"
    echo ""
    echo "环境变量:"
    echo "  SKIP_SWIFTLINT=1        跳过 SwiftLint 检查"
    echo "  SKIP_BUILD=1            跳过编译校验"
    echo "  SKIP_TESTS=1            跳过单元测试"
    echo "  SKIP_COVERAGE=1         跳过覆盖率检查"
    echo "  PRE_PUSH_JOBS=N         并行编译任务数（默认: sysctl -n hw.ncpu）"
    echo ""
    echo "示例:"
    echo "  $0                  # 常规推送前检查"
    echo "  $0 --full           # 发布前完整检查"
    echo "  $0 --quick          # 快速修补后检查"
    echo "  SKIP_TESTS=1 $0 --full  # 跳过测试的完整检查"
    exit 0
}

# ==============================================================================
# MARK: - 参数解析
# ==============================================================================

MODE="default"

for arg in "$@"; do
    case $arg in
        --full)   MODE="full" ;;
        --quick)  MODE="quick" ;;
        --help)   show_help ;;
        *)        echo -e "${RED}未知参数: $arg${NC}"; echo "使用 --help 查看帮助。"; exit 1 ;;
    esac
done

# ==============================================================================
# MARK: - 环境准备
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# 并行任务数
JOBS=${PRE_PUSH_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}

# 计数器
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

# ==============================================================================
# MARK: - 前置条件校验
# ==============================================================================

PREREQ_OK=true

check_prerequisite() {
    local name="$1"
    local check_cmd="$2"
    local install_hint="$3"

    if eval "$check_cmd" 2>/dev/null; then
        echo -e "  ${PASS} ${name} 就绪"
    else
        echo -e "  ${FAIL} ${name} 未安装或不可用"
        echo -e "     ${YELLOW}💡 安装方式: ${install_hint}${NC}"
        PREREQ_OK=false
    fi
}

echo -e "${BOLD}环境检查:${NC}"
check_prerequisite "Python 3"     "python3 --version > /dev/null"            "brew install python3 或 Xcode CLT"
check_prerequisite "SwiftLint"    "swiftlint version > /dev/null"             "brew install swiftlint"
check_prerequisite "XcodeGen"     "xcodegen --version > /dev/null"            "brew install xcodegen"
check_prerequisite "Xcode CLT"    "xcodebuild -version > /dev/null"           "xcode-select --install"

if [ "$MODE" != "quick" ]; then
    check_prerequisite "xcodebuild (Simulator)" \
        "xcrun simctl list devices available | grep -q iPhone" \
        "在 Xcode 中下载 iOS Simulator 运行时"
fi

echo ""

if [ "$PREREQ_OK" = "false" ]; then
    echo -e "${RED}${BOLD}❌ 前置条件不满足，请安装缺失的工具后重试。${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ZhiYu 推送前门禁检查 (Gatekeeper)                                       ║${NC}"
echo -e "${BOLD}║  模式: $(printf '%-65s' "$MODE")║${NC}"
echo -e "${BOLD}║  时间: $(date '+%Y-%m-%d %H:%M:%S')$(printf '%-50s' '')║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"

# ==============================================================================
# MARK: - Phase 1: 静态分析（所有模式均执行）
# ==============================================================================

phase_header "Phase 1/3 — 静态分析（代码质量与合规审计）"

# 1.1 硬编码密钥扫描（安全红线，最先执行）
run_check "硬编码密钥扫描" \
    "python3 Tools/Gatekeeper/Release/check_hardcoded_secrets.py" \
    || exit 1

# 1.2 SPM 依赖审计
run_check "SPM 依赖安全审计" \
    "python3 Tools/CI/Analyze/audit_spm_dependencies.py" \
    || exit 1

# 1.3 SwiftLint 严格模式
if [ "${SKIP_SWIFTLINT:-0}" = "1" ]; then
    echo -e "${CHECK_PREFIX} SwiftLint 严格检查..."
    echo -e "     ${SKIP} SwiftLint — 已跳过 (SKIP_SWIFTLINT=1)"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
else
    run_check "SwiftLint 严格检查" \
        "swiftlint lint --strict 2>&1" \
        "false" || true  # 非阻断：尊重本地开发中的 warning
fi

# 1.4 本地化合规检查
run_check "本地化合规审计（L10n Leak & Hardcode）" \
    "python3 Tools/Gatekeeper/Compliance/check_localization.py" \
    || exit 1

# 1.5 架构依赖检查（L0-L3 分层）
run_check "架构分层依赖检查（L0-L3）" \
    "python3 Tools/Gatekeeper/Architecture/check_architecture_dependency.py" \
    || exit 1

# 1.6 领域层纯净化检查
run_check "领域层纯净化检查（Domain Purity）" \
    "python3 Tools/Gatekeeper/Architecture/check_domain_purity.py" \
    || exit 1

# 1.7 魔法数字与硬编码常量检查
run_check "魔法数字/硬编码常量审计" \
    "python3 Tools/Gatekeeper/Compliance/check_magic_numbers.py" \
    || exit 1

# 1.8 存储常量审计
run_check "存储常量审计（DB Table/Field 硬编码）" \
    "python3 Tools/Gatekeeper/Compliance/check_storage_constants.py" \
    || exit 1

# 1.9 根目录卫生检查（临时文件、缓存残留）
run_check "根目录卫生检查（Temp Files / 缓存残留）" \
    "python3 Tools/Gatekeeper/Sanity/check_root_hygiene.py" \
    || exit 1

# 1.10 测试 DI 完整性
run_check "测试 DI 注入完整性检查" \
    "python3 Tools/Gatekeeper/Architecture/check_test_di_setup.py" \
    || exit 1

# 1.11 HIG 合规检查
run_check "HIG 合规检查（字体/无障碍/色彩）" \
    "python3 Tools/Gatekeeper/Compliance/check_hig_compliance.py" \
    || exit 1

# 1.12 App Store 上架就绪检查
run_check "App Store 上架就绪检查" \
    "python3 Tools/Gatekeeper/Release/check_appstore_readiness.py" \
    || exit 1

# 1.13 工具脚本质量审计
run_check "工具脚本质量审计" \
    "python3 Tools/Gatekeeper/Sanity/check_scripts_quality.py" \
    || exit 1

echo ""
echo -e "  ${GREEN}Phase 1 完成${NC} — 所有静态检查通过"

# 快速模式在此结束
if [ "$MODE" = "quick" ]; then
    check_failed $TOTAL $PASSED $FAILED $SKIPPED
    echo ""
    echo -e "${GREEN}${BOLD}✅ 快速门禁检查全部通过，准予推送！${NC}"
    exit 0
fi

# ==============================================================================
# MARK: - Phase 2: 编译校验（默认模式 + 完整模式）
# ==============================================================================

phase_header "Phase 2/3 — 编译校验（iOS Simulator）"

if [ "${SKIP_BUILD:-0}" = "1" ]; then
    echo -e "  ${SKIP} 编译校验已跳过 (SKIP_BUILD=1)"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
else
    # 2.1 生成 Xcode 项目
    echo -e "${CHECK_PREFIX} 生成 Xcode 项目 (xcodegen generate)..."
    XCODEGEN_LOG="${BUILD_DIR}/xcodegen.log"
    if xcodegen generate > "$XCODEGEN_LOG" 2>&1; then
        echo -e "     ${PASS} xcodegen generate — 通过"
        PASSED=$((PASSED + 1))
    else
        echo -e "     ${FAIL} xcodegen generate — ${RED}失败${NC}"
        echo "     ─── 日志尾部 ───"
        tail -15 "$XCODEGEN_LOG" | sed 's/^/       │ /'
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 2))  # 计入 xcodegen 检查
        check_failed $TOTAL $PASSED $FAILED $SKIPPED
        echo -e "${RED}${BOLD}❌ 项目生成失败！请检查 project.yml 语法。${NC}"
        exit 1
    fi
    TOTAL=$((TOTAL + 1))

    # 2.2 iOS 编译校验
    echo -e "${CHECK_PREFIX} iOS 编译校验 (xcodebuild, -j ${JOBS})..."
    BUILD_LOG="${BUILD_DIR}/pre_push_build.log"
    if xcodebuild build \
        -project ZhiYu.xcodeproj \
        -scheme ZhiYu \
        -destination 'generic/platform=iOS Simulator' \
        -jobs "$JOBS" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        > "$BUILD_LOG" 2>&1; then
        echo -e "     ${PASS} iOS 编译校验 — 通过"
        PASSED=$((PASSED + 1))
    else
        echo -e "     ${FAIL} iOS 编译校验 — ${RED}失败${NC}"
        echo "     ─── 编译错误 ───"
        grep -E "^.*:[0-9]+:[0-9]+: error:" "$BUILD_LOG" | sort -t: -k1,1 -k2,2n -u | head -20 | sed 's/^/       │ /' || echo "       │ (未匹配到标准编译错误)"
        echo "     ─── 日志尾部 ───"
        tail -20 "$BUILD_LOG" | sed 's/^/       │ /'
        echo ""
        echo -e "     完整日志: file://${PWD}/${BUILD_LOG}"
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 1))
        check_failed $TOTAL $PASSED $FAILED $SKIPPED
        echo -e "${RED}${BOLD}❌ 编译失败！请修复编译错误后再推送。${NC}"
        exit 1
    fi
    TOTAL=$((TOTAL + 1))

    echo ""
    echo -e "  ${GREEN}Phase 2 完成${NC} — 编译校验通过"
fi

# 默认模式在此结束
if [ "$MODE" = "default" ]; then
    check_failed $TOTAL $PASSED $FAILED $SKIPPED
    echo ""
    echo -e "${GREEN}${BOLD}✅ 门禁检查全部通过，准予推送！${NC}"
    echo ""
    echo -e "  ${CYAN}💡 提示：使用 ${BOLD}--full${NC}${CYAN} 模式可额外执行单元测试与覆盖率校验。${NC}"
    exit 0
fi

# ==============================================================================
# MARK: - Phase 3: 单元测试 + 覆盖率（仅 --full 模式）
# ==============================================================================

phase_header "Phase 3/3 — 单元测试与覆盖率红线（仅 --full 模式）"

# 3.1 单元测试
if [ "${SKIP_TESTS:-0}" = "1" ]; then
    echo -e "  ${SKIP} 单元测试已跳过 (SKIP_TESTS=1)"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
else
    echo -e "${CHECK_PREFIX} 运行单元测试..."
    echo -e "     ${CYAN}⏳ 这可能需要几分钟，请耐心等待...${NC}"

    TEST_LOG="${BUILD_DIR}/pre_push_test.log"

    # shellcheck source=/dev/null
    source "$(dirname "$0")/CI/common.sh" 2>/dev/null || true
    SIM_NAME=$(find_simulator 2>/dev/null || echo "iPhone 17 Pro")

    echo -e "     📱 使用模拟器: ${SIM_NAME}"

    if xcodebuild test \
        -project ZhiYu.xcodeproj \
        -scheme ZhiYu \
        -destination "platform=iOS Simulator,name=${SIM_NAME}" \
        -derivedDataPath "${BUILD_DIR}/DerivedData-ios" \
        -enableCodeCoverage YES \
        -parallel-testing-enabled YES \
        -parallel-testing-worker-count 2 \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        > "$TEST_LOG" 2>&1; then
        echo -e "     ${PASS} 单元测试 — 全部通过"
        PASSED=$((PASSED + 1))
    else
        echo -e "     ${FAIL} 单元测试 — ${RED}失败${NC}"
        echo "     ─── 失败用例 ───"
        grep -E "Test case.*failed|Test Suite.*failed" "$TEST_LOG" | tail -20 | sed 's/^/       │ /' || echo "       │ (未能提取失败用例)"
        echo "     ─── 错误摘要 ───"
        grep -E "^.*:[0-9]+:[0-9]+: error:" "$TEST_LOG" | sort -u | head -15 | sed 's/^/       │ /' || echo "       │ (无编译期错误)"
        echo ""
        echo -e "     完整日志: file://${PWD}/${TEST_LOG}"
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 1))
        check_failed $TOTAL $PASSED $FAILED $SKIPPED
        echo -e "${RED}${BOLD}❌ 单元测试未通过！请修复后再推送。${NC}"
        exit 1
    fi
    TOTAL=$((TOTAL + 1))
fi

# 3.2 覆盖率红线检查（Domain 层 ≥ 85%）
if [ "${SKIP_COVERAGE:-0}" = "1" ]; then
    echo -e "  ${SKIP} 覆盖率检查已跳过 (SKIP_COVERAGE=1)"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
elif [ "${SKIP_TESTS:-0}" = "1" ]; then
    echo -e "  ${SKIP} 覆盖率检查已跳过（测试被跳过则覆盖率无数据）"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
else
    run_check "Domain 层覆盖率红线（≥85%）" \
        "python3 Tools/CI/Test/check_coverage.py" \
        || exit 1
fi

echo ""
echo -e "  ${GREEN}Phase 3 完成${NC} — 测试与覆盖率校验通过"

# ==============================================================================
# MARK: - 最终汇总
# ==============================================================================

check_failed $TOTAL $PASSED $FAILED $SKIPPED
echo ""
echo -e "${GREEN}${BOLD}✅ 全部门禁检查通过，准予推送！${NC}"
echo ""
exit 0
