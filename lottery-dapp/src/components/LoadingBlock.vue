<template>
   <div :class="customClass">
      <LoadingOutlined />
      正在加载...
   </div>
</template>
<script setup>
import { LoadingOutlined } from '@ant-design/icons-vue';
defineProps({
  customClass: {
    type: String,
    default: 'loading-block'
  }
});
</script>