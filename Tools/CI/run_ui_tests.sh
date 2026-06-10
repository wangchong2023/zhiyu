#!/bin/bash
# run_ui_tests.sh
#
# 功能：UI 测试（并行多 Worker，独立阶段）
# 用法：./Tools/CI/run_ui_tests.sh
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DEST="platform=iOS Simulator,name=iPhone 17 Pro"
DERIVED="build/DerivedData"

set +e
xcodebuild test-without-building \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -destination "${DEST}" \
  -only-testing:ZhiYuUITests \
  -enableCodeCoverage YES \
  -derivedDataPath "${DERIVED}" \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee build/ui_test_output.log

UI_EXIT=${PIPESTATUS[0]}
set -e
if [ ${UI_EXIT} -ne 0 ]; then
  echo "❌ UI 测试失败 (exit=${UI_EXIT})"
  exit ${UI_EXIT}
fi
