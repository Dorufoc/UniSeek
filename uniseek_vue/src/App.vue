<script setup lang="ts">
</script>

<template>
  <!-- 根路由出口，所有页面通过路由切换在此渲染 -->
  <router-view />
</template>

<style>
/* 强制覆盖 Vite 默认居中和最大宽度限制，实现全屏大屏 */
html, body, #app {
  margin: 0 !important;
  padding: 0 !important;
  width: 100% !important;
  max-width: 100% !important;
  height: 100% !important;
  overflow: auto !important;
  background-color: #051024 !important;
  text-align: left !important;
}

/* 修复动态流列表在强制全屏后的滚动区域 */
.feed-list {
  width: 100%;
}
</style>
