<template>
  <div >
    <a-row style="margin-bottom: 20px;">
      <a-col :span="24">
         <span style="margin-right: 2px; color:gray">
          {{$t('message.contractAddress')}}：
         </span>
         <span ref="contractAddr" style="margin-right: 5px; color:gray">
          {{contractAddress}}
         </span>
         <a-tooltip placement="top" :title="$t('message.copyAddress')">
          <span style="cursor: pointer;" @click="copyContractAddress">📋</span>
         
         </a-tooltip>
      </a-col>
    </a-row >
      <a-row v-if="blockCountdown>=0" style="margin-bottom: 20px;">
      <a-col :span="24">
         <span  style="margin-right: 2px; font-size: large; color:tomato">
           {{ $t('message.betRemainTip',{blockCountdown: blockCountdown }) }}
         </span>
      
      </a-col>
    </a-row>
    <a-row>
      <a-col :span="8" :offset="8">
        <div style="margin-bottom: 10px; ">
        <a-space>
          <a-tooltip placement="top" :title="$t('message.refresh') ">
            <span style="cursor: pointer;font-size: x-large;" @click="refreshPage">🔄</span>
            <!-- <SyncOutlined @click="refreshPage" /> -->
          </a-tooltip>
          <a-tooltip placement="top" :title="$t('message.showRoundsInfo') ">
            <span style="cursor: pointer;font-size: x-large;" @click="showRoundsInfo">🧿</span>
            <!-- <SyncOutlined @click="refreshPage" /> -->
          </a-tooltip>
          <a-tooltip placement="top" :title="$t('message.myInfo') ">
            <!-- <UserOutlined @click="openUserInfo" /> -->
            <span  style="cursor: pointer;font-size: x-large;" @click="openUserInfo" >👤</span>
          </a-tooltip>
        </a-space>
      </div>
      </a-col>
    </a-row>
    <a-row>
      <a-col :span="24">
        <div :class="statusClass" style="margin-bottom: 20px; font-size: x-large;">
            <LoadingBlock v-if="isLoading" class="loading" />
            <span style="color: white; cursor: pointer;"  v-else-if="canBet" @click="goToBetPage">💵 {{ $t('message.bet') }}</span>
            <!-- <a-button type="text" style="color: white;"  v-else-if="canBet" @click="goToBetPage">💵 {{ $t('message.bet') }}</a-button> -->
            <span v-else>{{ $t('lotteryStatus.'+ lotteryStatus,{ number: winningNumber }) }}</span> 
        </div>
      </a-col>
    </a-row>
    
    <a-row>
      <a-col :span="24">
        <div style="margin-bottom: 20px;">
        <LoadingBlock v-if="isLoading" class="loading"/>
        <a-statistic v-else :title="$t('message.totalPrizePool')" :precision="4" :value="totalPot" class="statistic-info"  :value-style="{ fontSize: '30px' }"/>
        </div>
      </a-col>
    </a-row>
    <a-row>
      <a-col :span="10" :offset="2">
        <div style="float: right;margin-right: 15px;">
        <LoadingBlock v-if="isLoading" class="loading"/>
        <a-statistic v-else :title="$t('message.bettorsThisRound')" :value="playerCount" class="statistic-info" />
        </div>
      
      </a-col>
      <a-col :span="10">
        <div style="float: left;margin-left: 15px;">
        <LoadingBlock v-if="isLoading" class="loading" />
        <a-statistic v-else :title="$t('message.currentRoundBetAmount')" :value="currentPot" class="statistic-info" />
        </div>
      </a-col>
    </a-row>
        <a-row>
      <a-col :span="10" :offset="2">
        <div style="float: right;margin-right: 15px;">
        <LoadingBlock v-if="isLoading"  class="loading"/>
        <a-statistic v-else :title="$t('message.totalWinningEntries')" :value="cumulativeWinners" class="statistic-info" />
        </div>
      </a-col>
      <a-col :span="10">
        <div style="float: left;margin-left: 15px;">
        <LoadingBlock v-if="isLoading"  class="loading"/>
        <a-statistic v-else :title="$t('message.totalRewardsDistributed')" :value="cumulativePrizeAmount" :precision="4" class="statistic-info" />
         </div>
      </a-col>
    </a-row>
      <a-row>
      <a-col :span="10" :offset="2">
        <div style="float: right;margin-right: 15px;">
        <LoadingBlock v-if="isLoading"  class="loading"/>
        <a-statistic v-else :title="$t('message.historyBetEntries')" :value="cumulativePlayers" class="statistic-info" />
        </div>
      </a-col>
      <a-col :span="10">
        <div style="float: left;margin-left: 15px;">
        <LoadingBlock v-if="isLoading"  class="loading"/>
        <a-statistic v-else :title="$t('message.historyBetAmount')" :value="cumulativeBetAmount" :precision="4" class="statistic-info" />
         </div>
      </a-col>
    </a-row>
  </div>
  <a-drawer v-model:open="open" class="custom-class" root-class-name="root-class-name" :root-style="{ color: 'gary' }"
    :title="$t('message.myInfo') " placement="right" @after-open-change="afterOpenChange">
    <UserInfo ref="userInfoRef"/>  
  </a-drawer>
    <a-drawer v-model:open="openRoundRecord" class="custom-class" root-class-name="root-class-name" :root-style="{ color: 'gary' }"
    :title="$t('message.winRecord') " placement="right">
      <a-table :dataSource="roundRecords" :columns="roundRecordsColumns" />
  </a-drawer>
</template>

<script setup>
import { ref, onMounted,onUnmounted } from 'vue'
import { LotteryAPI } from '@/api/lotteryAPI'
import { SyncOutlined, UserOutlined, CopyOutlined } from '@ant-design/icons-vue';
import { LOTTERY_CONTRACT_ADDRESS } from '@/config/lotteryConfig';
import { message } from 'ant-design-vue';
import LoadingBlock from './LoadingBlock.vue';
import UserInfo from '@/components/UserInfo.vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const router = useRouter();
const contractAddress = ref("");
const currentPot = ref(0)
const totalPot = ref(0)
const open = ref(false);
const stateDesc = ref('加载中...'); // 状态描述
const isLoading = ref(true);
const playerCount = ref(0); //投注人数
const cumulativeWinners = ref(0);
const cumulativePrizeAmount = ref(0);
const userInfoRef = ref(null);
const canBet = ref(false); // 是否可以投注

const contractAddr = ref(null);
const statusClass = ref("");
const lotteryStatus = ref(0);
const winningNumber = ref(0);
const cumulativePlayers = ref(0);
const cumulativeBetAmount = ref(0);
const blockCountdown = ref('--');
const openRoundRecord = ref(false);
const roundRecords = ref([]);
const roundRecordsColumns = ref([])
const round = ref(0);
const intervalId = ref(null)
const emit = defineEmits(['update:round']) // 自定义事件

const showRoundsInfo = async() => {
  // 跳转到轮次信息页面
   openRoundRecord.value = true;
   roundRecordsColumns.value = [
     { title: t('message.roundName'), dataIndex: 'round', key: 'round' },
     { title: t('message.winNumber'), dataIndex: 'number', key: 'number'}
   ]
    if(round.value <= 1){
       return;
    }
 roundRecords.value = [];
    const events = await LotteryAPI.getRandomNumberFulfilledEvent(Number(round.value),10);
    if(events.length > 0){
       for(let i=0;i<events.length;i++){
           let returnValues = events[i].returnValues;
           roundRecords.value.push({
               round: returnValues.round,
               number: returnValues.randomNumber

           })
       }
       roundRecords.value = roundRecords.value.reverse();
    }

    console.info('event',events);
}

const goToBetPage = () => {
  // 跳转到投注页面
  router.push('/lottery-bet')
}
const copyContractAddress = async () => {
   try{
    const text = contractAddr.value.innerText;
    await navigator.clipboard.writeText(text);
    message.success(t('message.copySuccess'));

   }catch( err){
     message.error(t('message.copyFailed'));
   }
};

const afterOpenChange = bool => {
 
};

const openUserInfo = async () => {
  open.value = true;
  if(userInfoRef.value){
    userInfoRef.value.showUserInfo();
  }
};

const refreshPage = async () => {
  // 刷新当前页面
  await loadLotteryInfo();
}
const loadLotteryInfo = async () => {

  isLoading.value = true; // 开始加载状态
  try {
    contractAddress.value = LOTTERY_CONTRACT_ADDRESS;
    //查询当前轮次
    const lotteryInfo = await LotteryAPI.lotteryInfo();
    console.log('lotteryInfo', lotteryInfo);
    emit('update:round', lotteryInfo.round) // 更新父组件的轮次信息
    //更新状态描述
    stateDesc.value = lotteryInfo.simpleState; // 更新状态描述
    if(lotteryInfo.status ==0){
      statusClass.value = "Betting";
      canBet.value = true;
    }else{
      statusClass.value = "NoBetting";
      canBet.value = false;
    }
    round.value = lotteryInfo.round;
    lotteryStatus.value = lotteryInfo.status;
    winningNumber.value = lotteryInfo.latestRandomNumber;
    //查询当前状态
    currentPot.value = await LotteryAPI.getCurrentRoundTotalAmount()  //本轮投注总额
    totalPot.value = lotteryInfo.totalPrizePool;  //总奖金池
    playerCount.value = (await LotteryAPI.getCurrentTicketsCount()).toString();
    cumulativeWinners.value = Number(lotteryInfo.cumulativeWinners);
    cumulativePrizeAmount.value = lotteryInfo.cumulativePrizeAmount;
    cumulativePlayers.value = Number(lotteryInfo.cumulativePlayers);
    cumulativeBetAmount.value = lotteryInfo.cumulativeBetAmount ;
    if((lotteryInfo.endNumber - lotteryInfo.blockNumber )< 1000 ){
       blockCountdown.value = lotteryInfo.endNumber - lotteryInfo.blockNumber ;
    }else{
       blockCountdown.value = "--";

    }
    
  }
  catch (error) {
    console.error('Error loading lottery info:', error);
  } finally {
    isLoading.value = false; // 结束加载状态
  }
}

const intervalReload = () => {
  loadLotteryInfo();
  //每30秒刷新一次页面
  if (!intervalId.value) {
  intervalId.value =setInterval(() => {
    loadLotteryInfo();
  }, 30000);
}
}
onMounted(intervalReload)
onUnmounted(() => {
  if (intervalId.value) {
    clearInterval(intervalId.value)
    intervalId.value = null
  }
})
</script>
<style scoped>

.status {
  margin-bottom: 130px;
}
.Betting {
  color: green
}
.NoBetting{
  color: gray;
}
:deep(.statistic-info .ant-statistic-title) {
  color: #d9d9d9 !important;
}
:deep(.statistic-info .ant-statistic-content) {
  color: #fff
}
.loading {
  color: #fff;
}
</style>