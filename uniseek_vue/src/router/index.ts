import { createRouter, createWebHistory } from 'vue-router'

// 读取企业认证状态
const getCertStatus = () => {
  const cert = localStorage.getItem('uniseek_enterprise_cert')
  return cert ? JSON.parse(cert).status : 'none'
}

// 判断是否为招聘者
const isRecruiter = () => {
  const userStr = localStorage.getItem('uniseek_user')
  return userStr ? JSON.parse(userStr).role === 1 : false
}

// 判断是否为超级管理员（role === 99）
const isSuperAdmin = () => {
  const userStr = localStorage.getItem('uniseek_user')
  return userStr ? JSON.parse(userStr).role === 99 : false
}

// 路由配置 - 采用 HTML5 History 模式，所有页面组件懒加载
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      // 首页布局路由（需登录），所有主页面作为其子路由
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
          meta: { title: '发布职位 - UniSeek', requiresCert: true }
        },
        {
          path: 'my-applications',
          name: 'MyApplications',
          component: () => import('@/pages/MyApplications.vue'),
          meta: { title: '我的求职 - UniSeek' }
        },
        {
          path: 'account-security',
          name: 'AccountSecurity',
          component: () => import('@/pages/AccountSecurity.vue'),
          meta: { title: '账号安全 - UniSeek' }
        },
        {
          path: 'profile',
          name: 'Profile',
          component: () => import('@/pages/Profile.vue'),
          meta: { title: '个人中心 - UniSeek' }
        },
        {
          path: 'admin/super',
          name: 'SuperAdmin',
          component: () => import('@/pages/admin/SuperAdmin.vue'),
          meta: { title: '系统管理 - UniSeek', requiresAuth: true, requiresSuperAdmin: true }
        }
      ]
    },
    {
      // 登录页为独立路由，不嵌套在布局中
      path: '/login',
      name: 'Login',
      component: () => import('@/pages/Login.vue'),
      meta: { title: '登录 - UniSeek' }
    },
    {
      // 企业资质认证页为独立路由，不嵌套在布局中
      path: '/enterprise-cert',
      name: 'EnterpriseCert',
      component: () => import('@/pages/EnterpriseCertification.vue'),
      meta: { title: '企业资质认证 - UniSeek', requiresAuth: true }
    }
  ]
})

// 全局路由守卫
router.beforeEach((to, from) => {
  const token = localStorage.getItem('uniseek_token')
  const userStr = localStorage.getItem('uniseek_user')
  const userInfo = userStr ? JSON.parse(userStr) : null

  // 未登录用户访问需认证页面 → 重定向到登录页
  if (to.meta.requiresAuth && !token) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  // 已登录用户访问登录页 → 根据角色重定向
  if (to.name === 'Login' && token) {
    if (userInfo?.role === 1) {
      const certStatus = getCertStatus()
      return { path: certStatus === 'approved' ? '/' : '/enterprise-cert' }
    }
    return { path: '/' }
  }

  // 招聘者访问需要企业认证的页面（如发布职位），检查认证状态
  if (to.meta.requiresCert && isRecruiter()) {
    const certStatus = getCertStatus()
    if (certStatus !== 'approved') {
      return { path: '/enterprise-cert' }
    }
  }

  // 招聘者已认证后访问认证页 → 重定向到首页
  if (to.name === 'EnterpriseCert' && isRecruiter()) {
    const certStatus = getCertStatus()
    if (certStatus === 'approved') {
      return { path: '/' }
    }
  }

  // 非招聘者访问认证页 → 重定向到首页
  if (to.name === 'EnterpriseCert' && !isRecruiter()) {
    return { path: '/' }
  }

  // 超级管理员（role === 99）可以访问所有页面，跳过其余检查
  if (userInfo?.role === 99) {
    document.title = (to.meta.title as string) || 'UniSeek'
    return
  }

  // 需要超级管理员权限但角色不是 99 → 重定向到首页
  if (to.meta.requiresSuperAdmin) {
    return { path: '/' }
  }

  // 设置页面标题
  document.title = (to.meta.title as string) || 'UniSeek'
})

export default router
