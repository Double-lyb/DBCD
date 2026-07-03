<script setup>
// ============================================================
// App.vue — 根组件
// ============================================================
import { useRoute } from 'vue-router'
import { computed } from 'vue'
import { useAuthStore } from './stores/auth.js'
import NavBar from './components/NavBar.vue'
import Breadcrumb from './components/Breadcrumb.vue'
import ChatPanel from './components/ChatPanel.vue'

const route = useRoute()
const auth = useAuthStore()

// guest 路由：登录页、注册页
const isGuestPage = computed(() => {
  return route.meta?.guest === true
})

// 使用 Pinia store 的响应式状态（localStorage 不是响应式的！）
const isLoggedIn = computed(() => auth.isLoggedIn)
</script>

<template>
  <div class="app-root">
    <!-- 登录/注册页：全屏独立，无导航栏 -->
    <template v-if="isGuestPage">
      <router-view />
    </template>

    <!-- 已登录：顶部导航 + 面包屑 + 内容 + AI助手 -->
    <template v-else-if="isLoggedIn">
      <NavBar />
      <Breadcrumb />
      <main class="app-main">
        <router-view />
      </main>
      <ChatPanel />
    </template>

    <!-- 未登录过渡态 -->
    <template v-else>
      <router-view />
    </template>
  </div>
</template>

<style scoped>
.app-root {
  min-height: 100vh;
  background-color: var(--color-bg);
}

.app-main {
  padding-bottom: 48px;
}
</style>
