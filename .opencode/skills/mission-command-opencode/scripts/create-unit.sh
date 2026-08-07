#!/usr/bin/env bash
# 创建任务分队/督察会话并下达 OPORD。
# 用法: create-unit.sh "<标题>" <<'EOF'
# <OPORD 全文（应包含层级标记与回报协议）>
# EOF
# 输出: 新会话 sessionID
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh

TITLE="${1:?用法: create-unit.sh \"<标题>\" <<EOF ... EOF}"
OPORD="$(cat)"

TITLE_JSON=$(printf '%s' "$TITLE" | json_escape)
SID=$(oc_api POST /session "{\"title\": ${TITLE_JSON}}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')

TEXT_JSON=$(printf '%s' "$OPORD" | json_escape)
oc_api POST "/session/${SID}/prompt_async" "{\"parts\":[{\"type\":\"text\",\"text\":${TEXT_JSON}}]}" >/dev/null

echo "$SID"
