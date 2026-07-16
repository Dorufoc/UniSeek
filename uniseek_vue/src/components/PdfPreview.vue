<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
import * as pdfjs from 'pdfjs-dist/legacy/build/pdf'
import workerUrl from 'pdfjs-dist/legacy/build/pdf.worker.min.mjs?url'
import { ZoomIn, ZoomOut, Refresh, ArrowLeft, ArrowRight, Close } from '@element-plus/icons-vue'

pdfjs.GlobalWorkerOptions.workerSrc = workerUrl

const props = defineProps<{
  visible: boolean
  url: string
}>()

const emit = defineEmits<{
  (e: 'update:visible', val: boolean): void
}>()

// PDF 文档实例
let pdfDoc: pdfjs.PDFDocumentProxy | null = null
const pageCount = ref(0)
const currentPage = ref(1)
const loading = ref(false)
const errorMsg = ref('')

// 缩放
const scale = ref(1.0)
const scaleStep = 0.15
const minScale = 0.3
const maxScale = 3.0

const canvasRef = ref<HTMLCanvasElement | null>(null)
const containerRef = ref<HTMLDivElement | null>(null)

const zoomLevel = ref('100%')

// PDF 文档就绪信号
const pdfReady = ref(false)

// 加载 PDF（仅解析文档 — 渲染由 @opened 事件触发）
const loadPdf = async () => {
  if (!props.url) return
  loading.value = true
  errorMsg.value = ''
  pdfReady.value = false
  try {
    pdfDoc = await pdfjs.getDocument({ url: props.url }).promise
    pageCount.value = pdfDoc.numPages
    currentPage.value = 1
    scale.value = 1.0
    zoomLevel.value = '100%'
    pdfReady.value = true
  } catch (e: any) {
    errorMsg.value = e?.message || 'PDF 加载失败'
  } finally {
    loading.value = false
  }
}

// 对话框入场动画完成后才执行首次渲染
const onDialogOpened = async () => {
  if (!pdfReady.value) {
    await new Promise<void>(resolve => {
      const stop = watch(pdfReady, val => { if (val) { stop(); resolve() } })
    })
  }
  await nextTick()
  await renderPage()
}

// 渲染当前页
const renderPage = async () => {
  if (!pdfDoc || !canvasRef.value) return
  try {
    const page = await pdfDoc.getPage(currentPage.value)
    const viewport = page.getViewport({ scale: scale.value })

    const canvas = canvasRef.value
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    // 适配容器宽度
    const container = containerRef.value
    if (container) {
      const maxWidth = Math.max(container.clientWidth - 32, 0)
      if (maxWidth > 0 && viewport.width > maxWidth) {
        const fitScale = maxWidth / viewport.width
        const vp = page.getViewport({ scale: scale.value * fitScale })
        canvas.width = vp.width
        canvas.height = vp.height
        await page.render({ canvasContext: ctx, viewport: vp }).promise
        return
      }
    }

    canvas.width = viewport.width
    canvas.height = viewport.height
    await page.render({ canvasContext: ctx, viewport }).promise
  } catch (e: any) {
    errorMsg.value = '渲染失败：' + (e?.message || String(e))
  }
}

// 页面导航
const goToPage = async (page: number) => {
  if (page < 1 || page > pageCount.value) return
  currentPage.value = page
  await renderPage()
}

const prevPage = async () => {
  if (currentPage.value > 1) {
    currentPage.value--
    await renderPage()
  }
}

const nextPage = async () => {
  if (currentPage.value < pageCount.value) {
    currentPage.value++
    await renderPage()
  }
}

const onPageInputKeydown = async (e: KeyboardEvent) => {
  if (e.key === 'Enter') {
    const val = parseInt((e.target as HTMLInputElement).value)
    if (!isNaN(val)) {
      await goToPage(val)
    }
  }
}

const onPageInputBlur = (e: FocusEvent) => {
  const val = parseInt((e.target as HTMLInputElement).value)
  if (!isNaN(val)) {
    goToPage(val)
  }
}

// 缩放
const zoomIn = async () => {
  scale.value = Math.min(scale.value + scaleStep, maxScale)
  zoomLevel.value = Math.round(scale.value * 100) + '%'
  await renderPage()
}

const zoomOut = async () => {
  scale.value = Math.max(scale.value - scaleStep, minScale)
  zoomLevel.value = Math.round(scale.value * 100) + '%'
  await renderPage()
}

const resetZoom = async () => {
  scale.value = 1.0
  zoomLevel.value = '100%'
  await renderPage()
}

// 监听 visible 变化
watch(() => props.visible, async (val) => {
  if (val) {
    await nextTick()
    await loadPdf()
  } else {
    pdfDoc = null
  }
})

// 重新加载 PDF
const refreshPdf = async () => {
  await loadPdf()
  await nextTick()
  await renderPage()
}

// 窗口 resize 时重新渲染
let resizeTimer: ReturnType<typeof setTimeout>
const onResize = () => {
  clearTimeout(resizeTimer)
  resizeTimer = setTimeout(async () => {
    if (props.visible && pdfDoc) {
      await renderPage()
    }
  }, 200)
}

onMounted(() => {
  window.addEventListener('resize', onResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', onResize)
})
</script>

<template>
  <el-dialog
    :model-value="props.visible"
    @update:model-value="emit('update:visible', $event)"
    @opened="onDialogOpened"
    fullscreen
    class="pdf-preview-dialog"
  >
    <!-- 工具栏 -->
    <div class="pdf-toolbar">
      <div class="toolbar-left">
        <button class="tool-btn" @click="prevPage" :disabled="currentPage <= 1">
          <el-icon><ArrowLeft /></el-icon>
        </button>
        <span class="page-info">
          第
          <input
            class="page-input"
            :value="currentPage"
            type="number"
            min="1"
            :max="pageCount"
            @keydown="onPageInputKeydown"
            @blur="onPageInputBlur"
          />
          / {{ pageCount }} 页
        </span>
        <button class="tool-btn" @click="nextPage" :disabled="currentPage >= pageCount">
          <el-icon><ArrowRight /></el-icon>
        </button>
      </div>
      <div class="toolbar-right">
        <button class="tool-btn" @click="zoomOut" :disabled="scale <= minScale">
          <el-icon><ZoomOut /></el-icon>
        </button>
        <button class="tool-btn zoom-level-btn" @click="resetZoom" :title="'重置缩放'">
          {{ zoomLevel }}
        </button>
        <button class="tool-btn" @click="zoomIn" :disabled="scale >= maxScale">
          <el-icon><ZoomIn /></el-icon>
        </button>
        <button class="tool-btn" @click="refreshPdf" title="刷新">
          <el-icon><Refresh /></el-icon>
        </button>
        <button class="tool-btn close-btn" @click="emit('update:visible', false)" title="关闭">
          <el-icon><Close /></el-icon>
        </button>
      </div>
    </div>

    <!-- PDF 渲染区 -->
    <div class="pdf-viewer" ref="containerRef">
      <div v-if="loading" class="pdf-status">
        <el-icon class="loading-icon" :size="32"><Refresh /></el-icon>
        <span>加载中...</span>
      </div>
      <div v-else-if="errorMsg" class="pdf-status error">
        <span>加载失败：{{ errorMsg }}</span>
      </div>
      <div v-else class="pdf-canvas-wrapper">
        <canvas ref="canvasRef"></canvas>
      </div>
    </div>
  </el-dialog>
</template>

<style>
/* 全局样式：覆盖 el-dialog Teleport 到 body 的元素 */
.pdf-preview-dialog .el-overlay,
.pdf-preview-dialog .el-overlay-dialog {
  overflow: hidden;
  padding: 0;
  height: 100vh;
}

.pdf-preview-dialog .el-dialog__wrapper {
  overflow: hidden;
  padding: 0;
  inset: 0;
  height: 100vh;
}

.pdf-preview-dialog .el-dialog {
  margin: 0 !important;
  height: 100vh;
  max-height: 100vh;
  width: 100vw;
  max-width: 100vw;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  overflow: hidden;
  border-radius: 0;
  border: none;
  top: 0;
  left: 0;
  position: absolute;
}

.pdf-preview-dialog .el-dialog__header {
  display: none;
}

.pdf-preview-dialog .el-dialog__body {
  padding: 0;
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
  background: #525659;
  box-sizing: border-box;
}
</style>

<style scoped>
.pdf-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background: #323639;
  color: #fff;
  flex-shrink: 0;
  gap: 12px;
  flex-wrap: wrap;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tool-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: rgba(255, 255, 255, 0.85);
  cursor: pointer;
  transition: background 0.15s;
  font-size: 14px;
}

.tool-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.12);
}

.tool-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.tool-btn.close-btn {
  margin-left: 8px;
}

.tool-btn.zoom-level-btn {
  width: auto;
  padding: 0 10px;
  font-size: 13px;
  font-family: monospace;
}

.page-info {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.85);
  white-space: nowrap;
  display: flex;
  align-items: center;
  gap: 4px;
}

.page-input {
  width: 48px;
  height: 28px;
  text-align: center;
  border: 1px solid rgba(255, 255, 255, 0.25);
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
  font-size: 13px;
  outline: none;
  -moz-appearance: textfield;
}

.page-input::-webkit-inner-spin-button,
.page-input::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.page-input:focus {
  border-color: rgba(255, 255, 255, 0.5);
  background: rgba(255, 255, 255, 0.14);
}

.pdf-viewer {
  flex: 1;
  overflow: auto;
  display: flex;
  justify-content: center;
  padding: 20px;
}

.pdf-status {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 15px;
}

.pdf-status.error {
  color: #f56c6c;
}

.loading-icon {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.pdf-canvas-wrapper {
  display: flex;
  justify-content: center;
  align-self: flex-start;
}

.pdf-canvas-wrapper canvas {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
  background: #fff;
}
</style>
