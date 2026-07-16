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
            <img src="@/assets/uniseek_text_white_ZH.svg" alt="UniSeek优寻" class="brand-logo" />
          </h1>
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
              <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
            </div>
            <div id="chart-trend" class="chart-container"></div>
          </div>
          <div class="left-group">
            <div class="card-header">
              <span class="title">职位大类占比</span>
              <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
            </div>
            <div id="chart-ring" class="chart-container"></div>
          </div>
        </section>

        <!-- 中央：岗位地域流向图 + 投递转化进度条 -->
        <section class="chart-card center-panel">
          <div class="card-header">
              <span class="title">全国岗位流向</span>
              <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
          </div>
          <div id="chart-map" class="chart-container" style="flex:1;"></div>
          <!-- 投递转化进度条 -->
          <div class="funnel-section">
            <div class="funnel-header">
              <div class="funnel-title-group">
                <span class="funnel-title">投递转化率</span>
                <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
              </div>
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
              <div class="funnel-title-group">
                <span class="funnel-title">企业资质审核</span>
                <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
              </div>
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
              <div class="funnel-title-group">
                <span class="funnel-title">实名认证率</span>
                <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
              </div>
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
              <span class="funnel-range">{{ timeRangeLabels[currentRange] }}</span>
            </div>
            <div id="chart-bar" class="chart-container"></div>
          </div>
          <div class="right-group">
            <div class="card-header">
              <span class="title">实时动态</span>
              <span class="subtitle">动态更新</span>
            </div>
            <div class="feed-container" ref="feedListRef">
              <div class="feed-list">
                <div class="feed-item" v-for="(feed, idx) in displayFeed" :key="'fd-' + feed.id + '-' + idx">
                  <span class="feed-name">{{ feed.name }}</span>
                  <span class="feed-action">{{ feed.action }}</span>
                  <span class="feed-time">
                    <span class="time-date">{{ feed.time.split(' ')[0] }}</span>
                    <span class="time-clock">{{ feed.time.split(' ')[1] }}</span>
                  </span>
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
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getScreenSummary, getCategoryDistribution, getHotTasks, getLatestActivity, getTalentFlow, getApplicationFunnel, getEnterpriseSummary } from '@/api/admin'

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
  if (isUnmounted) return
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

    // 职位大类占比数据（所有统计都传入当前时间范围）
    const currentRangeVal = range || currentRange.value
    const [categoryRes, hotTasksRes, activityRes, talentFlowRes, funnelRes, enterpriseRes] = await Promise.allSettled([
      getCategoryDistribution(currentRangeVal),
      getHotTasks(currentRangeVal),
      getLatestActivity(),
      getTalentFlow(currentRangeVal),
      getApplicationFunnel(currentRangeVal),
      getEnterpriseSummary(currentRangeVal)
    ])

    if (categoryRes.status === 'fulfilled' && categoryRes.value && chartRing) {
      // 按 count 降序排列，最后 5 项合并到"其他"
      const sorted = [...categoryRes.value].sort((a, b) => b.count - a.count)
      const mergeCount = Math.min(5, sorted.length - 1)
      const topItems = sorted.slice(0, sorted.length - mergeCount)
      const restCount = sorted.slice(sorted.length - mergeCount).reduce((sum, item) => sum + item.count, 0)
      const chartData = topItems.map((item: any) => ({ name: item.categoryName, value: item.count }))
      if (restCount > 0) {
        chartData.push({ name: '其他', value: restCount })
      }
      chartRing.setOption({
        series: [{ data: chartData }]
      })
    }

    if (hotTasksRes.status === 'fulfilled' && hotTasksRes.value && chartBar) {
      const top10 = hotTasksRes.value.slice(0, 10)
      // 水平条形图 yAxis category 从下往上渲染，需反转使最多在顶部
      const reversed = [...top10].reverse()
      chartBar.setOption({
        yAxis: { data: reversed.map((t: any) => t.title) },
        series: [{ data: reversed.map((t: any) => t.applicationCount) }]
      })
    }

    if (activityRes.status === 'fulfilled' && activityRes.value) {
      // 反转：后端返回最新在前，旧→新排列使最新条目出现在底部
      const sorted = [...activityRes.value].reverse()
      appendFeed(sorted.map((item: any) => {
        let action = item.message || ''
        const uname = item.userName
        // 去掉开头重复的用户名（如 "张小芒 投递了…" → "投递了…"）
        if (uname && action.startsWith(uname)) {
          action = action.slice(uname.length).trim()
        }
        return {
          id: item.id,
          name: uname || '系统',
          action,
          target: item.target || '',
          time: item.time || ''
        }
      }))
    }

    if (talentFlowRes.status === 'fulfilled' && talentFlowRes.value && talentFlowRes.value.length > 0 && chartMap) {
      // 地区编码 → 城市坐标映射（常用城市）
      const regionCoordMap: Record<string, { name: string; coord: [number, number] }> = {
        // 直辖市
        '110000': { name: '北京市', coord: [116.4, 39.9] },
        '120000': { name: '天津市', coord: [117.2, 39.13] },
        '310000': { name: '上海市', coord: [121.47, 31.23] },
        '500000': { name: '重庆市', coord: [106.55, 29.57] },
        // 河北省
        '130100': { name: '石家庄市', coord: [114.48, 38.03] },
        '130200': { name: '唐山市', coord: [118.18, 39.63] },
        '130300': { name: '秦皇岛市', coord: [119.59, 39.93] },
        '130400': { name: '邯郸市', coord: [114.49, 36.61] },
        '130500': { name: '邢台市', coord: [114.5, 37.07] },
        '130600': { name: '保定市', coord: [115.48, 38.87] },
        '130700': { name: '张家口市', coord: [114.88, 40.77] },
        '130800': { name: '承德市', coord: [117.94, 40.95] },
        '130900': { name: '沧州市', coord: [116.86, 38.3] },
        '131000': { name: '廊坊市', coord: [116.7, 39.52] },
        '131100': { name: '衡水市', coord: [115.68, 37.73] },
        // 山西省
        '140100': { name: '太原市', coord: [112.55, 37.87] },
        '140200': { name: '大同市', coord: [113.3, 40.08] },
        '140300': { name: '阳泉市', coord: [113.58, 37.86] },
        '140400': { name: '长治市', coord: [113.12, 36.2] },
        '140500': { name: '晋城市', coord: [112.85, 35.49] },
        '140600': { name: '朔州市', coord: [112.43, 39.33] },
        '140700': { name: '晋中市', coord: [112.75, 37.69] },
        '140800': { name: '运城市', coord: [111.0, 35.03] },
        '140900': { name: '忻州市', coord: [112.73, 38.42] },
        '141000': { name: '临汾市', coord: [111.52, 36.08] },
        '141100': { name: '吕梁市', coord: [111.14, 37.52] },
        // 内蒙古
        '150100': { name: '呼和浩特市', coord: [111.75, 40.84] },
        '150200': { name: '包头市', coord: [109.85, 40.66] },
        '150300': { name: '乌海市', coord: [106.8, 39.66] },
        '150400': { name: '赤峰市', coord: [118.92, 42.26] },
        '150500': { name: '通辽市', coord: [122.26, 43.61] },
        '150600': { name: '鄂尔多斯市', coord: [109.78, 39.61] },
        '150700': { name: '呼伦贝尔市', coord: [119.77, 49.22] },
        '150800': { name: '巴彦淖尔市', coord: [107.39, 40.74] },
        '150900': { name: '乌兰察布市', coord: [113.13, 40.99] },
        '152200': { name: '兴安盟', coord: [122.04, 46.08] },
        '152500': { name: '锡林郭勒盟', coord: [116.04, 43.94] },
        '152900': { name: '阿拉善盟', coord: [105.7, 38.84] },
        // 辽宁省
        '210100': { name: '沈阳市', coord: [123.43, 41.8] },
        '210200': { name: '大连市', coord: [121.62, 38.92] },
        '210300': { name: '鞍山市', coord: [123.0, 41.1] },
        '210400': { name: '抚顺市', coord: [123.98, 41.88] },
        '210500': { name: '本溪市', coord: [123.77, 41.3] },
        '210600': { name: '丹东市', coord: [124.38, 40.13] },
        '210700': { name: '锦州市', coord: [121.13, 41.1] },
        '210800': { name: '营口市', coord: [122.24, 40.67] },
        '210900': { name: '阜新市', coord: [121.67, 42.02] },
        '211000': { name: '辽阳市', coord: [123.18, 41.27] },
        '211100': { name: '盘锦市', coord: [122.07, 41.12] },
        '211200': { name: '铁岭市', coord: [123.85, 42.29] },
        '211300': { name: '朝阳市', coord: [120.45, 41.58] },
        '211400': { name: '葫芦岛市', coord: [120.84, 40.71] },
        // 吉林省
        '220100': { name: '长春市', coord: [125.32, 43.9] },
        '220200': { name: '吉林市', coord: [126.55, 43.84] },
        '220300': { name: '四平市', coord: [124.37, 43.17] },
        '220400': { name: '辽源市', coord: [125.14, 42.88] },
        '220500': { name: '通化市', coord: [125.94, 41.73] },
        '220600': { name: '白山市', coord: [126.42, 41.94] },
        '220700': { name: '松原市', coord: [124.83, 45.14] },
        '220800': { name: '白城市', coord: [122.84, 45.62] },
        '222400': { name: '延边朝鲜族自治州', coord: [129.5, 42.88] },
        // 黑龙江省
        '230100': { name: '哈尔滨市', coord: [126.63, 45.75] },
        '230200': { name: '齐齐哈尔市', coord: [123.98, 47.35] },
        '230300': { name: '鸡西市', coord: [130.97, 45.3] },
        '230400': { name: '鹤岗市', coord: [130.28, 47.33] },
        '230500': { name: '双鸭山市', coord: [131.15, 46.64] },
        '230600': { name: '大庆市', coord: [125.02, 46.59] },
        '230700': { name: '伊春市', coord: [128.84, 47.73] },
        '230800': { name: '佳木斯市', coord: [130.36, 46.81] },
        '230900': { name: '七台河市', coord: [131.0, 45.77] },
        '231000': { name: '牡丹江市', coord: [129.6, 44.58] },
        '231100': { name: '黑河市', coord: [127.5, 50.25] },
        '231200': { name: '绥化市', coord: [126.98, 46.64] },
        '232700': { name: '大兴安岭地区', coord: [124.12, 50.41] },
        // 江苏省
        '320100': { name: '南京市', coord: [118.78, 32.06] },
        '320200': { name: '无锡市', coord: [120.3, 31.57] },
        '320300': { name: '徐州市', coord: [117.2, 34.26] },
        '320400': { name: '常州市', coord: [119.97, 31.78] },
        '320500': { name: '苏州市', coord: [120.62, 31.32] },
        '320600': { name: '南通市', coord: [120.86, 32.01] },
        '320700': { name: '连云港市', coord: [119.22, 34.6] },
        '320800': { name: '淮安市', coord: [119.02, 33.61] },
        '320900': { name: '盐城市', coord: [120.16, 33.35] },
        '321000': { name: '扬州市', coord: [119.42, 32.39] },
        '321100': { name: '镇江市', coord: [119.45, 32.2] },
        '321200': { name: '泰州市', coord: [119.92, 32.46] },
        '321300': { name: '宿迁市', coord: [118.28, 33.96] },
        // 浙江省
        '330100': { name: '杭州市', coord: [120.19, 30.26] },
        '330200': { name: '宁波市', coord: [121.54, 29.87] },
        '330300': { name: '温州市', coord: [120.7, 28.0] },
        '330400': { name: '嘉兴市', coord: [120.76, 30.77] },
        '330500': { name: '湖州市', coord: [120.09, 30.87] },
        '330600': { name: '绍兴市', coord: [120.58, 30.0] },
        '330700': { name: '金华市', coord: [119.65, 29.1] },
        '330800': { name: '衢州市', coord: [118.87, 28.94] },
        '330900': { name: '舟山市', coord: [122.2, 30.0] },
        '331000': { name: '台州市', coord: [121.42, 28.65] },
        '331100': { name: '丽水市', coord: [119.92, 28.45] },
        // 安徽省
        '340100': { name: '合肥市', coord: [117.27, 31.86] },
        '340200': { name: '芜湖市', coord: [118.38, 31.33] },
        '340300': { name: '蚌埠市', coord: [117.38, 32.92] },
        '340400': { name: '淮南市', coord: [117.0, 32.63] },
        '340500': { name: '马鞍山市', coord: [118.5, 31.7] },
        '340600': { name: '淮北市', coord: [116.8, 33.96] },
        '340700': { name: '铜陵市', coord: [117.82, 30.93] },
        '340800': { name: '安庆市', coord: [117.05, 30.53] },
        '341000': { name: '黄山市', coord: [118.33, 29.72] },
        '341100': { name: '滁州市', coord: [118.32, 32.3] },
        '341200': { name: '阜阳市', coord: [115.82, 32.9] },
        '341300': { name: '宿州市', coord: [116.98, 33.63] },
        '341500': { name: '六安市', coord: [116.52, 31.74] },
        '341600': { name: '亳州市', coord: [115.78, 33.85] },
        '341700': { name: '池州市', coord: [117.49, 30.66] },
        '341800': { name: '宣城市', coord: [118.76, 30.94] },
        // 福建省
        '350100': { name: '福州市', coord: [119.3, 26.08] },
        '350200': { name: '厦门市', coord: [118.1, 24.46] },
        '350300': { name: '莆田市', coord: [119.0, 25.44] },
        '350400': { name: '三明市', coord: [117.62, 26.26] },
        '350500': { name: '泉州市', coord: [118.59, 24.91] },
        '350600': { name: '漳州市', coord: [117.65, 24.52] },
        '350700': { name: '南平市', coord: [118.18, 26.64] },
        '350800': { name: '龙岩市', coord: [117.02, 25.08] },
        '350900': { name: '宁德市', coord: [119.55, 26.67] },
        // 江西省
        '360100': { name: '南昌市', coord: [115.86, 28.68] },
        '360200': { name: '景德镇市', coord: [117.18, 29.27] },
        '360300': { name: '萍乡市', coord: [113.85, 27.62] },
        '360400': { name: '九江市', coord: [116.0, 29.71] },
        '360500': { name: '新余市', coord: [114.92, 27.82] },
        '360600': { name: '鹰潭市', coord: [117.03, 28.24] },
        '360700': { name: '赣州市', coord: [114.93, 25.83] },
        '360800': { name: '吉安市', coord: [114.98, 27.12] },
        '360900': { name: '宜春市', coord: [114.39, 27.8] },
        '361000': { name: '抚州市', coord: [116.36, 27.98] },
        '361100': { name: '上饶市', coord: [117.97, 28.45] },
        // 山东省
        '370100': { name: '济南市', coord: [117.0, 36.65] },
        '370200': { name: '青岛市', coord: [120.33, 36.07] },
        '370300': { name: '淄博市', coord: [118.05, 36.82] },
        '370400': { name: '枣庄市', coord: [117.32, 34.81] },
        '370500': { name: '东营市', coord: [118.67, 37.43] },
        '370600': { name: '烟台市', coord: [121.39, 37.52] },
        '370700': { name: '潍坊市', coord: [119.1, 36.62] },
        '370800': { name: '济宁市', coord: [116.58, 35.42] },
        '370900': { name: '泰安市', coord: [117.08, 36.2] },
        '371000': { name: '威海市', coord: [122.12, 37.51] },
        '371100': { name: '日照市', coord: [119.52, 35.42] },
        '371300': { name: '临沂市', coord: [118.34, 35.07] },
        '371400': { name: '德州市', coord: [116.36, 37.44] },
        '371500': { name: '聊城市', coord: [115.98, 36.46] },
        '371600': { name: '滨州市', coord: [117.97, 37.38] },
        '371700': { name: '菏泽市', coord: [115.45, 35.25] },
        // 河南省
        '410100': { name: '郑州市', coord: [113.65, 34.76] },
        '410200': { name: '开封市', coord: [114.34, 34.8] },
        '410300': { name: '洛阳市', coord: [112.45, 34.62] },
        '410400': { name: '平顶山市', coord: [113.19, 33.77] },
        '410500': { name: '安阳市', coord: [114.38, 36.1] },
        '410600': { name: '鹤壁市', coord: [114.29, 35.9] },
        '410700': { name: '新乡市', coord: [113.87, 35.3] },
        '410800': { name: '焦作市', coord: [113.24, 35.22] },
        '410900': { name: '濮阳市', coord: [115.03, 35.76] },
        '411000': { name: '许昌市', coord: [113.85, 34.04] },
        '411100': { name: '漯河市', coord: [114.02, 33.58] },
        '411200': { name: '三门峡市', coord: [111.2, 34.78] },
        '411300': { name: '南阳市', coord: [112.53, 33.0] },
        '411400': { name: '商丘市', coord: [115.65, 34.44] },
        '411500': { name: '信阳市', coord: [114.07, 32.13] },
        '411600': { name: '周口市', coord: [114.65, 33.62] },
        '411700': { name: '驻马店市', coord: [114.02, 33.01] },
        // 湖北省
        '420100': { name: '武汉市', coord: [114.31, 30.52] },
        '420200': { name: '黄石市', coord: [115.07, 30.2] },
        '420300': { name: '十堰市', coord: [110.8, 32.63] },
        '420500': { name: '宜昌市', coord: [111.28, 30.7] },
        '420600': { name: '襄阳市', coord: [112.15, 32.01] },
        '420700': { name: '鄂州市', coord: [114.89, 30.4] },
        '420800': { name: '荆门市', coord: [112.2, 31.04] },
        '420900': { name: '孝感市', coord: [113.92, 30.93] },
        '421000': { name: '荆州市', coord: [112.24, 30.34] },
        '421100': { name: '黄冈市', coord: [114.87, 30.45] },
        '421200': { name: '咸宁市', coord: [114.32, 29.84] },
        '421300': { name: '随州市', coord: [113.38, 31.72] },
        '422800': { name: '恩施土家族苗族自治州', coord: [109.48, 30.3] },
        // 湖南省
        '430100': { name: '长沙市', coord: [112.98, 28.19] },
        '430200': { name: '株洲市', coord: [113.13, 27.84] },
        '430300': { name: '湘潭市', coord: [112.93, 27.84] },
        '430400': { name: '衡阳市', coord: [112.57, 26.89] },
        '430500': { name: '邵阳市', coord: [111.47, 27.24] },
        '430600': { name: '岳阳市', coord: [113.13, 29.37] },
        '430700': { name: '常德市', coord: [111.7, 29.03] },
        '430800': { name: '张家界市', coord: [110.48, 29.13] },
        '430900': { name: '益阳市', coord: [112.35, 28.59] },
        '431000': { name: '郴州市', coord: [113.01, 25.79] },
        '431100': { name: '永州市', coord: [111.61, 26.43] },
        '431200': { name: '怀化市', coord: [109.99, 27.56] },
        '431300': { name: '娄底市', coord: [112.0, 27.74] },
        '433100': { name: '湘西土家族苗族自治州', coord: [109.74, 28.32] },
        // 广东省
        '440100': { name: '广州市', coord: [113.23, 23.16] },
        '440200': { name: '韶关市', coord: [113.6, 24.81] },
        '440300': { name: '深圳市', coord: [114.07, 22.62] },
        '440400': { name: '珠海市', coord: [113.57, 22.27] },
        '440500': { name: '汕头市', coord: [116.7, 23.37] },
        '440600': { name: '佛山市', coord: [113.12, 23.02] },
        '440700': { name: '江门市', coord: [113.08, 22.58] },
        '440800': { name: '湛江市', coord: [110.36, 21.27] },
        '440900': { name: '茂名市', coord: [110.92, 21.66] },
        '441200': { name: '肇庆市', coord: [112.47, 23.05] },
        '441300': { name: '惠州市', coord: [114.42, 23.11] },
        '441400': { name: '梅州市', coord: [116.12, 24.29] },
        '441500': { name: '汕尾市', coord: [115.37, 22.79] },
        '441600': { name: '河源市', coord: [114.7, 23.74] },
        '441700': { name: '阳江市', coord: [111.98, 21.86] },
        '441800': { name: '清远市', coord: [113.03, 23.7] },
        '441900': { name: '东莞市', coord: [113.75, 23.05] },
        '442000': { name: '中山市', coord: [113.38, 22.52] },
        '445100': { name: '潮州市', coord: [116.62, 23.66] },
        '445200': { name: '揭阳市', coord: [116.36, 23.55] },
        '445300': { name: '云浮市', coord: [112.04, 22.92] },
        // 广西
        '450100': { name: '南宁市', coord: [108.37, 22.82] },
        '450200': { name: '柳州市', coord: [109.41, 24.33] },
        '450300': { name: '桂林市', coord: [110.28, 25.27] },
        '450400': { name: '梧州市', coord: [111.27, 23.48] },
        '450500': { name: '北海市', coord: [109.12, 21.48] },
        '450600': { name: '防城港市', coord: [108.35, 21.7] },
        '450700': { name: '钦州市', coord: [108.62, 21.96] },
        '450800': { name: '贵港市', coord: [109.6, 23.11] },
        '450900': { name: '玉林市', coord: [110.14, 22.63] },
        '451000': { name: '百色市', coord: [106.62, 23.9] },
        '451100': { name: '贺州市', coord: [111.57, 24.4] },
        '451200': { name: '河池市', coord: [108.07, 24.7] },
        '451300': { name: '来宾市', coord: [109.22, 23.75] },
        '451400': { name: '崇左市', coord: [107.36, 22.38] },
        // 海南省
        '460100': { name: '海口市', coord: [110.32, 20.03] },
        '460200': { name: '三亚市', coord: [109.51, 18.25] },
        '460300': { name: '三沙市', coord: [112.33, 16.84] },
        '460400': { name: '儋州市', coord: [109.58, 19.52] },
        // 四川省
        '510100': { name: '成都市', coord: [104.06, 30.67] },
        '510300': { name: '自贡市', coord: [104.78, 29.34] },
        '510400': { name: '攀枝花市', coord: [101.72, 26.58] },
        '510500': { name: '泸州市', coord: [105.44, 28.87] },
        '510600': { name: '德阳市', coord: [104.4, 31.13] },
        '510700': { name: '绵阳市', coord: [104.74, 31.46] },
        '510800': { name: '广元市', coord: [105.84, 32.44] },
        '510900': { name: '遂宁市', coord: [105.58, 30.53] },
        '511000': { name: '内江市', coord: [105.06, 29.58] },
        '511100': { name: '乐山市', coord: [103.76, 29.58] },
        '511300': { name: '南充市', coord: [106.11, 30.84] },
        '511400': { name: '眉山市', coord: [103.84, 30.05] },
        '511500': { name: '宜宾市', coord: [104.62, 28.76] },
        '511600': { name: '广安市', coord: [106.63, 30.46] },
        '511700': { name: '达州市', coord: [107.49, 31.21] },
        '511800': { name: '雅安市', coord: [103.0, 29.99] },
        '511900': { name: '巴中市', coord: [106.77, 31.86] },
        '512000': { name: '资阳市', coord: [104.64, 30.12] },
        '513200': { name: '阿坝藏族羌族自治州', coord: [102.22, 31.9] },
        '513300': { name: '甘孜藏族自治州', coord: [101.96, 30.05] },
        '513400': { name: '凉山彝族自治州', coord: [102.26, 27.88] },
        // 贵州省
        '520100': { name: '贵阳市', coord: [106.71, 26.57] },
        '520200': { name: '六盘水市', coord: [104.83, 26.59] },
        '520300': { name: '遵义市', coord: [106.93, 27.71] },
        '520400': { name: '安顺市', coord: [105.95, 26.25] },
        '520500': { name: '毕节市', coord: [105.29, 27.3] },
        '520600': { name: '铜仁市', coord: [109.18, 27.73] },
        '522300': { name: '黔西南布依族苗族自治州', coord: [104.9, 25.09] },
        '522600': { name: '黔东南苗族侗族自治州', coord: [107.97, 26.58] },
        '522700': { name: '黔南布依族苗族自治州', coord: [107.52, 26.25] },
        // 云南省
        '530100': { name: '昆明市', coord: [102.73, 25.04] },
        '530300': { name: '曲靖市', coord: [103.8, 25.5] },
        '530400': { name: '玉溪市', coord: [102.55, 24.35] },
        '530500': { name: '保山市', coord: [99.17, 25.12] },
        '530600': { name: '昭通市', coord: [103.72, 27.34] },
        '530700': { name: '丽江市', coord: [100.23, 26.87] },
        '530800': { name: '普洱市', coord: [100.97, 22.79] },
        '530900': { name: '临沧市', coord: [100.09, 23.89] },
        '532300': { name: '楚雄彝族自治州', coord: [101.55, 25.04] },
        '532500': { name: '红河哈尼族彝族自治州', coord: [103.38, 23.37] },
        '532600': { name: '文山壮族苗族自治州', coord: [104.24, 23.37] },
        '532800': { name: '西双版纳傣族自治州', coord: [100.8, 22.01] },
        '532900': { name: '大理白族自治州', coord: [100.23, 25.6] },
        '533100': { name: '德宏傣族景颇族自治州', coord: [98.58, 24.43] },
        '533300': { name: '怒江傈僳族自治州', coord: [98.86, 25.82] },
        '533400': { name: '迪庆藏族自治州', coord: [99.7, 27.82] },
        // 西藏
        '540100': { name: '拉萨市', coord: [91.13, 29.65] },
        '540200': { name: '日喀则市', coord: [88.88, 29.27] },
        '540300': { name: '昌都市', coord: [97.18, 31.14] },
        '540400': { name: '林芝市', coord: [94.37, 29.68] },
        '540500': { name: '山南市', coord: [91.77, 29.24] },
        '540600': { name: '那曲市', coord: [92.05, 31.48] },
        '542500': { name: '阿里地区', coord: [80.1, 32.5] },
        // 陕西省
        '610100': { name: '西安市', coord: [108.94, 34.26] },
        '610200': { name: '铜川市', coord: [108.94, 34.9] },
        '610300': { name: '宝鸡市', coord: [107.15, 34.38] },
        '610400': { name: '咸阳市', coord: [108.71, 34.33] },
        '610500': { name: '渭南市', coord: [109.49, 34.5] },
        '610600': { name: '延安市', coord: [109.49, 36.6] },
        '610700': { name: '汉中市', coord: [107.02, 33.07] },
        '610800': { name: '榆林市', coord: [109.74, 38.29] },
        '610900': { name: '安康市', coord: [109.02, 32.69] },
        '611000': { name: '商洛市', coord: [109.93, 33.87] },
        // 甘肃省
        '620100': { name: '兰州市', coord: [103.83, 36.06] },
        '620200': { name: '嘉峪关市', coord: [98.28, 39.78] },
        '620300': { name: '金昌市', coord: [102.19, 38.52] },
        '620400': { name: '白银市', coord: [104.14, 36.55] },
        '620500': { name: '天水市', coord: [105.73, 34.58] },
        '620600': { name: '武威市', coord: [102.64, 37.93] },
        '620700': { name: '张掖市', coord: [100.45, 38.93] },
        '620800': { name: '平凉市', coord: [106.67, 35.54] },
        '620900': { name: '酒泉市', coord: [98.52, 39.74] },
        '621000': { name: '庆阳市', coord: [107.64, 35.71] },
        '621100': { name: '定西市', coord: [104.63, 35.58] },
        '621200': { name: '陇南市', coord: [104.93, 33.4] },
        '622900': { name: '临夏回族自治州', coord: [103.21, 35.6] },
        '623000': { name: '甘南藏族自治州', coord: [102.91, 34.98] },
        // 青海省
        '630100': { name: '西宁市', coord: [101.76, 36.63] },
        '630200': { name: '海东市', coord: [102.12, 36.5] },
        '632200': { name: '海北藏族自治州', coord: [100.9, 36.96] },
        '632300': { name: '黄南藏族自治州', coord: [102.02, 35.52] },
        '632500': { name: '海南藏族自治州', coord: [100.62, 36.28] },
        '632600': { name: '果洛藏族自治州', coord: [100.24, 34.47] },
        '632700': { name: '玉树藏族自治州', coord: [97.02, 33.01] },
        '632800': { name: '海西蒙古族藏族自治州', coord: [97.37, 37.38] },
        // 宁夏
        '640100': { name: '银川市', coord: [106.28, 38.47] },
        '640200': { name: '石嘴山市', coord: [106.38, 39.02] },
        '640300': { name: '吴忠市', coord: [106.21, 37.99] },
        '640400': { name: '固原市', coord: [106.28, 36.01] },
        '640500': { name: '中卫市', coord: [105.19, 37.51] },
        // 新疆
        '650100': { name: '乌鲁木齐市', coord: [87.62, 43.82] },
        '650200': { name: '克拉玛依市', coord: [84.88, 45.6] },
        '650400': { name: '吐鲁番市', coord: [89.19, 42.95] },
        '650500': { name: '哈密市', coord: [93.51, 42.83] },
        '652300': { name: '昌吉回族自治州', coord: [87.31, 44.01] },
        '652700': { name: '博尔塔拉蒙古自治州', coord: [82.07, 44.91] },
        '652800': { name: '巴音郭楞蒙古自治州', coord: [86.14, 41.76] },
        '652900': { name: '阿克苏地区', coord: [80.26, 41.17] },
        '653000': { name: '克孜勒苏柯尔克孜自治州', coord: [76.17, 39.71] },
        '653100': { name: '喀什地区', coord: [75.99, 39.47] },
        '653200': { name: '和田地区', coord: [79.93, 37.11] },
        '654000': { name: '伊犁哈萨克自治州', coord: [81.32, 43.92] },
        '654200': { name: '塔城地区', coord: [82.99, 46.75] },
        '654300': { name: '阿勒泰地区', coord: [88.13, 47.85] },
        // 台湾省
        '830100': { name: '台北市', coord: [121.56, 25.04] },
        '830200': { name: '新北市', coord: [121.47, 25.02] },
        '830300': { name: '桃园市', coord: [121.3, 24.99] },
        '830400': { name: '台中市', coord: [120.67, 24.15] },
        '830500': { name: '台南市', coord: [120.23, 23.0] },
        '830600': { name: '高雄市', coord: [120.31, 22.62] },
        '830700': { name: '基隆市', coord: [121.74, 25.13] },
        '830800': { name: '新竹市', coord: [120.97, 24.81] },
        '830900': { name: '嘉义市', coord: [120.45, 23.48] },
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
        const topFlows = flows.slice(0, 30)
        
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
          lineStyle: { width: 1, opacity: 0.3 + Math.min(f.count / 20, 0.5) }
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
              label: { show: false }
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
      if (funnelEl) {
        if (total > 0) {
          const colors: Record<number, string> = { 0: '#1762FB', 1: '#26E2FF', 2: '#67C23A', 3: '#E6A23C', 4: '#909399', 5: '#F56C6C' }
          let html = ''
          statusList.forEach((item: any) => {
            const pct = ((item.count / total) * 100).toFixed(1)
            html += `<div class="funnel-segment" style="flex:${item.count};background:${colors[item.status] || '#333'};" title="${item.name}: ${item.count} (${pct}%)"></div>`
          })
          funnelEl.innerHTML = html
        } else {
          funnelEl.innerHTML = '<div class="funnel-empty">该时间范围内暂无投递数据</div>'
        }
        document.getElementById('funnel-total')!.textContent = total.toLocaleString()
        document.getElementById('funnel-today')!.textContent = (funnelData.todayNew || 0).toLocaleString()
      }
    }
    if (enterpriseRes.status === 'fulfilled' && enterpriseRes.value) {
      const entData = enterpriseRes.value
      const auditList = entData.auditList || []
      const entTotal = entData.totalEnterprise || 0
      const entEl = document.getElementById('funnel-enterprise')
      if (entEl) {
        if (entTotal > 0) {
          const entColors: Record<number, string> = { 0: '#E6A23C', 1: '#67C23A', 2: '#F56C6C' }
          let html = ''
          auditList.forEach((item: any) => {
            const pct = ((item.count / entTotal) * 100).toFixed(1)
            html += `<div class="funnel-segment" style="flex:${item.count};background:${entColors[item.status] || '#333'};" title="${item.name}: ${item.count} (${pct}%)"></div>`
          })
          entEl.innerHTML = html
        } else {
          entEl.innerHTML = '<div class="funnel-empty">该时间范围内暂无企业数据</div>'
        }
        document.getElementById('ent-total')!.textContent = entTotal.toLocaleString()
      }
      // 实名认证率
      const totalUser = entData.totalUser || 0
      const authed = entData.authedCount || 0
      const unauth = entData.unauthedCount || 0
      const authEl = document.getElementById('funnel-auth')
      if (authEl) {
        if (totalUser > 0) {
          authEl.innerHTML = `
            <div class="funnel-segment" style="flex:${authed};background:#67C23A;" title="已认证: ${authed} (${((authed/totalUser)*100).toFixed(1)}%)"></div>
            <div class="funnel-segment" style="flex:${unauth};background:#909399;" title="未认证: ${unauth} (${((unauth/totalUser)*100).toFixed(1)}%)"></div>
          `
        } else {
          authEl.innerHTML = '<div class="funnel-empty">该时间范围内暂无用户数据</div>'
        }
        document.getElementById('auth-rate')!.textContent = ((authed / totalUser) * 100).toFixed(1) + '%'
      }
    }
  } catch (e) {
    console.warn('大屏数据加载失败，使用默认展示', e)
  }
}

// 动态流数据
const feedData = ref<Array<{ id: number; name: string; action: string; target: string; time: string }>>([])
const feedListRef = ref<HTMLElement | null>(null)
// 双倍数据用于无缝循环滚动
const displayFeed = computed(() => {
  const d = feedData.value
  return d.length > 0 ? [...d, ...d] : []
})
// rAF 滚动控制
let feedRAF: number | null = null
let lastFeedTime = 0
const FEED_TICK_MS = 12500 // 12.5 秒，约大屏 tick 的 80% 速度

/**
 * 追加新项到 feed 列表（去重，防无限增长）
 */
function appendFeed(newItems: Array<{ id: number; name: string; action: string; target: string; time: string }>) {
  const existingIds = new Set(feedData.value.map(f => f.id))
  const fresh = newItems.filter(item => !existingIds.has(item.id))
  if (fresh.length === 0) return
  feedData.value = [...feedData.value, ...fresh]
  // 最多保留 50 条，防止无限增长
  if (feedData.value.length > 50) {
    feedData.value = feedData.value.slice(-50)
  }
}

/**
 * requestAnimationFrame 驱动的平滑滚动
 * 每次滚动半屏（双倍数据的 50% 位置），到达后重置到 0，实现无缝循环
 */
function startFeedScroll() {
  if (feedRAF !== null) return
  lastFeedTime = performance.now()
  const step = (now: number) => {
    const el = feedListRef.value
    if (!el) { feedRAF = null; return }
    const half = el.scrollHeight / 2
    if (half <= 0) { lastFeedTime = now; feedRAF = requestAnimationFrame(step); return }
    // 每帧步长 = 半高 / 总时长(ms)
    const delta = (half / FEED_TICK_MS) * (now - lastFeedTime)
    lastFeedTime = now
    el.scrollTop += delta
    if (el.scrollTop >= half) {
      el.scrollTop = 0
    }
    feedRAF = requestAnimationFrame(step)
  }
  feedRAF = requestAnimationFrame(step)
}

function stopFeedScroll() {
  if (feedRAF !== null) {
    cancelAnimationFrame(feedRAF)
    feedRAF = null
  }
}

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
  // 容器尺寸为 0 时跳过初始化，防止 0 尺寸 canvas 报错
  if (bgDom.offsetWidth === 0 || bgDom.offsetHeight === 0) return
  bgChart = echarts.init(bgDom)
  const noise = getNoiseHelper()
  
  const config = {
    frequency: 1200,
    offsetX: 0,
    offsetY: 100,
    minSize: 1,
    maxSize: 3,
    duration: 6000,
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
            delay: (rand - 1) * config.duration,
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

/** 标记组件是否已卸载，防止异步回调操作已销毁的图表 */
let isUnmounted = false

/** 安全销毁所有图表实例并置空引用 */
const disposeAllCharts = () => {
  bgChart?.dispose(); bgChart = null
  chartTrend?.dispose(); chartTrend = null
  chartMap?.dispose(); chartMap = null
  chartRing?.dispose(); chartRing = null
  chartBar?.dispose(); chartBar = null
}

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
  // 容器尺寸校验：防止 0 尺寸 canvas 导致 drawImage 报错
  const ensureSize = (id: string): HTMLElement | null => {
    const el = document.getElementById(id)
    if (!el || el.offsetWidth === 0 || el.offsetHeight === 0) return null
    return el
  }

  // 1. 供需趋势图 (双轴折线)
  const trendEl = ensureSize('chart-trend')
  if (!trendEl) return
  chartTrend = echarts.init(trendEl)
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
  const mapEl = ensureSize('chart-map')
  if (mapEl) chartMap = echarts.init(mapEl)
  const chengdu: [number, number] = [104.06, 30.67]

  fetch('https://geo.datav.aliyun.com/areas_v3/bound/100000_full.json')
    .then(res => res.json())
    .then(chinaJson => {
      if (isUnmounted || !chartMap) return
      echarts.registerMap('china', chinaJson)

      const mapOption = {
        tooltip: { trigger: 'item' },
        geo: {
          map: 'china',
          zoom: 1.2,
          center: [104, 35],
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
      if (!isUnmounted) fetchAllData()
    })
    .catch(err => console.warn('地图加载失败，请检查网络', err))

  // 3. 职位大类占比 (环形图)
  const ringEl = ensureSize('chart-ring')
  if (ringEl) chartRing = echarts.init(ringEl)
  const ringOption: echarts.EChartsOption = {
    ...getCommonOption(),
    tooltip: { trigger: 'item' },
    series: [
      {
        name: '职位大类',
        type: 'pie',
        radius: ['40%', '75%'],
        avoidLabelOverlap: false,
        labelLayout: { hideOverlap: false },
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
          { value: 16, name: '医疗', itemStyle: { color: '#1762FB' } },
          { value: 12, name: '教育培训', itemStyle: { color: '#685DFF' } },
          { value: 10, name: '房地产/建筑', itemStyle: { color: '#26E2FF' } },
          { value: 9, name: '批发/零售', itemStyle: { color: '#67C23A' } },
          { value: 8, name: '交通运输', itemStyle: { color: '#E6A23C' } },
          { value: 7, name: '文化传媒', itemStyle: { color: '#F56C6C' } },
          { value: 6, name: '住宿餐饮', itemStyle: { color: '#36CBCB' } },
          { value: 5, name: '农林牧渔', itemStyle: { color: '#B37FEB' } },
          { value: 5, name: '能源环保', itemStyle: { color: '#F06292' } },
          { value: 4, name: '电子信息', itemStyle: { color: '#4FC3F7' } },
          { value: 3, name: '法律服务', itemStyle: { color: '#AED581' } },
          { value: 3, name: '咨询/顾问', itemStyle: { color: '#FFB74D' } },
          { value: 10, name: '其他', itemStyle: { color: '#909399' } }
        ]
      }
    ]
  }
  chartRing.setOption(ringOption)

  // 4. 热门岗位排行 (横向条形图)
  const barEl = ensureSize('chart-bar')
  if (barEl) chartBar = echarts.init(barEl)
  const barOption: echarts.EChartsOption = {
    ...getCommonOption(),
    grid: { left: '15%', right: '15%', top: '10%', bottom: '10%' },
    xAxis: { type: 'value', splitLine: { show: false }, axisLabel: { show: false } },
    yAxis: {
      type: 'category',
      data: ['HR', '销售', '运营', '测试', '运维', 'UI设计', '数据分析', '产品经理', 'Java开发', 'AI算法'],
      axisLabel: { color: '#aaa', fontWeight: 'bold', fontSize: 12 }
    },
    series: [
      {
        type: 'bar',
        data: [10, 15, 21, 32, 43, 54, 65, 76, 87, 98],
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
  // 等待 DOM 布局完成后初始化图表，确保容器有有效尺寸
  nextTick(() => {
    if (isUnmounted) return
    initBgNoise()
    initECharts()
  })

  const intervalId = setInterval(async () => {
    if (isUnmounted) return
    rangeIndex = (rangeIndex + 1) % timeRanges.length
    const nextRange = timeRanges[rangeIndex]
    await fetchAllData(nextRange)
    currentRange.value = nextRange
  }, 10000)

  // 首次数据加载后启动 feed 滚动
  startFeedScroll()

  onUnmounted(() => {
    isUnmounted = true
    window.removeEventListener('resize', handleResize)
    clearInterval(intervalId)
    disposeAllCharts()
    stopFeedScroll()
  })
})


</script>

<style scoped>
/* ===== 全局重置与布局 ===== */
.dashboard-wrapper {
  position: relative;
  width: 100%;
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
  height: 36px;
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
  background: rgba(23, 98, 251, 0.08);
  border: 1px solid rgba(23, 98, 251, 0.2);
  border-radius: 16px;
  padding: 16px;
  backdrop-filter: blur(4px);
  box-shadow: 0 0 40px rgba(23, 98, 251, 0.1);
  display: flex;
  flex-direction: column;
  min-height: 0;
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
  min-height: 200px;
}
#chart-map {
  overflow: hidden;
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
  flex-shrink: 0;
}
.feed-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: rgba(23, 98, 251, 0.05);
  border-radius: 8px;
  border-left: 2px solid #1762FB;
  font-size: 13px;
  color: #fff;
  position: relative;
}
.feed-name { color: #26E2FF; font-weight: 500; }
.feed-time {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  text-align: right;
  line-height: 1.35;
}
.time-date, .time-clock {
  display: block;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.35);
}

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
.funnel-title-group {
  display: flex;
  align-items: center;
  gap: 8px;
}
.funnel-range {
  font-size: 11px;
  color: rgba(255,255,255,0.35);
  background: rgba(23,98,251,0.12);
  border: 1px solid rgba(23,98,251,0.2);
  border-radius: 10px;
  padding: 0 8px;
  line-height: 18px;
  white-space: nowrap;
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
.funnel-empty {
  width: 100%;
  text-align: center;
  color: rgba(255,255,255,0.3);
  font-size: 12px;
  line-height: 14px;
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
