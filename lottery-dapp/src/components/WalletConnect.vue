<template>
  <div style="margin-right: 20px; margin-top: 10px;">
    <a-space>
    <a-button @click="connectWallet">
      {{ account ? '已连接: ' + shortAccount : '连接钱包' }}
    </a-button>

    </a-space>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
const account = ref(null)

const connectWallet = async () => {
  if (window.ethereum) {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
    account.value = accounts[0]
  } else {
    alert('Please install MetaMask')
  }
}

const shortAccount = computed(() =>
  account.value ? account.value.slice(0, 6) + '...' + account.value.slice(-4) : ''
)
</script>
