<template>
   <div :class="customClass">
      <LoadingOutlined />
      {{ $t('message.loading') }}...
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