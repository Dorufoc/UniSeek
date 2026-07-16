import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// Vite 构建配置
export default defineConfig({
  plugins: [vue()],
  // 路径别名：@ 指向 src 目录
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // 开发服务器配置
  server: {
    // 监听所有网络接口，允许跨 IP 访问
    host: '0.0.0.0',
    proxy: {
      // 代理 /api 请求到 Java 后端（Spring Boot 默认 8080 端口）
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      },
      // 代理 WebSocket 聊天连接
      '/ws': {
        target: 'http://localhost:8080',
        ws: true
      }
    }
  }
})
