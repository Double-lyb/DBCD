<script setup>
// ============================================================
// BookSpine.vue — 书脊式图书条目（书架上的书脊效果）
// ============================================================
defineProps({
  book: { type: Object, required: true },
  showActions: { type: Boolean, default: true },
  canEdit: { type: Boolean, default: false },  // 仅 admin/librarian 可编辑删除
})

defineEmits(['view', 'edit', 'delete'])

// 分类 → 书脊颜色映射
const categoryColors = {
  '计算机': '#546E7A',
  '数学': '#2E7D32',
  '物理': '#7B1FA2',
  '人工智能': '#1565C0',
  '英语': '#E65100',
  '文学': '#F57C00',
  '历史': '#795548',
  '经济': '#00838F',
  '法律': '#6A1B9A',
  '艺术': '#AD1457',
}

function spineColor(category) {
  return categoryColors[category] || '#8D6E63'
}

function stockLevel(available, total) {
  if (available === 0) return 'empty'
  if (available < 3) return 'low'
  return 'normal'
}

function stockLabel(available, total) {
  if (available === 0) return '已借完'
  if (available < 3) return `仅剩 ${available} 本`
  return `${available} / ${total} 本`
}
</script>

<template>
  <div class="spine" :class="'spine--' + stockLevel(book.available_copies, book.total_copies)">
    <!-- 分类色条 -->
    <div
      class="spine__category-bar"
      :style="{ backgroundColor: spineColor(book.category) }"
    ></div>

    <!-- 主体信息 -->
    <div class="spine__body">
      <div class="spine__main">
        <h3 class="spine__title">{{ book.title }}</h3>
        <div class="spine__meta">
          <span class="spine__author">{{ book.author }}</span>
          <span class="spine__dot">·</span>
          <span class="spine__publisher">{{ book.publisher }}</span>
          <span class="spine__dot">·</span>
          <span class="spine__category-tag">{{ book.category }}</span>
        </div>
        <div class="spine__isbn text-mono text-muted">ISBN {{ book.isbn }}</div>
      </div>

      <!-- 右侧：库存 + 操作 -->
      <div class="spine__actions">
        <div class="spine__stock">
          <span class="spine__stock-num" :class="'text--' + stockLevel(book.available_copies, book.total_copies)">
            {{ stockLabel(book.available_copies, book.total_copies) }}
          </span>
          <span class="text-muted" style="font-size:0.8rem">¥{{ book.price }}</span>
        </div>
        <div v-if="showActions" class="spine__btns">
          <button class="btn btn-outline btn-sm" @click="$emit('view', book)">详情</button>
          <template v-if="canEdit">
            <button class="btn btn-outline btn-sm" @click="$emit('edit', book)">编辑</button>
            <button class="btn btn-ghost btn-sm text-danger" @click="$emit('delete', book)">删除</button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.spine {
  display: flex;
  background: var(--color-card);
  border-radius: var(--radius-sm);
  overflow: hidden;
  margin-bottom: 8px;
  border: 1px solid var(--color-border);
  transition: box-shadow 0.2s, transform 0.2s;
}

.spine:hover {
  box-shadow: var(--shadow-md);
  transform: translateX(2px);
}

.spine--empty {
  opacity: 0.65;
}

.spine--low {
  /* subtle orange left border indicator */
}

.spine__category-bar {
  width: 6px;
  flex-shrink: 0;
  border-radius: 0;
}

.spine__body {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  gap: 16px;
}

.spine__main {
  flex: 1;
  min-width: 0;
}

.spine__title {
  font-size: 1.05rem;
  margin-bottom: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.spine__meta {
  font-size: 0.82rem;
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.spine__dot {
  font-family: var(--font-serif);
}

.spine__category-tag {
  padding: 1px 6px;
  background: rgba(93, 64, 55, 0.06);
  border-radius: 3px;
  font-size: 0.78rem;
}

.spine__isbn {
  font-size: 0.75rem;
  margin-top: 2px;
}

.spine__actions {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-shrink: 0;
}

.spine__stock {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  min-width: 80px;
}

.spine__stock-num {
  font-family: var(--font-mono);
  font-size: 0.9rem;
  font-weight: 600;
}

.text--normal { color: var(--color-accent); }
.text--low {
  color: var(--color-warning);
  animation: pulse 2s ease-in-out infinite;
}
.text--empty { color: var(--color-danger); }

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.spine__btns {
  display: flex;
  gap: 4px;
}
</style>
