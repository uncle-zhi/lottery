const { expect } = require("chai");
const Web3 = require("web3");
const { ethers } = require("hardhat");

describe("Lottery Contract", function () {
    let lotteryContract;
    let owner;
    let player1;
    let player2;
    let web3;
    let lotteryInfo;

    const ticketPrice = "100000000000000000"; // 0.1 ETH in Wei using Web3.js

    before(async function () {
        // 获取Web3实例
        web3 = new Web3(ethers.provider);

        // 获取合约的部署者和其他账户
        [owner, player1, player2] = await ethers.getSigners();

        // 部署合约（不使用代理）
        const Lottery = await ethers.getContractFactory("Lottery");
        lotteryContract = await Lottery.deploy(
            1, // subscriptionId
            "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B", // coordinator
            "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae", // keyHash
            80 // callbackGasLimit
        );
    });

    it("开启新一轮", async function () {
        await lotteryContract.connect(owner).startNewRound();
        lotteryInfo = await lotteryContract.lotteryInfo();
        console.info("lotteryInfo", lotteryInfo)
        expect(lotteryInfo.isLotteryOpen).to.be.true;
        expect(lotteryInfo.round).to.equal(1);
        expect(lotteryInfo.startNumber).to.equal(2);
        expect(lotteryInfo.endNumber).to.equal(100000002);
    });

    it("should allow users to buy tickets", async function () {
        await lotteryContract.connect(owner).buyTicket(8, {
            value:  web3.utils.toWei((0.1 * 8).toString(), 'ether'),
        });

        const myTicket = await lotteryContract.connect(owner).getMyTicket();
        console.log(myTicket);
        expect(myTicket.player).to.equal(owner.address);
        expect(myTicket.amount).to.equal(web3.utils.toWei((0.1 * 8).toString(), 'ether'));
        expect(myTicket.number).to.equal(8);
        lotteryInfo = await lotteryContract.lotteryInfo();
        console.info('用户购票后的信息：',lotteryInfo)

    });
   
});
