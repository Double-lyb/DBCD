<script setup>
// ============================================================
// DashboardView.vue — 仪表盘（图书馆前台登记台面）
// ============================================================
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import api from '../api/index.js'

const auth = useAuthStore()
const isStaff = computed(() => auth.isAdmin || auth.isLibrarian)
const loading = ref(true)

const summary = ref({
  currentBorrows: 0,
  overdueCount: 0,
  totalBooks: 0,
  totalReaders: 0,
})

const recentBorrows = ref([])
const overdueAlerts = ref([])

// 当前日期（日历翻页效果）
const today = computed(() => {
  const d = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return {
    year: d.getFullYear(),
    month: d.getMonth() + 1,
    day: d.getDate(),
    weekday: weekdays[d.getDay()],
  }
})

onMounted(async () => {
  try {
    const [borrowRes, booksRes, overdueRes] = await Promise.all([
      api.get('/stats/current-borrowings').catch(() => ({ total: 0, data: [] })),
      api.get('/books?page_size=1').catch(() => ({ total: 0 })),
      api.get('/borrow/overdue').catch(() => ({ data: [] })),
    ])

    summary.value.totalBooks = booksRes.total || 0

    // 读者数和读者统计仅管理员/图书管理员可访问
    if (isStaff.value) {
      try {
        const r = await api.get('/readers?page_size=1')
        summary.value.totalReaders = r.total || 0
      } catch { summary.value.totalReaders = 0 }
      summary.value.currentBorrows = borrowRes.total || 0
      recentBorrows.value = (borrowRes.data || []).slice(0, 5)
      overdueAlerts.value = (overdueRes.data || []).slice(0, 5)
      summary.value.overdueCount = overdueRes.data?.length || 0
    } else {
      // 读者只看自己的数据
      const rid = auth.user?.reader_id
      const myBorrows = (borrowRes.data || []).filter(b => b.reader_id === rid)
      const myOverdue = (overdueRes.data || []).filter(o => o.reader_id === rid)
      summary.value.currentBorrows = myBorrows.length
      recentBorrows.value = myBorrows.slice(0, 5)
      overdueAlerts.value = myOverdue.slice(0, 5)
      summary.value.overdueCount = myOverdue.length
    }
  } catch {
    // 静默处理
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page">
    <!-- 欢迎语 + 日期 -->
    <div class="dashboard-header">
      <div>
        <h1 class="page-title" style="margin-bottom:4px">欢迎回来，{{ auth.user?.username }}</h1>
        <p class="text-muted" style="font-family:var(--font-serif)">
          {{ auth.user?.role === 'admin' ? '管理员' : auth.user?.role === 'librarian' ? '图书管理员' : '读者' }}视图
        </p>
      </div>
      <div class="date-display">
        <div class="date-display__month">{{ today.month }} 月</div>
        <div class="date-display__day">{{ today.day }}</div>
        <div class="date-display__info">
          <div>{{ today.year }}</div>
          <div>星期{{ today.weekday }}</div>
        </div>
      </div>
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="loading-center">
      <div class="book-loader">
        <div class="book-loader__spine"></div>
        <span class="book-loader__text">正在整理书架...</span>
      </div>
    </div>

    <template v-else>
      <!-- 概览卡片 -->
      <div class="stats-grid">
        <div class="stat-card stat-card--borrow">
          <div class="stat-card__icon">↗</div>
          <div class="stat-card__num">{{ summary.currentBorrows }}</div>
          <div class="stat-card__label">{{ isStaff ? '当前借出' : '我的借阅' }}</div>
        </div>
        <div class="stat-card stat-card--overdue">
          <div class="stat-card__icon">⚠</div>
          <div class="stat-card__num text-danger">{{ summary.overdueCount }}</div>
          <div class="stat-card__label">{{ isStaff ? '超期未还' : '我的超期' }}</div>
        </div>
        <div class="stat-card stat-card--books">
          <div class="stat-card__icon">▣</div>
          <div class="stat-card__num">{{ summary.totalBooks }}</div>
          <div class="stat-card__label">馆藏总量</div>
        </div>
        <div v-if="isStaff" class="stat-card stat-card--readers">
          <div class="stat-card__icon">▥</div>
          <div class="stat-card__num">{{ summary.totalReaders }}</div>
          <div class="stat-card__label">注册读者</div>
        </div>
      </div>

      <!-- 下方两栏 -->
      <div class="dashboard-cols">
        <!-- 左：最近借阅 -->
        <div class="card">
          <div class="card-header">
            <h3>{{ auth.isReader ? '我的借阅' : '最近借阅' }}</h3>
            <router-link v-if="isStaff" to="/borrow" class="btn btn-outline btn-sm">借书操作 →</router-link>
          </div>
          <div v-if="recentBorrows.length === 0" class="empty-state">
            <div class="empty-state__icon">📚</div>
            <p class="empty-state__text">暂无在借记录，<br>去书架看看有什么好书吧</p>
          </div>
          <table v-else>
            <thead>
              <tr>
                <th>读者</th>
                <th>书名</th>
                <th>借阅日期</th>
                <th>应还日期</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="b in recentBorrows" :key="b.borrow_id">
                <td>{{ b.reader_name }}</td>
                <td>{{ b.title }}</td>
                <td class="text-mono">{{ b.borrow_date }}</td>
                <td class="text-mono">{{ b.due_date }}</td>
                <td>
                  <span :class="['tag', b.status === 'overdue' ? 'tag-danger' : b.status === 'borrowed' ? 'tag-info' : 'tag-success']">
                    {{ b.status === 'overdue' ? '已超期' : b.status === 'borrowed' ? '在借' : '已还' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- 右：超期提醒 -->
        <div class="card">
          <div class="card-header">
            <h3>⚠ 超期提醒</h3>
            <router-link to="/overdue" class="btn btn-outline btn-sm">查看全部 →</router-link>
          </div>
          <div v-if="overdueAlerts.length === 0" class="empty-state">
            <div class="empty-state__icon">✓</div>
            <p class="empty-state__text">太棒了！<br>目前没有超期未还的图书</p>
          </div>
          <div v-else class="overdue-list">
            <div v-for="o in overdueAlerts" :key="o.borrow_id" class="overdue-item">
              <div class="overdue-item__days">
                <span class="overdue-days">{{ o.overdue_days }}</span>
                <span class="overdue-days-label">天</span>
              </div>
              <div class="overdue-item__info">
                <div class="overdue-item__reader">{{ o.reader_name }} · {{ o.reader_type === 'teacher' ? '教师' : '学生' }}</div>
                <div class="overdue-item__book">{{ o.title }}</div>
                <div class="overdue-item__date text-muted">
                  {{ o.borrow_date }} → {{ o.due_date }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 管理员额外：操作日志摘要 -->
      <div v-if="auth.isAdmin" class="card mt-6">
        <div class="card-header">
          <h3>最近操作日志</h3>
          <router-link to="/admin/logs" class="btn btn-outline btn-sm">全部日志 →</router-link>
        </div>
        <p class="text-muted" style="padding:16px">操作日志详情请在系统管理页面查看</p>
      </div>
    </template>
  </div>
</template>

<style scoped>
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 28px;
  flex-wrap: wrap;
  gap: 16px;
}

/* 日期翻页效果 */
.date-display {
  display: flex;
  align-items: center;
  background: var(--color-card);
  border: 2px solid var(--color-primary);
  border-radius: var(--radius-md);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.date-display__month {
  background: var(--color-primary);
  color: #FFF8F0;
  padding: 12px 16px;
  font-family: var(--font-serif);
  font-size: 1.2rem;
  font-weight: 700;
  writing-mode: vertical-rl;
  letter-spacing: 0.1em;
}

.date-display__day {
  padding: 12px 20px;
  font-family: var(--font-serif);
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--color-primary-dark);
  line-height: 1;
}

.date-display__info {
  padding: 12px 16px 12px 0;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  line-height: 1.6;
}

/* 统计卡片 */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 28px;
}

@media (max-width: 800px) {
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}

.stat-card {
  background: var(--color-card);
  border-radius: var(--radius-md);
  padding: 24px;
  text-align: center;
  border: 1px solid var(--color-border);
  position: relative;
  overflow: hidden;
}

.stat-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
}

.stat-card--borrow::before { background: #42A5F5; }
.stat-card--overdue::before { background: var(--color-danger); }
.stat-card--books::before { background: var(--color-accent); }
.stat-card--readers::before { background: var(--color-primary); }

.stat-card__icon {
  font-size: 1.5rem;
  margin-bottom: 8px;
}

.stat-card__num {
  font-family: var(--font-serif);
  font-size: 2.2rem;
  font-weight: 700;
  color: var(--color-primary-dark);
  line-height: 1.2;
}

.stat-card__label {
  margin-top: 4px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

/* 两栏布局 */
.dashboard-cols {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

@media (max-width: 900px) {
  .dashboard-cols { grid-template-columns: 1fr; }
}

/* 超期列表 */
.overdue-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.overdue-item {
  display: flex;
  gap: 14px;
  padding: 12px;
  background: rgba(198, 40, 40, 0.04);
  border-radius: var(--radius-sm);
  border-left: 3px solid var(--color-danger);
}

.overdue-item__days {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 48px;
}

.overdue-days {
  font-family: var(--font-serif);
  font-size: 1.6rem;
  font-weight: 700;
  color: var(--color-danger);
  line-height: 1;
}

.overdue-days-label {
  font-size: 0.75rem;
  color: var(--color-danger);
}

.overdue-item__info {
  flex: 1;
  min-width: 0;
}

.overdue-item__reader {
  font-weight: 600;
  font-size: 0.9rem;
}

.overdue-item__book {
  font-size: 0.9rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.overdue-item__date {
  font-size: 0.8rem;
  margin-top: 2px;
}
</style>
