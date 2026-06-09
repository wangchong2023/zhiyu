#!/bin/bash
# ci-test-progress.sh — 解析 xcodebuild 测试原始输出，stderr 输出实时进度，stdout 透传
# 用法: xcodebuild test ... 2>&1 | Tools/ci-test-progress.sh | xcbeautify
# 进度写入 stderr（Woodpecker 会捕获），原始行透传 stdout 供 xcbeautify
#
# 首次运行时从源码估算测试用例总数作为初始值，
# 后续通过 xcodebuild "Executed N tests" 汇总行缓存精确总数到 build/.test_count。

set -o pipefail
declare -i passed=0 failed=0 total=0
declare start_time last_progress=0
start_time=$(date +%s)

readonly CACHE_FILE="build/.test_count"
readonly REFRESH_INTERVAL=2     # 进度刷新间隔(秒)

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
    fi

    # 捕获 xcodebuild 汇总行 "Executed N tests" 并更新为精确总数
    if echo "$line" | grep -qE "^[[:space:]]*Executed [0-9]+ tests"; then
        new_total=$(echo "$line" | grep -oE '[0-9]+' | head -1)
        if [[ -n "$new_total" && "$new_total" -gt 0 ]]; then
            total=$new_total   # 实时更新为精确值
            echo "$new_total" > "$CACHE_FILE" 2>/dev/null || true
            # 缓存成功后立即刷新一次进度，展示精确百分比
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
