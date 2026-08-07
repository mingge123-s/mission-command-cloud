#!/usr/bin/env bash
# 公共库：OpenCode Server API 访问
set -euo pipefail

OC_BASE_URL="${OPENCODE_BASE_URL:-http://127.0.0.1:4096}"
OC_DIR="${OPENCODE_DIRECTORY:-/workspace}"

oc_api() {
  # oc_api <METHOD> <PATH> [JSON_BODY]
  local method="$1" path="$2" body="${3:-}"
  local url="${OC_BASE_URL}${path}"
  if [[ "$path" == *\?* ]]; then url="${url}&directory=${OC_DIR}"; else url="${url}?directory=${OC_DIR}"; fi
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" -H "Content-Type: application/json" -d "$body" "$url"
  else
    curl -sS -X "$method" "$url"
  fi
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

# 模型继承：OPENCODE_MODEL="provider/model" 显式指定；
# 未指定且设了 COS_SESSION_ID 时，自动取参谋长会话最近一条 assistant 消息的模型。
model_json() {
  local m="${OPENCODE_MODEL:-}"
  if [[ -z "$m" && -n "${COS_SESSION_ID:-}" ]]; then
    m=$(oc_api GET "/session/${COS_SESSION_ID}/message" | python3 -c 'import json,sys
ms=[x["info"] for x in json.load(sys.stdin) if x["info"].get("role")=="assistant" and x["info"].get("providerID")]
print(ms[-1]["providerID"]+"/"+ms[-1]["modelID"] if ms else "")') || m=""
  fi
  if [[ -n "$m" ]]; then
    printf '{"providerID":"%s","modelID":"%s"}' "${m%%/*}" "${m#*/}"
  fi
}

# 组装 prompt_async 请求体：$1=已转义的文本 JSON
prompt_body() {
  local text_json="$1" mj
  mj=$(model_json)
  if [[ -n "$mj" ]]; then
    printf '{"model":%s,"parts":[{"type":"text","text":%s}]}' "$mj" "$text_json"
  else
    printf '{"parts":[{"type":"text","text":%s}]}' "$text_json"
  fi
}
