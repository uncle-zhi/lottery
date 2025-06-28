<!-- filepath: d:\MyProject\lottery\src\App.vue -->
<template>
  <div class="fullscreen-container">
    <a-layout style="height: 100vh;">
      <a-layout-header style="color: #fff; background: #001529;">
        <h1 style="margin: 0;"></h1>
      </a-layout-header>
      <a-layout-content style="flex: 1;  justify-content: center; align-items: center; background: #f5f5f5;">
        <slot />
      </a-layout-content>
    </a-layout>
  </div>
</template>

<script setup>
// 这里可以添加你的逻辑
</script>

<style>
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
}
.fullscreen-container {
  width: 100vw;
  height: 100vh;
  min-height: 100vh;
  box-sizing: border-box;
}
</style>