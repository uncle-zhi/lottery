const { run } = require("hardhat");
const { ProxyAgent, setGlobalDispatcher } = require("undici"); // 设置代理,解决了hardhat-verify无法连接的问题
const proxyAgent = new ProxyAgent("http://127.0.0.1:10809");  // 设置代理地址，确保你的代理服务运行在这个地址上
setGlobalDispatcher(proxyAgent);
require('dotenv').config();

async function main() {
  const contractAddress = "0xABF2Fc9f342b42Ec79AAaFcF5Bc3d604f3bf3e89";
  const constructorArgs = [
    BigInt(process.env.SUBSCRIPTION_ID),                              // subscriptionId
    process.env.VRF_COORDINATOR,           // VRF coordinator
    process.env.KEY_HASH,                       // keyHash
    process.env.REWARD_RATE                                 // rewardRate
  ];

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
