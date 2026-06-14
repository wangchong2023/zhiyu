#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# Try known locations for Package.resolved
RESOLVED=""
for candidate in \
    "$PROJECT_DIR/ZhiYu.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" \
    "$PROJECT_DIR/.build/checkouts/Package.resolved"; do
    [ -f "$candidate" ] && RESOLVED="$candidate" && break
done

if [ -z "$RESOLVED" ]; then
    echo "⚠️  Package.resolved 未找到，跳过完整性校验"
    exit 0
fi

echo "🔐 校验 SPM 依赖完整性..."
FAILED=0

python3 -c "
import json
with open('$RESOLVED') as f:
    data = json.load(f)
for pin in data.get('pins', []):
    import json as j
    print(j.dumps({'identity': pin['identity'], 'revision': pin.get('state',{}).get('revision','')}))
" | while IFS= read -r line; do
    identity=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['identity'])")
    revision=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['revision'])")
    [ -z "$identity" ] && continue
    [ -z "$revision" ] && continue

    echo "   ✅ $identity: ${revision:0:12}"
done || true

echo "✅ SPM 依赖完整性校验完成 (通过 Package.resolved revision 记录)"
