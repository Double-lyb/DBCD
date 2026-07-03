<script setup>
// ============================================================
// BorrowView.vue — 借书操作
//   读者：浏览图书 → 申请借阅 → 查看申请状态
//   管理员：刷卡（输入读者编号）→ 查看待审批申请 → 同意/驳回
// ============================================================
import { ref, computed } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const auth = useAuthStore()
const isStaff = computed(() => auth.isAdmin || auth.isLibrarian)

// ===== 读者：申请借阅 =====
const searchKeyword = ref('')
const searchResults = ref([])
const searchLoading = ref(false)
const searched = ref(false)

const myApps = ref([])
const appsLoading = ref(false)
const applyingIsbn = ref('')

const toast = ref({ show: false, msg: '', type: 'success' })
function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 4000)
}

let debounce = null
function onSearchInput() {
  clearTimeout(debounce)
  debounce = setTimeout(doSearch, 300)
}

async function doSearch() {
  if (!searchKeyword.value.trim()) { searchResults.value = []; searched.value = false; return }
  searchLoading.value = true
  searched.value = true
  try {
    const res = await api.get('/books', { params: { keyword: searchKeyword.value, page_size: 20 } })
    searchResults.value = res.data || []
  } catch { searchResults.value = [] }
  finally { searchLoading.value = false }
}

async function applyBook(isbn, title) {
  if (!confirm(`确认申请借阅「${title}」？\n申请有效期6小时，需管理员审批。`)) return
  applyingIsbn.value = isbn
  try {
    await api.post('/borrow/apply', { isbn })
    showToast(`「${title}」借阅申请已提交！`)
    await loadMyApps()
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    applyingIsbn.value = ''
  }
}

async function loadMyApps() {
  appsLoading.value = true
  try {
    const res = await api.get('/borrow/applications/my')
    myApps.value = res.data || []
  } catch { myApps.value = [] }
  finally { appsLoading.value = false }
}

const cancellingId = ref(null)
async function cancelApp(appId, title) {
  if (!confirm(`确认撤销「${title}」的借阅申请？`)) return
  cancellingId.value = appId
  try {
    await api.delete(`/borrow/applications/${appId}`)
    showToast('申请已撤销，库存已释放')
    await loadMyApps()
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    cancellingId.value = null
  }
}

const statusLabel = { pending: '待审批', approved: '已通过', rejected: '已驳回', expired: '已过期' }
const statusClass = { pending: 'tag-warning', approved: 'tag-success', rejected: 'tag-danger', expired: 'tag-default' }

// ===== 管理员：审批 =====
const step = ref(1)
const adminReaderId = ref('')
const adminReader = ref(null)
const adminReaderError = ref('')
const adminReaderLoading = ref(false)
const pendingApps = ref([])
const pendingLoading = ref(false)
const processingId = ref(null)

async function lookupReader() {
  if (!adminReaderId.value.trim()) { adminReaderError.value = '请输入读者编号'; return }
  adminReaderError.value = ''
  adminReaderLoading.value = true
  try {
    const res = await api.get(`/readers/${adminReaderId.value.trim()}`)
    adminReader.value = res
    step.value = 2
    await loadPendingApps()
  } catch (e) {
    adminReaderError.value = e.message || '未找到该读者'
  } finally {
    adminReaderLoading.value = false
  }
}

async function loadPendingApps() {
  pendingLoading.value = true
  try {
    const res = await api.get(`/borrow/applications/${adminReader.value.reader_id}`)
    pendingApps.value = res.data || []
  } catch { pendingApps.value = [] }
  finally { pendingLoading.value = false }
}

async function approveApp(appId) {
  processingId.value = appId
  try {
    await api.put(`/borrow/applications/${appId}/approve`)
    showToast('审批通过，借阅成功！')
    await loadPendingApps()
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    processingId.value = null
  }
}

async function rejectApp(appId) {
  const reason = prompt('驳回理由（可选）：')
  processingId.value = appId
  try {
    await api.put(`/borrow/applications/${appId}/reject`, { reason: reason || undefined })
    showToast('已驳回申请')
    await loadPendingApps()
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    processingId.value = null
  }
}

function adminReset() {
  step.value = 1
  adminReaderId.value = ''
  adminReader.value = null
  pendingApps.value = []
  adminReaderError.value = ''
}

// 初始化：读者加载申请记录
if (!isStaff.value) {
  loadMyApps()
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">借书操作</h1>
    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">{{ toast.msg }}</div>

    <!-- ========== 读者视图 ========== -->
    <template v-if="!isStaff">
      <div class="card mb-4" style="background:rgba(46,125,50,0.04)">
        <p class="text-muted" style="font-size:0.9rem">
          💡 输入书名或作者搜索图书，点击「申请借阅」提交申请。管理员审批通过后即可取书。申请有效期 <strong>6 小时</strong>。
        </p>
      </div>

      <!-- 搜索 -->
      <div class="card mb-4">
        <div class="search-bar">
          <span class="search-bar__icon">⌕</span>
          <input v-model="searchKeyword" type="text" class="search-bar__input"
            placeholder="搜索书名或作者..." @input="onSearchInput" @keyup.enter="doSearch" />
        </div>

        <!-- 搜索结果 -->
        <div v-if="searchLoading" class="mt-4 text-muted" style="text-align:center">搜索中...</div>
        <div v-else-if="searched && searchResults.length === 0" class="mt-4 empty-state" style="padding:20px">
          <p class="empty-state__text">未找到匹配的图书</p>
        </div>
        <div v-else-if="searchResults.length > 0" class="mt-4">
          <div v-for="book in searchResults" :key="book.isbn" class="search-result-item">
            <div :class="['spine-cat', 'cat-' + (book.category || 'other')]"></div>
            <div class="search-result-info">
              <strong>{{ book.title }}</strong>
              <span class="text-muted">{{ book.author }} · {{ book.publisher }}</span>
              <span class="text-muted">可借: {{ book.available_copies }} / {{ book.total_copies }} · ¥{{ book.price }}</span>
            </div>
            <button
              class="btn btn-accent btn-sm"
              :disabled="applyingIsbn === book.isbn || book.available_copies <= 0"
              @click="applyBook(book.isbn, book.title)"
            >
              {{ applyingIsbn === book.isbn ? '...' : book.available_copies <= 0 ? '已借完' : '申请借阅' }}
            </button>
          </div>
        </div>
      </div>

      <!-- 我的申请记录 -->
      <div class="card">
        <div class="card-header">
          <h3>我的借阅申请</h3>
          <button class="btn btn-ghost btn-sm" @click="loadMyApps">刷新</button>
        </div>
        <div v-if="appsLoading" class="loading-center" style="min-height:80px">
          <div class="book-loader"><div class="book-loader__spine"></div></div>
        </div>
        <div v-else-if="myApps.length === 0" class="empty-state" style="padding:24px">
          <p class="empty-state__text">暂无借阅申请记录</p>
        </div>
        <table v-else>
          <thead>
            <tr><th>申请编号</th><th>图书</th><th>作者</th><th>申请时间</th><th>过期时间</th><th>状态</th><th>操作</th></tr>
          </thead>
          <tbody>
            <tr v-for="app in myApps" :key="app.application_id">
              <td class="text-mono" style="font-size:0.8rem">#{{ app.application_id }}</td>
              <td>{{ app.title }}</td>
              <td>{{ app.author }}</td>
              <td class="text-mono" style="font-size:0.8rem">{{ app.applied_at }}</td>
              <td class="text-mono" style="font-size:0.8rem">{{ app.expires_at }}</td>
              <td>
                <span :class="['tag', statusClass[app.status]]">{{ statusLabel[app.status] }}</span>
                <span v-if="app.status === 'rejected' && app.reject_reason" class="text-muted" style="font-size:0.75rem;display:block">
                  {{ app.reject_reason }}
                </span>
              </td>
              <td>
                <button
                  v-if="app.status === 'pending'"
                  class="btn btn-ghost btn-sm text-danger"
                  :disabled="cancellingId === app.application_id"
                  @click="cancelApp(app.application_id, app.title)"
                >
                  {{ cancellingId === app.application_id ? '...' : '撤销' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <!-- ========== 管理员视图 ========== -->
    <template v-else>
      <!-- 步骤指示器 -->
      <div class="steps mb-4">
        <div :class="['step', { 'step--active': step === 1, 'step--done': step > 1 }]">
          <span class="step__num">1</span><span class="step__label">刷卡</span>
        </div>
        <div class="step__line" :class="{ 'step__line--done': step > 1 }"></div>
        <div :class="['step', { 'step--active': step === 2 }]">
          <span class="step__num">2</span><span class="step__label">审批申请</span>
        </div>
      </div>

      <!-- Step 1: 输入读者编号 -->
      <div v-if="step === 1" class="card borrow-card">
        <div class="borrow-card__icon">🪪</div>
        <h2>请刷卡 — 输入读者编号</h2>
        <p class="text-muted">查看该读者的借阅申请</p>
        <form @submit.prevent="lookupReader" class="borrow-form">
          <input v-model="adminReaderId" type="text" class="form-input borrow-input"
            placeholder="输入读者编号" autofocus />
          <button type="submit" class="btn btn-primary btn-lg" :disabled="adminReaderLoading">
            {{ adminReaderLoading ? '查询中...' : '查询读者' }}
          </button>
        </form>
        <p v-if="adminReaderError" class="form-error mt-4">{{ adminReaderError }}</p>
      </div>

      <!-- Step 2: 审批申请 -->
      <div v-else-if="step === 2">
        <!-- 读者信息 -->
        <div class="card mb-4">
          <div class="reader-preview">
            <span class="tag" :class="adminReader?.reader_type === 'teacher' ? 'tag-info' : 'tag-success'">
              {{ adminReader?.reader_type === 'teacher' ? '教师' : '学生' }}
            </span>
            <strong>{{ adminReader?.name }}</strong>
            <span class="text-muted">{{ adminReader?.reader_id }} · {{ adminReader?.department }}</span>
            <span class="text-muted">已借 {{ adminReader?.current_borrow_count ?? 0 }} / {{ adminReader?.max_borrow_count ?? 10 }} 本</span>
            <button class="btn btn-ghost btn-sm" @click="adminReset">更换读者</button>
          </div>
        </div>

        <div v-if="pendingLoading" class="loading-center">
          <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">查询申请中...</span></div>
        </div>

        <div v-else-if="pendingApps.length === 0" class="empty-state">
          <div class="empty-state__icon">📋</div>
          <p class="empty-state__text">该读者暂无待审批的借阅申请</p>
          <button class="btn btn-outline mt-4" @click="adminReset">返回</button>
        </div>

        <template v-else>
          <h3 style="margin-bottom:12px">待审批申请（{{ pendingApps.length }}）</h3>
          <div class="app-list">
            <div v-for="app in pendingApps" :key="app.application_id" class="app-item card">
              <div class="app-item__body">
                <div class="app-item__info">
                  <h4>{{ app.title }}</h4>
                  <div class="app-item__meta">
                    <span>{{ app.author }} · {{ app.publisher }}</span>
                    <span class="text-mono">ISBN {{ app.isbn }}</span>
                    <span class="text-muted">申请时间: {{ app.applied_at }}</span>
                    <span class="text-muted">过期: {{ app.expires_at }}</span>
                  </div>
                </div>
                <div class="app-item__actions">
                  <button class="btn btn-accent" :disabled="processingId === app.application_id"
                    @click="approveApp(app.application_id)">
                    {{ processingId === app.application_id ? '...' : '同意借阅' }}
                  </button>
                  <button class="btn btn-danger" :disabled="processingId === app.application_id"
                    @click="rejectApp(app.application_id)">
                    驳回
                  </button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </template>
  </div>
</template>

<style scoped>
/* Steps (reused) */
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

/* Search */
.search-bar { position: relative; }
.search-bar__icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); font-size: 1.1rem; color: var(--color-text-secondary); z-index: 1; }
.search-bar__input { width: 100%; padding: 10px 14px 10px 40px; font-family: var(--font-sans); font-size: 0.95rem; border: 1.5px solid var(--color-border); border-radius: var(--radius-sm); background: #FFF; color: var(--color-text); outline: none; }
.search-bar__input:focus { border-color: var(--color-primary); }

.search-result-item { display: flex; align-items: center; gap: 14px; padding: 12px 0; border-bottom: 1px solid var(--color-border); }
.search-result-item:last-child { border-bottom: none; }
.spine-cat { width: 4px; height: 40px; border-radius: 2px; flex-shrink: 0; }
.cat-计算机 { background: #546E7A; } .cat-数学 { background: #2E7D32; } .cat-物理 { background: #7B1FA2; }
.cat-人工智能 { background: #1565C0; } .cat-英语 { background: #E65100; } .cat-文学 { background: #F57C00; }
.cat-other { background: #8D6E63; }
.search-result-info { flex: 1; display: flex; flex-direction: column; gap: 2px; font-size: 0.85rem; }

/* Admin */
.borrow-card { max-width: 560px; margin: 0 auto; text-align: center; padding: 40px; }
.borrow-card__icon { font-size: 3rem; margin-bottom: 16px; }
.borrow-form { display: flex; gap: 12px; margin-top: 24px; justify-content: center; }
.borrow-input { max-width: 280px; text-align: center; font-size: 1.1rem; font-family: var(--font-mono); }

.reader-preview { display: flex; align-items: center; justify-content: center; gap: 12px; padding: 8px 0; flex-wrap: wrap; }

.app-list { display: flex; flex-direction: column; gap: 12px; }
.app-item { padding: 0; overflow: hidden; }
.app-item__body { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; gap: 16px; }
.app-item__info h4 { margin-bottom: 4px; font-size: 1rem; }
.app-item__meta { display: flex; gap: 12px; font-size: 0.8rem; color: var(--color-text-secondary); flex-wrap: wrap; }
.app-item__actions { display: flex; gap: 8px; flex-shrink: 0; }
</style>
