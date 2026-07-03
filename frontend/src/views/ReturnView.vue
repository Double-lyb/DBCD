<script setup>
// ============================================================
// ReturnView.vue — 还书操作（仅管理员/图书管理员）
//   刷卡（输入读者编号）→ 查看该读者在借图书 → 逐本归还
// ============================================================
import { ref } from 'vue'
import api from '../api/index.js'

const step = ref(1) // 1=刷卡, 2=查看借阅

const readerId = ref('')
const readerLoading = ref(false)
const readerError = ref('')
const reader = ref(null)

const borrows = ref([])
const borrowsLoading = ref(false)
const returningId = ref(null)

const toast = ref({ show: false, msg: '', type: 'success' })
function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 4000)
}

// Step 1: 刷卡
async function lookupReader() {
  if (!readerId.value.trim()) { readerError.value = '请输入读者编号'; return }
  readerError.value = ''
  readerLoading.value = true
  try {
    const res = await api.get(`/readers/${readerId.value.trim()}`)
    reader.value = res
    step.value = 2
    await loadBorrows()
  } catch (e) {
    readerError.value = e.message || '未找到该读者'
  } finally {
    readerLoading.value = false
  }
}

// 加载该读者的在借图书
async function loadBorrows() {
  borrowsLoading.value = true
  try {
    const res = await api.get(`/borrow/reader/${reader.value.reader_id}/borrows`)
    borrows.value = res.data || []
  } catch { borrows.value = [] }
  finally { borrowsLoading.value = false }
}

// 归还
async function doReturn(borrowId, title) {
  if (!confirm(`确认归还「${title}」？`)) return
  returningId.value = borrowId
  try {
    const res = await api.put(`/borrow/${borrowId}/return`)
    const fine = res.fine_amount && parseFloat(res.fine_amount) > 0 ? ` 罚金 ¥${res.fine_amount}` : ''
    showToast(`「${title}」归还成功！${fine}`)
    await loadBorrows()
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    returningId.value = null
  }
}

function reset() {
  step.value = 1
  readerId.value = ''
  reader.value = null
  borrows.value = []
  readerError.value = ''
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">还书操作</h1>
    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">{{ toast.msg }}</div>

    <!-- 步骤指示器 -->
    <div class="steps mb-4">
      <div :class="['step', { 'step--active': step === 1, 'step--done': step > 1 }]">
        <span class="step__num">1</span><span class="step__label">刷卡</span>
      </div>
      <div class="step__line" :class="{ 'step__line--done': step > 1 }"></div>
      <div :class="['step', { 'step--active': step === 2 }]">
        <span class="step__num">2</span><span class="step__label">归还图书</span>
      </div>
    </div>

    <!-- Step 1: 刷卡 -->
    <div v-if="step === 1" class="card return-card">
      <div class="return-card__icon">🪪</div>
      <h2>请刷卡 — 输入读者编号</h2>
      <p class="text-muted">模拟读者到前台还书的场景</p>
      <form @submit.prevent="lookupReader" class="return-form">
        <input v-model="readerId" type="text" class="form-input return-input"
          placeholder="请输入读者编号" autofocus />
        <button type="submit" class="btn btn-primary btn-lg" :disabled="readerLoading">
          {{ readerLoading ? '查询中...' : '查询读者' }}
        </button>
      </form>
      <p v-if="readerError" class="form-error mt-4">{{ readerError }}</p>
    </div>

    <!-- Step 2: 显示借阅 + 归还 -->
    <div v-else-if="step === 2">
      <!-- 读者信息 -->
      <div class="card mb-4">
        <div class="reader-preview">
          <span class="tag" :class="reader?.reader_type === 'teacher' ? 'tag-info' : 'tag-success'">
            {{ reader?.reader_type === 'teacher' ? '教师' : '学生' }}
          </span>
          <strong>{{ reader?.name }}</strong>
          <span class="text-muted">{{ reader?.reader_id }} · {{ reader?.department }}</span>
          <span class="text-muted">在借 {{ borrows.length }} 本</span>
          <button class="btn btn-ghost btn-sm" @click="reset">更换读者</button>
        </div>
      </div>

      <div v-if="borrowsLoading" class="loading-center">
        <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">查询借阅记录...</span></div>
      </div>

      <div v-else-if="borrows.length === 0" class="empty-state">
        <div class="empty-state__icon">✓</div>
        <p class="empty-state__text">该读者当前没有在借图书</p>
        <button class="btn btn-outline mt-4" @click="reset">返回</button>
      </div>

      <template v-else>
        <h3 style="margin-bottom:12px">当前借阅（{{ borrows.length }} 本）</h3>
        <div class="borrow-list">
          <div v-for="b in borrows" :key="b.borrow_id" class="borrow-item card">
            <div class="borrow-item__bar" :class="{ 'borrow-item__bar--overdue': b.overdue_days > 0 }"></div>
            <div class="borrow-item__body">
              <div class="borrow-item__info">
                <h4>{{ b.title }}</h4>
                <div class="borrow-item__meta">
                  <span>{{ b.author }}</span>
                  <span class="text-mono">ISBN {{ b.isbn }}</span>
                </div>
                <div class="borrow-item__dates">
                  <span>借阅：{{ b.borrow_date }}</span>
                  <span>应还：{{ b.due_date }}</span>
                  <span v-if="b.status === 'overdue'" class="tag tag-danger">已超期</span>
                </div>
                <div v-if="b.overdue_days > 0" class="borrow-item__fine">
                  ⚠ 超期 <strong>{{ b.overdue_days }}</strong> 天，
                  预估罚金 <strong class="text-danger">¥{{ b.estimated_fine }}</strong>
                </div>
              </div>
              <button
                class="btn btn-accent"
                :disabled="returningId === b.borrow_id"
                @click="doReturn(b.borrow_id, b.title)"
              >
                {{ returningId === b.borrow_id ? '处理中...' : '确认归还' }}
              </button>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.steps { display: flex; align-items: center; justify-content: center; gap: 0; }
.step { display: flex; align-items: center; gap: 8px; padding: 8px 20px; border-radius: var(--radius-md); background: var(--color-card); border: 2px solid var(--color-border); }
.step--active { border-color: var(--color-primary); background: rgba(93, 64, 55, 0.06); }
.step--done { border-color: var(--color-accent); background: rgba(46, 125, 50, 0.06); }
.step__num { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-family: var(--font-serif); font-size: 0.9rem; font-weight: 700; background: var(--color-border); color: #FFF; }
.step--active .step__num { background: var(--color-primary); }
.step--done .step__num { background: var(--color-accent); }
.step__label { font-family: var(--font-serif); font-size: 0.95rem; font-weight: 600; }
.step__line { width: 60px; height: 2px; background: var(--color-border); margin: 0 -4px; }
.step__line--done { background: var(--color-accent); }

.return-card { max-width: 560px; margin: 0 auto; text-align: center; padding: 40px; }
.return-card__icon { font-size: 3rem; margin-bottom: 16px; }
.return-form { display: flex; gap: 12px; margin-top: 24px; justify-content: center; }
.return-input { max-width: 280px; text-align: center; font-size: 1.1rem; font-family: var(--font-mono); }

.reader-preview { display: flex; align-items: center; justify-content: center; gap: 12px; padding: 8px 0; flex-wrap: wrap; }

.borrow-list { display: flex; flex-direction: column; gap: 12px; }
.borrow-item { padding: 0; overflow: hidden; }
.borrow-item__bar { width: 5px; flex-shrink: 0; background: var(--color-accent); }
.borrow-item__bar--overdue { background: var(--color-danger); }
.borrow-item__body { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; gap: 16px; }
.borrow-item__info { flex: 1; }
.borrow-item__info h4 { margin-bottom: 4px; font-size: 1rem; }
.borrow-item__meta { display: flex; gap: 12px; font-size: 0.82rem; color: var(--color-text-secondary); }
.borrow-item__dates { display: flex; gap: 12px; align-items: center; font-size: 0.82rem; color: var(--color-text-secondary); margin-top: 4px; }
.borrow-item__fine { margin-top: 6px; padding: 8px 12px; background: rgba(198, 40, 40, 0.05); border-radius: var(--radius-sm); font-size: 0.85rem; }
</style>
