<template>
  <div class="dashboard-wrapper">
    <!-- p5.js 背景层 -->
    <div id="bg-container"></div>

    <!-- 大屏内容层 -->
    <div class="content-layer">
      <!-- 顶部 KPI 卡片 -->
      <header class="header">
        <div class="logo-area">
          <h1 class="brand-title">UniSeek <span class="brand-sub">优寻</span></h1>
          <div class="glow-line"></div>
        </div>
        <div class="kpi-grid">
          <div class="kpi-card" v-for="(item, index) in kpiData" :key="index">
            <div class="kpi-label">{{ item.label }}</div>
            <div class="kpi-value">
              <span class="number">{{ item.value }}</span>
              <span class="unit" v-if="item.unit">{{ item.unit }}</span>
            </div>
            <div class="kpi-trend" :class="item.trend > 0 ? 'up' : 'down'">
              <span>{{ item.trend > 0 ? '▲' : '▼' }} {{ Math.abs(item.trend) }}%</span>
              <span class="sub-text">较昨日</span>
            </div>
          </div>
        </div>
      </header>

      <!-- 核心图表区 -->
      <main class="main-charts">
        <!-- 左侧：供需趋势 -->
        <section class="chart-card left-panel">
          <div class="card-header">
            <span class="title">📈 供需趋势</span>
            <span class="subtitle">近7日新增</span>
          </div>
          <div id="chart-trend" class="chart-container"></div>
        </section>

        <!-- 中央：岗位地域流向图 -->
        <section class="chart-card center-panel">
          <div class="card-header">
            <span class="title">🗺️ 全国岗位流向</span>
            <span class="subtitle">各城市岗位人才汇聚成都</span>
          </div>
          <div id="chart-map" class="chart-container"></div>
        </section>

        <!-- 右侧：行业需求占比 -->
        <section class="chart-card right-panel">
          <div class="card-header">
            <span class="title">🧩 行业需求占比</span>
            <span class="subtitle">热门行业 TOP5</span>
          </div>
          <div id="chart-ring" class="chart-container"></div>
        </section>
      </main>

      <!-- 底部：洞察与动态 -->
      <footer class="footer-charts">
        <!-- 左下：热门岗位排行 -->
        <section class="chart-card footer-left">
          <div class="card-header">
            <span class="title">🏆 热门岗位 TOP10</span>
            <span class="subtitle">按需求量排序</span>
          </div>
          <div id="chart-bar" class="chart-container"></div>
        </section>

        <!-- 右下：实时动态流 -->
        <section class="chart-card footer-right">
          <div class="card-header">
            <span class="title">📡 优寻实时动态</span>
            <span class="subtitle">最新投递 / 匹配</span>
          </div>
          <div class="feed-container">
            <div class="feed-list" ref="feedList">
              <div class="feed-item" v-for="(feed, idx) in feedData" :key="feed.id" :style="{ animationDelay: (idx * 2) + 's' }">
                <span class="feed-name">{{ feed.name }}</span>
                <span class="feed-action">{{ feed.action }}</span>
                <span class="feed-target">{{ feed.target }}</span>
                <span class="feed-time">{{ feed.time }}</span>
              </div>
            </div>
          </div>
        </section>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, reactive } from 'vue'
import * as echarts from 'echarts'
import p5 from 'p5'

// ============== 1. 品牌配色与数据 ==============
const COLORS = {
  primary: '#1762FB',
  secondary: '#685DFF',
  highlight: '#26E2FF',
  bg: '#051024'
}

// KPI 数据
const kpiData = reactive([
  { label: '平台总用户', value: '1,286,743', unit: '人', trend: 12.3 },
  { label: '在招活跃岗位', value: '54,823', unit: '个', trend: 8.7 },
  { label: '今日新增投递', value: '9,871', unit: '次', trend: -2.1 },
  { label: '人岗匹配指数', value: '86.7', unit: '分', trend: 1.5 }
])

// 动态流数据
const feedData = reactive([
  { id: 1, name: '张先生（杭州）', action: '投递', target: 'Java开发 @ 字节跳动', time: '刚刚' },
  { id: 2, name: '李女士（上海）', action: '匹配', target: '产品经理 @ 小红书', time: '1分钟前' },
  { id: 3, name: '王同学（北京）', action: '投递', target: '算法工程师 @ 百度', time: '3分钟前' },
  { id: 4, name: '赵经理（深圳）', action: '录用', target: 'UI设计 @ 腾讯', time: '5分钟前' },
  { id: 5, name: '陈先生（广州）', action: '投递', target: '数据分析 @ 网易', time: '7分钟前' },
])

// ============== 2. p5.js 粒子背景 ==============
const p5Instance = ref<p5 | null>(null)

const initP5 = () => {
  const sketch = (p: p5) => {
    let particles: any[] = []
    const numParticles = 150

    // 颜色转换辅助
    const hexToRgb = (hex: string) => {
      let r = parseInt(hex.slice(1, 3), 16)
      let g = parseInt(hex.slice(3, 5), 16)
      let b = parseInt(hex.slice(5, 7), 16)
      return { r, g, b }
    }
    const primaryRgb = hexToRgb(COLORS.primary)
    const secondaryRgb = hexToRgb(COLORS.secondary)
    const highlightRgb = hexToRgb(COLORS.highlight)

    class Particle {
      x: number
      y: number
      noiseOffsetX: number
      noiseOffsetY: number
      speed: number
      size: number
      colorType: string

      constructor() {
        this.x = p.random(p.width)
        this.y = p.random(p.height)
        this.noiseOffsetX = p.random(1000)
        this.noiseOffsetY = p.random(1000)
        this.speed = 0.5 + p.random(0.5)
        this.size = p.random(1.5, 3.5)
        this.colorType = p.random() > 0.6 ? 'secondary' : 'primary'
      }

      update() {
        let angle = p.noise(this.noiseOffsetX, this.noiseOffsetY) * p.TWO_PI * 2
        let vx = p.cos(angle) * this.speed
        let vy = p.sin(angle) * this.speed

        // 鼠标引力
        let dx = p.mouseX - this.x
        let dy = p.mouseY - this.y
        let dist = p.sqrt(dx * dx + dy * dy)
        if (dist < 200) {
          let force = (200 - dist) / 2000
          vx += dx * force
          vy += dy * force
        }

        this.x += vx
        this.y += vy
        this.noiseOffsetX += 0.005
        this.noiseOffsetY += 0.005

        if (this.x < -10) this.x = p.width + 10
        if (this.x > p.width + 10) this.x = -10
        if (this.y < -10) this.y = p.height + 10
        if (this.y > p.height + 10) this.y = -10
      }

      display() {
        let c = this.colorType === 'primary' ? primaryRgb : secondaryRgb
        p.fill(c.r, c.g, c.b, 180)
        p.noStroke()
        p.ellipse(this.x, this.y, this.size)
      }
    }

    p.setup = () => {
      let container = document.getElementById('bg-container')
      let width = container ? container.offsetWidth : window.innerWidth
      let height = container ? container.offsetHeight : window.innerHeight
      p.createCanvas(width, height)
      p.colorMode(p.RGB, 255)
      for (let i = 0; i < numParticles; i++) {
        particles.push(new Particle())
      }
    }

    p.draw = () => {
      p.background(5, 16, 36) // #051024

      // 绘制连线
      p.strokeCap(p.ROUND)
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          let a = particles[i]
          let b = particles[j]
          let dist = p.dist(a.x, a.y, b.x, b.y)
          let maxDist = 150
          if (dist < maxDist) {
            let alpha = p.map(dist, 0, maxDist, 180, 0)
            p.stroke(highlightRgb.r, highlightRgb.g, highlightRgb.b, alpha)
            p.strokeWeight(0.6 + p.map(dist, 0, maxDist, 1.5, 0))
            p.line(a.x, a.y, b.x, b.y)
          }
        }
      }

      // 更新和绘制粒子
      for (let particle of particles) {
        particle.update()
        particle.display()
      }

      // 自适应窗口
      if (p.width !== window.innerWidth || p.height !== window.innerHeight) {
        p.resizeCanvas(window.innerWidth, window.innerHeight)
      }
    }

    p.windowResized = () => {
      p.resizeCanvas(window.innerWidth, window.innerHeight)
    }
  }

  p5Instance.value = new p5(sketch, 'bg-container')
}

// ============== 3. ECharts 图表实例 ==============
let chartTrend: echarts.ECharts | null = null
let chartMap: echarts.ECharts | null = null
let chartRing: echarts.ECharts | null = null
let chartBar: echarts.ECharts | null = null

// 通用 ECharts 主题配置
const getCommonOption = (): echarts.EChartsOption => ({
  backgroundColor: 'transparent',
  textStyle: { color: 'rgba(255,255,255,0.75)', fontSize: 12 },
  grid: {
    borderWidth: 0,
    containLabel: true,
    splitLine: { show: true, lineStyle: { color: 'rgba(255,255,255,0.06)', type: 'dashed' as const, width: 1 } }
  },
  xAxis: { axisLine: { show: false }, axisTick: { show: false } },
  yAxis: { axisLine: { show: false }, axisTick: { show: false } },
  tooltip: {
    backgroundColor: 'rgba(5,16,36,0.85)',
    borderColor: COLORS.primary,
    borderWidth: 1,
    textStyle: { color: '#fff' },
    extraCssText: 'box-shadow: 0 0 20px rgba(23,98,251,0.3); backdrop-filter: blur(4px);'
  }
})

const initECharts = () => {
  // 1. 供需趋势图 (双轴折线)
  chartTrend = echarts.init(document.getElementById('chart-trend')!)
  const trendOption: echarts.EChartsOption = {
    ...getCommonOption(),
    legend: { data: ['新增岗位', '投递简历'], icon: 'roundRect', right: 10, top: 0, textStyle: { color: '#aaa' } },
    xAxis: { type: 'category', data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'] },
    yAxis: [{ type: 'value', name: '岗位数' }, { type: 'value', name: '投递数' }],
    series: [
      {
        name: '新增岗位',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 8,
        lineStyle: { width: 3, color: COLORS.primary, shadowBlur: 10, shadowColor: COLORS.primary },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: COLORS.primary + '80' },
            { offset: 1, color: COLORS.primary + '00' }
          ])
        },
        data: [320, 380, 420, 400, 480, 510, 560]
      },
      {
        name: '投递简历',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        symbol: 'diamond',
        symbolSize: 8,
        lineStyle: { width: 2, type: 'dashed', color: COLORS.highlight },
        data: [280, 310, 390, 430, 460, 490, 580]
      }
    ]
  }
  chartTrend.setOption(trendOption)

  // 2. 人才热度地图 — 全国人才汇聚成都的弧线连线
  chartMap = echarts.init(document.getElementById('chart-map')!)

  // 成都坐标（目标汇聚点）
  const chengdu: [number, number] = [104.06, 30.67]

  // 全国各城市坐标及其活跃度
  const cityData: { name: string; coord: [number, number]; value: number }[] = [
    { name: '北京', coord: [116.4, 39.9], value: 980 },
    { name: '上海', coord: [121.47, 31.23], value: 920 },
    { name: '广州', coord: [113.23, 23.16], value: 850 },
    { name: '深圳', coord: [114.07, 22.62], value: 780 },
    { name: '杭州', coord: [120.19, 30.26], value: 720 },
    { name: '武汉', coord: [114.31, 30.52], value: 680 },
    { name: '南京', coord: [118.78, 32.06], value: 650 },
    { name: '西安', coord: [108.94, 34.26], value: 620 },
    { name: '重庆', coord: [106.55, 29.57], value: 600 },
    { name: '长沙', coord: [112.98, 28.19], value: 580 },
    { name: '郑州', coord: [113.65, 34.76], value: 550 },
    { name: '天津', coord: [117.2, 39.13], value: 530 },
    { name: '苏州', coord: [120.62, 31.32], value: 510 },
    { name: '昆明', coord: [102.73, 25.04], value: 490 },
    { name: '青岛', coord: [120.33, 36.07], value: 470 },
    { name: '厦门', coord: [118.1, 24.46], value: 450 },
    { name: '哈尔滨', coord: [126.63, 45.75], value: 420 },
    { name: '大连', coord: [121.62, 38.92], value: 400 },
    { name: '贵阳', coord: [106.71, 26.57], value: 380 },
    { name: '合肥', coord: [117.27, 31.86], value: 360 },
  ]

  // 构造弧线数据：每个城市 → 成都
  const lineData = cityData.map(city => ({
    coords: [city.coord, chengdu] as [[number, number], [number, number]],
    value: city.value
  }))

  fetch('https://geo.datav.aliyun.com/areas_v3/bound/100000_full.json')
    .then(res => res.json())
    .then(chinaJson => {
      echarts.registerMap('china', chinaJson)
      const mapOption: echarts.EChartsOption = {
        ...getCommonOption(),
        tooltip: { trigger: 'item' },
        geo: {
          map: 'china',
          roam: false,
          itemStyle: {
            areaColor: '#0A1628',
            borderColor: '#1762FB',
            borderWidth: 0.5,
            shadowBlur: 10,
            shadowColor: 'rgba(23,98,251,0.3)'
          },
          emphasis: {
            itemStyle: { areaColor: COLORS.highlight }
          }
        },
        series: [
          {
            name: '岗位人才流向成都',
            type: 'lines',
            coordinateSystem: 'geo',
            zlevel: 2,
            effect: {
              show: true,
              period: 4,
              trailLength: 0.15,
              symbol: 'arrow',
              symbolSize: 6,
              color: COLORS.highlight
            },
            lineStyle: {
              width: 1.5,
              opacity: 0.5,
              curveness: 0.3,
              color: COLORS.primary
            },
            data: lineData
          },
          {
            name: '城市节点',
            type: 'scatter',
            coordinateSystem: 'geo',
            zlevel: 3,
            data: cityData.map(c => ({
              name: c.name,
              value: [...c.coord, c.value]
            })),
            symbolSize: (val: any) => Math.max(4, (val[2] as number) / 80),
            itemStyle: {
              color: COLORS.highlight,
              shadowBlur: 8,
              shadowColor: COLORS.highlight + '80'
            },
            label: {
              show: true,
              position: 'right',
              formatter: '{b}',
              color: 'rgba(255,255,255,0.7)',
              fontSize: 10
            }
          },
          {
            name: '成都（汇聚中心）',
            type: 'scatter',
            coordinateSystem: 'geo',
            zlevel: 4,
            data: [{ name: '成都', value: [...chengdu, 1000] }],
            symbol: 'circle',
            symbolSize: 28,
            itemStyle: {
              color: {
                type: 'radial',
                x: 0.5, y: 0.5, r: 0.5,
                colorStops: [
                  { offset: 0, color: COLORS.highlight },
                  { offset: 0.4, color: COLORS.primary },
                  { offset: 1, color: 'rgba(23,98,251,0.1)' }
                ]
              } as any,
              shadowBlur: 20,
              shadowColor: COLORS.highlight
            },
            label: {
              show: true,
              position: 'bottom',
              formatter: '成都\n汇聚中心',
              color: '#fff',
              fontSize: 12,
              fontWeight: 'bold',
              lineHeight: 18
            }
          }
        ]
      }
      chartMap.setOption(mapOption)
    })
    .catch(err => console.warn('地图加载失败，请检查网络', err))

  // 3. 行业需求占比 (环形图)
  chartRing = echarts.init(document.getElementById('chart-ring')!)
  const ringOption: echarts.EChartsOption = {
    ...getCommonOption(),
    tooltip: { trigger: 'item' },
    legend: { orient: 'vertical', right: '5%', top: 'center', textStyle: { color: '#aaa' } },
    series: [
      {
        name: '行业占比',
        type: 'pie',
        radius: ['50%', '75%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#051024',
          borderWidth: 2
        },
        label: {
          show: true,
          position: 'inside',
          formatter: '{d}%',
          color: '#fff',
          fontSize: 14,
          fontWeight: 'bold'
        },
        emphasis: {
          itemStyle: {
            shadowBlur: 20,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        },
        data: [
          { value: 34, name: '互联网/IT', itemStyle: { color: COLORS.primary } },
          { value: 20, name: '金融', itemStyle: { color: COLORS.secondary } },
          { value: 18, name: '制造业', itemStyle: { color: COLORS.highlight } },
          { value: 16, name: '医疗', itemStyle: { color: COLORS.primary + '99' } },
          { value: 12, name: '其他', itemStyle: { color: COLORS.secondary + '99' } }
        ]
      }
    ]
  }
  chartRing.setOption(ringOption)

  // 4. 热门岗位排行 (横向条形图)
  chartBar = echarts.init(document.getElementById('chart-bar')!)
  const barOption: echarts.EChartsOption = {
    ...getCommonOption(),
    grid: { left: '15%', right: '15%', top: '10%', bottom: '10%' },
    xAxis: { type: 'value', splitLine: { show: false }, axisLabel: { show: false } },
    yAxis: {
      type: 'category',
      data: ['AI算法', 'Java开发', '产品经理', '数据分析', 'UI设计', '运维', '测试', '运营', '销售', 'HR'],
      axisLabel: { color: '#aaa', fontWeight: 'bold', fontSize: 12 }
    },
    series: [
      {
        type: 'bar',
        data: [98, 87, 76, 65, 54, 43, 32, 21, 15, 10],
        barWidth: 12,
        itemStyle: {
          borderRadius: [0, 6, 6, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: COLORS.secondary },
            { offset: 1, color: COLORS.primary }
          ]),
          shadowBlur: 8,
          shadowColor: COLORS.primary + '60'
        },
        label: {
          show: true,
          position: 'right',
          formatter: (p: any) => p.value + ' 个',
          color: COLORS.highlight,
          fontWeight: 'bold'
        }
      }
    ]
  }
  chartBar.setOption(barOption)

  // 窗口自适应
  window.addEventListener('resize', handleResize)
}

const handleResize = () => {
  chartTrend?.resize()
  chartMap?.resize()
  chartRing?.resize()
  chartBar?.resize()
}

// ============== 4. 生命周期控制 ==============
onMounted(async () => {
  await nextTick()
  initP5()
  initECharts()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  p5Instance.value?.remove()
  chartTrend?.dispose()
  chartMap?.dispose()
  chartRing?.dispose()
  chartBar?.dispose()
})
</script>

<style scoped>
/* ===== 全局重置与布局 ===== */
.dashboard-wrapper {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background-color: #051024;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

#bg-container {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 0;
  pointer-events: none;
}

.content-layer {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 20px 30px;
  box-sizing: border-box;
  pointer-events: none;
}
.content-layer > * {
  pointer-events: auto;
}

/* ===== 顶部 KPI ===== */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 80px;
  margin-bottom: 20px;
  background: rgba(23, 98, 251, 0.08);
  border: 1px solid rgba(23, 98, 251, 0.2);
  border-radius: 16px;
  padding: 0 24px;
  backdrop-filter: blur(10px);
  box-shadow: 0 0 40px rgba(23, 98, 251, 0.1);
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 12px;
}
.brand-title {
  font-size: 28px;
  font-weight: 700;
  color: #fff;
  letter-spacing: 2px;
  background: linear-gradient(135deg, #1762FB, #685DFF);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  text-shadow: 0 0 20px rgba(23, 98, 251, 0.3);
}
.brand-sub {
  font-size: 18px;
  font-weight: 300;
  color: rgba(255, 255, 255, 0.6);
  -webkit-text-fill-color: rgba(255, 255, 255, 0.6);
  margin-left: 8px;
}
.glow-line {
  width: 60px;
  height: 2px;
  background: linear-gradient(90deg, #1762FB, #26E2FF);
  border-radius: 2px;
  box-shadow: 0 0 20px #1762FB;
}

.kpi-grid {
  display: flex;
  gap: 30px;
}
.kpi-card {
  text-align: center;
  min-width: 120px;
}
.kpi-label {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.6);
  letter-spacing: 1px;
}
.kpi-value {
  font-size: 28px;
  font-weight: 700;
  color: #fff;
  margin: 4px 0;
  text-shadow: 0 0 20px rgba(23, 98, 251, 0.4);
  font-family: 'DIN', sans-serif;
}
.kpi-value .unit {
  font-size: 14px;
  font-weight: 400;
  color: rgba(255, 255, 255, 0.5);
  margin-left: 4px;
}
.kpi-trend {
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.kpi-trend.up { color: #26E2FF; }
.kpi-trend.down { color: #685DFF; }
.kpi-trend .sub-text {
  color: rgba(255, 255, 255, 0.3);
}

/* ===== 主图表网格 ===== */
.main-charts {
  display: flex;
  flex: 1;
  gap: 20px;
  margin-bottom: 20px;
  min-height: 0;
}

.chart-card {
  background: rgba(5, 16, 36, 0.6);
  border: 1px solid rgba(23, 98, 251, 0.15);
  border-radius: 16px;
  padding: 16px;
  backdrop-filter: blur(8px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  display: flex;
  flex-direction: column;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.card-header .title {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  letter-spacing: 1px;
}
.card-header .subtitle {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.4);
}

.chart-container {
  flex: 1;
  width: 100%;
  min-height: 0;
}

.left-panel { flex: 0 0 28%; }
.center-panel { flex: 1; }
.right-panel { flex: 0 0 22%; }

/* ===== 底部图表网格 ===== */
.footer-charts {
  display: flex;
  gap: 20px;
  height: 180px;
}
.footer-left { flex: 1; }
.footer-right { flex: 1; }

/* ===== 动态流列表 ===== */
.feed-container {
  flex: 1;
  overflow: hidden;
  position: relative;
}
.feed-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  animation: scrollFeed 20s linear infinite;
}
@keyframes scrollFeed {
  0% { transform: translateY(0); }
  100% { transform: translateY(-50%); }
}
.feed-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  background: rgba(23, 98, 251, 0.05);
  border-radius: 8px;
  border-left: 2px solid #1762FB;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.8);
}
.feed-name { color: #26E2FF; font-weight: 500; }
.feed-action { color: #fff; }
.feed-target { color: rgba(255, 255, 255, 0.6); }
.feed-time { margin-left: auto; font-size: 11px; color: rgba(255, 255, 255, 0.3); }

/* ===== 响应式微调 ===== */
@media (max-width: 1400px) {
  .header { height: 70px; padding: 0 16px; }
  .kpi-value { font-size: 22px; }
  .main-charts { flex-wrap: wrap; }
  .left-panel, .right-panel { flex: 1 1 40%; }
  .center-panel { flex: 1 1 100%; order: -1; }
  .footer-charts { height: 140px; }
}
</style>
