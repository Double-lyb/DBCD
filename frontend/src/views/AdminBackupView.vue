<script setup>
// ============================================================
// AdminBackupView.vue — 备份管理
// ============================================================
import { ref, onMounted } from 'vue'
import api from '../api/index.js'

const backups = ref([])
const loading = ref(true)
const backupLoading = ref('') // 'full' | 'diff' | ''

const toast = ref({ show: false, msg: '', type: 'success' })

function showToast(msg, type = 'success') {
  toast.value = { show: true, msg, type }
  setTimeout(() => { toast.value.show = false }, 4000)
}

async function fetchBackups() {
  loading.value = true
  try {
    const res = await api.get('/admin/backup-records')
    backups.value = res.data || []
  } catch { backups.value = [] }
  finally { loading.value = false }
}

async function runBackup(type) {
  backupLoading.value = type
  try {
    const endpoint = type === 'full' ? '/admin/backup/full' : '/admin/backup/diff'
    const res = await api.post(endpoint)
    showToast(`${type === 'full' ? '全量' : '差异'}备份成功！文件: ${res.file}`)
    await fetchBackups()
  } catch (e) {
    showToast(e.message || '备份失败', 'error')
  } finally {
    backupLoading.value = ''
  }
}

function formatSize(bytes) {
  if (!bytes) return '-'
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(2) + ' MB'
}

onMounted(fetchBackups)
</script>

<template>
  <div class="page">
    <h1 class="page-title">备份管理</h1>

    <div v-if="toast.show" :class="['toast', 'toast-' + toast.type]">{{ toast.msg }}</div>

    <!-- 备份操作 -->
    <div class="card mb-4">
      <h3>数据库备份</h3>
      <p class="text-muted mt-2">备份文件将保存在服务器 backup 目录中</p>
      <div class="backup-actions mt-4">
        <button
          class="btn btn-accent btn-lg"
          :disabled="backupLoading === 'full'"
          @click="runBackup('full')"
        >
          {{ backupLoading === 'full' ? '正在备份...' : '立即全量备份' }}
        </button>
        <button
          class="btn btn-outline btn-lg"
          :disabled="backupLoading === 'diff'"
          @click="runBackup('diff')"
        >
          {{ backupLoading === 'diff' ? '正在备份...' : '立即差异备份' }}
        </button>
      </div>
    </div>

    <!-- 备份记录 -->
    <div class="card">
      <h3>备份记录</h3>

      <div v-if="loading" class="loading-center" style="min-height:150px">
        <div class="book-loader"><div class="book-loader__spine"></div></div>
      </div>

      <div v-else-if="backups.length === 0" class="empty-state">
        <div class="empty-state__icon">💾</div>
        <p class="empty-state__text">暂无备份记录，<br>点击上方按钮执行首次备份</p>
      </div>

      <div v-else class="table-wrap mt-4">
        <table>
          <thead>
            <tr>
              <th>编号</th>
              <th>类型</th>
              <th>文件路径</th>
              <th>文件大小</th>
              <th>备份时间</th>
              <th>状态</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in backups" :key="b.backup_id">
              <td class="text-mono" style="font-size:0.82rem">{{ b.backup_id }}</td>
              <td>
                <span :class="['tag', b.backup_type === 'full' ? 'tag-info' : 'tag-warning']">
                  {{ b.backup_type === 'full' ? '全量' : '差异' }}
                </span>
              </td>
              <td class="text-mono" style="font-size:0.78rem;max-width:280px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                {{ b.file_path }}
              </td>
              <td class="text-mono" style="font-size:0.82rem">{{ formatSize(b.file_size) }}</td>
              <td class="text-mono" style="font-size:0.82rem">{{ b.backup_date }}</td>
              <td>
                <span :class="['tag', b.status === 'success' ? 'tag-success' : 'tag-danger']">
                  {{ b.status === 'success' ? '成功' : '失败' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.backup-actions {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}
</style>
