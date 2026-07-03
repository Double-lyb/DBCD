<script setup>
// ============================================================
// LoginView.vue — 登录页（藏书票 + 借书证风格）
// ============================================================
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const router = useRouter()
const auth = useAuthStore()

const username = ref('')
const password = ref('')
const captchaCode = ref('')
const captchaToken = ref('')
const captchaImage = ref('')
const captchaLoading = ref(false)
const loading = ref(false)
const errorMsg = ref('')

async function loadCaptcha() {
  captchaLoading.value = true
  errorMsg.value = ''
  try {
    const res = await auth.getCaptcha()
    captchaToken.value = res.token
    captchaImage.value = res.image_base64
    console.log('✅ 验证码加载成功, token:', res.token?.substring(0, 8) + '...')
  } catch (e) {
    console.error('❌ 验证码加载失败:', e.message)
    errorMsg.value = '无法连接后端服务，请确认已执行: python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload'
  } finally {
    captchaLoading.value = false
  }
}

async function handleLogin() {
  if (!username.value || !password.value || !captchaCode.value) {
    errorMsg.value = '请填写所有字段'
    return
  }
  errorMsg.value = ''
  loading.value = true
  try {
    await auth.login(username.value, password.value, captchaToken.value, captchaCode.value)
    router.push('/dashboard')
  } catch (e) {
    errorMsg.value = e.message || '登录失败'
    captchaCode.value = ''
    await loadCaptcha()
  } finally {
    loading.value = false
  }
}

onMounted(loadCaptcha)
</script>

<template>
  <div class="login-page">
    <!-- 左侧：藏书票 -->
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
          「书卷多情似故人，<br>晨昏忧乐每相亲」
        </p>
      </div>
    </div>

    <!-- 右侧：登录表单 -->
    <div class="login-right">
      <div class="login-card">
        <div class="login-card__header">
          <h1>高校图书借阅管理系统</h1>
          <p class="login-card__subtitle">Library Management System</p>
        </div>

        <form class="login-form" @submit.prevent="handleLogin">
          <div class="form-group">
            <label class="form-label">用户名</label>
            <div class="input-icon">
              <span class="input-icon__symbol">👤</span>
              <input
                v-model="username"
                type="text"
                class="form-input input-icon__input"
                placeholder="请输入用户名"
                autocomplete="username"
              />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">密码</label>
            <div class="input-icon">
              <span class="input-icon__symbol">🔒</span>
              <input
                v-model="password"
                type="password"
                class="form-input input-icon__input"
                placeholder="请输入密码"
                autocomplete="current-password"
              />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">验证码</label>
            <div class="captcha-row">
              <input
                v-model="captchaCode"
                type="text"
                class="form-input captcha-input"
                placeholder="验证码"
                maxlength="4"
                autocomplete="off"
              />
              <div class="captcha-img" :class="{ 'captcha-img--loading': captchaLoading }" @click="loadCaptcha" title="点击刷新验证码">
                <img
                  v-if="captchaImage"
                  :src="'data:image/png;base64,' + captchaImage"
                  alt="验证码"
                />
                <span v-else-if="captchaLoading" class="captcha-img__placeholder">加载中...</span>
                <span v-else class="captcha-img__placeholder">点击获取</span>
              </div>
            </div>
          </div>

          <!-- 错误提示（更显眼） -->
          <div v-if="errorMsg" class="login-error">
            <div class="login-error__icon">⚠</div>
            <div class="login-error__text">{{ errorMsg }}</div>
          </div>

          <button
            type="submit"
            class="btn btn-primary btn-lg login-btn"
            :disabled="loading"
          >
            {{ loading ? '正在登录...' : '登 录' }}
          </button>
        </form>

        <p class="login-footer">
          <span class="text-muted">测试账号: admin / admin123</span>
          <br>
          还没有借书证？<router-link to="/register">立即注册 →</router-link>
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

/* ---- 左侧：藏书票 ---- */
.login-left {
  flex: 1;
  background: linear-gradient(160deg, #4E342E, #3E2723, #2C1A14);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.exlibris {
  text-align: center;
}

.exlibris__border {
  width: 240px;
  height: 320px;
  margin: 0 auto 32px;
  padding: 8px;
  border: 3px double rgba(255, 248, 240, 0.3);
  border-radius: 4px;
}

.exlibris__inner {
  width: 100%;
  height: 100%;
  border: 1px solid rgba(255, 248, 240, 0.2);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.exlibris__building {
  font-family: var(--font-serif);
  font-size: 1.8rem;
  color: rgba(255, 248, 240, 0.6);
  line-height: 1;
  letter-spacing: -2px;
}

.exlibris__stamp {
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #C62828;
  border-radius: 50%;
  font-family: var(--font-serif);
  font-size: 2rem;
  color: #C62828;
  transform: rotate(-5deg);
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

/* ---- 右侧：登录卡片 ---- */
.login-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg);
  padding: 40px;
}

.login-card {
  width: 100%;
  max-width: 400px;
}

.login-card__header {
  text-align: center;
  margin-bottom: 40px;
}

.login-card__header h1 {
  font-size: 1.6rem;
  margin-bottom: 8px;
}

.login-card__subtitle {
  font-family: var(--font-serif);
  font-size: 0.85rem;
  color: var(--color-text-secondary);
  letter-spacing: 0.08em;
}

/* Form */
.login-form {
  background: var(--color-card);
  padding: 32px;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-md);
}

.input-icon {
  position: relative;
}

.input-icon__symbol {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1rem;
  opacity: 0.5;
}

.input-icon__input {
  padding-left: 42px;
}

.captcha-row {
  display: flex;
  gap: 10px;
}

.captcha-input {
  flex: 1;
}

.captcha-img {
  width: 120px;
  height: 44px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #FFF;
  flex-shrink: 0;
}

.captcha-img img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.captcha-img:hover {
  border-color: var(--color-primary);
}

.captcha-img--loading {
  border-color: var(--color-accent);
  animation: pulse-border 1s ease-in-out infinite;
}

@keyframes pulse-border {
  0%, 100% { border-color: var(--color-accent); }
  50% { border-color: var(--color-border); }
}

.captcha-img__placeholder {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  user-select: none;
}

.login-error {
  margin-bottom: 16px;
  padding: 12px 16px;
  background: #FFF5F5;
  border: 1px solid #FFCDD2;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.login-error__icon {
  flex-shrink: 0;
  font-size: 1.1rem;
}

.login-error__text {
  font-size: 0.88rem;
  color: #C62828;
  line-height: 1.5;
}

.login-btn {
  width: 100%;
  justify-content: center;
  padding: 14px;
  font-family: var(--font-serif);
  font-size: 1.1rem;
  letter-spacing: 0.15em;
  margin-top: 8px;
}

.login-footer {
  text-align: center;
  margin-top: 24px;
}
</style>
