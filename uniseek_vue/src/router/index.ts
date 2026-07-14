import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: () => import('@/layouts/DefaultLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'Home',
          component: () => import('@/pages/Home.vue'),
          meta: { title: 'UniSeek - 发现你心仪的工作' }
        },
        {
          path: 'jobs',
          name: 'Jobs',
          component: () => import('@/pages/Jobs.vue'),
          meta: { title: '职位搜索 - UniSeek' }
        },
        {
          path: 'jobs/:id',
          name: 'JobDetail',
          component: () => import('@/pages/JobDetail.vue'),
          meta: { title: '职位详情 - UniSeek' }
        },
        {
          path: 'company',
          name: 'Company',
          component: () => import('@/pages/Company.vue'),
          meta: { title: '公司 - UniSeek' }
        },
        {
          path: 'messages',
          name: 'Messages',
          component: () => import('@/pages/Messages.vue'),
          meta: { title: '消息 - UniSeek' }
        },
        {
          path: 'resume',
          name: 'Resume',
          component: () => import('@/pages/Resume.vue'),
          meta: { title: '简历 - UniSeek' }
        },
        {
          path: 'post-job',
          name: 'PostJob',
          component: () => import('@/pages/PostJob.vue'),
          meta: { title: '发布职位 - UniSeek' }
        },
        {
          path: 'profile',
          name: 'Profile',
          component: () => import('@/pages/Profile.vue'),
          meta: { title: '个人中心 - UniSeek' }
        }
      ]
    },
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/pages/Login.vue'),
      meta: { title: '登录 - UniSeek' }
    }
  ]
})

router.beforeEach((to, from) => {
  const token = localStorage.getItem('uniseek_token')
  const userStr = localStorage.getItem('uniseek_user')
  const userInfo = userStr ? JSON.parse(userStr) : null

  if (to.meta.requiresAuth && !token) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  if (to.name === 'Login' && token) {
    return { path: userInfo?.role === 'recruiter' ? '/post-job' : '/' }
  }

  document.title = (to.meta.title as string) || 'UniSeek'
})

export default router
