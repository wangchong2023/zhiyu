#!/bin/bash
# ci-test-progress.sh — 解析 xcodebuild 测试原始输出，stderr 输出进度，stdout 透传
# 用法: xcodebuild test ... 2>&1 | Tools/ci-test-progress.sh | xcbeautify
# 进度信息写入 stderr，原始行透传至 stdout 供 xcbeautify 格式化

set -o pipefail
declare -i passed=0 failed=0
declare start_time
start_time=$(date +%s)
declare last_progress=0

# 进度刷新间隔(秒)，避免刷屏
readonly REFRESH_INTERVAL=1

while IFS= read -r line; do
    # 匹配 "Test Case ... passed" (xcodebuild 原始输出，格式稳定)
    if echo "$line" | grep -q "Test Case.*passed"; then
        ((passed++))
    fi
    # 匹配 "Test Case ... failed"
    if echo "$line" | grep -q "Test Case.*failed"; then
        ((failed++))
    fi

    executed=$((passed + failed))
    now=$(date +%s)

    # 按间隔输出进度到 stderr
    if ((executed > 0 && now - last_progress >= REFRESH_INTERVAL)); then
        elapsed=$((now - start_time))
        printf "\r\033[K[进度] 已执行 %d 个用例 | ✓ %d 通过 | ✗ %d 失败 | 耗时 %ds\n" \
            "$executed" "$passed" "$failed" "$elapsed" >&2
        last_progress=$now
    fi

    # 原始行透传到 stdout 供 xcbeautify
    echo "$line"
done

# 最终汇总到 stderr
elapsed=$(($(date +%s) - start_time))
printf "\r\033[K[完成] 共执行 %d 个用例 | ✓ %d 通过 | ✗ %d 失败 | 耗时 %ds\n" \
    "$executed" "$passed" "$failed" "$elapsed" >&2

# 退出码由 pipefail 保证（xcodebuild 失败则管道失败），此处始终返回 0
