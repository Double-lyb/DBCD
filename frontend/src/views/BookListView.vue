<script setup>
// ============================================================
// BookListView.vue — 图书管理（书脊式列表）
// ============================================================
import { ref, onMounted, watch, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'
import SearchBar from '../components/SearchBar.vue'
import BookSpine from '../components/BookSpine.vue'
import Pagination from '../components/Pagination.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const isStaff = computed(() => auth.isAdmin || auth.isLibrarian)

const books = ref([])
const loading = ref(true)
const page = ref(1)
const total = ref(0)
const pageSize = 10

const filters = ref({
  keyword: route.query.keyword || '',
  category: route.query.category || '',
  price_min: route.query.price_min || '',
  price_max: route.query.price_max || '',
})

const categories = ['计算机', '数学', '物理', '人工智能', '英语', '文学', '历史', '经济', '法律', '艺术']

async function fetchBooks() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    Object.entries(filters.value).forEach(([k, v]) => {
      if (v) params[k] = v
    })
    const res = await api.get('/books', { params })
    books.value = res.data || []
    total.value = res.total || 0
  } catch {
    books.value = []
  } finally {
    loading.value = false
  }
}

function onSearch(f) {
  filters.value = { ...f }
  page.value = 1
  const q = {}
  Object.entries(f).forEach(([k, v]) => { if (v) q[k] = v })
  router.replace({ query: q })
  fetchBooks() // 立即搜索，不依赖 watch(page)
}

function onReset() {
  filters.value = { keyword: '', category: '', price_min: '', price_max: '' }
  page.value = 1
  router.replace({ query: {} })
  fetchBooks()
}

function goToPage(p) {
  page.value = p
}

function viewBook(book) {
  router.push(`/books/${book.isbn}`)
}

function editBook(book) {
  router.push(`/books/${book.isbn}/edit`)
}

async function deleteBook(book) {
  if (!confirm(`确定要删除「${book.title}」吗？\n（系统会阻止删除有未还记录的图书）`)) return
  try {
    await api.delete(`/books/${book.isbn}`)
    books.value = books.value.filter(b => b.isbn !== book.isbn)
    total.value--
    showToast('删除成功', 'success')
  } catch (e) {
    showToast(e.message, 'error')
  }
}

// Toast
const toast = ref({ show: false, msg: '', type: 'success' })
function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}

watch(page, fetchBooks)
onMounted(fetchBooks)
</script>

<template>
  <div class="page">
    <div class="flex-between mb-4">
      <h1 class="page-title">图书管理</h1>
      <router-link
        v-if="auth.isAdmin || auth.isLibrarian"
        to="/books/add"
        class="btn btn-accent"
      >
        + 新增图书
      </router-link>
    </div>

    <!-- 搜索栏 -->
    <div class="card mb-4">
      <SearchBar
        :initial-keyword="filters.keyword"
        :initial-category="filters.category"
        :initial-price-min="filters.price_min"
        :initial-price-max="filters.price_max"
        :categories="categories"
        show-category
        show-price-range
        @search="onSearch"
        @reset="onReset"
      />
    </div>

    <!-- Toast -->
    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">
      {{ toast.msg }}
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-center">
      <div class="book-loader">
        <div class="book-loader__spine"></div>
        <span class="book-loader__text">正在浏览书架...</span>
      </div>
    </div>

    <!-- 空状态 -->
    <div v-else-if="books.length === 0" class="empty-state">
      <div class="empty-state__icon">📖</div>
      <p class="empty-state__text">
        书架上暂时没有{{ filters.keyword ? '匹配的' : '' }}书，<br>
        {{ filters.keyword ? '试试其他关键词？' : '去添加几本好书吧' }}
      </p>
    </div>

    <!-- 书脊列表 -->
    <template v-else>
      <BookSpine
        v-for="book in books"
        :key="book.isbn"
        :book="book"
        :can-edit="isStaff"
        @view="viewBook"
        @edit="editBook"
        @delete="deleteBook"
      />
      <Pagination :page="page" :page-size="pageSize" :total="total" @change="goToPage" />
    </template>
  </div>
</template>
