const { run ,network} = require("hardhat");
const { ProxyAgent, setGlobalDispatcher } = require("undici"); // 设置代理,解决了hardhat-verify无法连接的问题
const proxyAgent = new ProxyAgent("http://127.0.0.1:10809");  // 设置代理地址，确保你的代理服务运行在这个地址上
setGlobalDispatcher(proxyAgent);
require('dotenv').config();

async function main() {
  const contractAddress = "0xABF2Fc9f342b42Ec79AAaFcF5Bc3d604f3bf3e89";
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
      BigInt(process.env.SUBSCRIPTION_ID_BCS_TEST), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR_BCS_TEST, // 替换为实际地址
      process.env.KEY_HASH_BCS_TEST, // 替换为实际keyHash
      process.env.REWARD_RATE_BCS_TEST, // 返奖比例
      process.env.ROUND_DURATION_BCS_TEST
    ]
  } else if(network.name === "amoy"){
    constructorArgs = [
      BigInt(process.env.SUBSCRIPTION_ID_AMOY), // 替换为实际订阅ID
      process.env.VRF_COORDINATOR_AMOY,// 替换为实际地址
      process.env.KEY_HASH_AMOY, // 替换为实际keyHash
      process.env.REWARD_RATE_AMOY,  // 返奖比例
      process.env.ROUND_DURATION_AMOY
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
