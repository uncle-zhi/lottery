// filepath: lottery-contracts/scripts/deploy.js
const { ethers, network } = require("hardhat");
require('dotenv').config();

async function main() {

  let subscriptionId
  let vrfCoordinator
  let keyHash
  let rewardRate // 返奖比例，0-10000
  let roundDuration
  console.log("准备部署 Lottery 合约...");
  if (network.name === "sepolia") {
    subscriptionId = BigInt(process.env.SUBSCRIPTION_ID); // 替换为实际订阅ID
    vrfCoordinator = process.env.VRF_COORDINATOR; // 替换为实际地址
    keyHash = process.env.KEY_HASH; // 替换为实际keyHash
    rewardRate = process.env.REWARD_RATE;  // 返奖比例
    roundDuration = process.env.ROUND_DURATION;  // 轮次时长
  } else if (network.name === "bsctest") {
     subscriptionId = BigInt(process.env.SUBSCRIPTION_ID_BSC_TEST); // 替换为实际订阅ID
      vrfCoordinator = process.env.VRF_COORDINATOR_BSC_TEST; // 替换为实际地址
      keyHash = process.env.KEY_HASH_BSC_TEST; // 替换为实际keyHash
      rewardRate = process.env.REWARD_RATE_BSC_TEST;  // 返奖比例
      roundDuration = process.env.ROUND_DURATION_BSC_TEST;  // 轮次时长
  } else if(network.name === "amoy"){
      subscriptionId = BigInt(process.env.SUBSCRIPTION_ID_AMOY); // 替换为实际订阅ID
      vrfCoordinator = process.env.VRF_COORDINATOR_AMOY; // 替换为实际地址
      keyHash = process.env.KEY_HASH_AMOY; // 替换为实际keyHash
      rewardRate = process.env.REWARD_RATE_AMOY;  // 返奖比例
      roundDuration = process.env.ROUND_DURATION_AMOY;  // 轮次时长
  }else{
    throw new Error(`未为网络 ${network.name} 配置参数`);
  }

  const Lottery = await ethers.getContractFactory("Lottery");
  console.log("已获取合约工厂，开始部署...");
  const lottery = await Lottery.deploy(subscriptionId, vrfCoordinator, keyHash, rewardRate,roundDuration);
  console.log("部署交易已发送，等待上链...");
  console.log(`Lottery deployed to: ${lottery.target} on network: ${network.name}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
