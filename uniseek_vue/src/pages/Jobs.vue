<script setup lang="ts">
import { ref } from 'vue'

type JobType = '全部' | '全职' | '兼职' | '实习'

const activeType = ref<JobType>('全部')

const jobTypes: JobType[] = ['全部', '全职', '兼职', '实习']

const setType = (type: JobType) => {
  activeType.value = type
}
</script>

<template>
  <div class="jobs-page">
    <div class="jobs-header">
      <h2 class="jobs-title">职位搜索</h2>
      <div class="type-tabs">
        <button
          v-for="type in jobTypes"
          :key="type"
          :class="['type-tab', { active: activeType === type }]"
          @click="setType(type)"
        >
          {{ type }}
        </button>
      </div>
    </div>

    <div class="jobs-content">
      <p class="jobs-placeholder">职位列表加载中...</p>
    </div>
  </div>
</template>

<style scoped>
.jobs-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.jobs-header {
  display: flex;
  align-items: center;
  gap: 24px;
  margin-bottom: 24px;
  background: #fff;
  padding: 16px 24px;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.jobs-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-h);
  margin: 0;
  white-space: nowrap;
}

.type-tabs {
  display: flex;
  gap: 4px;
}

.type-tab {
  padding: 8px 20px;
  font-size: 14px;
  border: none;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
}

.type-tab:hover {
  color: #007AFF;
  background: rgba(0, 122, 255, 0.05);
}

.type-tab.active {
  color: #fff;
  background: #007AFF;
  font-weight: 500;
}

.jobs-content {
  background: #fff;
  border-radius: 8px;
  padding: 40px 24px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.jobs-placeholder {
  text-align: center;
  font-size: 15px;
  color: #999;
  margin: 0;
}

@media (max-width: 768px) {
  .jobs-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .type-tabs {
    width: 100%;
  }

  .type-tab {
    flex: 1;
    text-align: center;
  }
}
</style>
