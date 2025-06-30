# Lottery 区块链彩票项目

本项目包含三个子项目，分别实现了智能合约、前端 DApp 和后端服务，旨在提供一个完整的区块链彩票系统解决方案。

---

## 1. lottery-contracts（智能合约）

- 使用 Solidity 编写，部署在 EVM 兼容链（如 Sepolia 测试网）。
- 支持 Chainlink VRF 随机数，确保开奖公平。
- 支持购票、开奖、派奖、奖金领取等功能。
- 合约安全性考虑：防重入、参数校验、权限控制等。

**主要目录结构：**
```
lottery-contracts/
├── contracts/         # Solidity 合约（Lottery.sol）
├── scripts/           # 部署脚本与验证脚本（deploy.js、verify.js）
├── ignition/          # Hardhat Ignition 部署模块
├── test/              # 合约测试
├── hardhat.config.js  # Hardhat 配置
└── package.json
```

**快速开始：**
```bash
cd lottery-contracts
npm install
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat run scripts/verify.js --network sepolia
```

详细说明见 [lottery-contracts/README.md](lottery-contracts/README.md)。

---

## 2. lottery-dapp（前端 DApp）

- 使用 Vue3 + Vite 构建，界面简洁，交互友好。
- 支持购买彩票、开奖展示、中奖信息展示等功能。
- 预留与合约交互的接口，便于后续集成 Web3 功能。

**主要目录结构：**
```
lottery-dapp/
├── src/
│   ├── components/    # 组件（Lottery.vue 等）
│   ├── views/         # 页面视图（Home.vue 等）
│   ├── App.vue        # 根组件
│   └── main.js        # 入口文件
├── public/            # 静态资源
├── package.json
└── vite.config.js
```

**快速开始：**
```bash
cd lottery-dapp
npm install
npm run dev
# 浏览器访问 http://localhost:3000
```

详细说明见 [lottery-dapp/README.md](lottery-dapp/README.md)。

---

## 3. lottery-backend（后端服务）

- 典型 Java/Spring Boot 项目结构，负责业务支撑、数据分析、日志等后台功能。
- 可扩展为提供 API、自动开奖、数据统计等服务。

**主要目录结构：**
```
lottery-backend/
├── src/           # Java 源码
├── logs/          # 日志文件
├── pom.xml        # Maven 配置
└── target/        # 编译输出
```

**快速开始：**
```bash
cd lottery-backend
# 使用 IDE 或命令行构建运行
mvn clean package
java -jar target/xxx.jar
```

---

## 目录说明

- [lottery-contracts/README.md](lottery-contracts/README.md)：合约项目说明
- [lottery-dapp/README.md](lottery-dapp/README.md)：前端项目说明
- lottery-backend：后端项目说明（可在 src/ 或代码注释中查看）


Demo 地址：http://sepolia.lottery.unclepro.top/#/

如有建议或问题，欢迎提 Issue