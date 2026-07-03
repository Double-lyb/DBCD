<script setup>
// ============================================================
// ReaderDetailView.vue — 读者详情 / 新增读者
// ============================================================
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const isNew = computed(() => !route.params.id || route.params.id === 'add')
const isSelf = computed(() => auth.isReader && auth.user?.reader_id === route.params.id)

const reader = ref(null)
const loading = ref(false)
const submitLoading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')
const currentBorrows = ref([])

const form = ref({
  reader_id: '',
  name: '',
  reader_type_id: 1,
  department: '',
  phone: '',
  email: '',
  password: 'reader123',
})

onMounted(async () => {
  if (isNew.value) return

  loading.value = true
  try {
    const res = await api.get(`/readers/${route.params.id}`)
    reader.value = res
    Object.assign(form.value, {
      reader_id: res.reader_id,
      name: res.name,
      reader_type_id: res.reader_type_id || 1,
      department: res.department || '',
      phone: res.phone || '',
      email: res.email || '',
    })

    // 加载当前借阅
    try {
      const br = await api.get(`/borrow/current/${route.params.id}`)
      currentBorrows.value = br.data || []
    } catch { currentBorrows.value = [] }
  } catch {
    errorMsg.value = '加载读者信息失败'
  } finally {
    loading.value = false
  }
})

async function submit() {
  submitLoading.value = true
  errorMsg.value = ''
  try {
    if (isNew.value) {
      await api.post('/readers', form.value)
      successMsg.value = '新增读者成功'
      router.push('/readers')
    } else {
      await api.put(`/readers/${route.params.id}`, form.value)
      successMsg.value = '读者信息已更新'
    }
  } catch (e) {
    errorMsg.value = e.message || '操作失败'
  } finally {
    submitLoading.value = false
  }
}

function progressClass(current, max) {
  if (!max) return 'safe'
  if (current >= max) return 'danger'
  if (current >= max * 0.8) return 'warn'
  return 'safe'
}
</script>

<template>
  <div class="page">
    <!-- 新增读者模式 -->
    <template v-if="isNew">
      <h1 class="page-title">新增读者</h1>
      <div class="card form-card">
        <p v-if="errorMsg" class="form-error mb-4">{{ errorMsg }}</p>
        <form @submit.prevent="submit">
          <div class="form-grid">
            <div class="form-group">
              <label class="form-label">学工号 *</label>
              <input v-model="form.reader_id" class="form-input" required placeholder="如 20210001" />
            </div>
            <div class="form-group">
              <label class="form-label">姓名 *</label>
              <input v-model="form.name" class="form-input" required placeholder="请输入姓名" />
            </div>
            <div class="form-group">
              <label class="form-label">读者类型</label>
              <select v-model.number="form.reader_type_id" class="form-select">
                <option :value="1">学生（限额10本/30天）</option>
                <option :value="2">教师（限额15本/60天）</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">院系</label>
              <input v-model="form.department" class="form-input" placeholder="请输入院系" />
            </div>
            <div class="form-group">
              <label class="form-label">手机号（加密存储）</label>
              <input v-model="form.phone" class="form-input" placeholder="请输入手机号" />
            </div>
            <div class="form-group">
              <label class="form-label">邮箱（加密存储）</label>
              <input v-model="form.email" class="form-input" placeholder="请输入邮箱" />
            </div>
            <div class="form-group">
              <label class="form-label">登录密码</label>
              <input v-model="form.password" class="form-input" type="password" placeholder="默认 reader123" />
            </div>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn btn-accent btn-lg" :disabled="submitLoading">
              {{ submitLoading ? '保存中...' : '新增读者' }}
            </button>
            <button type="button" class="btn btn-ghost" @click="router.push('/readers')">取消</button>
          </div>
        </form>
      </div>
    </template>

    <!-- 读者详情模式 -->
    <template v-else>
      <h1 class="page-title">读者详情</h1>

      <div v-if="loading" class="loading-center">
        <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">正在翻阅登记册...</span></div>
      </div>

      <template v-else-if="reader">
        <p v-if="errorMsg" class="form-error mb-4">{{ errorMsg }}</p>
        <p v-if="successMsg" style="color:var(--color-accent);margin-bottom:16px">✓ {{ successMsg }}</p>

        <div class="detail-grid">
          <!-- 基本信息 -->
          <div class="card">
            <div class="reader-header">
              <div class="reader-avatar" :class="'avatar--' + (reader.reader_type === 'teacher' ? 'teacher' : 'student')">
                {{ reader.name?.charAt(0) }}
              </div>
              <div>
                <h2>{{ reader.name }}</h2>
                <p class="text-muted">{{ reader.reader_id }} · {{ reader.reader_type === 'teacher' ? '教师' : '学生' }}</p>
              </div>
              <span :class="['tag', reader.status === 'active' ? 'tag-success' : 'tag-danger']">
                {{ reader.status === 'active' ? '正常' : '已禁用' }}
              </span>
            </div>

            <div class="detail-info-grid">
              <div class="detail-info-item">
                <span class="detail-info-label">院系</span>
                <span>{{ reader.department || '-' }}</span>
              </div>
              <div class="detail-info-item">
                <span class="detail-info-label">借阅限额</span>
                <span>{{ reader.current_borrow_count ?? 0 }} / {{ reader.max_borrow_count ?? 10 }} 本</span>
              </div>
              <div class="detail-info-item" v-if="auth.isAdmin || isSelf">
                <span class="detail-info-label">手机号</span>
                <span class="text-mono">{{ reader.phone || '(未填写)' }}</span>
              </div>
              <div class="detail-info-item" v-if="auth.isAdmin || isSelf">
                <span class="detail-info-label">邮箱</span>
                <span>{{ reader.email || '(未填写)' }}</span>
              </div>
              <div class="detail-info-item">
                <span class="detail-info-label">账户状态</span>
                <span>{{ reader.status === 'active' ? '正常' : '已禁用' }}</span>
              </div>
              <div class="detail-info-item">
                <span class="detail-info-label">累计借阅</span>
                <span>{{ reader.total_borrow_count ?? 0 }} 次</span>
              </div>
            </div>

            <div class="detail-actions mt-4">
              <button v-if="auth.isAdmin || auth.isLibrarian" class="btn btn-outline" @click="router.push(`/readers/${reader.reader_id}/edit`)">编辑信息</button>
              <button class="btn btn-ghost" @click="router.push('/readers')">返回列表</button>
            </div>
          </div>

          <!-- 借阅概况 -->
          <div class="card detail-sidebar">
            <h3>借阅概况</h3>
            <div class="borrow-limit-indicator">
              <div class="borrow-limit-num">
                <span class="text-serif" style="font-size:2rem;font-weight:700">{{ reader.current_borrow_count ?? 0 }}</span>
                <span style="font-size:1rem"> / {{ reader.max_borrow_count ?? 10 }}</span>
              </div>
              <div class="progress-bar mt-2">
                <div
                  class="progress-bar__fill"
                  :class="'progress-bar__fill--' + progressClass(reader.current_borrow_count ?? 0, reader.max_borrow_count ?? 10)"
                  :style="{ width: ((reader.current_borrow_count ?? 0) / (reader.max_borrow_count ?? 10) * 100) + '%' }"
                ></div>
              </div>
            </div>

            <div v-if="currentBorrows.length > 0" class="mt-4">
              <h4 style="font-size:0.9rem;margin-bottom:8px">当前借阅 ({{ currentBorrows.length }})</h4>
              <div v-for="b in currentBorrows" :key="b.borrow_id" class="current-borrow-item">
                <div class="current-borrow-title">{{ b.title }}</div>
                <div class="text-muted" style="font-size:0.78rem">
                  {{ b.borrow_date }} → {{ b.due_date }}
                  <span v-if="b.overdue_days > 0" class="text-danger">（超期 {{ b.overdue_days }} 天）</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<style scoped>
.form-card { max-width: 800px; }
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 24px; }
@media (max-width: 600px) { .form-grid { grid-template-columns: 1fr; } }
.form-actions { display: flex; gap: 12px; margin-top: 24px; padding-top: 20px; border-top: 1px solid var(--color-border); }

.detail-grid { display: grid; grid-template-columns: 1fr 320px; gap: 20px; }
@media (max-width: 800px) { .detail-grid { grid-template-columns: 1fr; } }

.reader-header { display: flex; align-items: center; gap: 16px; margin-bottom: 24px; }
.reader-avatar {
  width: 56px; height: 56px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-serif); font-size: 1.6rem; font-weight: 700;
  color: #FFF;
}
.avatar--student { background: var(--color-accent); }
.avatar--teacher { background: #1565C0; }

.detail-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.detail-info-item { display: flex; flex-direction: column; }
.detail-info-label { font-size: 0.78rem; color: var(--color-text-secondary); margin-bottom: 2px; }
.detail-actions { display: flex; gap: 8px; }

.detail-sidebar { text-align: center; }
.borrow-limit-indicator { margin-top: 20px; }
.borrow-limit-num { font-family: var(--font-serif); }

.current-borrow-item {
  text-align: left;
  padding: 10px;
  background: rgba(93, 64, 55, 0.03);
  border-radius: var(--radius-sm);
  margin-bottom: 6px;
}
.current-borrow-title { font-size: 0.85rem; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
