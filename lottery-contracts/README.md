# lottery-contracts

本目录包含区块链彩票系统的智能合约源码、部署脚本与相关配置。

---

## 目录结构

```
lottery-contracts/
├── contracts/           # Solidity 智能合约
│   └── Lottery.sol      # 核心彩票合约
├── scripts/             # 部署与交互脚本
│   └── deploy.js        # 合约部署脚本
├── ignition/            # Hardhat Ignition 部署模块
├── test/                # 合约测试（可扩展）
├── hardhat.config.js    # Hardhat 配置文件
└── package.json         # Node.js 依赖管理
```

---

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 编译合约

```bash
npx hardhat compile  # 编译合约
或者
npm run compile 
```

### 3. 部署合约

- 配置 `.env` 文件，填写私钥、RPC、Chainlink VRF 等参数（参考 `hardhat.config.js`）。
- 部署到测试网（如 Sepolia）：
- 部署前，请先编译合约，并确保 `.env` 文件配置正确。

```bash
npx hardhat run scripts/deploy.js --network sepolia # 部署到 Sepolia 测试网
或者
npm run deploy:sepolia  # 部署到 Sepolia 测试网
```

或使用 Ignition：

```bash
npx hardhat ignition deploy ignition/modules/lottery.js --network sepolia
```

### 3. 部署合约源码上传(合约部署后，要先在etherscan查询到合约地址，然后才能上传源码)
```
#修改 scripts/verify.js 里的合约地址
执行以下代码：
npm run verify:sepolia
或
npx hardhat verify --network sepolia 0x1234...abcd "constructorParam1" "constructorParam2"

```

### 4. 合约地址要添加到Chainlink VRF 的consumer
```
https://vrf.chain.link/

```

---

## 主要合约说明

### Lottery.sol

- 支持用户购买彩票，选择号码参与每轮抽奖
- 使用 Chainlink VRF 实现链上可验证随机数
- 中奖奖金按投注比例分配
- 支持超时未开奖时用户退款
- 管理员权限控制与安全防护

主要接口：

- `buyTicket(uint8 number)`：购买彩票
- `startNewRound()`：开启新一轮
- `preDistributePrizes()`：请求开奖
- `distributePrizesAndEndCurrentRound()`：派奖并结束本轮
- `claimPrize()`：用户领奖
- `refundTickets()`：超时退款

详细接口与参数说明请见 [`contracts/Lottery.sol`](contracts/Lottery.sol)。

---

## 测试

可在 `test/` 目录下添加或运行 Hardhat 测试：

```bash
npx hardhat test
```

---

## 依赖

- [Hardhat](https://hardhat.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Chainlink VRF](https://docs.chain.link/)

---

## 许可证

MIT