#!/usr/bin/env bash
# 查询会话元数据。用法: get-session.sh <sessionID>
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh
SID="${1:?用法: get-session.sh <sessionID>}"
oc_api GET "/session/${SID}" | python3 -m json.tool
