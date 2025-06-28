# lottery-dapp

本目录为区块链彩票系统的前端 DApp，基于 Vue3 + Vite 构建，提供购买彩票、开奖展示等功能界面。

---

## 目录结构

```
lottery-dapp/
├── src/
│   ├── components/      # 组件目录（如 Lottery.vue）
│   ├── views/           # 页面视图（如 Home.vue）
│   ├── App.vue          # 根组件
│   └── main.js          # 入口文件
├── public/              # 静态资源
├── vite.config.js       # Vite 配置
└── package.json         # 依赖管理
```

---

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

浏览器访问 [http://localhost:3000](http://localhost:3000) 查看效果。

---

## 主要功能

- 购买彩票：选择号码、提交购买
- 开奖展示：显示当前轮次、开奖结果、中奖信息
- 中奖领奖：展示中奖金额，支持领奖操作（后续集成链上功能）
- 友好的用户界面，支持移动端适配

---

## 技术栈

- [Vue3](https://vuejs.org/)
- [Vite](https://vitejs.dev/)
- [Ant Design Vue](https://www.antdv.com/)（UI 组件库）
- [Ethers.js](https://docs.ethers.org/)（预留 Web3 支持）

---

## 未来规划

- 集成钱包连接，实现链上购票与领奖
- 支持多网络切换
- 增加用户历史记录、开奖动画等功能
- 完善前端自动化测试

---

## 许可证