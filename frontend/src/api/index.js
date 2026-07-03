// ============================================================
// api/index.js — Axios 实例 + 拦截器
// ============================================================
import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// 请求拦截器：自动附加 JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器：统一错误处理
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response) {
      const { status, data } = error.response
      if (status === 401) {
        localStorage.removeItem('token')
        localStorage.removeItem('user')
        // 不在登录页才跳转，避免死循环
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
      }
      const message = data?.detail || '请求失败，请稍后再试'
      return Promise.reject(new Error(message))
    }
    if (error.code === 'ECONNABORTED') {
      return Promise.reject(new Error('请求超时，请检查网络连接'))
    }
    return Promise.reject(new Error('无法连接到服务器，请确认后端已启动'))
  }
)

export default api
