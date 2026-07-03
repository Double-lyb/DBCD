<script setup>
// ============================================================
// OverdueView.vue — 超期未还清单（催还通知单风格）
// ============================================================
import { ref, onMounted } from 'vue'
import api from '../api/index.js'

const overdueList = ref([])
const loading = ref(true)

onMounted(async () => {
  try {
    const res = await api.get('/borrow/overdue')
    overdueList.value = res.data || []
  } catch { overdueList.value = [] }
  finally { loading.value = false }
})

function fineEstimate(days) {
  // 当前罚金 0.5 元/天
  return (days * 0.5).toFixed(2)
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">超期未还清单</h1>

    <div v-if="loading" class="loading-center">
      <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">正在整理催还清单...</span></div>
    </div>

    <div v-else-if="overdueList.length === 0" class="empty-state">
      <div class="empty-state__icon">✓</div>
      <p class="empty-state__text">
        太棒了！<br>目前没有超期未还的图书，<br>所有读者都很守时
      </p>
    </div>

    <template v-else>
      <!-- 统计概览 -->
      <div class="overdue-summary mb-4">
        <div class="overdue-summary__item">
          <span class="text-serif" style="font-size:1.8rem;font-weight:700;color:var(--color-danger)">{{ overdueList.length }}</span>
          <span class="text-muted">本超期未还</span>
        </div>
        <div class="overdue-summary__item">
          <span class="text-serif" style="font-size:1.8rem;font-weight:700;color:var(--color-warning)">
            ¥{{ overdueList.reduce((s, o) => s + (o.overdue_days || 0) * 0.5, 0).toFixed(2) }}
          </span>
          <span class="text-muted">预估罚金</span>
        </div>
      </div>

      <!-- 催还通知单列表 -->
      <div class="overdue-notices">
        <div v-for="item in overdueList" :key="item.borrow_id" class="overdue-notice">
          <div class="overdue-notice__header">
            <div class="overdue-notice__days">
              <span class="overdue-notice__days-num">{{ item.overdue_days }}</span>
              <span class="overdue-notice__days-label">天超期</span>
            </div>
            <span class="tag tag-danger">催还通知</span>
          </div>

          <div class="overdue-notice__body">
            <div class="overdue-notice__row">
              <span class="overdue-notice__label">读者</span>
              <span>{{ item.reader_name }} · {{ item.reader_type === 'teacher' ? '教师' : '学生' }}</span>
            </div>
            <div class="overdue-notice__row">
              <span class="overdue-notice__label">图书</span>
              <span>{{ item.title }}</span>
            </div>
            <div class="overdue-notice__row">
              <span class="overdue-notice__label">ISBN</span>
              <span class="text-mono">{{ item.isbn || '-' }}</span>
            </div>
            <div class="overdue-notice__timeline">
              <div class="timeline-point timeline-point--start">
                <span class="timeline-date">{{ item.borrow_date }}</span>
                <span class="timeline-label">借阅日期</span>
              </div>
              <div class="timeline-bar"></div>
              <div class="timeline-point timeline-point--end">
                <span class="timeline-date text-danger">{{ item.due_date }}</span>
                <span class="timeline-label">应还日期</span>
              </div>
            </div>
            <div class="overdue-notice__fine">
              预估罚金：<span class="text-serif" style="font-size:1.3rem;font-weight:700;color:var(--color-danger)">
                ¥{{ fineEstimate(item.overdue_days) }}
              </span>
              <span class="text-muted">（{{ item.overdue_days }} × ¥0.50/天）</span>
            </div>
          </div>

          <div class="overdue-notice__footer">
            <span class="overdue-notice__stamp">逾期</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.overdue-summary {
  display: flex;
  gap: 24px;
}
.overdue-summary__item {
  display: flex; flex-direction: column;
  padding: 16px 24px;
  background: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  min-width: 150px;
}

/* 催还通知单 */
.overdue-notices {
  display: grid;
  gap: 20px;
}

.overdue-notice {
  background: var(--color-card);
  border: 1px solid var(--color-danger-light);
  border-radius: var(--radius-md);
  overflow: hidden;
  position: relative;
  box-shadow: var(--shadow-sm);
}

.overdue-notice::before {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 4px;
  background: var(--color-danger);
}

.overdue-notice__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  background: rgba(198, 40, 40, 0.04);
  border-bottom: 1px dashed var(--color-danger-light);
}

.overdue-notice__days {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.overdue-notice__days-num {
  font-family: var(--font-serif);
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--color-danger);
  line-height: 1;
}

.overdue-notice__days-label {
  font-family: var(--font-serif);
  color: var(--color-danger);
  font-size: 0.9rem;
}

.overdue-notice__body {
  padding: 16px 20px;
}

.overdue-notice__row {
  display: flex;
  gap: 12px;
  padding: 4px 0;
  font-size: 0.9rem;
}

.overdue-notice__label {
  min-width: 50px;
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}

/* 时间线 */
.overdue-notice__timeline {
  display: flex;
  align-items: center;
  gap: 0;
  margin: 16px 0;
  padding: 8px 0;
}

.timeline-point {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  min-width: 100px;
}

.timeline-date {
  font-family: var(--font-mono);
  font-size: 0.85rem;
  font-weight: 600;
}

.timeline-label {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.timeline-bar {
  flex: 1;
  height: 2px;
  background: var(--color-danger-light);
  margin: 0 8px;
  position: relative;
}

.timeline-bar::before,
.timeline-bar::after {
  content: '';
  position: absolute;
  top: -3px;
  width: 8px; height: 8px;
  border-radius: 50%;
  background: var(--color-danger);
}

.timeline-bar::before { left: 0; }
.timeline-bar::after { right: 0; }

.overdue-notice__fine {
  padding: 10px 14px;
  background: rgba(198, 40, 40, 0.05);
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
}

.overdue-notice__footer {
  padding: 10px 20px;
  display: flex;
  justify-content: flex-end;
}

.overdue-notice__stamp {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  color: var(--color-danger);
  border: 2px solid var(--color-danger);
  padding: 4px 16px;
  border-radius: 4px;
  transform: rotate(-8deg);
  opacity: 0.7;
}
</style>
