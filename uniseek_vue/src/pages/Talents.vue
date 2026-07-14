<script setup lang="ts">
import { ref, computed } from 'vue'
import { Search } from '@element-plus/icons-vue'

// 人才筛选标签
const talentFilters = ['全部', '在线简历', '附件简历', '在校生', '有工作经验']
const activeFilter = ref('全部')
const keyword = ref('')

// 示例人才数据（后续应替换为后端简历搜索接口返回的真实数据）
const demoTalents = [
  {
    id: 1,
    name: '张晓明',
    age: 22,
    education: '本科',
    school: '杭州电子科技大学',
    experience: '1 年',
    jobType: '兼职',
    expectedCity: '杭州',
    tags: ['Java', 'Spring Boot', 'Vue'],
    summary: '有前端和后端开发经验，可接受周末兼职。'
  },
  {
    id: 2,
    name: '李雨桐',
    age: 20,
    education: '本科在读',
    school: '浙江大学',
    experience: '无',
    jobType: '实习',
    expectedCity: '杭州',
    tags: ['UI 设计', 'Figma', 'Photoshop'],
    summary: '设计专业大三学生，擅长 UI 界面设计与原型制作。'
  },
  {
    id: 3,
    name: '王浩然',
    age: 24,
    education: '本科',
    school: '浙江工业大学',
    experience: '2 年',
    jobType: '兼职',
    expectedCity: '上海',
    tags: ['新媒体运营', '文案', '短视频'],
    summary: '负责过多个公众号和短视频账号运营，熟悉内容策划。'
  }
]

const filteredTalents = computed(() => {
  return demoTalents.filter(t => {
    const matchKeyword = keyword.value.trim()
      ? t.name.includes(keyword.value) || t.tags.some(tag => tag.includes(keyword.value))
      : true
    const matchFilter = activeFilter.value === '全部'
      ? true
      : activeFilter.value === '在校生'
        ? t.school.includes('大学') && t.education.includes('在读')
        : activeFilter.value === '有工作经验'
          ? t.experience !== '无'
          : true
    return matchKeyword && matchFilter
  })
})
</script>

<template>
  <div class="talents-page">
    <div class="talents-header">
      <h2 class="talents-title">人才库</h2>
      <div class="talents-filter">
        <el-input
          v-model="keyword"
          placeholder="搜索姓名、技能标签"
          :prefix-icon="Search"
          clearable
          class="search-input"
        />
        <div class="filter-tabs">
          <button
            v-for="filter in talentFilters"
            :key="filter"
            :class="['filter-tab', { active: activeFilter === filter }]"
            @click="activeFilter = filter"
          >
            {{ filter }}
          </button>
        </div>
      </div>
    </div>

    <div class="talents-list">
      <el-card v-for="talent in filteredTalents" :key="talent.id" class="talent-card" shadow="hover">
        <div class="talent-main">
          <div class="talent-avatar">{{ talent.name.charAt(0) }}</div>
          <div class="talent-info">
            <div class="talent-name">
              {{ talent.name }}
              <span class="talent-meta">{{ talent.age }}岁 · {{ talent.education }} · {{ talent.experience }}</span>
            </div>
            <div class="talent-school">{{ talent.school }}</div>
            <div class="talent-tags">
              <el-tag v-for="tag in talent.tags" :key="tag" size="small" class="talent-tag">{{ tag }}</el-tag>
            </div>
            <div class="talent-summary">{{ talent.summary }}</div>
          </div>
        </div>
        <div class="talent-extra">
          <span>期望工作：{{ talent.expectedCity }} · {{ talent.jobType }}</span>
          <el-button type="primary" size="small">查看简历</el-button>
        </div>
      </el-card>

      <div v-if="filteredTalents.length === 0" class="empty-tip">
        暂无匹配人才
      </div>
    </div>

    <div class="api-tip">
      提示：当前为示例数据，后续可对接后端简历搜索接口。
    </div>
  </div>
</template>

<style scoped>
.talents-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.talents-header {
  background: #fff;
  padding: 16px 24px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.talents-title {
  font-size: 18px;
  font-weight: 600;
  color: #000;
  margin: 0 0 16px;
}

.talents-filter {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.search-input {
  width: 280px;
}

.filter-tabs {
  display: flex;
  gap: 4px;
}

.filter-tab {
  padding: 8px 16px;
  font-size: 14px;
  border: none;
  background: transparent;
  color: #000;
  border-radius: 4px;
  cursor: pointer;
}

.filter-tab.active {
  background: #409eff;
  color: #fff;
}

.talents-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.talent-card {
  color: #000;
}

.talent-main {
  display: flex;
  gap: 16px;
}

.talent-avatar {
  width: 56px;
  height: 56px;
  line-height: 56px;
  text-align: center;
  border-radius: 50%;
  background: #409eff;
  color: #fff;
  font-size: 20px;
  flex-shrink: 0;
}

.talent-info {
  flex: 1;
}

.talent-name {
  font-size: 16px;
  font-weight: 600;
  color: #000;
  margin-bottom: 4px;
}

.talent-meta {
  font-size: 13px;
  color: #666;
  font-weight: normal;
  margin-left: 8px;
}

.talent-school {
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
}

.talent-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 8px;
}

.talent-tag {
  color: #000;
}

.talent-summary {
  font-size: 14px;
  color: #333;
  line-height: 1.5;
}

.talent-extra {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #666;
}

.empty-tip {
  text-align: center;
  padding: 48px;
  color: #999;
  background: #fff;
  border-radius: 8px;
}

.api-tip {
  margin-top: 16px;
  text-align: center;
  font-size: 13px;
  color: #999;
}
</style>
