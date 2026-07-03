<script setup>
// ============================================================
// FinesView.vue — 罚金管理
// ============================================================
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const auth = useAuthStore()

const rules = ref([])
const readerFines = ref([])
const loading = ref(true)

// Edit rule
const editingRule = ref(false)
const newFinePerDay = ref(0.5)
const saveLoading = ref(false)

// Reader search
const searchReaderId = ref('')
const searchLoading = ref(false)
const searchResult = ref(null)

onMounted(async () => {
  try {
    const res = await api.get('/fines/rules')
    rules.value = res.data || res || []
    if (rules.value.length > 0) {
      newFinePerDay.value = rules.value[0].fine_per_day || 0.5
    }
  } catch { /* ignore */ }
  loading.value = false
})

async function updateRule() {
  saveLoading.value = true
  try {
    await api.put('/fines/rules', { fine_per_day: newFinePerDay.value })
    editingRule.value = false
    showToast('罚金规则已更新', 'success')
    // Refresh
    const res = await api.get('/fines/rules')
    rules.value = res.data || res || []
  } catch (e) {
    showToast(e.message, 'error')
  } finally {
    saveLoading.value = false
  }
}

async function searchReaderFines() {
  if (!searchReaderId.value.trim()) return
  searchLoading.value = true
  try {
    const res = await api.get(`/fines/reader/${searchReaderId.value.trim()}`)
    searchResult.value = res
  } catch (e) {
    searchResult.value = { error: e.message }
  } finally {
    searchLoading.value = false
  }
}

const toast = ref({ show: false, msg: '', type: 'success' })
function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">罚金管理</h1>

    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">{{ toast.msg }}</div>

    <div class="fines-grid">
      <!-- 罚金规则 -->
      <div class="card">
        <div class="card-header">
          <h3>当前罚金规则</h3>
          <button
            v-if="auth.isAdmin && !editingRule"
            class="btn btn-outline btn-sm"
            @click="editingRule = true"
          >
            修改规则
          </button>
        </div>

        <div v-if="loading" class="loading-center" style="min-height:100px">
          <div class="book-loader"><div class="book-loader__spine"></div></div>
        </div>

        <template v-else>
          <div class="rule-display">
            <div class="rule-display__amount">
              <span class="text-serif" style="font-size:3rem;font-weight:700;color:var(--color-primary-dark)">¥{{ rules[0]?.fine_per_day || '0.50' }}</span>
              <span class="text-muted">/ 天</span>
            </div>
            <p class="text-muted" style="font-size:0.85rem">
              生效时间：{{ rules[0]?.effective_from || '-' }}
            </p>
          </div>

          <!-- 编辑模式 -->
          <div v-if="editingRule" class="edit-rule mt-4">
            <div class="form-group">
              <label class="form-label">每日罚金 (¥)</label>
              <input v-model.number="newFinePerDay" type="number" class="form-input" min="0.1" step="0.1" style="max-width:200px" />
            </div>
            <div style="display:flex;gap:8px">
              <button class="btn btn-accent btn-sm" :disabled="saveLoading" @click="updateRule">
                {{ saveLoading ? '保存中...' : '确认修改' }}
              </button>
              <button class="btn btn-ghost btn-sm" @click="editingRule = false; newFinePerDay = rules[0]?.fine_per_day || 0.5">取消</button>
            </div>
          </div>
        </template>
      </div>

      <!-- 按读者查询罚金 -->
      <div class="card">
        <h3>查询读者罚金</h3>
        <div class="search-bar mt-4">
          <input
            v-model="searchReaderId"
            type="text"
            class="form-input"
            placeholder="输入读者学工号"
            @keyup.enter="searchReaderFines"
          />
          <button class="btn btn-primary" :disabled="searchLoading" @click="searchReaderFines">
            {{ searchLoading ? '查询中...' : '查询' }}
          </button>
        </div>

        <div v-if="searchResult" class="mt-4">
          <div v-if="searchResult.error" class="form-error">{{ searchResult.error }}</div>
          <div v-else class="search-result">
            <div class="search-result__total">
              累计罚金：
              <span class="text-serif" style="font-size:1.5rem;font-weight:700" :class="(searchResult.total_fine || 0) > 0 ? 'text-danger' : 'text-accent'">
                ¥{{ searchResult.total_fine || '0.00' }}
              </span>
            </div>
            <div v-if="searchResult.data && searchResult.data.length > 0" class="mt-4">
              <table>
                <thead>
                  <tr><th>借阅编号</th><th>图书</th><th>超期天数</th><th>罚金</th></tr>
                </thead>
                <tbody>
                  <tr v-for="f in searchResult.data" :key="f.borrow_id">
                    <td class="text-mono">{{ f.borrow_id }}</td>
                    <td>{{ f.title }}</td>
                    <td class="text-danger">{{ f.overdue_days }} 天</td>
                    <td class="text-mono text-danger">¥{{ f.fine }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-else class="text-muted mt-4">该读者无罚金记录</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.fines-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
@media (max-width: 800px) { .fines-grid { grid-template-columns: 1fr; } }

.rule-display {
  text-align: center;
  padding: 32px 0;
}

.edit-rule {
  padding: 20px;
  background: rgba(93, 64, 55, 0.03);
  border-radius: var(--radius-sm);
}

.search-bar {
  display: flex;
  gap: 8px;
}

.search-result__total {
  padding: 16px;
  background: rgba(93, 64, 55, 0.03);
  border-radius: var(--radius-sm);
  text-align: center;
}
</style>
