# 记录-AI助手「拾墨」

## 执行时间
2026-07-03

## 完成情况

### ✅ 已完成

| 步骤 | 内容 | 文件 | 状态 |
|------|------|------|------|
| 1 | 创建知识库 Markdown | `backend/ai/knowledge_base.md` | ✅ |
| 2 | 后端 AI 路由 + System Prompt 构建 + LLM 调用 | `backend/routers/ai.py` | ✅ |
| 3 | 配置项（多供应商支持） | `backend/config.py` | ✅ |
| 4 | 前端 ChatPanel 组件 | `frontend/src/components/ChatPanel.vue` | ✅ |
| 5 | 前端全局挂载 | `App.vue` 引入 ChatPanel | ✅ |
| 6 | 超时优化（30→90秒）+ 重试机制 | `backend/routers/ai.py` | ✅ |
| 7 | 多模型支持（付费+免费） | `backend/config.py` + `backend/routers/ai.py` | ✅ |

### 已实现的功能

#### 后端
- **模型列表接口** `GET /api/ai/models`：返回可用模型列表及默认模型
- **聊天接口** `POST /api/ai/chat`：与AI助手对话，支持动态路由到不同供应商
- **多供应商支持**：根据模型自动选择对应的 API 地址和 Key
- **用户上下文注入**：每次对话自动注入当前用户的借阅状态、馆藏概况等数据
- **超时重试机制**：90秒超时，最多重试2次，间隔2秒

#### 前端
- **悬浮按钮**：右下角「拾墨」图标，点击展开聊天面板
- **聊天面板**：抽屉式设计，包含消息列表、快捷问题按钮、输入框
- **模型切换**：支持选择不同模型（DeepSeek V4 Flash / DeepSeek-R1 / Qwen3.5）
- **消息状态**：发送中 loading 状态、成功/失败提示

### 当前模型配置

| 模型 | 供应商 | 类型 | 默认 | 特点 |
|------|--------|------|------|------|
| DeepSeek V4 Flash | DeepSeek | 付费 | ✅ | 响应快、质量高 |
| DeepSeek-R1 (8B) | SiliconFlow | 免费 | ❌ | 推理能力强，较慢 |
| Qwen3.5 (4B) | SiliconFlow | 免费 | ❌ | 轻量快速 |

### 测试结果

| 测试项 | 结果 |
|--------|------|
| GET /api/ai/models | ✅ 返回3个模型列表 |
| POST /api/ai/chat（付费模型） | ✅ 成功返回AI回复 |
| POST /api/ai/chat（超时重试） | ✅ 超时后自动重试 |
| 前端聊天面板显示 | ✅ 正常显示 |
| 切换模型 | ✅ 成功切换不同模型 |

### 技术点对照

| 要求 | 实现 |
|------|------|
| 多供应商路由 | `_get_model_config()` 根据模型选择 provider |
| 用户上下文注入 | `build_user_context()` 查询数据库注入借阅/申请/超期信息 |
| 知识库 | `knowledge_base.md` 作为 System Prompt 固定部分 |
| 安全隔离 | 只注入当前用户有权查看的数据 |

### 启动方式

后端已集成到主应用，启动后端后即可使用：

```bash
cd backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### 已知问题

1. **API 稳定性**：免费模型（SiliconFlow）响应较慢，建议使用默认的付费 DeepSeek V4 Flash
2. **免费额度限制**：SiliconFlow 免费额度有限，高频使用可能触发限流

## 下一步

1. 测试 AI 助手能否正确回答借阅相关问题
2. 优化 System Prompt，提升回答准确性
3. 考虑添加频率限制（每人每分钟最多5次请求）