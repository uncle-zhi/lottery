<template>
  <div class="main-container bg-img">
    <slot />
  </div>
</template>
<style scoped>
.main-container {
    min-height: 100vh;
    /* display: flex; */
    /* align-items: center; */
    justify-content: center;
    /* padding-top: 50px; */
}
.bg-img {
  background-image: url('@/assets/bg1.jpg');
  background-size: cover;
  background-position: center;
  /* height: 300px; */
}
</style>
