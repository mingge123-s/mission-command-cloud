# OpenCode Server API 映射

Base URL：`http://127.0.0.1:4096`（容器内），所有请求带查询参数 `?directory=/workspace`。

| 军事概念 | API |
| --- | --- |
| 建立分队会话 | `POST /session`，body `{"title": "..."}` → 返回 `{"id": "ses_..."}` |
| 下达 OPORD / FRAGORD / 战报 | `POST /session/{id}/prompt_async`，body `{"parts": [{"type": "text", "text": "..."}]}`（异步排队，不等待） |
| 读取会话消息 | `GET /session/{id}/message` → 消息数组（`info.role` + `parts[].text`） |
| 查询忙闲 | `GET /session/status` → `{ "<sessionID>": {"type": "..."} }`，无记录或 idle 即空闲 |
| 查询会话元数据 | `GET /session/{id}` |
| 中止执行 | `POST /session/{id}/abort` |
| 归档（复员） | `DELETE /session/{id}` |
| 列出全部会话 | `GET /session` |

要点：

- 会话没有 envVars——参谋长会话 ID 与层级标记必须写入 OPORD 正文。
- `prompt_async` 立即返回，模型在后台执行；用 `GET /session/status` + `GET /session/{id}/message` 跟踪。
- 所有会话共享 `/workspace`；分队间的文件隔离靠命令边界约束，不靠平台。
- 完整 OpenAPI 文档：`GET /doc`。
