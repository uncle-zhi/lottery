import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '@/views/Home.vue'
import Admin from '@/views/Admin.vue'
import { Layout } from 'ant-design-vue'
import About from '@/views/About.vue'
import AboutEn from '@/views/About-en.vue'

const routes = [
  { path: '/', name: 'Home', component: Home, meta: { layout: 'FullscreenLayout' } },
  { path: '/Admin', name: 'Admin', component: Admin, meta: { layout: 'AdminLayout' } },
  { path: '/About', name: 'About', component: About, meta: { layout: 'FullscreenLayout' } },
  { path: '/About-En', name: 'About-en', component: AboutEn, meta: { layout: 'FullscreenLayout' } },
  { path: '/lottery-bet', name: 'LotteryBet', component: () => import('@/views/LotteryBet.vue'), meta: { layout: 'FullscreenLayout' } },
  // 你可以在这里添加更多路由
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

export default router