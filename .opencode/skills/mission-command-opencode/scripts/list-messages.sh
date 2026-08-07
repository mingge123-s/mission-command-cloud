#!/usr/bin/env bash
# 列出会话最近消息（拉取兜底）。用法: list-messages.sh <sessionID> [条数=5]
set -euo pipefail
cd "$(dirname "$0")" && source ./_lib.sh

SID="${1:?用法: list-messages.sh <sessionID> [条数]}"
N="${2:-5}"

oc_api GET "/session/${SID}/message" | python3 -c "
import json,sys
msgs=json.load(sys.stdin)
for m in msgs[-int('$N'):]:
    info=m.get('info',{})
    role=info.get('role','?')
    texts=[p.get('text','') for p in m.get('parts',[]) if p.get('type')=='text']
    print('----', role, info.get('id',''))
    print('\n'.join(t for t in texts if t)[:2000])
"
