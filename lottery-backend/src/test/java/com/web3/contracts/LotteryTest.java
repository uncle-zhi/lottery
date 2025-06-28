package com.web3.contracts;

import com.web3.BaseTest;
import com.web3.struct.LotteryInfo;
import com.web3.vo.ReturnDataVO;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.annotation.Resource;
import java.math.BigInteger;

public class LotteryTest extends BaseTest {
    private static final Logger LOGGER = LoggerFactory.getLogger(LotteryTest.class);
    @Resource
    Lottery lottery;

    @Test
    public void testGetLotteryInfo()  {
        ReturnDataVO<LotteryInfo> returnDataVO =  lottery.getLotteryInfo();
        LotteryInfo lotteryInfo  =  returnDataVO.getData();
        LOGGER.info("返回值为：{}",lotteryInfo);
        assert returnDataVO.isSuccess();
    }

    @Test
    public void testGetLotteryStatus()  {
        ReturnDataVO<BigInteger> returnDataVO  = lottery.getLotteryStatus();
        LOGGER.info("LotteryStatus:{}",returnDataVO.getData());
        assert returnDataVO.isSuccess();
    }

    @Test
    public void testPreDistributePrizes() {
        ReturnDataVO<?> returnDataVO = lottery.preDistributePrizes();
        LOGGER.info("testPreDistributePrizes是否成功：{}， 返回信息：{}",returnDataVO.isSuccess(),returnDataVO.getMsg());
        assert returnDataVO.isSuccess();
    }

    @Test
    public void testDistributePrizesAndEndCurrentRound(){
        ReturnDataVO<?> returnDataVO = lottery.distributePrizesAndEndCurrentRound();
        LOGGER.info("distributePrizesAndEndCurrentRound是否成功：{}， 返回信息：{}",returnDataVO.isSuccess(),returnDataVO.getMsg());
        assert returnDataVO.isSuccess();
    }


    @Test
    public void testStartNewRound(){
        ReturnDataVO<?> returnDataVO = lottery.startNewRound();
        LOGGER.info("testStartNewRound：{}， 返回信息：{}",returnDataVO.isSuccess(),returnDataVO.getMsg());
        assert returnDataVO.isSuccess();
    }

    @Test
    public void testGetBlockNumber(){
        ReturnDataVO<BigInteger> returnDataVO = lottery.getBlockNumber();
        LOGGER.info("最新的区块高度为：{}",returnDataVO.getData());
    }
}
