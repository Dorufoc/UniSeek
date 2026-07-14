import { createRouter, createWebHistory } from 'vue-router'

// 从 localStorage 获取当前登录用户的角色
const getUserRole = (): number => {
  const userStr = localStorage.getItem('uniseek_user')
  return userStr ? JSON.parse(userStr).role : -1
}

// 读取企业认证状态
const getCertStatus = () => {
  const cert = localStorage.getItem('uniseek_enterprise_cert')
  return cert ? JSON.parse(cert).status : 'none'
}

// 路由配置
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
          path: 'talents',
          name: 'Talents',
          component: () => import('@/pages/Talents.vue'),
          meta: { title: '人才库 - UniSeek', requiresRecruiter: true }
        },
        {
          path: 'job-management',
          name: 'JobManagement',
          component: () => import('@/pages/JobManagement.vue'),
          meta: { title: '职位管理 - UniSeek', requiresRecruiter: true }
        },
        {
          path: 'resume-pool',
          name: 'ResumePool',
          component: () => import('@/pages/ResumePool.vue'),
          meta: { title: '简历池 - UniSeek', requiresRecruiter: true }
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
        }
      ]
    },
    {
      path: '/enterprise-cert',
      name: 'EnterpriseCert',
      component: () => import('@/pages/EnterpriseCertification.vue'),
      meta: { title: '企业资质认证 - UniSeek', requiresAuth: true }
    },
    {
      path: '/admin',
      component: () => import('@/layouts/AdminLayout.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
      redirect: '/admin/dashboard',
      children: [
        {
          path: 'dashboard',
          name: 'AdminDashboard',
          component: () => import('@/pages/admin/Dashboard.vue'),
          meta: { title: '工作台 - UniSeek 管理后台' }
        },
        {
          path: 'enterprises',
          name: 'AdminEnterprises',
          component: () => import('@/pages/admin/EnterpriseAudit.vue'),
          meta: { title: '企业审核 - UniSeek 管理后台' }
        },
        {
          path: 'tasks',
          name: 'AdminTasks',
          component: () => import('@/pages/admin/TaskAudit.vue'),
          meta: { title: '职位审核 - UniSeek 管理后台' }
        },
        {
          path: 'users',
          name: 'AdminUsers',
          component: () => import('@/pages/admin/UserManagement.vue'),
          meta: { title: '用户管理 - UniSeek 管理后台' }
        },
        {
          path: 'complaints',
          name: 'AdminComplaints',
          component: () => import('@/pages/admin/ComplaintManage.vue'),
          meta: { title: '投诉处理 - UniSeek 管理后台' }
        },
        {
          path: 'logs',
          name: 'AdminLogs',
          component: () => import('@/pages/admin/OperationLogs.vue'),
          meta: { title: '操作日志 - UniSeek 管理后台' }
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

// 全局路由守卫
router.beforeEach((to, _from) => {
  const token = localStorage.getItem('uniseek_token')
  const role = getUserRole()

  // 未登录用户访问需认证页面 → 重定向到登录页
  if (to.meta.requiresAuth && !token) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  // 已登录用户访问登录页 → 根据角色重定向
  if (to.name === 'Login' && token) {
    if (role >= 9) {
      return { path: '/admin/dashboard' }
    }
    if (role === 1) {
      const certStatus = getCertStatus()
      return { path: certStatus === 'approved' ? '/' : '/enterprise-cert' }
    }
    return { path: '/' }
  }

  // 管理员路由守卫：/admin/* 仅允许 role >= 9 访问
  if (to.path.startsWith('/admin') && role < 9) {
    return { path: '/' }
  }

  // 招聘者路由守卫：requiresRecruiter 仅允许 role=1
  if (to.meta.requiresRecruiter && role !== 1) {
    return { path: '/' }
  }

  // 企业认证页：非招聘者不可访问
  if (to.name === 'EnterpriseCert' && role !== 1) {
    return { path: '/' }
  }

  document.title = (to.meta.title as string) || 'UniSeek'
  return true
})

export default router
