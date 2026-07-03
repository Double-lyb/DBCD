<script setup>
// ============================================================
// AdminLogsView.vue — 操作日志
// ============================================================
import { ref, onMounted, watch } from 'vue'
import api from '../api/index.js'
import Pagination from '../components/Pagination.vue'

const logs = ref([])
const loading = ref(true)
const page = ref(1)
const total = ref(0)
const pageSize = 20

const filterType = ref('')
const filterTable = ref('')

const operationTypes = ['INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'BACKUP']
const tableNames = ['books', 'readers', 'borrow_records', 'users', 'fine_rules', 'backup_records']

async function fetchLogs() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    if (filterType.value) params.operation_type = filterType.value
    if (filterTable.value) params.table_name = filterTable.value
    const res = await api.get('/admin/logs', { params })
    logs.value = res.data || []
    total.value = res.total || 0
  } catch { logs.value = [] }
  finally { loading.value = false }
}

watch([page, filterType, filterTable], fetchLogs)
onMounted(fetchLogs)

function typeTag(type) {
  const map = { INSERT: 'tag-success', UPDATE: 'tag-info', DELETE: 'tag-danger', LOGIN: 'tag-default', BACKUP: 'tag-warning' }
  return map[type] || 'tag-default'
}
</script>

<template>
  <div class="page">
    <h1 class="page-title">操作日志</h1>

    <!-- 筛选 -->
    <div class="card mb-4">
      <div class="filters">
        <select v-model="filterType" class="form-select" style="max-width:160px">
          <option value="">全部操作类型</option>
          <option v-for="t in operationTypes" :key="t" :value="t">{{ t }}</option>
        </select>
        <select v-model="filterTable" class="form-select" style="max-width:160px">
          <option value="">全部表</option>
          <option v-for="t in tableNames" :key="t" :value="t">{{ t }}</option>
        </select>
        <button v-if="filterType || filterTable" class="btn btn-ghost btn-sm" @click="filterType = ''; filterTable = ''; page = 1">
          清除筛选
        </button>
      </div>
    </div>

    <div v-if="loading" class="loading-center">
      <div class="book-loader"><div class="book-loader__spine"></div><span class="book-loader__text">正在查阅审计日志...</span></div>
    </div>

    <div v-else-if="logs.length === 0" class="empty-state">
      <div class="empty-state__icon">📜</div>
      <p class="empty-state__text">暂无操作日志记录</p>
    </div>

    <template v-else>
      <div class="card">
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>编号</th>
                <th>用户</th>
                <th>操作类型</th>
                <th>表名</th>
                <th>记录ID</th>
                <th>IP地址</th>
                <th>时间</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in logs" :key="log.log_id">
                <td class="text-mono" style="font-size:0.8rem">{{ log.log_id }}</td>
                <td>{{ log.user_id }}</td>
                <td><span :class="['tag', typeTag(log.operation_type)]">{{ log.operation_type }}</span></td>
                <td class="text-mono" style="font-size:0.82rem">{{ log.table_name || '-' }}</td>
                <td class="text-mono" style="font-size:0.82rem">{{ log.record_id || '-' }}</td>
                <td class="text-mono" style="font-size:0.82rem">{{ log.ip_address || '-' }}</td>
                <td class="text-mono" style="font-size:0.82rem">{{ log.created_at }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <Pagination :page="page" :page-size="pageSize" :total="total" @change="p => { page = p }" />
      </div>
    </template>
  </div>
</template>

<style scoped>
.filters {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}
</style>
