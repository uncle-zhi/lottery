<template>
    <a-page-header
    style="color: white;"
    title=""
    :breadcrumb="{ routes }"
    sub-title=""
  />
  <div class="bet-page">
    <h2>投注页面</h2>

    <a-form ref="formRef" :model="formState" name="dynamic_rule" v-bind="formItemLayout" @finish="checkInput"
      @finishFailed="gotBetFailed">
      <a-form-item label="" name="betNumber" :rules="[{ required: true, message: '请选择你的投注号码' }]" class="numberSelect">
    <a-radio-group v-model:value="formState.betNumber" name="radioGroup" >
      <div>
      <a-space>
      <a-radio value="1">1</a-radio>
      <a-radio value="2">2</a-radio>
      <a-radio value="3">3</a-radio>
      <a-radio value="4">4</a-radio>
      <a-radio value="5">5</a-radio>

      </a-space>
      </div>
   <div>
      <a-space>
      <a-radio  value="6">6</a-radio>
      <a-radio value="7">7</a-radio>
      <a-radio value="8">8</a-radio>
      <a-radio value="9">9</a-radio>
      <a-radio value="10">10</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
          <a-radio value="11">11</a-radio>
      <a-radio value="12">12</a-radio>
      <a-radio value="13">13</a-radio>
      <a-radio value="14">14</a-radio>
      <a-radio value="15">15</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="16">16</a-radio>
      <a-radio value="17">17</a-radio>
      <a-radio value="18">18</a-radio>
      <a-radio value="19">19</a-radio>
      <a-radio value="20">20</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="21">21</a-radio>
      <a-radio value="22">22</a-radio>
      <a-radio value="23">23</a-radio>
      <a-radio value="24">24</a-radio>
      <a-radio value="25">25</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="26">26</a-radio>
      <a-radio value="27">27</a-radio>
      <a-radio value="28">28</a-radio>
      <a-radio value="29">29</a-radio>
      <a-radio value="30">30</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="31">31</a-radio>
      <a-radio value="32">32</a-radio>
      <a-radio value="33">33</a-radio>
      <a-radio value="34">34</a-radio>
      <a-radio value="35">35</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="36">36</a-radio>
      <a-radio value="37">37</a-radio>
      <a-radio value="38">38</a-radio>
      <a-radio value="39">39</a-radio>
      <a-radio value="40">40</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="41">41</a-radio>
      <a-radio value="42">42</a-radio>
      <a-radio value="43">43</a-radio>
      <a-radio value="44">44</a-radio>
      <a-radio value="45">45</a-radio>
      </a-space>
    </div>
    <div>
      <a-space>
      <a-radio value="46">46</a-radio>
      <a-radio value="47">47</a-radio>
      <a-radio value="48">48</a-radio>
      <a-radio value="49">49</a-radio>
      <a-radio value="50">50</a-radio>
      </a-space>
    </div>
    </a-radio-group>
    </a-form-item>
      <a-form-item  label="" name="betAmount" :rules="[{ required: true, message: '请转入你的投注金额!最低为 0.01 ETH' }]">
        <span style="margin-top: 5px;">投注(ETH):</span>
        <a-input-number  v-model:value="formState.betAmount" :min="0.01" step="0.01"  style="margin-left: 15px;"/>
      </a-form-item>

      <a-popconfirm v-model:open="popOpen" :title="confirmTip" cancelText="取消" okText="确认" @confirm="goBet"
        @cancel="cancel">
        <!-- dummy 触发元素，用作承载 -->
        <template #default>
          <span></span>
        </template>
      </a-popconfirm>
      <a-form-item v-bind="tailLayout">
        <div>
        <a-space>
        <a-button html-type="submit" size="middle">投注</a-button>
        <a-button @Click="resetForm" size="middle">重置</a-button>
        </a-space>
        </div>
      </a-form-item>
    </a-form>
    <div style="color: red;">{{ tip}}</div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import {  SUPPORTED_NETWORK } from '@/config/lotteryConfig'
import {LotteryAPI} from '@/api/lotteryAPI'
import { message } from 'ant-design-vue';

const routes = [
  {
    path: '/',
    breadcrumbName: '首页',
  },
  {
    path: '/lottery-bet',
    breadcrumbName: '投注页面',
  }

];

const confirmTip = ref('请确认投注信息');
const popOpen = ref(false)
const tip = ref(`	❗请在投注前确保已连接钱包，并且当前网络为 ${SUPPORTED_NETWORK.chainName}`);
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
  popOpen.value = false
  confirmTip.value = '请确认投注信息'
  tip.value = `❗请在投注前确保已连接钱包，并且当前网络为 ${SUPPORTED_NETWORK.chainName}`;
}

const goBet = async (e) => {
  console.log(e);
  loading.value = true
  message.value = ''
  try {
    const receipt = await LotteryAPI.buyTicket(formState.betNumber, formState.betAmount)
    if (receipt.status) {
      console.log('投注成功', receipt);
      message.success('投注成功！');
      resetForm(); // 重置表单
    } else {
      console.error('投注失败', receipt);
      message.error('投注失败，请稍后再试。');    }
  } catch (err) {
    console.log('交易失败', err);
     message.error(LotteryAPI.getRequireError(err), 5);
  } finally {
    loading.value = false
  }
};



const cancel = e => {
  console.log(e);
  message.error('取消投注');
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
    message.error('请先安装 MetaMask 等以太坊钱包插件')
    return
  }
  confirmTip.value = `请确认投注信息，投注号码: ${formState.betNumber}, 投注金额: ${formState.betAmount} ETH`;
  popOpen.value = true; // 显示确认弹窗
}

const gotBetFailed = errorInfo => {
  console.log('Failed:', errorInfo);
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