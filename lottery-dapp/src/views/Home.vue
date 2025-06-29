<template>
  <div class="p-4">
    <div class = "connect-wallet">
       <WalletConnect ref="wallet" />
      </div>
    <h1 class="text-2xl font-bold mb-4 white">🎰 {{$t('message.homeTitle')}}({{$t('message.round',{round: round})}})</h1>
    <LotteryInfo @update:round="updateRound" />
  </div>
</template>

<script setup>
import WalletConnect from '@/components/WalletConnect.vue'
import LotteryInfo from '@/components/LotteryInfo.vue'
import { ref, onMounted } from 'vue'
const round = ref(0);
const wallet = ref();
const updateRound = (newRound) => {
  round.value = newRound;
}
</script>
<style scoped>
.connect-wallet {
  display: flex;
  justify-content: flex-end;
}
</style>
