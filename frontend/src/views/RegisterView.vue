<script setup>
// ============================================================
// RegisterView.vue — 读者注册页
// ============================================================
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const router = useRouter()
const auth = useAuthStore()

const form = ref({
  reader_id: '',
  name: '',
  reader_type_id: 1,
  department: '',
  password: '',
  confirmPassword: '',
})

const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

async function handleRegister() {
  errorMsg.value = ''
  successMsg.value = ''

  if (!form.value.reader_id || !form.value.name || !form.value.password) {
    errorMsg.value = '请填写所有必填字段'
    return
  }
  if (form.value.password !== form.value.confirmPassword) {
    errorMsg.value = '两次密码输入不一致'
    return
  }
  if (form.value.password.length < 6) {
    errorMsg.value = '密码至少需要 6 位'
    return
  }

  loading.value = true
  try {
    await auth.register({
      reader_id: form.value.reader_id,
      name: form.value.name,
      reader_type_id: form.value.reader_type_id,
      department: form.value.department,
      password: form.value.password,
    })
    successMsg.value = '注册成功！即将跳转到登录页...'
    setTimeout(() => {
      router.push('/login')
    }, 1500)
  } catch (e) {
    errorMsg.value = e.message || '注册失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <!-- 左侧：与登录页一致的藏书票 -->
    <div class="login-left">
      <div class="exlibris">
        <div class="exlibris__border">
          <div class="exlibris__inner">
            <div class="exlibris__building">▨<br>▥<br>▤</div>
            <div class="exlibris__stamp">館</div>
            <div class="exlibris__text">EX · LIBRIS</div>
          </div>
        </div>
        <p class="exlibris__quote">
          「新读者，欢迎你<br>来到知识的殿堂」
        </p>
      </div>
    </div>

    <!-- 右侧：注册表单 -->
    <div class="login-right">
      <div class="login-card">
        <div class="login-card__header">
          <h1>读者注册</h1>
          <p class="login-card__subtitle">办理你的借书证</p>
        </div>

        <form class="login-form" @submit.prevent="handleRegister">
          <div class="form-group">
            <label class="form-label">学工号 *</label>
            <input
              v-model="form.reader_id"
              type="text"
              class="form-input"
              placeholder="如 20210001"
              required
            />
          </div>

          <div class="form-group">
            <label class="form-label">姓名 *</label>
            <input
              v-model="form.name"
              type="text"
              class="form-input"
              placeholder="请输入真实姓名"
              required
            />
          </div>

          <div class="form-group">
            <label class="form-label">读者类型</label>
            <select v-model.number="form.reader_type_id" class="form-select">
              <option :value="1">学生（限额10本/30天）</option>
              <option :value="2">教师（限额15本/60天）</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">院系</label>
            <input
              v-model="form.department"
              type="text"
              class="form-input"
              placeholder="请输入所在院系"
            />
          </div>

          <div class="form-group">
            <label class="form-label">登录密码 *</label>
            <input
              v-model="form.password"
              type="password"
              class="form-input"
              placeholder="至少 6 位密码"
              required
            />
          </div>

          <div class="form-group">
            <label class="form-label">确认密码 *</label>
            <input
              v-model="form.confirmPassword"
              type="password"
              class="form-input"
              placeholder="再次输入密码"
              required
            />
          </div>

          <p v-if="errorMsg" class="form-error login-error">{{ errorMsg }}</p>
          <p v-if="successMsg" class="login-success">{{ successMsg }}</p>

          <button
            type="submit"
            class="btn btn-primary btn-lg login-btn"
            :disabled="loading"
          >
            {{ loading ? '正在注册...' : '注 册' }}
          </button>
        </form>

        <p class="login-footer">
          已有借书证？<router-link to="/login">返回登录</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  display: flex;
  min-height: 100vh;
}

.login-left {
  flex: 1;
  background: linear-gradient(160deg, #4E342E, #3E2723, #2C1A14);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.exlibris { text-align: center; }

.exlibris__border {
  width: 240px; height: 320px;
  margin: 0 auto 32px;
  padding: 8px;
  border: 3px double rgba(255, 248, 240, 0.3);
  border-radius: 4px;
}

.exlibris__inner {
  width: 100%; height: 100%;
  border: 1px solid rgba(255, 248, 240, 0.2);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 16px;
}

.exlibris__building {
  font-family: var(--font-serif);
  font-size: 1.8rem;
  color: rgba(255, 248, 240, 0.6);
  line-height: 1; letter-spacing: -2px;
}

.exlibris__stamp {
  width: 64px; height: 64px;
  display: flex; align-items: center; justify-content: center;
  border: 2px solid #C62828; border-radius: 50%;
  font-family: var(--font-serif); font-size: 2rem;
  color: #C62828; transform: rotate(-5deg);
}

.exlibris__text {
  font-family: var(--font-serif);
  font-size: 0.8rem;
  color: rgba(255, 248, 240, 0.5);
  letter-spacing: 0.15em;
}

.exlibris__quote {
  font-family: var(--font-serif);
  font-size: 1rem;
  color: rgba(255, 248, 240, 0.55);
  line-height: 1.8;
}

.login-right {
  flex: 1;
  display: flex; align-items: center; justify-content: center;
  background: var(--color-bg); padding: 40px;
}

.login-card { width: 100%; max-width: 420px; }

.login-card__header {
  text-align: center; margin-bottom: 30px;
}

.login-card__header h1 {
  font-size: 1.6rem; margin-bottom: 8px;
}

.login-card__subtitle {
  font-family: var(--font-serif);
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  letter-spacing: 0.08em;
}

.login-form {
  background: var(--color-card);
  padding: 28px 32px;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-md);
}

.login-error {
  margin-bottom: 12px; padding: 8px 12px;
  background: #FFEBEE; border-radius: var(--radius-sm);
}

.login-success {
  margin-bottom: 12px; padding: 8px 12px;
  background: #E8F5E9; color: #2E7D32;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.login-btn {
  width: 100%; justify-content: center;
  padding: 14px; margin-top: 8px;
  font-family: var(--font-serif);
  font-size: 1.1rem; letter-spacing: 0.15em;
}

.login-footer {
  text-align: center; margin-top: 20px;
  font-size: 0.9rem; color: var(--color-text-secondary);
}

.login-footer a {
  color: var(--color-primary);
  font-weight: 600;
}

@media (max-width: 768px) {
  .login-left { display: none; }
  .login-right { flex: 1; }
}
</style>
