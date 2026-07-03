<script setup>
// ============================================================
// Pagination.vue — 分页组件
// ============================================================
import { computed } from 'vue'

const props = defineProps({
  page: { type: Number, default: 1 },
  pageSize: { type: Number, default: 10 },
  total: { type: Number, default: 0 },
})

const emit = defineEmits(['change'])

const totalPages = computed(() => Math.max(1, Math.ceil(props.total / props.pageSize)))

const showPages = computed(() => {
  const pages = []
  const total = totalPages.value
  const current = props.page

  let start = Math.max(1, current - 2)
  let end = Math.min(total, current + 2)

  if (end - start < 4) {
    if (start === 1) end = Math.min(total, start + 4)
    else start = Math.max(1, end - 4)
  }

  if (start > 1) pages.push(1)
  if (start > 2) pages.push('...')
  for (let i = start; i <= end; i++) pages.push(i)
  if (end < total - 1) pages.push('...')
  if (end < total) pages.push(total)

  return pages
})

function goTo(p) {
  if (p === '...' || p === props.page) return
  emit('change', p)
}
</script>

<template>
  <div class="pagination" v-if="totalPages > 1">
    <span class="pagination__info text-muted">
      共 {{ total }} 条，第 {{ page }} / {{ totalPages }} 页
    </span>
    <div class="pagination__pages">
      <button
        class="pagination__btn"
        :disabled="page <= 1"
        @click="goTo(page - 1)"
      >
        ‹
      </button>
      <button
        v-for="p in showPages"
        :key="p"
        :class="['pagination__btn', { 'pagination__btn--active': p === page, 'pagination__btn--ellipsis': p === '...' }]"
        :disabled="p === '...'"
        @click="goTo(p)"
      >
        {{ p }}
      </button>
      <button
        class="pagination__btn"
        :disabled="page >= totalPages"
        @click="goTo(page + 1)"
      >
        ›
      </button>
    </div>
  </div>
</template>

<style scoped>
.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0;
  flex-wrap: wrap;
  gap: 12px;
}

.pagination__info {
  font-size: 0.85rem;
  font-family: var(--font-serif);
}

.pagination__pages {
  display: flex;
  gap: 4px;
}

.pagination__btn {
  min-width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--color-border);
  background: var(--color-card);
  color: var(--color-text);
  font-family: var(--font-serif);
  font-size: 0.9rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.15s;
}

.pagination__btn:hover:not(:disabled) {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.pagination__btn--active {
  background: var(--color-primary);
  border-color: var(--color-primary);
  color: #FFF8F0;
}

.pagination__btn--ellipsis {
  border: none;
  background: transparent;
  cursor: default;
}

.pagination__btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
</style>
