# ============================================================
# routers/ai.py — 拾墨-阅读助手（AI 聊天接口）
# ============================================================
import os
import httpx
import asyncio
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from auth import get_current_user
from database import execute_query
from config import AI_MODEL, AI_MODELS, AI_MAX_TOKENS, AI_TEMPERATURE, AI_PROVIDERS

router = APIRouter()


def _get_model_config(model_id: str = None) -> dict:
    """根据模型 ID 获取对应的 API 配置（url + key）"""
    target_model = model_id or AI_MODEL
    
    for model in AI_MODELS:
        if model['id'] == target_model:
            provider_id = model.get('provider', 'siliconflow')
            provider = AI_PROVIDERS.get(provider_id)
            if provider:
                return {
                    'url': provider['url'],
                    'key': provider['key'],
                    'model': target_model,
                }
    
    return {
        'url': AI_PROVIDERS['siliconflow']['url'],
        'key': AI_PROVIDERS['siliconflow']['key'],
        'model': target_model,
    }


# ---- 模型列表 ----
@router.get('/models')
def list_models():
    """返回可用的 AI 模型列表"""
    return {
        'models': AI_MODELS,
        'default': AI_MODEL,
    }

# 加载知识库
_KB_PATH = os.path.join(os.path.dirname(__file__), '..', 'ai', 'knowledge_base.md')
with open(_KB_PATH, 'r', encoding='utf-8') as f:
    KNOWLEDGE_BASE = f.read()


class ChatRequest(BaseModel):
    message: str
    model: str | None = None  # 可选，不传则用默认模型


class ChatResponse(BaseModel):
    reply: str


def build_user_context(user: dict) -> str:
    """根据当前用户角色构建数据上下文"""
    role = user.get('role', 'reader')
    reader_id = user.get('reader_id')
    username = user.get('sub', user.get('username', '未知'))

    ctx = f'当前用户：{username}，角色：{role}'

    if reader_id and role == 'reader':
        # 读者基本信息
        reader = execute_query(
            """SELECT r.name, rt.type_name, rt.max_borrow_count, rt.borrow_days
               FROM readers r JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
               WHERE r.reader_id = %s;""",
            (reader_id,)
        )
        if reader:
            r = reader[0]
            ctx += f'\n读者姓名：{r[0]}，类型：{r[1]}（限额{r[2]}本，借期{r[3]}天）'

        # 当前借阅
        borrows = execute_query(
            """SELECT * FROM sp_get_reader_borrowings(%s);""",
            (reader_id,)
        )
        if borrows:
            ctx += f'\n\n当前借阅（共{len(borrows)}本）：'
            for b in borrows:
                line = f'\n  ·《{b[2]}》借于{b[5]}，应还{b[6]}'
                if b[7] > 0:
                    line += f' ⚠已超期{b[7]}天（预估罚金¥{b[8]}）'
                ctx += line
        else:
            ctx += '\n\n当前借阅：无'

        # 待审批申请
        apps = execute_query(
            """SELECT a.application_id, b.title, a.applied_at, a.expires_at
               FROM borrow_applications a JOIN books b ON a.isbn = b.isbn
               WHERE a.reader_id = %s AND a.status = 'pending'
               ORDER BY a.applied_at;""",
            (reader_id,)
        )
        if apps:
            ctx += f'\n\n借阅申请（共{len(apps)}条待审批）：'
            for a in apps:
                ctx += f'\n  ·《{a[1]}》— 申请于{a[2]}，{a[3]}前有效'
        else:
            ctx += '\n\n借阅申请：无待审批'

        # 罚金汇总
        fines = execute_query(
            """SELECT COALESCE(SUM(fine_amount), 0) FROM borrow_records
               WHERE reader_id = %s AND fine_amount > 0 AND return_date IS NOT NULL;""",
            (reader_id,)
        )
        if fines:
            ctx += f'\n\n累计罚金：¥{fines[0][0]}'

    elif role in ('admin', 'librarian'):
        # 馆藏概况
        stats = execute_query(
            """SELECT
                (SELECT COUNT(*) FROM books),
                (SELECT COUNT(*) FROM borrow_records WHERE return_date IS NULL),
                (SELECT COUNT(*) FROM borrow_applications WHERE status='pending'),
                (SELECT COUNT(*) FROM readers WHERE status='active');"""
        )
        if stats:
            s = stats[0]
            ctx += f'\n\n馆藏概况：{s[0]}本书，{s[1]}本在借，{s[2]}条待审批申请，{s[3]}位活跃读者'

        # 超期情况
        overdue = execute_query(
            "SELECT COUNT(*) FROM v_overdue_books;"
        )
        if overdue:
            ctx += f'\n超期未还：{overdue[0][0]}本'

    return ctx


@router.post('/chat', response_model=ChatResponse)
async def chat(
    req: ChatRequest,
    user: dict = Depends(get_current_user),
):
    """与拾墨-阅读助手对话"""
    model_config = _get_model_config(req.model)
    api_key = model_config['key']
    api_url = model_config['url']
    target_model = model_config['model']
    
    if not api_key:
        raise HTTPException(status_code=503, detail='AI 助手未配置 API Key，请联系管理员')

    # 构建完整 System Prompt
    user_ctx = build_user_context(user)
    system_prompt = f"""{KNOWLEDGE_BASE}

---
以下是当前用户的真实数据，你可以据此回答具体问题：

{user_ctx}
"""

    # 调用 AI API（根据模型选择对应的 Provider）
    async with httpx.AsyncClient(timeout=90.0) as client:
        max_retries = 2
        retry_delay = 2.0
        
        for attempt in range(max_retries + 1):
            try:
                resp = await client.post(
                    api_url,
                    headers={
                        'Authorization': f'Bearer {api_key}',
                        'Content-Type': 'application/json',
                    },
                    json={
                        'model': target_model,
                        'messages': [
                            {'role': 'system', 'content': system_prompt},
                            {'role': 'user', 'content': req.message},
                        ],
                        'max_tokens': AI_MAX_TOKENS,
                        'temperature': AI_TEMPERATURE,
                        'stream': False,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                reply = data['choices'][0]['message']['content'].strip()
                return ChatResponse(reply=reply)

            except httpx.TimeoutException:
                if attempt < max_retries:
                    print(f"DEBUG: AI 请求超时，第 {attempt + 1} 次重试...")
                    await asyncio.sleep(retry_delay)
                    continue
                raise HTTPException(status_code=504, detail='AI 服务响应超时，请稍后重试')
            
            except httpx.HTTPStatusError as e:
                if attempt < max_retries and e.response.status_code >= 500:
                    print(f"DEBUG: AI 服务错误 {e.response.status_code}，第 {attempt + 1} 次重试...")
                    await asyncio.sleep(retry_delay)
                    continue
                raise HTTPException(
                    status_code=502,
                    detail=f'AI 服务调用失败（{e.response.status_code}），请稍后重试',
                )
            
            except Exception as e:
                if attempt < max_retries:
                    print(f"DEBUG: AI 调用异常 {str(e)}，第 {attempt + 1} 次重试...")
                    await asyncio.sleep(retry_delay)
                    continue
                raise HTTPException(status_code=500, detail=f'AI 调用异常: {str(e)}')
