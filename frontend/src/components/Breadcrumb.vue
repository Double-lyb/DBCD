<script setup>
// ============================================================
// Breadcrumb.vue — 面包屑导航（图书馆楼层导视牌）
// ============================================================
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const crumbs = computed(() => {
  const items = [{ label: '首页', path: '/dashboard' }]
  const name = route.name
  const params = route.params

  const map = {
    Dashboard: null,
    Books: { label: '图书管理', path: '/books' },
    BookAdd: [
      { label: '图书管理', path: '/books' },
      { label: '新增图书', path: '' },
    ],
    BookDetail: [
      { label: '图书管理', path: '/books' },
      { label: params.isbn || '图书详情', path: '' },
    ],
    BookEdit: [
      { label: '图书管理', path: '/books' },
      { label: params.isbn || '编辑', path: '' },
      { label: '编辑图书', path: '' },
    ],
    Readers: { label: '读者管理', path: '/readers' },
    ReaderAdd: [
      { label: '读者管理', path: '/readers' },
      { label: '新增读者', path: '' },
    ],
    ReaderDetail: [
      { label: '读者管理', path: '/readers' },
      { label: params.id || '读者详情', path: '' },
    ],
    Borrow: { label: '借书操作', path: '/borrow' },
    Return: { label: '还书操作', path: '/return' },
    Overdue: { label: '超期清单', path: '/overdue' },
    Stats: { label: '统计报表', path: '/stats' },
    Fines: { label: '罚金管理', path: '/fines' },
    AdminLogs: { label: '操作日志', path: '/admin/logs' },
    AdminBackup: { label: '备份管理', path: '/admin/backup' },
  }

  const extra = map[name]
  if (!extra) return items
  if (Array.isArray(extra)) return items.concat(extra)
  return [...items, extra]
})
</script>

<template>
  <div class="breadcrumb" v-if="crumbs.length > 1">
    <div class="breadcrumb__inner">
      <template v-for="(crumb, i) in crumbs" :key="i">
        <span v-if="i > 0" class="breadcrumb__sep">/</span>
        <router-link
          v-if="crumb.path"
          :to="crumb.path"
          class="breadcrumb__link"
        >
          {{ crumb.label }}
        </router-link>
        <span v-else class="breadcrumb__current">{{ crumb.label }}</span>
      </template>
    </div>
  </div>
</template>

<style scoped>
.breadcrumb {
  background: var(--color-card);
  border-bottom: 1px solid var(--color-border);
}

.breadcrumb__inner {
  max-width: 1400px;
  margin: 0 auto;
  padding: 8px 32px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.85rem;
}

.breadcrumb__link {
  color: var(--color-primary-light);
  font-family: var(--font-serif);
}

.breadcrumb__link:hover {
  color: var(--color-primary);
}

.breadcrumb__current {
  color: var(--color-text);
  font-family: var(--font-serif);
  font-weight: 600;
}

.breadcrumb__sep {
  color: var(--color-border);
  font-family: var(--font-serif);
}
</style>
