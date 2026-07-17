<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

// 解析状态码：支持 /error/502 或 /error?code=502 两种方式
const errorCode = computed(() => {
  const paramCode = Number(route.params.code)
  if (!Number.isNaN(paramCode) && paramCode > 0) return paramCode
  const queryCode = Number(route.query.code)
  if (!Number.isNaN(queryCode) && queryCode > 0) return queryCode
  return 404
})

// 错误码配置
const errorMap: Record<number, {
  title: string
  subtitle: string
  desc: string
  // 故障链路节点
  chain: { label: string; status: 'ok' | 'fail' | 'pending' }[]
  hint: string
  canRetry: boolean
}> = {
  400: {
    title: '请求有误',
    subtitle: 'Bad Request',
    desc: '你发送的请求无法被服务器理解，请检查参数后重试。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '校验层', status: 'fail' },
      { label: '服务层', status: 'pending' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '请检查输入的查询参数或表单内容',
    canRetry: true
  },
  401: {
    title: '身份未通过验证',
    subtitle: 'Unauthorized',
    desc: '你需要登录后才能访问该资源，或登录状态已过期。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '鉴权层', status: 'fail' },
      { label: '服务层', status: 'pending' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '请重新登录后继续',
    canRetry: false
  },
  403: {
    title: '无权访问',
    subtitle: 'Forbidden',
    desc: '你当前没有权限访问此页面，请联系管理员申请。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '鉴权层', status: 'ok' },
      { label: '权限层', status: 'fail' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '如需访问请联系管理员',
    canRetry: false
  },
  404: {
    title: '页面去远方了',
    subtitle: 'Not Found',
    desc: '你访问的页面可能已被移除、更名，或地址拼写有误。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '路由层', status: 'fail' },
      { label: '服务层', status: 'pending' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '请检查 URL 是否正确',
    canRetry: true
  },
  500: {
    title: '系统遇到了小麻烦',
    subtitle: 'Internal Server Error',
    desc: '服务器内部出现了异常，我们的工程师已收到通知，正在紧急处理。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '网关', status: 'ok' },
      { label: '服务层', status: 'fail' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '请稍后再试，问题正在处理中',
    canRetry: true
  },
  502: {
    title: '服务暂时不可用',
    subtitle: 'Bad Gateway',
    desc: '上游服务暂时没有响应，可能是维护中或负载过高，请稍后再试。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '网关', status: 'ok' },
      { label: '服务层', status: 'fail' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '我们正在全力恢复，请耐心等待',
    canRetry: true
  },
  503: {
    title: '服务正在维护',
    subtitle: 'Service Unavailable',
    desc: '系统正在进行例行维护或临时升级，预计很快恢复。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '网关', status: 'ok' },
      { label: '服务层', status: 'fail' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '预计短时间内恢复',
    canRetry: true
  },
  504: {
    title: '请求超时',
    subtitle: 'Gateway Timeout',
    desc: '服务器等待上游响应超时，可能是网络波动或后端繁忙。',
    chain: [
      { label: '客户端', status: 'ok' },
      { label: '网关', status: 'fail' },
      { label: '服务层', status: 'pending' },
      { label: '数据层', status: 'pending' }
    ],
    hint: '请检查网络连接后重试',
    canRetry: true
  }
}

const config = computed(() => errorMap[errorCode.value] || errorMap[404])

// 字符级入场动画
const digits = computed(() => String(errorCode.value).split(''))
const showDigits = ref(false)

// 鼠标视差
const glowX = ref(50)
const glowY = ref(50)
const onMouseMove = (e: MouseEvent) => {
  const w = window.innerWidth
  const h = window.innerHeight
  glowX.value = (e.clientX / w) * 100
  glowY.value = (e.clientY / h) * 100
}

// 故障链路动画
const showChain = ref(false)

// 返回首页
const handleGoHome = () => {
  router.push('/')
}

onMounted(() => {
  // 触发入场动画
  setTimeout(() => {
    showChain.value = true
  }, 600)
  window.addEventListener('mousemove', onMouseMove)
})

onUnmounted(() => {
  window.removeEventListener('mousemove', onMouseMove)
})
</script>

<template>
  <div class="error-page">
    <!-- 背景层：渐变 + 鼠标视差光晕 + 网格噪点 -->
    <div
      class="bg-glow"
      :style="{
        background: `radial-gradient(600px circle at ${glowX}% ${glowY}%, rgba(23, 98, 251, 0.18), transparent 60%)`
      }"
    />
    <div class="bg-grid" />
    <div class="bg-noise" />

    <!-- 顶部导航条 -->
    <header class="error-header">
      <router-link to="/" class="brand">
        <img src="@/assets/uniseek_text_white_ZH.svg" alt="UniSeek" class="brand-img" />
      </router-link>
    </header>

    <!-- 主体内容 -->
    <main class="error-main">
      <div class="error-stage">
        <!-- 巨大错误码 -->
        <h1 class="error-code" :class="{ visible: showDigits }">
          <span
            v-for="(d, i) in digits"
            :key="i"
            class="digit"
            :style="{ animationDelay: `${i * 120}ms` }"
          >{{ d }}</span>
        </h1>

        <!-- 状态名 + 描述 -->
        <h2 class="error-title">{{ config.title }}</h2>
        <p class="error-desc">{{ config.desc }}</p>

        <!-- 故障链路可视化 -->
        <div class="chain" :class="{ visible: showChain }">
          <template v-for="(node, idx) in config.chain" :key="idx">
            <div class="chain-node" :class="`status-${node.status}`">
              <div class="node-dot">
                <span v-if="node.status === 'ok'" class="node-mark ok">●</span>
                <span v-else-if="node.status === 'fail'" class="node-mark fail">✕</span>
                <span v-else class="node-mark pending">·</span>
              </div>
              <span class="node-label">{{ node.label }}</span>
            </div>
            <div
              v-if="idx < config.chain.length - 1"
              class="chain-line"
              :class="{
                'line-ok': node.status === 'ok',
                'line-fail': node.status === 'fail'
              }"
            />
          </template>
        </div>

        <!-- 行动按钮组 -->
        <div class="actions">
          <button class="action-btn primary" @click="handleGoHome">
            <el-icon><ArrowLeft /></el-icon>
            <span>返回首页</span>
          </button>
        </div>
      </div>
    </main>

    <!-- 底部信息条 -->
    <footer class="error-footer">
      <span class="footer-left">© UniSeek · 让好工作主动来找你</span>
    </footer>
  </div>
</template>

<style scoped>
/* ── 根布局：全屏深色舞台 ── */
.error-page {
  position: relative;
  min-height: 100vh;
  background: #050a16;
  color: #e6ebf5;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  isolation: isolate;
}

/* ── 背景层 ── */
.bg-glow {
  position: absolute;
  inset: 0;
  transition: background 0.25s ease;
  z-index: -3;
}

.bg-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.04) 1px, transparent 1px);
  background-size: 56px 56px;
  mask-image: radial-gradient(ellipse at center, #000 0%, transparent 75%);
  -webkit-mask-image: radial-gradient(ellipse at center, #000 0%, transparent 75%);
  z-index: -2;
}

.bg-noise {
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml;utf8,<svg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.05 0'/></filter><rect width='100%' height='100%' filter='url(%23n)'/></svg>");
  opacity: 0.4;
  z-index: -1;
  pointer-events: none;
}

/* ── 顶部导航 ── */
.error-header {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px 40px;
}

.brand {
  display: flex;
  align-items: center;
  text-decoration: none;
  transition: opacity 0.2s;
}
.brand:hover { opacity: 0.85; }

.brand-img {
  height: 30px;
  width: auto;
  display: block;
}

/* ── 主体舞台 ── */
.error-main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
  position: relative;
  z-index: 1;
}

.error-stage {
  width: 100%;
  max-width: 760px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* ── 巨大错误码 ── */
.error-code {
  font-family: 'SF Pro Display', system-ui, -apple-system, 'Segoe UI', sans-serif;
  font-size: clamp(140px, 26vw, 280px);
  font-weight: 900;
  line-height: 0.9;
  letter-spacing: -0.04em;
  margin: 0 0 20px;
  display: flex;
  justify-content: center;
  gap: 0.02em;
  color: #ffffff;
  text-shadow: 0 0 40px rgba(23, 98, 251, 0.4);
  user-select: none;
}

.digit {
  display: inline-block;
  opacity: 0;
  transform: translateY(60px);
  animation: digitIn 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes digitIn {
  0% {
    opacity: 0;
    transform: translateY(60px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ── 标题与描述 ── */
.error-title {
  font-size: clamp(20px, 3vw, 28px);
  font-weight: 600;
  color: #fff;
  margin: 0 0 12px;
  letter-spacing: -0.01em;
}

.error-desc {
  font-size: 15px;
  line-height: 1.7;
  color: rgba(255, 255, 255, 0.55);
  margin: 0 0 48px;
  max-width: 540px;
}

/* ── 故障链路 ── */
.chain {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0;
  margin-bottom: 16px;
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 0.8s ease 0.2s, transform 0.8s cubic-bezier(0.16, 1, 0.3, 1) 0.2s;
}

.chain.visible {
  opacity: 1;
  transform: translateY(0);
}

.chain-node {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-width: 76px;
}

.node-dot {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(255, 255, 255, 0.15);
  background: rgba(255, 255, 255, 0.03);
  font-size: 16px;
  color: rgba(255, 255, 255, 0.4);
  transition: all 0.3s;
}

.status-ok .node-dot {
  border-color: rgba(46, 213, 115, 0.5);
  background: rgba(46, 213, 115, 0.1);
}
.status-ok .node-mark.ok {
  color: #2ed573;
  font-size: 14px;
}

.status-fail .node-dot {
  border-color: rgba(255, 107, 107, 0.6);
  background: rgba(255, 107, 107, 0.12);
  box-shadow: 0 0 0 4px rgba(255, 107, 107, 0.08), 0 0 24px rgba(255, 107, 107, 0.3);
  animation: shake 2.4s ease-in-out infinite;
}
.status-fail .node-mark.fail {
  color: #ff6b6b;
  font-weight: 700;
}

.status-pending .node-dot {
  border-color: rgba(255, 255, 255, 0.1);
  opacity: 0.5;
}

@keyframes shake {
  0%, 90%, 100% { transform: translateX(0); }
  92% { transform: translateX(-2px); }
  94% { transform: translateX(2px); }
  96% { transform: translateX(-1px); }
  98% { transform: translateX(1px); }
}

.node-label {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  letter-spacing: 0.05em;
}

.status-fail .node-label {
  color: #ff8a8a;
}

.chain-line {
  width: 56px;
  height: 1px;
  background: rgba(255, 255, 255, 0.12);
  margin: 0 -4px 22px;
  position: relative;
  overflow: hidden;
}

.line-ok {
  background: rgba(46, 213, 115, 0.4);
}

.line-fail {
  background: linear-gradient(90deg, rgba(46, 213, 115, 0.4) 0%, rgba(255, 107, 107, 0.6) 100%);
  position: relative;
}

.line-fail::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent, rgba(255, 107, 107, 0.8), transparent);
  animation: lineFlow 1.6s linear infinite;
}

@keyframes lineFlow {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

/* ── 行动按钮 ── */
.actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: center;
}

.action-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  font-size: 14px;
  font-weight: 500;
  color: #fff;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.action-btn::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(23, 98, 251, 0.2), transparent);
  opacity: 0;
  transition: opacity 0.25s;
}

.action-btn:hover {
  border-color: rgba(23, 98, 251, 0.5);
  background: rgba(23, 98, 251, 0.08);
}

.action-btn:hover::before {
  opacity: 1;
}

.action-btn .el-icon,
.action-btn span {
  position: relative;
  z-index: 1;
  transition: transform 0.25s;
}

.action-btn.primary {
  background: #1762FB;
  border-color: #1762FB;
  color: #fff;
  box-shadow: 0 4px 20px rgba(23, 98, 251, 0.3);
}

.action-btn.primary:hover {
  background: #0052d4;
  border-color: #0052d4;
  box-shadow: 0 6px 28px rgba(23, 98, 251, 0.5);
}

/* ── 底部信息 ── */
.error-footer {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 40px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  font-size: 12px;
  color: rgba(255, 255, 255, 0.35);
  font-family: ui-monospace, 'SF Mono', Consolas, monospace;
}

/* ── 响应式 ── */
@media (max-width: 768px) {
  .error-header {
    padding: 18px 20px;
  }
  .brand-img {
    height: 24px;
  }
  .error-main {
    padding: 20px 20px 40px;
  }
  .error-code {
    font-size: 96px;
    margin-bottom: 20px;
  }
  .error-desc {
    margin-bottom: 32px;
  }
  .chain-node {
    min-width: 56px;
  }
  .node-dot {
    width: 30px;
    height: 30px;
  }
  .chain-line {
    width: 24px;
    margin: 0 -2px 18px;
  }
  .node-label {
    font-size: 11px;
  }
  .actions {
    width: 100%;
  }
  .action-btn {
    flex: 1 1 calc(50% - 6px);
    justify-content: center;
    padding: 10px 12px;
    font-size: 13px;
  }
  .error-footer {
    flex-direction: column;
    gap: 8px;
    padding: 16px 20px;
    text-align: center;
  }
}
</style>
