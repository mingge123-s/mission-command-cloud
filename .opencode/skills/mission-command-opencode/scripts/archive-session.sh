#!/usr/bin/env bash
# 归档（删除）分队会话——复员，需统帅批准后执行。用法: archive-session.sh <sessionID>
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh
SID="${1:?用法: archive-session.sh <sessionID>}"
oc_api DELETE "/session/${SID}" >/dev/null && echo "archived ${SID}"
