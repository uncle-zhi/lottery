<template>
  <div style="margin-right: 20px; margin-top: 10px;">
    <a-space>
      <a-dropdown>
        <a-button  type="text"  style=" color: white">{{ $t('message.language') }}</a-button>
        <template #overlay>
          <a-menu>
            <a-menu-item >
               <a @click="switchToZh">中文</a>
            </a-menu-item>
            <a-menu-item v-if="locale.value !== 'en'">
               <a @click="switchToEn">English</a>
            </a-menu-item>
           
          </a-menu>
        </template>
      </a-dropdown>
      </a-space>

    <a-space>
    <a-button  type="text" @click="connectWallet" style="margin-left: 10px; color: white">
      {{ account ? t('message.connected')+': ' + shortAccount : t('message.connectWallet') }}
    </a-button>

    </a-space>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { t, locale } = useI18n()
const account = ref(null)

const switchToZh = () => {
  locale.value = 'zh'
}

const switchToEn = () => {
  locale.value = 'en'
}

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
<style scoped>
#components-dropdown-demo-placement .ant-btn {
  margin-right: 8px;
  margin-bottom: 8px;
}
  </style>

