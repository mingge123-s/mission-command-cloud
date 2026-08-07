#!/usr/bin/env bash
# 分队向参谋长会话回报战报（从 stdin 读取，必须以 [MISSION-COMMAND REPORT] 开头）。
# 依赖环境变量或参数: MISSION_COMMAND_COS_SESSION_ID
# 用法: report-to-cos.sh [cosSessionID] <<'EOF' ... EOF
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh

COS="${1:-${MISSION_COMMAND_COS_SESSION_ID:?缺少参谋长会话 ID (MISSION_COMMAND_COS_SESSION_ID)}}"
REPORT="$(cat)"
case "$REPORT" in
  "[MISSION-COMMAND REPORT]"*) ;;
  *) echo "错误: 战报必须以 [MISSION-COMMAND REPORT] 开头" >&2; exit 1 ;;
esac

TEXT_JSON=$(printf '%s' "$REPORT" | json_escape)
COS_SESSION_ID="$COS"
BODY="$(prompt_body "$TEXT_JSON")"
for i in 1 2 3 4 5; do
  if oc_api POST "/session/${COS}/prompt_async" "$BODY" >/dev/null; then
    echo "report sent -> ${COS}"; exit 0
  fi
  sleep $((i * 5))
done
echo "错误: 战报发送失败（已重试 5 次），请写入 artifacts/ 并在最终回复中完整给出" >&2
exit 1
