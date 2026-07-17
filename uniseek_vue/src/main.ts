// 应用入口 - 初始化 Vue 实例及所有插件
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import App from './App.vue'
import router from './router'
import './style.css'
import './styles/admin-theme.css'

const app = createApp(App)

// 注册 Pinia 状态管理
app.use(createPinia())
// 注册 Vue Router 路由
app.use(router)
// 注册 Element Plus UI 组件库
app.use(ElementPlus)

// 全局注册所有 Element Plus 图标组件
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 挂载到 #app 根节点
app.mount('#app')
