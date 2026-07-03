<script setup>
// ============================================================
// ReaderListView.vue — 读者管理（借书证登记册风格）
// ============================================================
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/index.js'
import Pagination from '../components/Pagination.vue'

const router = useRouter()

const readers = ref([])
const loading = ref(true)
const keyword = ref('')
const page = ref(1)
const total = ref(0)
const pageSize = 10

const toast = ref({ show: false, msg: '', type: 'success' })

function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}

let debounce = null
function onSearch() {
  clearTimeout(debounce)
  debounce = setTimeout(() => { page.value = 1; fetchReaders() }, 300)
}

async function fetchReaders() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    if (keyword.value) params.keyword = keyword.value
    const res = await api.get('/readers', { params })
    readers.value = res.data || []
    total.value = res.total || 0
  } catch { readers.value = [] }
  finally { loading.value = false }
}

function goToReader(r) {
  router.push(`/readers/${r.reader_id}`)
}

watch(page, fetchReaders)
onMounted(fetchReaders)

// 借阅进度条颜色
function progressClass(current, max) {
  if (current >= max) return 'danger'
  if (current >= max * 0.8) return 'warn'
  return 'safe'
}
</script>

<template>
  <div class="page">
    <div class="flex-between mb-4">
      <h1 class="page-title">读者管理</h1>
      <router-link to="/readers/add" class="btn btn-accent">+ 新增读者</router-link>
    </div>

    <!-- 搜索 -->
    <div class="card mb-4">
      <div class="search-bar">
        <div class="search-bar__main">
          <span class="search-bar__icon">⌕</span>
          <input v-model="keyword" type="text" class="search-bar__input" placeholder="搜索读者姓名或学工号..." @input="onSearch" />
        </div>
      </div>
    </div>

    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">{{ toast.msg }}</div>

    <div v-if="loading" class="loading-center">
      <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">正在查阅登记册...</span></div>
    </div>

    <div v-else-if="readers.length === 0" class="empty-state">
      <div class="empty-state__icon">📋</div>
      <p class="empty-state__text">登记册上暂无读者记录</p>
    </div>

    <template v-else>
      <!-- 借书证条目列表 -->
      <div v-for="reader in readers" :key="reader.reader_id" class="reader-card" @click="goToReader(reader)">
        <div class="reader-card__avatar" :class="'avatar--' + (reader.reader_type === 'teacher' ? 'teacher' : 'student')">
          {{ reader.name.charAt(0) }}
        </div>
        <div class="reader-card__info">
          <div class="reader-card__name">
            {{ reader.name }}
            <span class="tag" :class="reader.reader_type === 'teacher' ? 'tag-info' : 'tag-success'">
              {{ reader.reader_type === 'teacher' ? '教师' : '学生' }}
            </span>
            <span v-if="reader.status === 'disabled'" class="tag tag-danger">已禁用</span>
          </div>
          <div class="reader-card__meta">
            <span>{{ reader.reader_id }}</span>
            <span class="spine__dot">·</span>
            <span>{{ reader.department }}</span>
          </div>
        </div>
        <div class="reader-card__borrow">
          <div class="reader-card__borrow-num">
            {{ reader.current_borrow_count ?? 0 }} / {{ reader.max_borrow_count ?? 10 }}
          </div>
          <div class="progress-bar" style="width:120px">
            <div
              class="progress-bar__fill"
              :class="'progress-bar__fill--' + progressClass(reader.current_borrow_count ?? 0, reader.max_borrow_count ?? 10)"
              :style="{ width: ((reader.current_borrow_count ?? 0) / (reader.max_borrow_count ?? 10) * 100) + '%' }"
            ></div>
          </div>
          <span class="text-muted" style="font-size:0.75rem">已借 / 限额</span>
        </div>
      </div>
      <Pagination :page="page" :page-size="pageSize" :total="total" @change="p => { page = p }" />
    </template>
  </div>
</template>

<style scoped>
.reader-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
  background: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  margin-bottom: 8px;
  cursor: pointer;
  transition: box-shadow 0.2s, transform 0.2s;
}
.reader-card:hover { box-shadow: var(--shadow-md); transform: translateX(2px); }

.reader-card__avatar {
  width: 44px; height: 44px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-serif);
  font-size: 1.2rem; font-weight: 700;
  color: #FFF;
  flex-shrink: 0;
}
.avatar--student { background: var(--color-accent); }
.avatar--teacher { background: #1565C0; }

.reader-card__info { flex: 1; min-width: 0; }
.reader-card__name { display: flex; align-items: center; gap: 8px; font-weight: 600; margin-bottom: 2px; }
.reader-card__meta { font-size: 0.82rem; color: var(--color-text-secondary); display: flex; align-items: center; gap: 4px; }

.reader-card__borrow {
  display: flex; flex-direction: column; align-items: center;
  gap: 4px; flex-shrink: 0;
}
.reader-card__borrow-num { font-family: var(--font-mono); font-size: 0.9rem; font-weight: 600; }

/* reuse search bar style from global */
.search-bar { display: flex; align-items: center; }
.search-bar__main { position: relative; flex: 1; }
.search-bar__icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); font-size: 1.1rem; color: var(--color-text-secondary); }
.search-bar__input {
  width: 100%; padding: 10px 40px 10px 40px; font-family: var(--font-sans); font-size: 0.95rem;
  border: 1.5px solid var(--color-border); border-radius: var(--radius-sm); background: #FFF;
  color: var(--color-text); outline: none; transition: border-color 0.2s;
}
.search-bar__input:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(93, 64, 55, 0.08); }
</style>
