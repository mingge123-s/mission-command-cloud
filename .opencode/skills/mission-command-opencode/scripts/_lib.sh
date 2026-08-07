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
