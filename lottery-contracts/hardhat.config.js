require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();
const { ProxyAgent, setGlobalDispatcher } = require("undici"); // 设置代理,解决了hardhat-verify无法连接的问题
const proxyAgent = new ProxyAgent("http://127.0.0.1:10809");  // 设置代理地址，确保你的代理服务运行在这个地址上
setGlobalDispatcher(proxyAgent);
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true // ✅ 放在这里才生效
    }
  },
  sourcify: {
    enabled: true
  },
  defaultNetwork: "hardhat",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    bsctest: {
      url: process.env.BSC_TESTNET_RPC,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 97
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY, // 在 .env 文件中配置
  },
};
