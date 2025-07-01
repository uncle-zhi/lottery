<template>
    <a-page-header
    style="color: white;"
    title=""
    :breadcrumb="{ routes }"
    sub-title=""
  />
  <div class="bet-page">
    <h2>{{ $t('message.betNumber') }}</h2>

    <a-form ref="formRef" :model="formState" name="dynamic_rule" v-bind="formItemLayout" @finish="checkInput"
      @finishFailed="gotBetFailed">
        <a-form-item label="" name="betNumber" :rules="[{ required: true, message: $t('message.tip1') }]" class="numberSelect">
    <a-radio-group v-model:value="formState.betNumber" name="radioGroup">
      <div v-for="(row, rowIndex) in radioRows" :key="rowIndex">
        <a-space>
          <a-radio
            v-for="num in row"
            :key="num"
            :value="String(num)"
          >{{ num }}</a-radio>
        </a-space>
      </div>
    </a-radio-group>
  </a-form-item>
      <a-form-item  label="" name="betAmount" :rules="[{ required: true, message: $t('message.tip2') }]">
        <span style="margin-top: 5px;">{{$t('message.betAmount')}}</span>
        <a-input-number  v-model:value="formState.betAmount" :min="0.01" step="0.01"  style="margin-left: 15px;"/>
      </a-form-item>
      <a-form-item v-bind="tailLayout">
        <div>
        <a-space>
        <a-button html-type="submit" size="middle" :loading="betLoading">{{$t('message.bet')}}</a-button>
        <a-button @Click="resetForm" size="middle">{{$t('message.reset')}}</a-button>
        <a-button @Click="goHome" size="middle">{{$t('message.cancel')}}</a-button>
        </a-space>
        </div>
      </a-form-item>
    </a-form>
    <div style="color: red;">{{ $t('message.tip3',{network:SUPPORTED_NETWORK.chainName})}}</div>
  </div>
</template>

<script setup>
import { reactive, ref, computed } from 'vue'
import {  SUPPORTED_NETWORK } from '@/config/lotteryConfig'
import {LotteryAPI} from '@/api/lotteryAPI'
import { message } from 'ant-design-vue';
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
const { t } = useI18n()
const router = useRouter()
// 生成 1~50 的数组，每行 5 个分组
const radioRows = computed(() => {
  const numbers = Array.from({ length: 5 }, (_, i) => i + 1)
  const chunkSize = 5
  const rows = []
  for (let i = 0; i < numbers.length; i += chunkSize) {
    rows.push(numbers.slice(i, i + chunkSize))
  }
  return rows
})
const goHome = () => {
  router.push('/')
}
const routes = [
  {
    path: '/',
    breadcrumbName: t('breadcrumb.home'),
  },
  {
    path: '/lottery-bet',
    breadcrumbName: t('breadcrumb.bet'),
  }

];

const betLoading = ref(false)
const formItemLayout = {
  labelCol: { span: 8 },
  wrapperCol: { span: 20 },
}
const tailLayout = {
  wrapperCol: { offset: 4, span: 14 },
}
const resetForm = () => {
  formState.betNumber = ''
  formState.betAmount = ''
}

const goBet = async (e) => {
  betLoading.value = true
  message.value = ''
  try {
    const receipt = await LotteryAPI.buyTicket(formState.betNumber, formState.betAmount)
    if (receipt.status) {
      message.success(t('message.betSuccess'));
      goHome()
      // resetForm(); // 重置表单
    } else {
      message.error(t('message.betFailed'));    }
  } catch (err) {
     message.error(t('message.betFailed')+':'+LotteryAPI.getRequireError(err), 5);
  } finally {
    betLoading.value = false
  }
};
const amount = ref('')
const loading = ref(false)
const formState = reactive({
  betNumber: '',
  betAmount: '0.01'
})

//利用form 来验证输入
const checkInput = e => {
  if (!window.ethereum) {
    message.error(t('message.installWallet'));
    return
  }
   goBet()
}

const onValuesChange = (changedValues, allValues) => {
 
}

const gotBetFailed = errorInfo => {
  
};

</script>

<style scoped>
.bet-page {
  max-width: 400px;
  margin: 0 auto;
  padding: 24px;
  border: 1px solid #eee;
  border-radius: 8px;
  background: #fafbfc;
  /* background: transparent; */
}
:deep(.ant-radio + span) {
  display: inline-block !important; /* 使 span 成为块级元素 */
  width: 14px !important; /* 设置每个 radio 的宽度 */
}
:deep(.ant-radio-group + .ant-form-item) {
  margin-top: 15px;
  width: 322px;
  margin-left: 50px;
}
:deep(.numberSelect) {
  display: flex;
  justify-content: center;
}
:deep(.ant-breadcrumb-link){
  color: gray;
}
:deep(.ant-breadcrumb a){
  color: white;
}
:deep(.ant-breadcrumb-separator){
  color: white;
}
</style>