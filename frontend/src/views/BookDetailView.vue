<script setup>
// ============================================================
// BookDetailView.vue — 图书详情 + 借阅历史
// ============================================================
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const book = ref(null)
const loading = ref(true)
const notFound = ref(false)

// 分类颜色
const categoryColors = {
  '计算机': '#546E7A', '数学': '#2E7D32', '物理': '#7B1FA2',
  '人工智能': '#1565C0', '英语': '#E65100', '文学': '#F57C00',
  '历史': '#795548', '经济': '#00838F', '法律': '#6A1B9A', '艺术': '#AD1457',
}
function getCategoryColor(cat) { return categoryColors[cat] || '#8D6E63' }
function stockLevel(available, total) {
  if (available === 0) return 'empty'
  if (available < 3) return 'low'
  return 'normal'
}

onMounted(async () => {
  try {
    const res = await api.get(`/books/${route.params.isbn}`)
    book.value = res
  } catch {
    notFound.value = true
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page">
    <div v-if="loading" class="loading-center">
      <div class="book-loader">
        <div class="book-loader__spine"></div>
        <span class="book-loader__text">正在翻阅...</span>
      </div>
    </div>

    <div v-else-if="notFound" class="empty-state">
      <div class="empty-state__icon">🔍</div>
      <p class="empty-state__text">未找到该图书信息</p>
      <router-link to="/books" class="btn btn-outline mt-4">返回书架</router-link>
    </div>

    <template v-else-if="book">
      <h1 class="page-title">图书详情</h1>

      <div class="detail-grid">
        <div class="card detail-main">
          <div class="detail-header">
            <div class="detail-category-bar" :style="{ backgroundColor: getCategoryColor(book.category) }"></div>
            <div>
              <h2>{{ book.title }}</h2>
              <p class="text-muted">{{ book.author }} · {{ book.publisher }}</p>
            </div>
          </div>
          <div class="detail-info-grid">
            <div class="detail-info-item">
              <span class="detail-info-label">ISBN</span>
              <span class="text-mono">{{ book.isbn }}</span>
            </div>
            <div class="detail-info-item">
              <span class="detail-info-label">分类</span>
              <span>{{ book.category }}</span>
            </div>
            <div class="detail-info-item">
              <span class="detail-info-label">出版年份</span>
              <span>{{ book.publish_year }}</span>
            </div>
            <div class="detail-info-item">
              <span class="detail-info-label">馆藏位置</span>
              <span class="text-mono">{{ book.location }}</span>
            </div>
            <div class="detail-info-item">
              <span class="detail-info-label">单价</span>
              <span class="text-mono">¥{{ book.price }}</span>
            </div>
            <div class="detail-info-item">
              <span class="detail-info-label">馆藏 / 可借</span>
              <span>
                <span :class="book.available_copies === 0 ? 'text-danger' : book.available_copies < 3 ? 'text-warning' : 'text-accent'">
                  {{ book.available_copies }}
                </span>
                / {{ book.total_copies }}
              </span>
            </div>
          </div>
          <div class="detail-actions mt-4">
            <button v-if="auth.isAdmin || auth.isLibrarian" class="btn btn-outline" @click="router.push(`/books/${book.isbn}/edit`)">编辑图书</button>
            <button class="btn btn-ghost" @click="router.push('/books')">返回列表</button>
          </div>
        </div>

        <div class="card detail-sidebar">
          <h3>库存状态</h3>
          <div class="stock-indicator">
            <div class="stock-indicator__circle" :class="'stock--' + stockLevel(book.available_copies, book.total_copies)">
              {{ book.available_copies }}
            </div>
            <p class="stock-indicator__text">
              {{ book.available_copies === 0 ? '已全部借出' : book.available_copies < 3 ? '库存紧张' : '库存充足' }}
            </p>
          </div>
          <div class="progress-bar mt-4">
            <div
              class="progress-bar__fill"
              :class="'progress-bar__fill--' + (book.available_copies / book.total_copies > 0.5 ? 'safe' : book.available_copies / book.total_copies > 0 ? 'warn' : 'danger')"
              :style="{ width: (book.available_copies / book.total_copies * 100) + '%' }"
            ></div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.detail-grid { display: grid; grid-template-columns: 1fr 320px; gap: 20px; }
@media (max-width: 800px) { .detail-grid { grid-template-columns: 1fr; } }
.detail-header { display: flex; gap: 16px; margin-bottom: 24px; }
.detail-category-bar { width: 6px; border-radius: 3px; flex-shrink: 0; }
.detail-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.detail-info-item { display: flex; flex-direction: column; }
.detail-info-label { font-size: 0.78rem; color: var(--color-text-secondary); margin-bottom: 2px; }
.detail-actions { display: flex; gap: 8px; }
.detail-sidebar { text-align: center; }
.stock-indicator { display: flex; flex-direction: column; align-items: center; margin-top: 24px; }
.stock-indicator__circle {
  width: 80px; height: 80px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-serif); font-size: 2rem; font-weight: 700;
}
.stock--normal { background: #E8F5E9; color: #2E7D32; }
.stock--low { background: #FFF3E0; color: #E65100; }
.stock--empty { background: #FFEBEE; color: #C62828; }
.stock-indicator__text { margin-top: 12px; font-size: 0.9rem; color: var(--color-text-secondary); }
</style>
