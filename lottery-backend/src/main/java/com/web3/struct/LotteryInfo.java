package com.web3.struct;

import lombok.ToString;
import org.web3j.abi.datatypes.Bool;
import org.web3j.abi.datatypes.StaticStruct;
import org.web3j.abi.datatypes.generated.*;

import java.math.BigInteger;

@ToString
public class LotteryInfo extends StaticStruct {

    public BigInteger round;
    public BigInteger startNumber;
    public BigInteger endNumber;
    public Boolean isLotteryOpen;
    public BigInteger totalPrizePool; // 累计奖金池
    public BigInteger totalPendingRewards; // 总待领取奖金
    public BigInteger lastRequestId; // 最近的请求 ID
    public BigInteger latestRandomNumber; // 最近的随机数
    public BigInteger rewardRate; // 返奖比例
    public Boolean isDistributing; // 是否在派奖中
    public BigInteger  cumulativePrizeAmount; //累计中奖金额
    public BigInteger cumulativeWinners; //累计中奖人次
    public BigInteger distributedCount; //已经发奖人次

    public LotteryInfo(Uint32 round, Uint256 startNumber, Uint256 endNumber, Bool isLotteryOpen, Uint128 totalPrizePool, Uint128 totalPendingRewards,
                       Uint256 lastRequestId, Uint8 latestRandomNumber,Uint8 rewardRate, Bool isDistributing,Uint256 cumulativePrizeAmount,
                       Uint128 cumulativeWinners,Uint64 distributedCount){

        super(round,startNumber,endNumber,isLotteryOpen,totalPrizePool,totalPendingRewards,lastRequestId,latestRandomNumber,rewardRate,
                isDistributing,cumulativePrizeAmount,cumulativeWinners,distributedCount);
        this.round = round.getValue();
        this.startNumber = startNumber.getValue();
        this.endNumber = endNumber.getValue();
        this.isLotteryOpen = isLotteryOpen.getValue();
        this.totalPrizePool = totalPrizePool.getValue();
        this.totalPendingRewards = totalPendingRewards.getValue();
        this.lastRequestId = lastRequestId.getValue();
        this.latestRandomNumber = latestRandomNumber.getValue();
        this.rewardRate = rewardRate.getValue();
        this.isDistributing = isDistributing.getValue();
        this.cumulativePrizeAmount = cumulativePrizeAmount.getValue();
        this.cumulativeWinners = cumulativeWinners.getValue();
        this.distributedCount = distributedCount.getValue();
    }
}
