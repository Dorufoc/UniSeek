<template>
  <div class="dashboard-wrapper">
    <!-- ECharts 噪声背景层 -->
    <div id="bg-container"></div>

    <!-- 大屏内容层 -->
    <div class="content-layer">
      <!-- 顶部 KPI 卡片 -->
      <header class="header">
        <div class="logo-area">
          <h1 class="brand-title">
            <img src="@/assets/uniseek-icon.png" alt="UniSeek" class="brand-icon" />
            <img src="@/assets/uniseek-logo.svg" alt="UniSeek优寻" class="brand-logo" />
          </h1>
          <span class="range-badge">{{ timeRangeLabels[currentRange] || currentRange }}</span>
          <div class="glow-line"></div>
        </div>
        <div class="kpi-grid">
          <div class="kpi-card" v-for="(item, index) in kpiData" :key="index">
            <div class="kpi-label">{{ item.label }}</div>
            <div class="kpi-value">
              <span class="number">{{ item.value }}</span>
              <span class="unit" v-if="item.unit">{{ item.unit }}</span>
            </div>
            <div class="kpi-trend" :class="item.trend > 0 ? 'up' : 'down'" v-if="item.trend !== null">
              <span>{{ item.trend > 0 ? '▲' : '▼' }} {{ Math.abs(item.trend) }}%</span>
              <span class="sub-text">较昨日</span>
            </div>
          </div>
        </div>
      </header>

      <!-- 核心图表区 -->
      <main class="main-charts">
        <!-- 左侧：供需趋势 + 行业需求占比（垂直排列） -->
        <section class="chart-card left-panel">
          <div class="left-group">
            <div class="card-header">
              <span class="title">供需趋势</span>
              <span class="subtitle">近7日新增</span>
            </div>
            <div id="chart-trend" class="chart-container"></div>
          </div>
          <div class="left-group">
            <div class="card-header">
              <span class="title">行业需求占比</span>
              <span class="subtitle">热门行业 TOP5</span>
            </div>
            <div id="chart-ring" class="chart-container"></div>
          </div>
        </section>

        <!-- 中央：岗位地域流向图 + 投递转化进度条 -->
        <section class="chart-card center-panel">
          <div class="card-header">
            <span class="title">全国岗位流向</span>
            <span class="subtitle">求职者来源 → 企业所在城市</span>
          </div>
          <div id="chart-map" class="chart-container" style="flex:1;"></div>
          <!-- 投递转化进度条 -->
          <div class="funnel-section">
            <div class="funnel-header">
              <span class="funnel-title">投递转化率</span>
              <span class="funnel-stats">累计投递 <strong id="funnel-total">-</strong> 次 · 今日新增 <strong id="funnel-today">-</strong> 次</span>
            </div>
            <div class="funnel-bar" id="funnel-bar"></div>
            <div class="funnel-labels">
              <span style="color:#1762FB;">● 已投递</span>
              <span style="color:#26E2FF;">● 待面试</span>
              <span style="color:#67C23A;">● 面试通过</span>
              <span style="color:#E6A23C;">● 已录用</span>
              <span style="color:#909399;">● 已淘汰</span>
              <span style="color:#F56C6C;">● 已完成</span>
            </div>
          </div>
          <!-- 企业资质审核 -->
          <div class="funnel-row">
            <div class="funnel-row-header">
              <span class="funnel-title">企业资质审核</span>
              <span class="funnel-stats">共 <strong id="ent-total">-</strong> 家企业</span>
            </div>
            <div class="funnel-bar" id="funnel-enterprise"></div>
            <div class="funnel-labels">
              <span style="color:#E6A23C;">● 待审核</span>
              <span style="color:#67C23A;">● 已认证</span>
              <span style="color:#F56C6C;">● 已驳回</span>
            </div>
          </div>
          <!-- 实名认证率 -->
          <div class="funnel-row">
            <div class="funnel-row-header">
              <span class="funnel-title">实名认证率</span>
              <span class="funnel-stats">认证率 <strong id="auth-rate">-</strong></span>
            </div>
            <div class="funnel-bar" id="funnel-auth"></div>
            <div class="funnel-labels">
              <span style="color:#67C23A;">● 已认证</span>
              <span style="color:#909399;">● 未认证</span>
            </div>
          </div>
        </section>

        <!-- 右侧：热门岗位 TOP10 + 实时动态（垂直排列） -->
        <section class="chart-card right-panel">
          <div class="right-group">
            <div class="card-header">
              <span class="title">热门岗位 TOP10</span>
              <span class="subtitle">按需求量排序</span>
            </div>
            <div id="chart-bar" class="chart-container"></div>
          </div>
          <div class="right-group">
            <div class="card-header">
              <span class="title">优寻实时动态</span>
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
          </div>
        </section>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getScreenSummary, getIndustryDistribution, getHotTasks, getLatestActivity, getTalentFlow, getApplicationFunnel, getEnterpriseSummary } from '@/api/admin'

// ============== 1. 品牌配色与数据 ==============
const COLORS = {
  primary: '#1762FB',
  secondary: '#685DFF',
  highlight: '#26E2FF',
  bg: '#051024'
}

// KPI 数据
const kpiData = ref([
  { label: '平台总用户', value: '-', unit: '人', trend: null },
  { label: '在招活跃岗位', value: '-', unit: '个', trend: null },
  { label: '今日新增投递', value: '-', unit: '次', trend: null },
  { label: '认证企业数', value: '-', unit: '家', trend: null }
])

const fetchAllData = async (range?: string) => {
  try {
    // KPI + 趋势图数据
    const summaryRes = await getScreenSummary(range || currentRange.value)
    if (summaryRes.summary) {
      kpiData.value = [
        { label: '平台总用户', value: (summaryRes.summary.totalUsers ?? 0).toLocaleString(), unit: '人', trend: null },
        { label: '在招活跃岗位', value: (summaryRes.summary.publishedTasks ?? 0).toLocaleString(), unit: '个', trend: null },
        { label: '今日新增投递', value: (summaryRes.latestDeliveries ?? 0).toLocaleString(), unit: '次', trend: null },
        { label: '认证企业数', value: (summaryRes.summary.totalEnterprises ?? 0).toLocaleString(), unit: '家', trend: null }
      ]
    }
    // 供需趋势图数据
    if (summaryRes.dailyList && summaryRes.dailyList.length > 0) {
      const dates = summaryRes.dailyList.map((d: any) => d.date.slice(5))
      if (chartTrend) {
        chartTrend.setOption({
          legend: {
            data: ['新增用户', '新增企业', '新增岗位', '新增投递', '新增面试', '新增入职'],
            icon: 'roundRect', right: 10, top: 0,
            textStyle: { color: '#aaa', fontSize: 10 }
          },
          xAxis: { data: dates },
          yAxis: { type: 'value', name: '数量' },
          series: [
            {
              name: '新增用户',
              type: 'line', smooth: true, symbol: 'circle', symbolSize: 4,
              lineStyle: { width: 2, color: '#1762FB' },
              data: summaryRes.dailyList.map((d: any) => d.newUsers)
            },
            {
              name: '新增企业',
              type: 'line', smooth: true, symbol: 'diamond', symbolSize: 4,
              lineStyle: { width: 2, color: '#67C23A' },
              data: summaryRes.dailyList.map((d: any) => d.newEnterprises)
            },
            {
              name: '新增岗位',
              type: 'line', smooth: true, symbol: 'circle', symbolSize: 4,
              lineStyle: { width: 2, color: '#1762FB' },
              areaStyle: {
                color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                  { offset: 0, color: '#1762FB40' },
                  { offset: 1, color: '#1762FB00' }
                ])
              },
              data: summaryRes.dailyList.map((d: any) => d.newTasks)
            },
            {
              name: '新增投递',
              type: 'line', smooth: true, symbol: 'diamond', symbolSize: 4,
              lineStyle: { width: 2, type: 'dashed', color: '#26E2FF' },
              data: summaryRes.dailyList.map((d: any) => d.newApplications)
            },
            {
              name: '新增面试',
              type: 'line', smooth: true, symbol: 'triangle', symbolSize: 4,
              lineStyle: { width: 2, color: '#E6A23C' },
              data: summaryRes.dailyList.map((d: any) => d.newInterviews)
            },
            {
              name: '新增入职',
              type: 'line', smooth: true, symbol: 'rect', symbolSize: 4,
              lineStyle: { width: 2, color: '#F56C6C' },
              data: summaryRes.dailyList.map((d: any) => d.newEntries)
            }
          ]
        })
      }
    }

    // 行业占比数据
    const [industryRes, hotTasksRes, activityRes, talentFlowRes, funnelRes, enterpriseRes] = await Promise.allSettled([
      getIndustryDistribution(),
      getHotTasks(),
      getLatestActivity(),
      getTalentFlow(),
      getApplicationFunnel(),
      getEnterpriseSummary()
    ])

    if (industryRes.status === 'fulfilled' && industryRes.value && chartRing) {
      chartRing.setOption({
        series: [{
          data: industryRes.value.map((item: any) => ({ name: item.industry, value: item.count }))
        }]
      })
    }

    if (hotTasksRes.status === 'fulfilled' && hotTasksRes.value && chartBar) {
      const top10 = hotTasksRes.value.slice(0, 10)
      chartBar.setOption({
        xAxis: { data: top10.map((t: any) => t.title) },
        yAxis: { name: '投递量' },
        series: [{ data: top10.map((t: any) => t.applicationCount) }]
      })
    }

    if (activityRes.status === 'fulfilled' && activityRes.value) {
      feedData.value = activityRes.value.map((item: any) => ({
        id: item.id,
        name: item.userName || '系统',
        action: item.message || '',
        target: item.target || '',
        time: item.time || ''
      }))
    }

    if (talentFlowRes.status === 'fulfilled' && talentFlowRes.value && talentFlowRes.value.length > 0 && chartMap) {
      // 地区编码 → 城市坐标映射（常用城市）
      const regionCoordMap: Record<string, { name: string; coord: [number, number] }> = {
        '110000': { name: '北京市', coord: [116.4, 39.9] },
        '120000': { name: '天津市', coord: [117.2, 39.13] },
        '130100': { name: '石家庄', coord: [114.48, 38.03] },
        '130200': { name: '唐山', coord: [118.18, 39.63] },
        '130300': { name: '秦皇岛', coord: [119.59, 39.93] },
        '130400': { name: '邯郸', coord: [114.49, 36.61] },
        '130500': { name: '邢台', coord: [114.5, 37.07] },
        '130600': { name: '保定', coord: [115.48, 38.87] },
        '140100': { name: '太原', coord: [112.55, 37.87] },
        '140200': { name: '大同', coord: [113.3, 40.08] },
        '210100': { name: '沈阳', coord: [123.43, 41.8] },
        '210200': { name: '大连', coord: [121.62, 38.92] },
        '210300': { name: '鞍山', coord: [123.0, 41.1] },
        '220100': { name: '长春', coord: [125.32, 43.9] },
        '230100': { name: '哈尔滨', coord: [126.63, 45.75] },
        '310000': { name: '上海市', coord: [121.47, 31.23] },
        '320100': { name: '南京', coord: [118.78, 32.06] },
        '320200': { name: '无锡', coord: [120.3, 31.57] },
        '320300': { name: '徐州', coord: [117.2, 34.26] },
        '320400': { name: '常州', coord: [119.97, 31.78] },
        '320500': { name: '苏州', coord: [120.62, 31.32] },
        '320600': { name: '南通', coord: [120.86, 32.01] },
        '321000': { name: '扬州', coord: [119.42, 32.39] },
        '330100': { name: '杭州', coord: [120.19, 30.26] },
        '330200': { name: '宁波', coord: [121.54, 29.87] },
        '330300': { name: '温州', coord: [120.7, 28.0] },
        '330400': { name: '嘉兴', coord: [120.76, 30.77] },
        '330500': { name: '湖州', coord: [120.09, 30.87] },
        '330600': { name: '绍兴', coord: [120.58, 30.0] },
        '331000': { name: '台州', coord: [121.42, 28.65] },
        '340100': { name: '合肥', coord: [117.27, 31.86] },
        '340200': { name: '芜湖', coord: [118.38, 31.33] },
        '350100': { name: '福州', coord: [119.3, 26.08] },
        '350200': { name: '厦门', coord: [118.1, 24.46] },
        '350500': { name: '泉州', coord: [118.59, 24.91] },
        '360100': { name: '南昌', coord: [115.86, 28.68] },
        '370100': { name: '济南', coord: [117.0, 36.65] },
        '370200': { name: '青岛', coord: [120.33, 36.07] },
        '370600': { name: '烟台', coord: [121.39, 37.52] },
        '370700': { name: '潍坊', coord: [119.1, 36.62] },
        '410100': { name: '郑州', coord: [113.65, 34.76] },
        '410300': { name: '洛阳', coord: [112.45, 34.62] },
        '420100': { name: '武汉', coord: [114.31, 30.52] },
        '430100': { name: '长沙', coord: [112.98, 28.19] },
        '430400': { name: '衡阳', coord: [112.57, 26.89] },
        '440100': { name: '广州', coord: [113.23, 23.16] },
        '440300': { name: '深圳', coord: [114.07, 22.62] },
        '440400': { name: '珠海', coord: [113.57, 22.27] },
        '440500': { name: '汕头', coord: [116.7, 23.37] },
        '440600': { name: '佛山', coord: [113.12, 23.02] },
        '440700': { name: '江门', coord: [113.08, 22.58] },
        '441300': { name: '惠州', coord: [114.42, 23.11] },
        '441900': { name: '东莞', coord: [113.75, 23.05] },
        '442000': { name: '中山', coord: [113.38, 22.52] },
        '450100': { name: '南宁', coord: [108.37, 22.82] },
        '450300': { name: '桂林', coord: [110.28, 25.27] },
        '460100': { name: '海口', coord: [110.32, 20.03] },
        '500000': { name: '重庆市', coord: [106.55, 29.57] },
        '510100': { name: '成都', coord: [104.06, 30.67] },
        '510300': { name: '自贡', coord: [104.78, 29.34] },
        '510500': { name: '泸州', coord: [105.44, 28.87] },
        '510600': { name: '德阳', coord: [104.4, 31.13] },
        '510700': { name: '绵阳', coord: [104.74, 31.46] },
        '520100': { name: '贵阳', coord: [106.71, 26.57] },
        '530100': { name: '昆明', coord: [102.73, 25.04] },
        '610100': { name: '西安', coord: [108.94, 34.26] },
        '610300': { name: '宝鸡', coord: [107.15, 34.38] },
        '620100': { name: '兰州', coord: [103.83, 36.06] },
        '630100': { name: '西宁', coord: [101.76, 36.63] },
        '640100': { name: '银川', coord: [106.28, 38.47] },
        '650100': { name: '乌鲁木齐', coord: [87.62, 43.82] },
      }

      // 汇总流向：按来源城市聚合
      const flowMap = new Map<string, { fromName: string; fromCoord: [number, number]; toName: string; toCoord: [number, number]; count: number }>()
      
      talentFlowRes.value.forEach((flow: any) => {
        // 身份证前6位是区县级代码（如110101=北京东城），需转为城市级代码
        // 直辖市（11/12/31/50）：城市级=前2位+"0000"（如110000=北京市）
        // 普通地级市：城市级=前4位+"00"（如440300=深圳市）
        const rawFrom = String(flow.fromCode)
        const rawTo = String(flow.toCode)
        const fromCode = ['11','12','31','50'].includes(rawFrom.substring(0,2))
          ? rawFrom.substring(0,2) + '0000'
          : rawFrom.substring(0,4) + '00'
        const toCode = ['11','12','31','50'].includes(rawTo.substring(0,2))
          ? rawTo.substring(0,2) + '0000'
          : rawTo.substring(0,4) + '00'
        const fromCity = regionCoordMap[fromCode]
        const toCity = regionCoordMap[toCode]
        if (!fromCity || !toCity) return
        
        const key = fromCode + '-' + toCode
        if (flowMap.has(key)) {
          flowMap.get(key)!.count += flow.flowCount
        } else {
          flowMap.set(key, {
            fromName: fromCity.name,
            fromCoord: fromCity.coord,
            toName: toCity.name,
            toCoord: toCity.coord,
            count: flow.flowCount
          })
        }
      })

      const flows = Array.from(flowMap.values())
      if (flows.length > 0) {
        // 按热度排序取前 20 条主要流向
        flows.sort((a, b) => b.count - a.count)
        const topFlows = flows.slice(0, 20)
        
        // 更新地图数据
        const mapOption = chartMap.getOption() as any
        // 更新散点（城市节点）
        const cityPoints = new Map<string, { name: string; coord: [number, number]; value: number }>()
        topFlows.forEach(f => {
          const fromKey = f.fromName
          const toKey = f.toName
          if (!cityPoints.has(fromKey)) {
            cityPoints.set(fromKey, { name: f.fromName, coord: f.fromCoord, value: 0 })
          }
          if (!cityPoints.has(toKey)) {
            cityPoints.set(toKey, { name: f.toName, coord: f.toCoord, value: 0 })
          }
          cityPoints.get(fromKey)!.value += f.count
          cityPoints.get(toKey)!.value += f.count
        })
        
        // 构建弧线数据
        const linesData = topFlows.map(f => ({
          coords: [f.fromCoord, f.toCoord],
          lineStyle: { width: Math.min(f.count * 1.5, 4), opacity: 0.3 + Math.min(f.count / 20, 0.5) }
        }))

        // 应用新数据到 ECharts option
        chartMap.setOption({
          series: [
            {
              name: '人才流向',
              type: 'lines',
              coordinateSystem: 'geo',
              geoIndex: 0,
              zlevel: 2,
              effect: {
                show: true,
                period: 4,
                trailLength: 0.15,
                symbol: 'arrow',
                symbolSize: 6,
                color: '#26E2FF'
              },
              lineStyle: {
                width: 1.5,
                opacity: 0.5,
                curveness: 0.3,
                color: '#1762FB'
              },
              data: linesData
            },
            {
              name: '城市节点',
              type: 'scatter',
              coordinateSystem: 'geo',
              geoIndex: 0,
              zlevel: 3,
              data: Array.from(cityPoints.values()).map(c => ({
                name: c.name,
                value: [...c.coord, c.value]
              })),
              symbolSize: (val: any) => Math.max(4, (val[2] as number) / 80),
              itemStyle: {
                color: '#26E2FF',
                shadowBlur: 8,
                shadowColor: '#26E2FF80'
              },
              label: {
                show: true,
                position: 'right',
                formatter: '{b}',
                color: 'rgba(255,255,255,0.7)',
                fontSize: 10
              }
            }
          ]
        })
      }
    }
    if (funnelRes.status === 'fulfilled' && funnelRes.value) {
      const funnelData = funnelRes.value
      const total = funnelData.total || 0
      const statusList = funnelData.statusList || []
      const funnelEl = document.getElementById('funnel-bar')
      if (funnelEl && total > 0) {
        const colors: Record<number, string> = { 0: '#1762FB', 1: '#26E2FF', 2: '#67C23A', 3: '#E6A23C', 4: '#909399', 5: '#F56C6C' }
        let html = ''
        statusList.forEach((item: any) => {
          const pct = ((item.count / total) * 100).toFixed(1)
          html += `<div class="funnel-segment" style="flex:${item.count};background:${colors[item.status] || '#333'};" title="${item.name}: ${item.count} (${pct}%)"><span class="funnel-count">${item.count}</span></div>`
        })
        funnelEl.innerHTML = html
        document.getElementById('funnel-total')!.textContent = total.toLocaleString()
        document.getElementById('funnel-today')!.textContent = (funnelData.todayNew || 0).toLocaleString()
      }
    }
    if (enterpriseRes.status === 'fulfilled' && enterpriseRes.value) {
      const entData = enterpriseRes.value
      const auditList = entData.auditList || []
      const entTotal = entData.totalEnterprise || 0
      const entEl = document.getElementById('funnel-enterprise')
      if (entEl && entTotal > 0) {
        const entColors: Record<number, string> = { 0: '#E6A23C', 1: '#67C23A', 2: '#F56C6C' }
        let html = ''
        auditList.forEach((item: any) => {
          const pct = ((item.count / entTotal) * 100).toFixed(1)
          html += `<div class="funnel-segment" style="flex:${item.count};background:${entColors[item.status] || '#333'};" title="${item.name}: ${item.count} (${pct}%)"><span class="funnel-count">${item.count}</span></div>`
        })
        entEl.innerHTML = html
        document.getElementById('ent-total')!.textContent = entTotal.toLocaleString()
      }
      // 实名认证率
      const totalUser = entData.totalUser || 0
      const authed = entData.authedCount || 0
      const unauth = entData.unauthedCount || 0
      const authEl = document.getElementById('funnel-auth')
      if (authEl && totalUser > 0) {
        authEl.innerHTML = `
          <div class="funnel-segment" style="flex:${authed};background:#67C23A;" title="已认证: ${authed} (${((authed/totalUser)*100).toFixed(1)}%)"><span class="funnel-count">${authed}</span></div>
          <div class="funnel-segment" style="flex:${unauth};background:#909399;" title="未认证: ${unauth} (${((unauth/totalUser)*100).toFixed(1)}%)"><span class="funnel-count">${unauth}</span></div>
        `
        document.getElementById('auth-rate')!.textContent = ((authed / totalUser) * 100).toFixed(1) + '%'
      }
    }
  } catch (e) {
    console.warn('大屏数据加载失败，使用默认展示', e)
  }
}

// 动态流数据
const feedData = ref<Array<{ id: number; name: string; action: string; target: string; time: string }>>([])

// 时间范围轮播
const timeRanges = ['10y', '12m', '30d', '7d', '24h']
const timeRangeLabels: Record<string, string> = {
  '10y': '近 10 年',
  '12m': '近 12 月',
  '30d': '近 30 天',
  '7d': '近 7 天',
  '24h': '近 24 小时'
}
const currentRange = ref('7d')
let rangeIndex = 3


// ============== 3. ECharts 图表实例 ==============
// ============== 2. ECharts 噪声背景 ==============
let bgChart: echarts.ECharts | null = null

// Perlin noise helper (from https://github.com/josephg/noisejs)
function getNoiseHelper() {
  class Grad {
    x: number; y: number; z: number;
    constructor(x: number, y: number, z: number) { this.x = x; this.y = y; this.z = z; }
    dot2(x: number, y: number) { return this.x * x + this.y * y; }
    dot3(x: number, y: number, z: number) { return this.x * x + this.y * y + this.z * z; }
  }
  const grad3 = [
    new Grad(1,1,0), new Grad(-1,1,0), new Grad(1,-1,0), new Grad(-1,-1,0),
    new Grad(1,0,1), new Grad(-1,0,1), new Grad(1,0,-1), new Grad(-1,0,-1),
    new Grad(0,1,1), new Grad(0,-1,1), new Grad(0,1,-1), new Grad(0,-1,-1)
  ]
  const p = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]
  let perm = new Array(512)
  let gradP = new Array(512)
  function seed(seed: number) { if (seed > 0 && seed < 1) seed *= 65536; seed = Math.floor(seed); if (seed < 256) seed |= seed << 8; for (let i = 0; i < 256; i++) { let v = (i & 1) ? p[i] ^ (seed & 255) : p[i] ^ ((seed >> 8) & 255); perm[i] = perm[i + 256] = v; gradP[i] = gradP[i + 256] = grad3[v % 12] } }
  function fade(t: number) { return t * t * t * (t * (t * 6 - 15) + 10) }
  function lerp(a: number, b: number, t: number) { return (1 - t) * a + t * b }
  function perlin2(x: number, y: number) {
    let X = Math.floor(x), Y = Math.floor(y)
    x = x - X; y = y - Y
    X = X & 255; Y = Y & 255
    let n00 = gradP[X + perm[Y]].dot2(x, y)
    let n01 = gradP[X + perm[Y + 1]].dot2(x, y - 1)
    let n10 = gradP[X + 1 + perm[Y]].dot2(x - 1, y)
    let n11 = gradP[X + 1 + perm[Y + 1]].dot2(x - 1, y - 1)
    let u = fade(x)
    return lerp(lerp(n00, n10, u), lerp(n01, n11, u), fade(y))
  }
  seed(Math.random())
  return { seed, perlin2 }
}

const initBgNoise = () => {
  const bgDom = document.getElementById('bg-container')
  if (!bgDom) return
  bgChart = echarts.init(bgDom)
  const noise = getNoiseHelper()
  
  const config = {
    frequency: 500,
    offsetX: 0,
    offsetY: 100,
    minSize: 1,
    maxSize: 3,
    duration: 4000,
    color0: '#1762FB',
    color1: '#051024',
    backgroundColor: '#051024'
  }

  function createElements() {
    const elements: any[] = []
    const width = bgDom.offsetWidth
    const height = bgDom.offsetHeight
    for (let x = 10; x < width; x += 10) {
      for (let y = 10; y < height; y += 10) {
        const rand = noise.perlin2(x / config.frequency + config.offsetX, y / config.frequency + config.offsetY)
        elements.push({
          type: 'circle',
          x, y,
          style: { fill: config.color1 },
          shape: { r: config.maxSize },
          keyframeAnimation: {
            duration: config.duration,
            loop: true,
            delay: (rand - 1) * 4000,
            keyframes: [
              { percent: 0.5, easing: 'sinusoidalInOut', style: { fill: config.color0 }, scaleX: config.minSize / config.maxSize, scaleY: config.minSize / config.maxSize },
              { percent: 1, easing: 'sinusoidalInOut', style: { fill: config.color1 }, scaleX: 1, scaleY: 1 }
            ]
          }
        })
      }
    }
    return elements
  }

  bgChart.setOption({
    backgroundColor: config.backgroundColor,
    animationFrameRate: 30,
    graphic: { elements: createElements() }
  })
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

  // 2. 人才热度地图 — 全国人才流向（数据由 fetchAllData 提供真实 API 数据）
  chartMap = echarts.init(document.getElementById('chart-map')!)
  const chengdu: [number, number] = [104.06, 30.67]

  fetch('https://geo.datav.aliyun.com/areas_v3/bound/100000_full.json')
    .then(res => res.json())
    .then(chinaJson => {
      echarts.registerMap('china', chinaJson)

      const mapOption = {
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
          },
          label: {
            show: false
          },
          regions: [
            {
              name: '南海诸岛',
              itemStyle: {
                areaColor: '#0A1628',
                borderColor: '#1762FB80',
                borderWidth: 1
              },
              label: {
                show: true,
                color: 'rgba(255,255,255,0.4)',
                fontSize: 9,
                position: 'bottom'
              }
            }
          ]
        }
      }
      chartMap.setOption(mapOption)
      // 地图就绪后再拉取数据
      fetchAllData()
    })
    .catch(err => console.warn('地图加载失败，请检查网络', err))

  // 3. 行业需求占比 (环形图)
  chartRing = echarts.init(document.getElementById('chart-ring')!)
  const ringOption: echarts.EChartsOption = {
    ...getCommonOption(),
    tooltip: { trigger: 'item' },
    series: [
      {
        name: '行业占比',
        type: 'pie',
        radius: ['40%', '75%'],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 6,
          borderColor: '#051024',
          borderWidth: 2
        },
        label: {
          show: true,
          position: 'outside',
          formatter: '{b}\n{d}%',
          color: 'rgba(255,255,255,0.85)',
          fontSize: 11,
          lineHeight: 16,
          fontWeight: 'normal'
        },
        labelLine: {
          show: true,
          length: 8,
          length2: 12,
          lineStyle: { color: 'rgba(255,255,255,0.2)' }
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
onMounted(() => {
  initBgNoise()
  initECharts()
  const intervalId = setInterval(() => {
    rangeIndex = (rangeIndex + 1) % timeRanges.length
    currentRange.value = timeRanges[rangeIndex]
    fetchAllData(currentRange.value)
  }, 10000)
  onUnmounted(() => {
    window.removeEventListener('resize', handleResize)
    bgChart?.dispose()
    chartTrend?.dispose()
    chartMap?.dispose()
    chartRing?.dispose()
    chartBar?.dispose()
    clearInterval(intervalId)
  })
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
  backdrop-filter: blur(4px);
  box-shadow: 0 0 40px rgba(23, 98, 251, 0.1);
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 12px;
}
.brand-title {
  margin: 0;
  line-height: 1;
  display: flex;
  align-items: center;
}
.brand-logo {
  height: 18px;
  width: auto;
  display: block;
}
.brand-icon {
  height: 72px;
  width: auto;
  margin-right: 12px;
  filter: brightness(0) invert(1);
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

.range-badge {
  font-size: 11px;
  color: rgba(255,255,255,0.5);
  background: rgba(23,98,251,0.15);
  border: 1px solid rgba(23,98,251,0.3);
  border-radius: 12px;
  padding: 2px 10px;
  margin-left: 12px;
  white-space: nowrap;
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
  backdrop-filter: blur(4px);
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

.left-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-width: 0;
}
.left-panel .left-group {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.left-panel .left-group .chart-container {
  flex: 1;
}
.center-panel { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.right-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-width: 0;
}
.right-panel .right-group {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.right-panel .right-group .chart-container {
  flex: 1;
}
.right-panel .right-group .feed-container {
  flex: 1;
  overflow: hidden;
}

/* ===== 底部图表网格 ===== */
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
  .left-panel { flex: 1 1 40%; }
  .center-panel { flex: 1 1 100%; order: -1; }
  .right-panel { flex: 1 1 100%; }
}

/* ===== 投递转化进度条 ===== */
.funnel-section {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid rgba(23,98,251,0.15);
}
.funnel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}
.funnel-title {
  font-size: 13px;
  font-weight: 600;
  color: #fff;
}
.funnel-stats {
  font-size: 11px;
  color: rgba(255,255,255,0.5);
}
.funnel-stats strong {
  color: #26E2FF;
  font-weight: 600;
}
.funnel-bar {
  display: flex;
  height: 14px;
  border-radius: 7px;
  overflow: hidden;
  background: rgba(255,255,255,0.05);
}
.funnel-segment {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: flex 0.5s ease;
  min-width: 20px;
}
.funnel-count {
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  text-shadow: 0 1px 2px rgba(0,0,0,0.6);
  pointer-events: none;
}
.funnel-labels {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
  margin-top: 6px;
  font-size: 11px;
  color: rgba(255,255,255,0.5);
}
.funnel-row {
  margin-top: 6px;
  padding-top: 6px;
  border-top: 1px solid rgba(23,98,251,0.08);
}
.funnel-row-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}
</style>
