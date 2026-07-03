<script setup>
// ============================================================
// BookFormView.vue — 新增/编辑图书表单
// ============================================================
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../api/index.js'

const route = useRoute()
const router = useRouter()

const isEdit = ref(false)
const loading = ref(false)
const submitLoading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const form = ref({
  isbn: '',
  title: '',
  author: '',
  publisher: '',
  total_copies: 1,
  price: 0,
  category: '',
  publish_year: new Date().getFullYear(),
  location: '',
})

const categories = ['计算机', '数学', '物理', '人工智能', '英语', '文学', '历史', '经济', '法律', '艺术', '其他']

onMounted(async () => {
  if (route.params.isbn) {
    isEdit.value = true
    loading.value = true
    try {
      const res = await api.get(`/books/${route.params.isbn}`)
      Object.assign(form.value, {
        isbn: res.isbn,
        title: res.title,
        author: res.author,
        publisher: res.publisher,
        total_copies: res.total_copies,
        price: res.price,
        category: res.category,
        publish_year: res.publish_year,
        location: res.location,
      })
    } catch {
      errorMsg.value = '加载图书信息失败'
    } finally {
      loading.value = false
    }
  }
})

async function submit() {
  submitLoading.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value) {
      await api.put(`/books/${route.params.isbn}`, form.value)
      successMsg.value = '图书信息更新成功'
    } else {
      await api.post('/books', form.value)
      successMsg.value = '新增图书成功'
      // 清空表单
      form.value = { isbn: '', title: '', author: '', publisher: '', total_copies: 1, price: 0, category: '', publish_year: new Date().getFullYear(), location: '' }
    }
    setTimeout(() => { successMsg.value = '' }, 2000)
  } catch (e) {
    errorMsg.value = e.message || '操作失败'
  } finally {
    submitLoading.value = false
  }
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">{{ isEdit ? '编辑图书' : '新增图书' }}</h1>

    <div v-if="loading" class="loading-center">
      <div class="book-loader"><div class="book-loader__spine"></div></div>
    </div>

    <div v-else class="card form-card">
      <p v-if="errorMsg" class="form-error mb-4">{{ errorMsg }}</p>
      <p v-if="successMsg" style="color:var(--color-accent);margin-bottom:16px">✓ {{ successMsg }}</p>

      <form @submit.prevent="submit">
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label">ISBN *</label>
            <input v-model="form.isbn" class="form-input" required :disabled="isEdit" placeholder="如 978-7-111-00000" />
          </div>
          <div class="form-group">
            <label class="form-label">书名 *</label>
            <input v-model="form.title" class="form-input" required placeholder="请输入书名" />
          </div>
          <div class="form-group">
            <label class="form-label">作者 *</label>
            <input v-model="form.author" class="form-input" required placeholder="请输入作者" />
          </div>
          <div class="form-group">
            <label class="form-label">出版社</label>
            <input v-model="form.publisher" class="form-input" placeholder="请输入出版社" />
          </div>
          <div class="form-group">
            <label class="form-label">分类</label>
            <select v-model="form.category" class="form-select">
              <option value="">请选择分类</option>
              <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">出版年份</label>
            <input v-model.number="form.publish_year" type="number" class="form-input" min="1900" :max="new Date().getFullYear()" />
          </div>
          <div class="form-group">
            <label class="form-label">馆藏数量</label>
            <input v-model.number="form.total_copies" type="number" class="form-input" min="1" />
          </div>
          <div class="form-group">
            <label class="form-label">单价 (¥)</label>
            <input v-model.number="form.price" type="number" class="form-input" min="0" step="0.01" />
          </div>
          <div class="form-group">
            <label class="form-label">馆藏位置</label>
            <input v-model="form.location" class="form-input" placeholder="如 A-01-01" />
          </div>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn btn-accent btn-lg" :disabled="submitLoading">
            {{ submitLoading ? '保存中...' : (isEdit ? '保存修改' : '新增图书') }}
          </button>
          <button type="button" class="btn btn-ghost" @click="router.push('/books')">取消</button>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.form-card { max-width: 800px; }
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 24px; }
@media (max-width: 600px) { .form-grid { grid-template-columns: 1fr; } }
.form-actions { display: flex; gap: 12px; margin-top: 24px; padding-top: 20px; border-top: 1px solid var(--color-border); }
</style>
