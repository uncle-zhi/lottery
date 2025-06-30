import Web3 from 'web3'
import { LOTTERY_CONTRACT_ADDRESS, LOTTERY_ABI, SUPPORTED_NETWORK } from '@/config/lotteryConfig'

let web3
let contract
let isInitialized = false

export const getHistoryEvents = async (eventName, fromBlock) => {
  contract.getPastEvents(eventName, {
    fromBlock: fromBlock,
    toBlock: 'latest'
  })
    .then(events => {
      events.forEach(event => {
        console.log(`事件 ${eventName} 在区块 ${event.blockNumber} 中触发`);
        console.log('事件数据:', event.returnValues);
      });
    })
    .catch(console.error);
}

export const checkNetwork = async () => {
  if (typeof window.ethereum === "undefined") {
    alert("请先安装 MetaMask 等以太坊钱包插件");
    return;
  }
  const targetChainId = '0x' + SUPPORTED_NETWORK.chainId.toString(16);

  const currentChainId = await window.ethereum.request({ method: "eth_chainId" });
  console.log(`当前网络 ID: ${currentChainId}, 目标网络 ID: ${targetChainId}`);
  if (currentChainId !== targetChainId) {
    alert(`请在钱包中切换到 ${SUPPORTED_NETWORK.chainName} 测试网络`);
    // 可自动请求切换网络
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: targetChainId }]
      });
    } catch (switchError) {
      // 如果没有添加过 Sepolia，可以请求添加
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: "wallet_addEthereumChain",
            params: [{
              chainId: sepoliaChainId,
              chainName: "Sepolia Test Network",
              rpcUrls: ["https://rpc.sepolia.org"],
              nativeCurrency: { name: "SepoliaETH", symbol: "ETH", decimals: 18 },
              blockExplorerUrls: ["https://sepolia.etherscan.io"]
            }]
          });
        } catch (addError) {
          alert("添加 Sepolia 网络失败，请手动切换");
        }
      } else {
        alert("切换网络失败，请手动切换到 Sepolia");
      }
    }
  }
}

export const initWeb3AndContract = () => {
  if (!isInitialized) {
    web3 = new Web3(window.ethereum)
    contract = new web3.eth.Contract(LOTTERY_ABI, LOTTERY_CONTRACT_ADDRESS)
    isInitialized = true
  }
}

export const LotteryAPI = {
  weiToEther: (amount) => {
     return Number(web3.utils.fromWei(amount , 'ether'))
  },
  getWinRecords: async(player) => {
      const events = await contract.getPastEvents("PrizeDistributed", {
        fromBlock: 0,
        toBlock: 'latest',
        filter: {
          player: player
        }
      })
      return events;
  },
  getRandomNumberFulfilledEvent: async(round,count) => {
      //只取最近10轮的
      let filterRound = [];
      if(round>count){
        for(let i=round-1;i>=round-count;i--){
          filterRound.push(i);
        }
      }else{
        for(let i=round-1;i>0;i--){
          filterRound.push(i);
        }
      }
    const events = await contract.getPastEvents("RandomNumberFulfilled", {
        fromBlock: 0,
        toBlock: 'latest',
        filter: {
          round: filterRound
        }
      })
    return events;
  },
  getTicketPurchasedEvent: async() => {
    const accounts = await web3.eth.getAccounts();
    const events = await contract.getPastEvents("TicketPurchased", {
      fromBlock: 0,
      toBlock: 'latest',
      filter: {
        player: accounts[0]
      }
    })
     console.log('event',events);
     return events;
  },
  getPlayerPrizeEvent: async() => {
    const accounts = await web3.eth.getAccounts();
    const events = await contract.getPastEvents("PrizeDistributed", {
      fromBlock: 0,
      toBlock: 'latest',
      filter: {
        player: accounts[0]
      }
    })
     console.log('event',events);
     return events;
  },
  withdrawAll: async() =>{
     //先用call方法测试能不能调通
     const accounts = await web3.eth.getAccounts();
     try {
      const canDistribute = await contract.methods.withdrawAll().call({ from: accounts[0] });
      console.log("预测成功，可以调用，返回值:", canDistribute);
    } catch (error) {
      console.error("Error checking distribution eligibility:", error);
      throw new Error(error.message || "无法提现");
    }
    await contract.methods.withdrawAll().send({from: accounts[0]});
  },
  simulatePreDis: async(num) =>{
    const accounts = await web3.eth.getAccounts();
    await contract.methods.simulatePreDis(num).send({from: accounts[0]});
  },
  getRequireError: (error) => {
    const msg = error.message;
    const parts = msg.split(":");
    const lastPart = parts[parts.length - 1].trim();
    return lastPart;
  },
  // ✅ payable 函数
  buyTicket: async (betNumber, betAmount) => {
    await checkNetwork();  // 检查网络
    const accounts = await web3.eth.getAccounts();
    console.log(betNumber, betAmount);

    //先用call方法测试能不能调通
    try {
      const canBuy = await contract.methods.buyTicket(betNumber).call({
        from: accounts[0],
        value: web3.utils.toWei(betAmount, 'ether')
      });
      console.log("预测成功，可以调用，返回值:", canBuy);
    } catch (error) {
      console.error("Error checking buy eligibility:", error);
      throw new Error(error.message || "无法购买彩票，请检查网络或合约状态");
    }
    // 假设合约有 bet() payable 方法
    const receipt = await contract.methods.buyTicket(betNumber).send({
      from: accounts[0],
      value: web3.utils.toWei(betAmount, 'ether')
    })
    return receipt
  },

  // ✅ 非 payable 发送函数
  claimPrize: async () => {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    //先用call方法测试能不能调通
    await checkNetwork();  //检查网络
    try {
      const canClaim = await contract.methods.claimPrize().call({ from: accounts[0] });
      console.log("预测成功，可以调用，返回值:", canClaim);
    } catch (error) {
      console.error("Error checking claim eligibility:", error);
      throw new Error(error.message || "无法领取奖金，请检查网络或合约状态");
    }
    const receipt = await contract.methods.claimPrize().send({ from: accounts[0] });
    return receipt;
  },
  distributePrizesAndEndCurrentRound: async () => {
    await checkNetwork();  //检查网络
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    //先用call方法测试能不能调通
    try {
      const canDistribute = await contract.methods.distributePrizesAndEndCurrentRound().call({ from: accounts[0] });
      console.log("预测成功，可以调用，返回值:", canDistribute);
    } catch (error) {
      console.error("Error checking distribution eligibility:", error);
      throw new Error(error.message || "无法分配奖金，请检查网络或合约状态");
    }

    const receipt = await contract.methods.distributePrizesAndEndCurrentRound().send({ from: accounts[0] });
    return receipt;
  },
  startNewRound: async (from) => {
    await checkNetwork();  //检查网络
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    //先用call方法测试能不能调通
    try {
      const canStartNewRound = await contract.methods.startNewRound().call({ from: accounts[0] });
      console.log("预测成功，可以调用，返回值:", canStartNewRound);
    } catch (error) {
      console.error("Error checking new round eligibility:", error);
      throw new Error(error.message || "无法开始新一轮，请检查网络或合约状态");
    }
    const receipt = await contract.methods.startNewRound().send({ from: accounts[0] });
    return receipt;
  },
  acceptOwnership: (from) => contract.methods.acceptOwnership().send({ from }),
  preDistributePrizes: async () => {
    await checkNetwork();  //检查网络
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    //先用call方法测试能不能调通
    try {
      const canPreDistribute = await contract.methods.preDistributePrizes().call({ from: accounts[0] });
      console.log("预测成功，可以调用，返回值:", canPreDistribute);
    } catch (error) {
      console.error("Error checking pre-distribution eligibility:", error);
      throw new Error(error.message || "无法预分配奖金，请检查网络或合约状态");
    }
    const receipt = await contract.methods.preDistributePrizes().send({ from: accounts[0] })
    return receipt;
  },
  refundTickets: (from) => contract.methods.refundTickets().send({ from }),
  transferOwnership: (from, to) => contract.methods.transferOwnership(to).send({ from }),
  setCoordinator: (from, address) => contract.methods.setCoordinator(address).send({ from }),


  getCurrentRoundTotalAmount: async () => {
    const amount = await contract.methods.getCurrentRoundTotalAmount().call();
    return web3.utils.fromWei(amount, 'ether')
  },
  getPendingPrize: async (from) => {
    const amount = await contract.methods.pendingRewards(from).call();
    return web3.utils.fromWei(amount, 'ether');
  },
  getMyPrize: async () => {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const amount = await contract.methods.pendingRewards(accounts[0]).call();
    return web3.utils.fromWei(amount, 'ether');;
  },
  getMyTicket: async () => {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const ticket = await contract.methods.getMyTicket().call({from: accounts[0]});
    if(ticket){
      ticket.amount = web3.utils.fromWei(ticket.amount, 'ether');
    }
    return ticket;
  } ,
  getPlayerInfo: async () => {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const playInfo = await contract.methods.getPlayerInfo(accounts[0]).call({});
    if(playInfo){
       playInfo.currentBetAmount = web3.utils.fromWei(playInfo.currentBetAmount , 'ether');
       playInfo.pendingPrize = web3.utils.fromWei(playInfo.pendingPrize , 'ether');
    }
    return playInfo;
  },
  contractOwner: () => contract.methods.contractOwner().call(),
  owner: () => contract.methods.owner().call(),
  MIN_BET_AMOUNT: () => contract.methods.MIN_BET_AMOUNT().call(),
  MIN_NUMBER: () => contract.methods.MIN_NUMBER().call(),
  MAX_NUMBER: () => contract.methods.MAX_NUMBER().call(),
  ROUND_DURATION: () => contract.methods.ROUND_DURATION().call(),
  DELAY_DURATION: async () => {
    const delay = await contract.methods.DELAY_DURATION().call()
    return delay
  },
  getCurrentTicketsCount: async () => {
       const playerCount = await contract.methods.getCurrentTicketsCount().call();
       return playerCount;
  },
  prevRoundData: async () => {
       const roundData = await contract.methods.prevRoundData().call();
       return roundData;
  },
  lotteryInfo: async () => {
    const lotteryInfo = await contract.methods.lotteryInfo().call()
    console.log(lotteryInfo);
    const blockNumber = await web3.eth.getBlockNumber()
    const delay_duration = await contract.methods.DELAY_DURATION().call()

    const info = {
      round: lotteryInfo.round,
      startNumber: lotteryInfo.startNumber,
      endNumber: lotteryInfo.endNumber,
      isLotteryOpen: lotteryInfo.isLotteryOpen,
      totalPrizePool: web3.utils.fromWei(lotteryInfo.totalPrizePool, 'ether'),
      totalPendingRewards: web3.utils.fromWei(lotteryInfo.totalPendingRewards, 'ether'),
      lastRequestId: lotteryInfo.lastRequestId,
      latestRandomNumber: lotteryInfo.latestRandomNumber,
      rewardRate: lotteryInfo.rewardRate,
      isDistributing: lotteryInfo.isDistributing,
      cumulativePrizeAmount: web3.utils.fromWei(lotteryInfo.cumulativePrizeAmount, 'ether'),  //累计中奖金额
      cumulativeWinners: lotteryInfo.cumulativeWinners, //累计中奖人次
      distributedCount: lotteryInfo.distributedCount,
      cumulativePlayers: lotteryInfo.cumulativePlayers, //累计投注人次 (Cumulative players)
      cumulativeBetAmount: web3.utils.fromWei(lotteryInfo.cumulativeBetAmount,'ether'), //累计投注金额 (Cumulative bet amount)
      blockNumber: blockNumber,
      delayDuration: delay_duration,
      status: 0,
      stateDesc: '未知状态',
      simpleState: '未知状态'
    }
    const status = await contract.methods.getLotteryStatus().call();
    info.status = Number(status);

    if(status==0){
      info.stateDesc = '接受投注中'
      info.simpleState = '接受投注中'
    }
    if(status==1){
      info.stateDesc = '延时开奖中'
      info.simpleState = '投注结束，待开奖'
    }
        if(status==2){
      info.stateDesc = '等待预开奖'
      info.simpleState = '投注结束，待开奖'
    }
        if(status==3){
      info.stateDesc = '预开奖中'
      info.simpleState = '投注结束，待开奖'
    }
        if(status==4){
      info.stateDesc = '预开奖完成，等待开奖（随机数已生成）'
      info.simpleState = '投注结束，待开奖'
    }
        if(status==5){
      info.stateDesc = '开奖完成，等待开启下一轮'
      info.simpleState = `开奖结束，中奖号码为: ${info.latestRandomNumber}`
    }
    return info
  },
  vrfConfig: () => contract.methods.vrfConfig().call(),
  s_vrfCoordinator: () => contract.methods.s_vrfCoordinator().call(),

  // ✅ 带参数的 getter
  getPlayerTicket: (address) => contract.methods.getPlayerTicket(address).call(),
  getTotalAmountForNumber: (number) => contract.methods.getTotalAmountForNumber(number).call(),
  getTickets: (round) => contract.methods.getTickets(round).call(),
  hasBought: (round, address) => contract.methods.hasBought(round, address).call(),
  requestIdToRandomNumber: (requestId) => contract.methods.requestIdToRandomNumber(requestId).call(),
  ticketsPerRound: (round, index) => contract.methods.ticketsPerRound(round, index).call(),
  ticketsPerNumber: (round, number, index) => contract.methods.ticketsPerNumber(round, number, index).call(),

  // ⚠️ 内部函数（如 rawFulfillRandomWords）一般不建议外部调用
  rawFulfillRandomWords: (from, requestId, randomWords) => contract.methods.rawFulfillRandomWords(requestId, randomWords).send({ from })
}

initWeb3AndContract(); // 初始化合约