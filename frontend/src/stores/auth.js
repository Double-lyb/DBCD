// ============================================================
// stores/auth.js — 用户认证状态 (Pinia)
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/index.js'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isLibrarian = computed(() => user.value?.role === 'librarian')
  const isReader = computed(() => user.value?.role === 'reader')

  // 获取验证码
  async function getCaptcha() {
    return await api.get('/auth/captcha')
  }

  // 登录
  async function login(username, password, captchaToken, captchaCode) {
    const res = await api.post('/auth/login', {
      username,
      password,
      captcha_token: captchaToken,
      captcha_code: captchaCode,
    })
    token.value = res.access_token
    user.value = {
      username: res.username,
      role: res.role,
      reader_id: res.reader_id || null,
    }
    localStorage.setItem('token', res.access_token)
    localStorage.setItem('user', JSON.stringify(user.value))
    return res
  }

  // 注册
  async function register(data) {
    return await api.post('/auth/register', data)
  }

  // 获取当前用户信息
  async function fetchMe() {
    const res = await api.get('/auth/me')
    user.value = {
      username: res.username,
      role: res.role,
      reader_id: res.reader_id || null,
    }
    localStorage.setItem('user', JSON.stringify(user.value))
    return res
  }

  // 退出
  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    window.location.href = '/login'
  }

  return {
    token, user, isLoggedIn, isAdmin, isLibrarian, isReader,
    getCaptcha, login, register, fetchMe, logout,
  }
})
