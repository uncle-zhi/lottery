<template>
   <div style="text-align: center;">
    <a-row style="margin-bottom: 20px;">
      <a-col :span="24">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.myCurrentRoundBetNumber')" :value="myBetNumber" :value-style="{color: '#3f8600',fontWeight:'600',fontSize: '60px'}" />
      </a-col>
    </a-row>

    <a-row style="margin-bottom: 20px;">
            <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.myCurrentRoundBetAmount')" :precision="2" :value="myBetAmount" :value-style="{color: '#3f8600'}" />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.pendingRewards')" :precision="4" :value="myPrize" />
      </a-col>
  
    </a-row>
       <a-row style="margin-bottom: 20px;">
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.totalBets')" :value="totalBetCount"  />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.totalBetAmount')" :precision="4" :value="totalBetAmount" />
      </a-col>
    </a-row>
    <a-row style="margin-bottom: 20px;">
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.totalWins')" :value="winCount"  />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else :title="$t('message.totalPrizeAmount')" :precision="4" :value="totalWinAmount" />
      </a-col>
    </a-row>
      <a-row style="margin-bottom: 20px;">
      <a-col :span="24">
        <a-button @click="claimPrize" :loading="claiming" style="margin-left: 20px">
          {{ $t('message.withdrawReward') }}
        </a-button>
         <a-button @click="showWinRecords" style="margin-left: 20px">
           {{$t('message.winRecord')}}
        </a-button>
      </a-col>
    </a-row>
   </div>
     <a-drawer v-model:open="winRecordsDrawer" :title="$t('message.winRecord') " width="320" :closable="false">
        <a-table :dataSource="winRecords" :columns="columns" />
    </a-drawer>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { LotteryAPI } from '@/api/lotteryApi'
import LoadingBlock from './LoadingBlock.vue';
import { message } from 'ant-design-vue';
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const winCount = ref(0);
const totalWinAmount = ref(0);
const myBetNumber = ref("--");
const myBetAmount = ref("--");
const claiming = ref(false); // 领取奖金状态
const myPrize = ref(0);
const isLoading = ref(true)
const totalBetCount = ref(0);
const totalBetAmount = ref(0);
const winRecordsDrawer = ref(false);
const winRecords = ref([]);
const columns = ref([]);
const player = ref('');


const showWinRecords = async() => {
     columns.value = [
          {
            title: t('message.roundName'),
            dataIndex: 'round',
            key: 'round',
          },
          {
            title: t('message.betNumber'),
            dataIndex: 'number',
            key: 'number',
          },
          {
            title: t('message.bet')+'(ETH)',
            dataIndex: 'betAmount',
            key: 'betAmount',
          },
          {
            title: t('message.reward'),
            dataIndex: 'reward',
            key: 'reward',
          },
        ]
      winRecords.value = [];
      const events = await LotteryAPI.getWinRecords(player.value);
      if(events){
        for(let i=0; i< events.length;i++){
          winRecords.value.push({
                round: events[i].returnValues.round,
                number: events[i].returnValues.winNumber,
                betAmount: LotteryAPI.weiToEther(events[i].returnValues.betAmount),
                reward: LotteryAPI.weiToEther(events[i].returnValues.prizeAmount)
          })
        }
      }
   winRecordsDrawer.value = true;

}
const claimPrize = async () => {
  claiming.value = true; // 设置领取奖金状态为加载中
  try {
    await LotteryAPI.claimPrize();
    await showUserInfo(); // 重新加载我的信息
    message.success(t('message.claimSuccess'));
  } catch (error) {
    message.error(t('message.claimFailed') +' ：'+LotteryAPI.getRequireError(error));
  } finally {
    claiming.value = false; // 结束领取奖金状态
  }
};

const showUserInfo = async () => {
  isLoading.value = true;
  const playInfo = await LotteryAPI.getPlayerInfo();
  player.value = playInfo.player;
  console.log('playInfo',playInfo);
  myPrize.value = playInfo.pendingPrize;
  myBetNumber.value = Number(playInfo.currentBetNumber)==0?"--":Number(playInfo.currentBetNumber);
  myBetAmount.value = playInfo.currentBetAmount == 0 ? "--" : Number(playInfo.currentBetAmount);
  open.value = true;
  const events = await LotteryAPI.getPlayerPrizeEvent();
   
  if(events){
     winCount.value = events.length;
     let amount = 0 
     for(let i = 0; i< events.length;i++){
       amount += LotteryAPI.weiToEther(events[i].returnValues.prizeAmount);
     }
     totalWinAmount.value = amount;
  }

  const ticketPurchasedEvent = await LotteryAPI.getTicketPurchasedEvent();
  if(ticketPurchasedEvent){
       totalBetCount.value = ticketPurchasedEvent.length;
       let amount = 0 
       for(let i = 0; i< ticketPurchasedEvent.length;i++){
         amount += LotteryAPI.weiToEther(ticketPurchasedEvent[i].returnValues.amount);
       }
       totalBetAmount.value = amount;
  }

  isLoading.value = false;
  
};
defineExpose({
    showUserInfo
})
onMounted(showUserInfo)
</script>
<style scoped>
:deep(.ant-drawer-body .ant-statistic-title){
  color: black !important;
}
</style>