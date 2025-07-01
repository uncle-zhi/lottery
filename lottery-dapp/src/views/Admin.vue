<template>
   <a-page-header
    style="border: 1px solid rgb(235, 237, 240)"
    title=""
    :breadcrumb="{ routes }"
    sub-title=""
  />
  <div class="p-4">
    <h1 class="text-2xl font-bold mb-4">🎰 欢迎来到管理后台</h1>
    <div style="color: red;">{{ adminMessage }}</div>
    <div>
</div>
  <div>
    <a-space>
    <a-button  @click="showCurrentRoundInfo" :loading="showCurrentRoundInfoLoading">显示当前轮信息</a-button>
    <a-button  @click="startNewRound" :loading="startNewRoundLoading">开启新一轮投注</a-button>
    </a-space>
  </div>
    <div>
      <a-space>
    <a-button  @click="preDistributePrizes" :loading="preDistributePrizesLoading">预开奖</a-button>
    <a-button  @click="distributePrizesAndEndCurrentRound" :loading="distributePrizesAndEndCurrentRoundLoading">开奖</a-button>
      </a-space>
  </div>
  <div>
      <a-space>
    <a-button  @click="simulatePreDis" :loading="preDistributePrizesLoading">模拟预开奖</a-button>
    <a-button  @click="withdrawAll" :loading="distributePrizesAndEndCurrentRoundLoading">提现</a-button>
      </a-space>
  </div>
  </div>

  <a-drawer
    v-model:open="open"
    class="custom-class"
    root-class-name="root-class-name"
    :root-style="{ color: 'blue' }"
    style="color: red"
    title="当前轮次信息"
    placement="right"
    @after-open-change="afterOpenChange"
  >
    <p>当前轮次：{{ lotteryState.round }}</p>
    <p>总奖金池：{{ lotteryState.totalPrizePool }} ETH</p>
    <p>待领取奖励总额：{{ lotteryState.totalPendingRewards }} ETH</p>
    <p>起始区块：[{{ lotteryState.startNumber }} ,{{lotteryState.endNumber}}], 当前区块：{{ lotteryState.blockNumber }}</p>
    <p>是否开启投注: {{ lotteryState.isLotteryOpen }}</p>
    <p>开奖号码：{{ lotteryState.latestRandomNumber }}</p>
    <p>奖励分配率：{{ lotteryState.rewardRate }}%</p>
    <p>是否正在开奖: {{ lotteryState.isDistributing }}</p>
    <p>延迟时间: {{ lotteryState.delayDuration }} 区块</p>
    <p>状态描述: {{ lotteryState.stateDesc }}</p>
  </a-drawer>
</template>
<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import {LotteryAPI} from '@/api/lotteryAPI'
import { message } from 'ant-design-vue';
const routes = [
  {
    path: '/',
    breadcrumbName: '首页',
  },
  {
    path: '/Admin',
    breadcrumbName: '后台管理',
  }

];
const adminMessage = ref('这是一个仅限管理员访问的区域')
const router = useRouter()
const open = ref(false);
const showCurrentRoundInfoLoading = ref(false);
const startNewRoundLoading = ref(false);
const preDistributePrizesLoading = ref(false);
const distributePrizesAndEndCurrentRoundLoading = ref(false);
const lotteryState = reactive({
        round: 0,
        startNumber: 0,
        endNumber: 0,
        isLotteryOpen: false,
        totalPrizePool: 0,
        totalPendingRewards: 0,
        lastRequestId: 0,
        latestRandomNumber: 0,
        rewardRate: 0,
        isDistributing: false,
        blockNumber: 0,
        delayDuration: 0,
        stateDesc: '未知状态'
});

const withdrawAll = async() =>{
   try{
      await LotteryAPI.withdrawAll();
      message.success('提现成功');
   }catch(error){
    message.error(LotteryAPI.getRequireError(error), 5);
   }
 
};
const simulatePreDis = async () =>{
   await LotteryAPI.simulatePreDis(2);
};

const afterOpenChange = bool => {
  console.log('open', bool);
};
const showCurrentRoundInfo = async () => {
  // 显示当前轮次信息
  showCurrentRoundInfoLoading.value = true;
  const lotteryInfo  = await LotteryAPI.lotteryInfo();
  Object.assign(lotteryState, lotteryInfo);
  open.value = true;
  showCurrentRoundInfoLoading.value = false;
};

const goToHome = () => {
  // 跳转到投注页面
  router.push('/')
}

const startNewRound =  async() => {
  startNewRoundLoading.value = true;
   console.log('开始新一轮投注');
     try {
       await LotteryAPI.startNewRound();
       message.success('新一轮投注已开启！');
     } catch (error) {
       message.error(LotteryAPI.getRequireError(error), 5);
     } finally {
       startNewRoundLoading.value = false;
     }
   
}
const preDistributePrizes = async () => {
  preDistributePrizesLoading.value = true;
   console.log('预开奖');
   try {
     await LotteryAPI.preDistributePrizes();
     message.success('预开奖成功！');
   } catch (error) {
     message.error(LotteryAPI.getRequireError(error), 5);
   } finally {
     preDistributePrizesLoading.value = false;
   }
}
const distributePrizesAndEndCurrentRound = async () => {
  distributePrizesAndEndCurrentRoundLoading.value = true;
   console.log('号码开奖');
   try {
     await LotteryAPI.distributePrizesAndEndCurrentRound();
     message.success('号码开奖成功！');
   } catch (error) {
     message.error(LotteryAPI.getRequireError(error), 5);
   } finally {
     distributePrizesAndEndCurrentRoundLoading.value = false;
   }
}
</script> 