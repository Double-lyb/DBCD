// ============================================================
// router/index.js — Vue Router 路由配置 + 导航守卫
// ============================================================
import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
    meta: { guest: true },
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('../views/RegisterView.vue'),
    meta: { guest: true },
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/DashboardView.vue'),
  },
  {
    path: '/books',
    name: 'Books',
    component: () => import('../views/BookListView.vue'),
  },
  {
    path: '/books/add',
    name: 'BookAdd',
    component: () => import('../views/BookFormView.vue'),
    meta: { roles: ['admin', 'librarian'] },
  },
  {
    path: '/books/:isbn',
    name: 'BookDetail',
    component: () => import('../views/BookDetailView.vue'),
  },
  {
    path: '/books/:isbn/edit',
    name: 'BookEdit',
    component: () => import('../views/BookFormView.vue'),
    meta: { roles: ['admin', 'librarian'] },
  },
  {
    path: '/readers',
    name: 'Readers',
    component: () => import('../views/ReaderListView.vue'),
    meta: { roles: ['admin', 'librarian'] },
  },
  {
    path: '/readers/add',
    name: 'ReaderAdd',
    component: () => import('../views/ReaderDetailView.vue'),
    meta: { roles: ['admin', 'librarian'] },
  },
  {
    path: '/readers/:id',
    name: 'ReaderDetail',
    component: () => import('../views/ReaderDetailView.vue'),
  },
  {
    path: '/borrow',
    name: 'Borrow',
    component: () => import('../views/BorrowView.vue'),
    // 所有用户：读者申请借书，管理员审批
  },
  {
    path: '/return',
    name: 'Return',
    component: () => import('../views/ReturnView.vue'),
    meta: { roles: ['admin', 'librarian'] },
    // 仅管理员/图书管理员：线下还书操作
  },
  {
    path: '/overdue',
    name: 'Overdue',
    component: () => import('../views/OverdueView.vue'),
    // 所有用户可访问，读者只能看自己的超期
  },
  {
    path: '/stats',
    name: 'Stats',
    component: () => import('../views/StatsView.vue'),
  },
  {
    path: '/fines',
    name: 'Fines',
    component: () => import('../views/FinesView.vue'),
  },
  {
    path: '/admin/logs',
    name: 'AdminLogs',
    component: () => import('../views/AdminLogsView.vue'),
    meta: { roles: ['admin'] },
  },
  {
    path: '/admin/backup',
    name: 'AdminBackup',
    component: () => import('../views/AdminBackupView.vue'),
    meta: { roles: ['admin'] },
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 全局路由守卫：JWT 认证 + RBAC 角色控制
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  let user = null
  try {
    user = JSON.parse(localStorage.getItem('user') || 'null')
  } catch {
    user = null
  }

  // 登录页：已登录用户直接跳转仪表盘
  if (to.meta.guest) {
    if (token) return next('/dashboard')
    return next()
  }

  // 其他页面：未登录重定向到登录页
  if (!token) {
    return next('/login')
  }

  // 角色检查
  if (to.meta.roles) {
    const allowed = to.meta.roles
    if (!allowed.includes(user?.role)) {
      return next('/dashboard')
    }
  }

  next()
})

export default router
