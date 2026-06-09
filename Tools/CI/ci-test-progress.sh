#!/bin/bash
# ci-test-progress.sh — 解析 xcodebuild 测试原始输出，stderr 输出实时进度与失败详情，stdout 透传
# 用法: xcodebuild test ... 2>&1 | Tools/ci-test-progress.sh | xcbeautify
# 进度写入 stderr（Woodpecker 会捕获），原始行透传 stdout 供 xcbeautify
#
# 兼容 XCTest 串行格式 (Test Case) 和并行格式 (Test case)

set -o pipefail
declare -i passed=0 failed=0 total=0
declare start_time last_progress=0
start_time=$(date +%s)

readonly CACHE_FILE="build/.test_count"
readonly REFRESH_INTERVAL=2     # 进度刷新间隔(秒)

# 失败测试名称收集
declare -a failed_names=()

# 尝试读取缓存的总数（来自上一次 xcodebuild 的精确值）
if [[ -f "$CACHE_FILE" ]]; then
    total=$(cat "$CACHE_FILE" 2>/dev/null) || total=0
fi

# 若缓存为空，从源码估算测试用例总数作为初始值
if ((total <= 0)); then
    estimated=$(grep -rc "^[[:space:]]*func test" Tests/ --include="*.swift" 2>/dev/null \
        | awk -F: '{sum += $2} END {print sum}')
    if [[ -n "$estimated" && "$estimated" -gt 0 ]]; then
        total=$estimated
    fi
fi

build_progress() {
    local executed=$((passed + failed))
    local elapsed=$(($(date +%s) - start_time))
    local line="[测试进度] 已执行 ${executed}"
    if ((total > 0 && total >= executed)); then
        local pct=$((executed * 100 / total))
        line+="/${total} (${pct}%)"
    fi
    line+=" | ✓ ${passed} 通过 | ✗ ${failed} 失败 | 已运行 ${elapsed}s"
    printf "\r\033[K%s\n" "$line" >&2
}

while IFS= read -r line; do
    if echo "$line" | grep -q "Test [Cc]ase.*passed"; then
        ((passed++))
    elif echo "$line" | grep -q "Test [Cc]ase.*failed"; then
        ((failed++))
        # 提取测试名称 "SuiteName.testName()"
        test_name=$(echo "$line" | grep -oE "[A-Za-z_]+\.[A-Za-z_]+\(\)" | head -1)
        if [[ -n "$test_name" ]]; then
            failed_names+=("$test_name")
            # 立即输出失败详情到 stderr
            printf "\r\033[K❌ FAIL: %s\n" "$test_name" >&2
        fi
    fi

    # 捕获 xcodebuild 汇总行 "Executed N tests" 并更新为精确总数
    if echo "$line" | grep -qE "^[[:space:]]*Executed [0-9]+ tests"; then
        new_total=$(echo "$line" | grep -oE '[0-9]+' | head -1)
        if [[ -n "$new_total" && "$new_total" -gt 0 ]]; then
            total=$new_total
            echo "$new_total" > "$CACHE_FILE" 2>/dev/null || true
            build_progress
            last_progress=$(date +%s)
        fi
    fi

    executed=$((passed + failed))
    now=$(date +%s)

    if ((executed > 0 && now - last_progress >= REFRESH_INTERVAL)); then
        build_progress
        last_progress=$now
    fi

    # 透传到 stdout 供 xcbeautify 格式化
    echo "$line"
done

# 最终汇总
elapsed=$(($(date +%s) - start_time))
final_line="[测试完成] 共执行 $((passed + failed)) 个用例"
if ((total > 0 && total >= (passed + failed))); then
    final_line+=" / ${total}"
fi
final_line+=" | ✓ ${passed} 通过 | ✗ ${failed} 失败 | 耗时 ${elapsed}s"
printf "\r\033[K%s\n" "$final_line" >&2

# 输出失败测试汇总
if ((failed > 0)); then
    echo "" >&2
    echo "=== 失败测试汇总 (${failed} 个) ===" >&2
    for i in "${!failed_names[@]}"; do
        echo "  $((i+1)). ${failed_names[$i]}" >&2
    done
    echo "" >&2
fi
