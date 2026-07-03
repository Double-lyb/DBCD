<script setup>
// ============================================================
// StatsView.vue — 统计报表（暖色调 Chart.js）
// ============================================================
import { ref, onMounted, computed } from 'vue'
import api from '../api/index.js'
import { Bar, Doughnut, Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale, LinearScale, BarElement,
  ArcElement,
  PointElement, LineElement,
  Title, Tooltip, Legend,
} from 'chart.js'

ChartJS.register(
  CategoryScale, LinearScale, BarElement,
  ArcElement,
  PointElement, LineElement,
  Title, Tooltip, Legend
)

const loading = ref(true)
const tab = ref('books')

const bookStats = ref([])
const readerStats = ref([])
const monthlyFines = ref([])

// 暖色调色盘
const warmColors = ['#5D4037', '#8D6E63', '#A1887F', '#2E7D32', '#C62828', '#E65100', '#1565C0', '#6A1B9A', '#00838F', '#F57C00']

onMounted(async () => {
  try {
    const [booksRes, readersRes, finesRes] = await Promise.all([
      api.get('/stats/books'),
      api.get('/stats/readers'),
      api.get('/stats/monthly-fines'),
    ])
    bookStats.value = booksRes.data || []
    readerStats.value = readersRes.data || []
    monthlyFines.value = (finesRes.data || []).reverse() // 正序时间轴
  } catch { /* ignore */ }
  loading.value = false
})

// 图书借阅热度（横向条形图）
const bookChartData = computed(() => ({
  labels: bookStats.value.slice(0, 10).map(b => b.title.length > 10 ? b.title.slice(0, 10) + '…' : b.title),
  datasets: [{
    label: '借阅次数',
    data: bookStats.value.slice(0, 10).map(b => b.total_borrow_times),
    backgroundColor: warmColors,
    borderColor: warmColors,
    borderWidth: 1,
    borderRadius: 4,
  }],
}))

const bookChartOptions = {
  indexAxis: 'y',
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    title: { display: true, text: '图书借阅热度排行', font: { family: 'Georgia, serif', size: 14 }, color: '#3E2723' },
  },
  scales: {
    x: { ticks: { color: '#8D6E63' }, grid: { color: '#D7CCC8' } },
    y: { ticks: { color: '#3E2723', font: { size: 11 } }, grid: { display: false } },
  },
}

// 读者借阅量（环形图）
const readerChartData = computed(() => ({
  labels: readerStats.value.slice(0, 8).map(r => r.name),
  datasets: [{
    label: '总借阅量',
    data: readerStats.value.slice(0, 8).map(r => r.total_borrow_count),
    backgroundColor: warmColors,
    borderColor: '#FFF8F0',
    borderWidth: 2,
  }],
}))

const readerChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { position: 'bottom', labels: { color: '#8D6E63', font: { size: 11 } } },
    title: { display: true, text: '读者借阅量分布', font: { family: 'Georgia, serif', size: 14 }, color: '#3E2723' },
  },
}

// 月度罚金趋势（折线图）
const fineChartData = computed(() => ({
  labels: monthlyFines.value.map(f => f.month?.substring(0, 7)),
  datasets: [
    {
      label: '罚金总额 (¥)',
      data: monthlyFines.value.map(f => parseFloat(f.total_fine)),
      borderColor: '#C62828',
      backgroundColor: 'rgba(198, 40, 40, 0.08)',
      fill: true,
      tension: 0.4,
      pointBackgroundColor: '#C62828',
      pointRadius: 4,
    },
    {
      label: '超期次数',
      data: monthlyFines.value.map(f => f.overdue_count),
      borderColor: '#E65100',
      backgroundColor: 'rgba(230, 81, 0, 0.05)',
      fill: true,
      tension: 0.4,
      pointBackgroundColor: '#E65100',
      pointRadius: 4,
      yAxisID: 'y1',
    },
  ],
}))

const fineChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  interaction: { mode: 'index', intersect: false },
  plugins: {
    title: { display: true, text: '月度罚金与超期趋势', font: { family: 'Georgia, serif', size: 14 }, color: '#3E2723' },
    legend: { labels: { color: '#8D6E63' } },
  },
  scales: {
    x: { ticks: { color: '#8D6E63' }, grid: { color: '#D7CCC8' } },
    y: {
      type: 'linear',
      display: true,
      position: 'left',
      title: { display: true, text: '罚金 (¥)', color: '#C62828' },
      ticks: { color: '#C62828' },
      grid: { color: '#D7CCC8' },
    },
    y1: {
      type: 'linear',
      display: true,
      position: 'right',
      title: { display: true, text: '超期次数', color: '#E65100' },
      ticks: { color: '#E65100' },
      grid: { drawOnChartArea: false },
    },
  },
}

</script>

<template>
  <div class="page">
    <h1 class="page-title">统计报表</h1>

    <!-- Tab 切换 -->
    <div class="tabs mb-4">
      <button :class="['tab', { 'tab--active': tab === 'books' }]" @click="tab = 'books'">借阅热度榜</button>
      <button :class="['tab', { 'tab--active': tab === 'readers' }]" @click="tab = 'readers'">读者统计</button>
      <button :class="['tab', { 'tab--active': tab === 'fines' }]" @click="tab = 'fines'">月度趋势</button>
    </div>

    <div v-if="loading" class="loading-center">
      <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">正在整理统计数据...</span></div>
    </div>

    <template v-else>
      <!-- 借阅热度榜 -->
      <div v-if="tab === 'books'" class="card">
        <div class="chart-container" style="height:400px">
          <Bar v-if="bookStats.length > 0" :data="bookChartData" :options="bookChartOptions" />
          <div v-else class="empty-state"><p class="empty-state__text">暂无图书借阅数据</p></div>
        </div>
      </div>

      <!-- 读者统计 -->
      <div v-if="tab === 'readers'" class="card">
        <div class="chart-container" style="height:400px">
          <Doughnut v-if="readerStats.length > 0" :data="readerChartData" :options="readerChartOptions" />
          <div v-else class="empty-state"><p class="empty-state__text">暂无读者统计数据</p></div>
        </div>
      </div>

      <!-- 月度罚金趋势 -->
      <div v-if="tab === 'fines'" class="card">
        <div class="chart-container" style="height:400px">
          <Line v-if="monthlyFines.length > 0" :data="fineChartData" :options="fineChartOptions" />
          <div v-else class="empty-state"><p class="empty-state__text">暂无月度罚金数据</p></div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.tabs {
  display: flex;
  gap: 4px;
  border-bottom: 2px solid var(--color-border);
  padding-bottom: 0;
}

.tab {
  padding: 10px 24px;
  background: transparent;
  border: none;
  font-family: var(--font-serif);
  font-size: 0.95rem;
  color: var(--color-text-secondary);
  cursor: pointer;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  transition: all 0.2s;
}

.tab:hover { color: var(--color-primary); }

.tab--active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
  font-weight: 600;
}

.chart-container {
  position: relative;
}
</style>
