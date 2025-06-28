# Lottery 区块链彩票项目

本项目包含两个子项目：

- **lottery-contracts**：基于 Solidity 的智能合约，负责彩票的核心逻辑与链上操作。
- **lottery-dapp**：基于 Vue3 + Vite 的前端 Dapp，提供用户友好的购买彩票和开奖体验。

---

## 1. lottery-contracts（智能合约）

- 使用 Solidity 编写，部署在 EVM 兼容链（如 Sepolia 测试网）。
- 支持 Chainlink VRF 随机数，确保开奖公平。
- 支持购票、开奖、派奖、奖金领取、超时退款等功能。
- 合约安全性考虑：防重入、参数校验、权限控制等。

### 主要功能

- 用户可在每轮开放期间选择号码购票。
- 每轮结束后，合约管理员或服务器自动通过 Chainlink VRF 获取随机数开奖。
- 中奖用户按投注比例分配奖金，可随时领取奖金。
- 合约管理员与玩家都可以操作开奖。

### 目录结构

```
lottery-contracts/
├── contracts/         # Solidity 合约（Lottery.sol）
├── scripts/           # 部署脚本（deploy.js）
├── ignition/          # Hardhat Ignition 部署模块
├── test/              # 合约测试（可扩展）
├── hardhat.config.js  # Hardhat 配置
└── package.json
```

### 快速开始

```bash
cd lottery-contracts
npm install
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
```

---

## 2. lottery-dapp（前端 Dapp）

- 使用 Vue3 + Vite 构建，界面简洁，交互友好。
- 支持购买彩票、开奖展示、中奖信息展示等功能。
- 预留与合约交互的接口，便于后续集成 Web3 功能。

### 主要功能

- 首页展示彩票信息。
- 购买彩票（模拟功能，后续可接入合约）。
- 开奖按钮，随机选出中奖者（当前为前端模拟，后续可接入链上数据）。
- 展示中奖结果。

### 目录结构

```
lottery-dapp/
├── src/
│   ├── components/    # 组件（Lottery.vue）
│   ├── views/         # 页面视图（Home.vue）
│   ├── App.vue        # 根组件
│   └── main.js        # 入口文件
├── public/            # 静态资源
├── package.json
└── vite.config.js
```

### 快速开始

```bash
cd lottery-dapp
npm install
npm run dev
# 浏览器访问 http://localhost:3000
```

---

## 3. 未来规划

- 前端集成 Web3，与合约实时交互。
- 增加用户钱包连接、链上购票、链上开奖等功能。
- 完善合约测试与前端测试。

---

## 4. 目录说明

- [`lottery-contracts`](lottery-contracts/README.md)：合约项目说明
- [`lottery-dapp`](lottery-dapp/README.md)：前端项目说明

---

如有建议或问题，欢迎提 Issue 或 PR！