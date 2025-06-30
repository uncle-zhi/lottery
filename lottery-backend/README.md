
---

## 功能简介

- **合约交互**：通过 Web3j 与区块链上的 Lottery 智能合约进行交互，支持获取彩票信息、开奖、派奖、开启新一轮等操作。
- **自动运营**：内置定时任务与事件监听，自动完成预开奖、开奖、开启新轮等流程。
- **事件监听**：监听链上 RandomNumberFulfilled 等事件，驱动后端自动化流程。
- **日志管理**：支持多环境日志分级输出，便于运维与问题追踪。
- **配置灵活**：支持多环境（dev/stg/prd）配置，合约地址、私钥等敏感信息通过配置文件管理。

---

## 快速开始

### 1. 环境准备

- JDK 17+
- Maven 3.6+
- 已部署的 Lottery 智能合约（见 [lottery-contracts](../lottery-contracts/README.md)）

### 2. 配置文件

在 `src/main/resources/` 下有多套配置：

- `application.yml`：主配置，指定激活环境（默认 `dev`）
- `application-dev.yml`：开发环境配置（默认使用本地或测试网合约地址）
- `application-stg.yml`：测试环境配置
- `logback-custom.xml`：日志分级与输出路径配置

**主要配置项说明（以 `application-dev.yml` 为例）：**

```yaml
server:
  port: 8089

spring:
  application:
    name: lottery-backend
logging:
  config: classpath:logback-custom.xml
  file:
    path: ./logs/

web3:
  web3jService: <你的以太坊节点RPC地址>
  fromAddress: "<钱包地址>"
  contractAddress: "<Lottery合约地址>"
  privateKey: "<钱包私钥>"
  binFilePath: Lottery.bin