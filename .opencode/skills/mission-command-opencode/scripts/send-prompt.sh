#!/usr/bin/env bash
# 向指定会话发后续命令（FRAGORD/补充指示），异步不等待。
# 用法: send-prompt.sh <sessionID> "<文本>"   或  send-prompt.sh <sessionID> <<'EOF' ... EOF
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh

SID="${1:?用法: send-prompt.sh <sessionID> [文本]}"
if [[ $# -ge 2 ]]; then TEXT="$2"; else TEXT="$(cat)"; fi

TEXT_JSON=$(printf '%s' "$TEXT" | json_escape)
oc_api POST "/session/${SID}/prompt_async" "$(prompt_body "$TEXT_JSON")" >/dev/null
echo "sent -> ${SID}"
