const { run ,network} = require("hardhat");
const { ProxyAgent, setGlobalDispatcher } = require("undici"); // 设置代理,解决了hardhat-verify无法连接的问题
const proxyAgent = new ProxyAgent("http://127.0.0.1:10809");  // 设置代理地址，确保你的代理服务运行在这个地址上
setGlobalDispatcher(proxyAgent);
require('dotenv').config();

async function main() {
  const contractAddress = "0xa54c573Abf21AD98b856C2A283829d512F6aF472";
  let constructorArgs = [];

  if (network.name === "sepolia") {
    constructorArgs = [
      BigInt(process.env.SUBSCRIPTION_ID), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR, // 替换为实际地址
      process.env.KEY_HASH,// 替换为实际keyHash
      process.env.REWARD_RATE,  // 返奖比例
      process.env.ROUND_DURATION
    ]
  } else if (network.name === "bsctest") {
    constructorArgs = [
      BigInt(process.env.SUBSCRIPTION_ID_BSC_TEST), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR_BSC_TEST, // 替换为实际地址
      process.env.KEY_HASH_BSC_TEST, // 替换为实际keyHash
      process.env.REWARD_RATE_BSC_TEST, // 返奖比例
      process.env.ROUND_DURATION_BSC_TEST
    ]
  } else if(network.name === "amoy"){
    constructorArgs = [
      BigInt(process.env.SUBSCRIPTION_ID_AMOY), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR_AMOY,// 替换为实际地址
      process.env.KEY_HASH_AMOY, // 替换为实际keyHash
      process.env.REWARD_RATE_AMOY,  // 返奖比例
      process.env.ROUND_DURATION_AMOY
    ]
  }else if(network.name === "polygon"){
    constructorArgs = [
      BigInt(process.env.SUBSCRIPTION_ID_POLYGON), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR_POLYGON,// 替换为实际地址
      process.env.KEY_HASH_POLYGON, // 替换为实际keyHash
      process.env.REWARD_RATE_POLYGON,  // 返奖比例
      process.env.ROUND_DURATION_POLYGON
    ]
  }else{
    throw new Error(`未为网络 ${network.name} 配置参数`);
  }
  console.log("正在验证合约...");

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: constructorArgs,
    });

    console.log("合约验证成功！");
  } catch (err) {
    console.error("合约验证失败:", err);
  }
}

main();
