---
name: mission-command-opencode
description: '用任务式指挥在 OpenCode 本机会话上建立指挥所：主会话任参谋长，经 OpenCode Server API 创建独立分队/督察会话，并用 prompt_async 双向发令与战报。用于"建立指挥部""调兵遣将""创建并指挥多个会话""参谋长分派任务""分队向参谋长汇报""按任务式指挥执行"等场景；也用于带有 [MISSION-COMMAND ECHELON: ...] 标记的会话。不用于单步简单请求，也不用于现实暴力或武器规划。'
compatibility: 需要能访问本机 OpenCode Server API（默认 http://127.0.0.1:4096），以及 curl 与 python3。
---

# Mission Command（OpenCode 版）

面向 **OpenCode Server API** 的任务式指挥技能。把任务映射为独立的 OpenCode 会话；用本机 HTTP API 创建、发令、收报。所有分队会话都会出现在 Web UI 中，统帅可随时打开查看。

## 30 秒速览

| 术语 | 含义 |
| --- | --- |
| 统帅 | 用户 |
| 指挥所 / 参谋长 | **当前主会话**（默认兼任） |
| 任务分队 / 督察 | 经 `POST /session` 创建的独立 OpenCode 会话 |
| 发令 | 参谋长 → 分队：`POST /session/{unitId}/prompt_async` |
| 战报 | 分队 → 参谋长：`POST /session/{cosId}/prompt_async` |
| 拉取备份 | 参谋长 `GET /session/{unitId}/message` 读最新消息 |
| 证据调阅 | 分队把证据写入工作区 `artifacts/`，参谋长直接读文件核验 |
| WARNORD / OPORD / FRAGORD | 预先号令 / 五段式命令 / 变更令 |

命令模板见 [references/orders.md](references/orders.md)。制度见 [references/doctrine-foundations.md](references/doctrine-foundations.md)。参谋制度见 [references/staff-system.md](references/staff-system.md)。督察与 AAR 见 [references/inspection-and-aar.md](references/inspection-and-aar.md)。API 映射见 [references/opencode-api.md](references/opencode-api.md)。

## 平台事实（必须遵守）

1. **可以双向对话**：任何一方都能对任意会话调用 `POST /session/{id}/prompt_async`。参谋长能给分队发令；分队也能给参谋长会话塞战报。
2. **没有"下属身份"通道**：塞进参谋长会话的内容看起来像又一条用户 prompt。必须用固定前缀 `[MISSION-COMMAND REPORT]`，参谋长据此识别，勿当成统帅新战略意图。
3. **没有环境变量注入**：OpenCode 会话不支持 envVars。参谋长必须把自己的会话 ID（`ses_...`）与层级标记**写进 OPORD 正文**，分队从 OPORD 中读取回报地址。
4. **同一工作区**：所有会话共享 `/workspace` 文件系统。并行分队**不得写同一文件/目录**；共享写入或未解依赖的分队不得并行。证据统一写入 `artifacts/<行动代号>/<分队代号>/`。
5. **忙闲状态**：`GET /session/status` 可查各会话是否空闲；`prompt_async` 会排队不报 409，但不要向执行中的会话连发多条命令。

## 确定指挥层级

- `[MISSION-COMMAND ECHELON: CHIEF-OF-STAFF]` 或用户授权建立指挥部 → 本会话任参谋长，不再另建参谋长层。
- `[MISSION-COMMAND ECHELON: TASK-UNIT]` → 只执行本分队 OPORD；完成后向 OPORD 中给出的参谋长会话 ID 回报；不创建下级指挥体系。
- `[MISSION-COMMAND ECHELON: INSPECTOR]` → 只督察，不改实施结果；结论回报参谋长。
- 用户要求 dry run / 只出方案 → 只输出兵力编组与命令草案，不调用创建 API。
- 用户未授权创建独立会话时 → 先呈交编组，只请求一次创建授权。
- 短时、只读、可汇总的参谋工作 → 优先本会话 Subagent（`task` 工具），不建独立会话。

## 参谋长流程

### 1. 受领任务

提炼指挥官意图（目的、关键任务、终局、主攻、限制、禁止、决策门）。只追问会改变授权/风险/验收的问题。遵守三分之一—三分之二规则：筹划不超过可用时间的三分之一，尽早发 WARNORD 让准备工作并行。

### 2. 确认本会话身份

自己的会话 ID 即当前会话的 `ses_...`（可从上下文获知，或 `GET /session` 按标题查找）。记为 `COS_SESSION_ID`。确认 `curl http://127.0.0.1:4096/global/health` 正常；不通则停止创建并上报统帅。

### 3. 快速或标准筹划

默认最多 **3 个**同时活跃的直属分队会话，并保留 1 个预备容量。

编组规则：

| 情况 | 编组 |
| --- | --- |
| 短期、读多写少、只需摘要 | 本会话 Subagent（task 工具） |
| 长期、写代码、需独立上下文/可被用户打开查看 | 独立会话任务分队 |
| 高风险验收 / 红队 | 独立会话督察 |
| 生产、外发、费用、法律人事、缺权限 | 统帅或人工 |

### 4. 创建分队会话

使用 [scripts/create-unit.sh](scripts/create-unit.sh)：

```bash
scripts/create-unit.sh "[行动代号][分队] 成果名" <<'EOF'
[MISSION-COMMAND ECHELON: TASK-UNIT]
COS_SESSION_ID: ses_xxxxxxxx
UNIT_ID: 后端接口分队
ACTION_CODE: <行动代号>

<完整 OPORD：态势/任务/实施/保障/指挥与通信>

回报协议：任务完成或受阻时，必须执行
  bash <skills目录>/mission-command-opencode/scripts/report-to-cos.sh ses_xxxxxxxx <<'RPT'
  [MISSION-COMMAND REPORT]
  ...
  RPT
EOF
```

- 标题：`[行动代号][分队|督察] 成果名`
- OPORD 正文必须含：层级标记、`COS_SESSION_ID`、分队代号、行动代号、任务边界、证据目录 `artifacts/<行动代号>/<分队代号>/`、回报协议
- 高风险任务先要求分队只出方案（反向简报）再放行
- 创建后记录 `unitId`，写入共同态势表。首个战报应含确认简报（复述意图与任务）；复述跑偏立即 FRAGORD 纠正。

### 5. 指挥与收报

- **发令/改令**：`scripts/send-prompt.sh <unitId> "<FRAGORD或补充>"`
- **主动回报**（分队侧）：`scripts/report-to-cos.sh <cosId>` ← stdin 战报
- **拉取备份**：`scripts/list-messages.sh <unitId> 5` 读最新消息；`scripts/wait-idle.sh <unitId>` 等待本轮结束
- **证据调阅**：直接读 `artifacts/<行动代号>/<分队代号>/` 下的文件核验
- 事件式等待，不高频空转轮询；状态无变化不向统帅刷屏
- 收到 `[MISSION-COMMAND REPORT]` 开头的消息时：按分队战报处理，更新态势，必要时发 FRAGORD 或呈交统帅决策简报——**不要**当成统帅下达的新行动目的

### 6. 督察与终报

代码写入、外发、高风险、跨模块成果必须安排独立督察（见 [references/inspection-and-aar.md](references/inspection-and-aar.md)）。区分「分队声称完成」与「督察 PASS」。向统帅只报态势、证据、决策请求。AAR 后经统帅批准对完成分队归档（`scripts/archive-session.sh`）。

### 7. 向统帅汇报格式（强制）

参谋长**每次**向统帅汇报（含阶段战报、决策请示、终报），必须首先呈现任务态势表格，字段固定为：

| 任务名 | 任务状态 | 任务描述 | 任务完成进度 | 负责分队 | 证据链接 | 阻塞点/下一步 |
| --- | --- | --- | --- | --- | --- | --- |
| <中文任务名> | 未开始 / 执行中 / 已完成待督察 / 督察通过 / 阻塞 / 待决策 | <一句话任务描述> | 0-100% | <中文分队代号> | <artifacts 路径，无则「—」> | <阻塞原因或下一步动作，无则「—」> |

- 表格覆盖当前行动的**所有**任务（含 Subagent 与独立会话分队），不得遗漏。
- 「任务名」与「负责分队」必须用中文表达；分队的 sessionID（ses_...）只在需要时以括号附注。
- 仅分队自称完成、未经督察者，进度不得标为 100%。
- 表格之后再给态势要点、证据与决策请求。

## 任务分队 / 督察流程

1. 从 OPORD 中读取层级标记、`COS_SESSION_ID`、分队代号与边界；首个回复开头先给确认简报（复述意图、任务、边界）。
2. 在意图与边界内自主执行；关键证据写入 `artifacts/<行动代号>/<分队代号>/`；不创建下一层指挥体系。
3. 触发 CCIR、越权、不可逆、无法验证时：向参谋长发送 `STATUS: COMMAND_DECISION` 或 `BLOCKED` 战报并停止扩大范围。
4. **强制汇报纪律**：任何任务完成（含 COMPLETE_CLAIMED、BLOCKED、COMMAND_DECISION）后，**必须第一时间向参谋长汇报**，不得静默收尾。调用回报协议（见下）；发送失败（脚本已内置重试）则把战报写入 artifacts 目录并在自身最终回复中完整给出。未汇报视为任务未完成。
5. 不要向统帅旁路汇报（除非参谋长失联且 OPORD 允许升级）。

## 回报协议（分队 → 参谋长）

战报全文必须以此开头，便于参谋长识别：

```text
[MISSION-COMMAND REPORT]
UNIT: <分队代号>
ACTION: <行动代号>
ECHELON: TASK-UNIT | INSPECTOR
STATUS: EXECUTING | COMPLETE_CLAIMED | BLOCKED | COMMAND_DECISION
COS_SESSION_ID: <ses_...>
UNIT_SESSION_ID: <ses_...>
MISSION_RESULT:
ARTIFACTS:
CHANGES:
VERIFICATION:
EVIDENCE:
DEVIATIONS_WITHIN_INTENT:
CCIR_TRIGGERED:
RISKS:
NEXT_ACTION:
```

发送方式：

```bash
scripts/report-to-cos.sh <cosSessionId> <<'EOF'
[MISSION-COMMAND REPORT]
...
EOF
```

## 不可越过的决策门

暂停并请示统帅：

- 改变目的、范围或验收标准
- 不可逆 / 破坏性操作
- 生产部署、正式发布、外部发送
- 新增费用、凭据、广泛权限、敏感数据
- 法律 / 财务 / 人事 / 安全边界
- 命令冲突或缺少授权与资源
- Server API 不可用或创建会话失败且影响主攻

## 自动化

仅在统帅明确要求时建立定时跟进。自动化不得扩大权限或替代统帅批准。优先手动跑通制度后再自动化。

## 脚本索引

| 脚本 | 用途 |
| --- | --- |
| `scripts/create-unit.sh` | 创建分队/督察会话并下达 OPORD |
| `scripts/send-prompt.sh` | 向指定会话发后续命令（FRAGORD） |
| `scripts/report-to-cos.sh` | 分队向参谋长回报（带重试） |
| `scripts/wait-idle.sh` | 等待会话本轮执行结束并打印最新回复 |
| `scripts/list-messages.sh` | 列出会话最近消息（拉取兜底入口） |
| `scripts/get-session.sh` | 查询会话元数据 |
| `scripts/archive-session.sh` | 归档/删除会话（复员，需统帅批准） |
