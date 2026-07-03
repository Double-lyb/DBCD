<script setup>
// ============================================================
// NavBar.vue — 顶部导航栏（图书馆楼层导视牌风格）
// ============================================================
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const navItems = computed(() => {
  const items = [
    { label: '仪表盘', path: '/dashboard', icon: '▤' },
    { label: '图书管理', path: '/books', icon: '▣' },
    { label: '读者管理', path: '/readers', icon: '▥', roles: ['admin', 'librarian'] },
    { label: '借书操作', path: '/borrow', icon: '↗' },
    { label: '还书操作', path: '/return', icon: '↙', roles: ['admin', 'librarian'] },
    { label: '超期清单', path: '/overdue', icon: '⚠' },
    { label: '统计报表', path: '/stats', icon: '◫' },
    { label: '罚金管理', path: '/fines', icon: '¤' },
  ]
  if (auth.isAdmin) {
    items.push({ label: '系统管理', path: '/admin/logs', icon: '⚙' })
  }
  return items.filter(item => !item.roles || item.roles.includes(auth.user?.role))
})

function isActive(path) {
  if (path === '/admin/logs') return route.path.startsWith('/admin')
  return route.path === path
}

function goTo(path) {
  router.push(path)
}
</script>

<template>
  <nav class="navbar">
    <div class="navbar__inner">
      <!-- Logo / 系统名 -->
      <div class="navbar__brand" @click="router.push('/dashboard')">
        <span class="navbar__logo">館</span>
        <span class="navbar__title">高校图书借阅管理系统</span>
      </div>

      <!-- 导航项 -->
      <div class="navbar__links">
        <button
          v-for="item in navItems"
          :key="item.path"
          :class="['navbar__link', { 'navbar__link--active': isActive(item.path) }]"
          @click="goTo(item.path)"
        >
          <span class="navbar__link-icon">{{ item.icon }}</span>
          <span>{{ item.label }}</span>
        </button>
      </div>

      <!-- 用户信息 + 退出 -->
      <div class="navbar__user">
        <span class="navbar__username">
          <span class="navbar__role-tag" :class="'navbar__role-tag--' + auth.user?.role">
            {{ auth.user?.role === 'admin' ? '管理员' : auth.user?.role === 'librarian' ? '图书管理员' : '读者' }}
          </span>
          {{ auth.user?.username }}
        </span>
        <button class="btn btn-ghost btn-sm" @click="auth.logout()">退出</button>
      </div>
    </div>
  </nav>
</template>

<style scoped>
.navbar {
  background: linear-gradient(135deg, var(--color-primary-dark), var(--color-primary));
  color: #FFF8F0;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 12px rgba(62, 39, 35, 0.3);
}

.navbar__inner {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  height: 56px;
  gap: 8px;
}

.navbar__brand {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  margin-right: 20px;
  flex-shrink: 0;
}

.navbar__logo {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.15);
  border-radius: var(--radius-sm);
  font-family: var(--font-serif);
  font-size: 1.3rem;
  color: #FFD54F;
}

.navbar__title {
  font-family: var(--font-serif);
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  white-space: nowrap;
}

.navbar__links {
  display: flex;
  gap: 2px;
  flex: 1;
  overflow-x: auto;
}

.navbar__link {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  background: transparent;
  border: none;
  color: rgba(255,255,255,0.75);
  font-family: var(--font-sans);
  font-size: 0.85rem;
  cursor: pointer;
  border-radius: var(--radius-sm);
  white-space: nowrap;
  transition: all 0.2s;
}

.navbar__link:hover {
  color: #FFF;
  background: rgba(255,255,255,0.1);
}

.navbar__link--active {
  color: #FFD54F;
  background: rgba(255,255,255,0.12);
  font-weight: 600;
}

.navbar__link-icon {
  font-size: 0.85rem;
}

.navbar__user {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
  margin-left: auto;
}

.navbar__username {
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 8px;
}

.navbar__role-tag {
  padding: 1px 8px;
  font-size: 0.72rem;
  font-weight: 600;
  border-radius: 10px;
  letter-spacing: 0.03em;
}

.navbar__role-tag--admin { background: rgba(198, 40, 40, 0.7); }
.navbar__role-tag--librarian { background: rgba(46, 125, 50, 0.7); }
.navbar__role-tag--reader { background: rgba(93, 64, 55, 0.5); }
</style>
