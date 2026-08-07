#!/usr/bin/env bash
# 等待会话空闲（本轮执行结束）并打印最后一条助手消息。
# 用法: wait-idle.sh <sessionID> [超时秒=600]
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh

SID="${1:?用法: wait-idle.sh <sessionID> [超时秒]}"
TIMEOUT="${2:-600}"
START=$(date +%s)

while true; do
  BUSY=$(oc_api GET /session/status | python3 -c "
import json,sys
st=json.load(sys.stdin)
s=st.get('$SID') if isinstance(st,dict) else None
t=(s or {}).get('type','idle')
print('1' if t not in ('idle','') else '0')
")
  [[ "$BUSY" == "0" ]] && break
  (( $(date +%s) - START > TIMEOUT )) && { echo "超时: 会话仍在执行" >&2; exit 1; }
  sleep 10
done

exec "$(dirname "$0")/list-messages.sh" "$SID" 1
