<script setup>
// ============================================================
// ChatPanel.vue — 拾墨-阅读助手（悬浮聊天面板）
// ============================================================
import { ref, nextTick, watch } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const auth = useAuthStore()
const open = ref(false)
const message = ref('')
const messages = ref([])
const loading = ref(false)
const chatBody = ref(null)
const models = ref([])
const selectedModel = ref('')

const quickQuestions = [
  '我借了哪些书？',
  '有哪些超期的书？',
  '借书限额是多少？',
  '怎么申请借书？',
  '罚金怎么算的？',
]

async function loadModels() {
  try {
    const res = await api.get('/ai/models')
    models.value = res.models || []
    selectedModel.value = res.default || ''
  } catch { /* ignore */ }
}

function toggle() {
  open.value = !open.value
  if (open.value) {
    if (messages.value.length === 0) {
      messages.value.push({
        role: 'assistant',
        content: '你好！我是拾墨，图书馆的智能阅读助手 📚\n我可以帮你查询借阅状态、了解借阅规则、推荐图书。试着问我点什么吧！',
      })
    }
    if (models.value.length === 0) loadModels()
    nextTick(() => { chatBody.value?.scrollTo(0, chatBody.value.scrollHeight) })
  }
}

async function send(question) {
  const text = question || message.value.trim()
  if (!text || loading.value) return

  messages.value.push({ role: 'user', content: text })
  message.value = ''
  loading.value = true

  nextTick(() => { chatBody.value?.scrollTo(0, chatBody.value.scrollHeight) })

  try {
    const res = await api.post('/ai/chat', { message: text, model: selectedModel.value })
    messages.value.push({ role: 'assistant', content: res.reply })
  } catch (e) {
    messages.value.push({ role: 'assistant', content: '抱歉，我暂时无法回复。' + e.message })
  } finally {
    loading.value = false
    nextTick(() => { chatBody.value?.scrollTo(0, chatBody.value.scrollHeight) })
  }
}

function onKeyup(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    send()
  }
}
</script>

<template>
  <!-- 悬浮按钮 -->
  <button v-if="!open" class="chat-fab" @click="toggle" title="拾墨-阅读助手">
    <span class="chat-fab__icon">🔮</span>
  </button>

  <!-- 聊天面板 -->
  <div v-if="open" class="chat-panel">
    <div class="chat-panel__header">
      <div class="chat-panel__title">
        <span class="chat-panel__logo">🔮</span>
        <span>拾墨-阅读助手</span>
      </div>
      <div class="chat-panel__header-right">
        <select v-if="models.length > 0" v-model="selectedModel" class="chat-model-select">
          <option v-for="m in models" :key="m.id" :value="m.id" :title="m.desc">{{ m.name }}</option>
        </select>
        <button class="chat-panel__close" @click="toggle">✕</button>
      </div>
    </div>

    <div ref="chatBody" class="chat-panel__body">
      <div v-for="(msg, i) in messages" :key="i" :class="['chat-msg', 'chat-msg--' + msg.role]">
        <div class="chat-msg__avatar">{{ msg.role === 'assistant' ? '🔮' : '👤' }}</div>
        <div class="chat-msg__bubble">{{ msg.content }}</div>
      </div>

      <!-- 快捷问题 -->
      <div v-if="messages.length <= 1" class="chat-quick">
        <p class="chat-quick__hint">试试问我：</p>
        <button v-for="q in quickQuestions" :key="q" class="chat-quick__btn" @click="send(q)">
          {{ q }}
        </button>
      </div>

      <div v-if="loading" class="chat-msg chat-msg--assistant">
        <div class="chat-msg__avatar">🔮</div>
        <div class="chat-msg__bubble chat-msg__bubble--thinking">思考中...</div>
      </div>
    </div>

    <div class="chat-panel__input">
      <input
        v-model="message"
        type="text"
        class="chat-input"
        placeholder="输入问题，回车发送..."
        :disabled="loading"
        @keyup="onKeyup"
      />
      <button class="chat-send" :disabled="!message.trim() || loading" @click="send()">
        ▶
      </button>
    </div>
  </div>
</template>

<style scoped>
/* 悬浮按钮 */
.chat-fab {
  position: fixed;
  bottom: 28px;
  right: 28px;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, #5D4037, #3E2723);
  border: none;
  color: #FFF;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(62, 39, 35, 0.35);
  z-index: 999;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s, box-shadow 0.2s;
}
.chat-fab:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px rgba(62, 39, 35, 0.45);
}
.chat-fab__icon {
  font-size: 1.5rem;
}

/* 面板 */
.chat-panel {
  position: fixed;
  bottom: 28px;
  right: 28px;
  width: 400px;
  max-width: calc(100vw - 40px);
  height: 560px;
  max-height: calc(100vh - 80px);
  background: var(--color-card);
  border-radius: var(--radius-lg);
  box-shadow: 0 8px 40px rgba(62, 39, 35, 0.25);
  z-index: 999;
  display: flex;
  flex-direction: column;
  border: 1px solid var(--color-border);
  overflow: hidden;
}

.chat-panel__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  background: linear-gradient(135deg, var(--color-primary-dark), var(--color-primary));
  color: #FFF8F0;
  flex-shrink: 0;
}

.chat-panel__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-serif);
  font-size: 1rem;
  font-weight: 600;
}

.chat-panel__logo {
  font-size: 1.2rem;
}

.chat-panel__header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.chat-model-select {
  padding: 3px 8px;
  font-size: 0.72rem;
  font-family: var(--font-sans);
  background: rgba(255,255,255,0.12);
  border: 1px solid rgba(255,255,255,0.25);
  border-radius: 10px;
  color: #FFF8F0;
  outline: none;
  cursor: pointer;
  max-width: 140px;
}

.chat-model-select option {
  background: var(--color-primary-dark);
  color: #FFF8F0;
}

.chat-panel__close {
  background: rgba(255,255,255,0.15);
  border: none;
  color: #FFF;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.chat-panel__close:hover {
  background: rgba(255,255,255,0.25);
}

/* 消息区 */
.chat-panel__body {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.chat-msg {
  display: flex;
  gap: 8px;
  align-items: flex-start;
}

.chat-msg--user {
  flex-direction: row-reverse;
}

.chat-msg__avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  background: rgba(93, 64, 55, 0.08);
  flex-shrink: 0;
}

.chat-msg__bubble {
  max-width: 80%;
  padding: 10px 14px;
  border-radius: 14px;
  font-size: 0.88rem;
  line-height: 1.55;
  white-space: pre-wrap;
  word-break: break-word;
}

.chat-msg--assistant .chat-msg__bubble {
  background: rgba(93, 64, 55, 0.06);
  color: var(--color-text);
  border-bottom-left-radius: 4px;
}

.chat-msg--user .chat-msg__bubble {
  background: var(--color-primary);
  color: #FFF8F0;
  border-bottom-right-radius: 4px;
}

.chat-msg__bubble--thinking {
  opacity: 0.6;
  animation: thinking 1.4s ease-in-out infinite;
}

@keyframes thinking {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 1; }
}

/* 快捷问题 */
.chat-quick {
  padding: 8px 0;
}

.chat-quick__hint {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  margin-bottom: 8px;
}

.chat-quick__btn {
  display: block;
  width: 100%;
  text-align: left;
  padding: 8px 12px;
  margin-bottom: 4px;
  background: rgba(93, 64, 55, 0.04);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: 0.85rem;
  color: var(--color-text);
  cursor: pointer;
  transition: background 0.15s;
}

.chat-quick__btn:hover {
  background: rgba(93, 64, 55, 0.1);
  border-color: var(--color-primary-light);
}

/* 输入区 */
.chat-panel__input {
  display: flex;
  gap: 8px;
  padding: 12px 16px;
  border-top: 1px solid var(--color-border);
  flex-shrink: 0;
}

.chat-input {
  flex: 1;
  padding: 10px 14px;
  border: 1.5px solid var(--color-border);
  border-radius: 20px;
  font-size: 0.9rem;
  font-family: var(--font-sans);
  outline: none;
  background: #FFF;
  color: var(--color-text);
}

.chat-input:focus {
  border-color: var(--color-primary);
}

.chat-send {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--color-primary);
  border: none;
  color: #FFF8F0;
  font-size: 0.85rem;
  cursor: pointer;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chat-send:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.chat-send:hover:not(:disabled) {
  background: var(--color-primary-dark);
}
</style>
