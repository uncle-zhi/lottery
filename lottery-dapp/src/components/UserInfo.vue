<template>
   <div style="text-align: center;">
    <a-row style="margin-bottom: 20px;">
      <a-col :span="24">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="本轮投注号码" :value="myBetNumber" :value-style="{color: '#3f8600',fontWeight:'600',fontSize: '60px'}" />
      </a-col>
    </a-row>

    <a-row style="margin-bottom: 20px;">
            <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="本轮投注金额(ETH)" :precision="2" :value="myBetAmount" :value-style="{color: '#3f8600'}" />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="待提奖金(ETH)" :precision="4" :value="myPrize" />
      </a-col>
  
    </a-row>
       <a-row style="margin-bottom: 20px;">
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="总投注次数" :value="totalBetCount"  />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="总投注金额(ETH)" :precision="4" :value="totalBetAmount" />
      </a-col>
    </a-row>
    <a-row style="margin-bottom: 20px;">
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="总中奖次数" :value="winCount"  />
      </a-col>
      <a-col :span="12">
         <LoadingBlock v-if="isLoading"  />
        <a-statistic v-else title="总中奖金额(ETH)" :precision="4" :value="totalWinAmount" />
      </a-col>
    </a-row>
      <a-row style="margin-bottom: 20px;">
      <a-col :span="24">
        <a-button @click="claimPrize" :loading="claiming" style="margin-left: 20px">
          提取奖金
        </a-button>
      </a-col>
    </a-row>
   </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { LotteryAPI } from '@/api/lotteryAPI'
import LoadingBlock from './LoadingBlock.vue';
import { message } from 'ant-design-vue';
const winCount = ref(0);
const totalWinAmount = ref(0);
const myBetNumber = ref("--");
const myBetAmount = ref(0);
const claiming = ref(false); // 领取奖金状态
const myPrize = ref(0);
const isLoading = ref(true)
const totalBetCount = ref(0);
const totalBetAmount = ref(0);


const claimPrize = async () => {
  claiming.value = true; // 设置领取奖金状态为加载中
  console.log('claimPrize')
  try {
    await LotteryAPI.claimPrize();
    await showUserInfo(); // 重新加载我的信息
    message.success('奖金领取成功！');
  } catch (error) {
    message.error(LotteryAPI.getRequireError(error));
  } finally {
    claiming.value = false; // 结束领取奖金状态
  }
};

const showUserInfo = async () => {
    console.info("刷新用户信息")
    isLoading.value = true;
  const playInfo = await LotteryAPI.getPlayerInfo();
  console.log('playInfo',playInfo);
  myPrize.value = playInfo.pendingPrize;
  myBetNumber.value = Number(playInfo.currentBetNumber)==0?"--":Number(playInfo.currentBetNumber);
  console.log("myPrize",myPrize.value);
  console.log("myBetNumber",myBetNumber.value);
  console.log("myBetAmount",myBetAmount.value);

  myBetAmount.value = playInfo.currentBetAmount;
  open.value = true;
  const events = await LotteryAPI.getPlayerPrizeEvent();
   
  if(events){
     winCount.value = events.length;
     let amount = 0 
     for(let i = 0; i< events.length;i++){
       amount += LotteryAPI.weiToEther(events[i].returnValues.amount);
     }
     console.log("amount",amount);
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