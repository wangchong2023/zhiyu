#!/bin/bash
set -euo pipefail

STATUS="${CI_PIPELINE_STATUS:-unknown}"
HEALTH_FILE="build/.ci_health"

# 仅在失败或恢复时发送
LAST_STATUS="unknown"
[ -f "$HEALTH_FILE" ] && LAST_STATUS=$(head -1 "$HEALTH_FILE")
echo "$STATUS" > "$HEALTH_FILE"

if [ "$STATUS" = "$LAST_STATUS" ]; then
    echo "ℹ️  状态未变 ($STATUS)，跳过通知"
    exit 0
fi

WEBHOOK="${FEISHU_WEBHOOK_URL:-}"
if [ -z "$WEBHOOK" ]; then
    echo "⚠️  FEISHU_WEBHOOK_URL 未设置，跳过通知"
    exit 0
fi

SHA_SHORT="${CI_COMMIT_SHA:0:8}"
MSG="${CI_COMMIT_MESSAGE:-No message}"
PIPELINE_URL="${CI_PIPELINE_URL:-https://woodpecker.zhiyu.app}"

if [ "$STATUS" = "failure" ]; then
    EMOJI="🔴"
    TITLE="CI 流水线失败"
    COLOR="red"
else
    EMOJI="🟢"
    TITLE="CI 流水线已恢复"
    COLOR="green"
fi

JSON=$(cat << JSONEOF
{
  "msg_type": "interactive",
  "card": {
    "header": {
      "title": {"tag": "plain_text", "content": "$EMOJI $TITLE"},
      "template": "$COLOR"
    },
    "elements": [
      {"tag": "div", "text": {"tag": "lark_md", "content": "**提交:** $SHA_SHORT — $MSG"}},
      {"tag": "div", "text": {"tag": "lark_md", "content": "**流水线:** #$CI_PIPELINE_NUMBER"}},
      {"tag": "action", "actions": [{"tag": "button", "text": {"tag": "plain_text", "content": "查看日志"}, "url": "$PIPELINE_URL", "type": "default"}]}
    ]
  }
}
JSONEOF
)

curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$WEBHOOK"
echo ""
echo "  ✅ 飞书通知已发送 ($STATUS)"
