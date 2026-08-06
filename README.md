# mission-command-cloud

用任务式指挥（Mission Command，ADP 6-0 / MDMP / OPORD-FRAGORD / CCIR / AAR）在 **Cursor Cloud Agents API** 上建立指挥所：主对话任参谋长，经 API 创建独立任务分队/督察对话，双向发令与战报。

技能本体：[`.cursor/skills/mission-command-cloud/`](.cursor/skills/mission-command-cloud/)（入口 [SKILL.md](.cursor/skills/mission-command-cloud/SKILL.md)）。

## 安装

**方式一：项目级**（仅当前仓库可用）

把 `.cursor/` 目录复制到你的项目根：

```bash
git clone https://github.com/mingge123-s/mission-command-cloud.git
cp -r mission-command-cloud/.cursor <你的项目根>/
```

**方式二：全局**（所有项目可用）

```bash
mkdir -p ~/.cursor/skills
cp -r mission-command-cloud/.cursor/skills/mission-command-cloud ~/.cursor/skills/
```

## 配置

1. 在 [Cursor Dashboard → API Keys](https://cursor.com/dashboard/api) 生成 API Key。
2. 设置环境变量（脚本按此优先级读取）：

```bash
export MISSION_COMMAND_API_KEY=<你的 Key>   # 首选
# 或 export CURSOR_API_KEY=<你的 Key>
```

3. 网络需能访问 `https://api.cursor.com`。

## 使用

在 Cursor 对话中说「建立指挥部」「按任务式指挥执行」等即可触发；或直接引用 skill。分队/督察由参谋长经 `scripts/create-unit.sh` 创建，战报经 `scripts/report-to-cos.sh` 回传。

脚本一览见 [SKILL.md 脚本索引](.cursor/skills/mission-command-cloud/SKILL.md#脚本索引)；API 映射见 [references/cloud-api.md](.cursor/skills/mission-command-cloud/references/cloud-api.md)。

## 已知限制

- `envVars` 为 Cursor Beta 功能：未启用的账户可能被静默忽略。技能已内置分队自检 + 参谋长拉取兜底（`scripts/list-runs.sh`），但这是当前最大的运行时风险。
- `GET /v1/agents/{id}/usage` 为早期功能，未启用返回 `403 feature_unavailable`。
