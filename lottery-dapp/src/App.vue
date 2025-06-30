<template>
  <div id="app">
    <component :is="layoutComponent">
      <router-view />
    </component>
  </div>
</template>

<script setup>
const name = 'App'
import { useRoute } from 'vue-router'
import { computed } from 'vue'

import AdminLayout from '@/layouts/AdminLayout.vue'
import FullscreenLayout from '@/layouts/FullscreenLayout.vue'

const route = useRoute()

const layoutMap = {
  AdminLayout,
  FullscreenLayout
}

const layoutComponent = computed(() => {
  return layoutMap[route.meta.layout] || FullscreenLayout
})
</script>

<style>
#app {
  text-align: center;
  /* margin-top: 20px; */
}

</style>