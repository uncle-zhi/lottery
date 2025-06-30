package com.web3.service.impl;

import com.web3.contracts.Lottery;
import com.web3.service.ContractService;
import com.web3.vo.ReturnDataVO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.math.BigInteger;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

@Service
public class ContractServiceImpl implements ContractService {
    private static final Logger LOGGER = LoggerFactory.getLogger(ContractService.class);

    private static final Lock LOCK = new ReentrantLock();
    @Resource
    private Lottery lottery;

    // 接受投注中
    private static final int  AcceptingBets = 0;

    // 延时开奖中
    private static final int  DelayRevealing = 1;
    //等待预开奖
    private static final int  WaitPreReveal = 2;
    // 预开奖中
    private static final int PreRevealing = 3;
    //预开奖完成，等待开奖（随机数已生成）
    private static final int WaitReveal = 4;
    // 开奖完成
    private static final int Revealed = 5;

    @Override
    public void autoOperationLottery() {
        if(LOCK.tryLock()) {
          try {
              ReturnDataVO<BigInteger> returnDataVO = lottery.getLotteryStatus();
              if (returnDataVO.isSuccess()) {
                  int status = returnDataVO.getData().intValue();  //获取当前的状态
                  if (status == WaitPreReveal) {
                      LOGGER.info("当前状态：等待预开奖");
                      ReturnDataVO<?> preReturn = lottery.preDistributePrizes();
                      if (preReturn.isSuccess()) {
                          LOGGER.info("自动操作预开奖成功");
                      } else {
                          LOGGER.error(preReturn.getMsg());
                      }
                  }
                  if (status == WaitReveal) {
                      LOGGER.info("当前状态：等待开奖");
                      ReturnDataVO<?> disReturn = lottery.distributePrizesAndEndCurrentRound();
                      if (disReturn.isSuccess()) {
                          LOGGER.info("自动操作开奖成功 ");
                      } else {
                          LOGGER.error(disReturn.getMsg());
                      }
                  }
                  if (status == Revealed) {
                      LOGGER.info("当前状态：开奖结束，待开启下一轮");
                      ReturnDataVO<?> strReturn = lottery.startNewRound();
                      if (strReturn.isSuccess()) {
                          LOGGER.info("自动操作开启新一轮成功");
                      } else {
                          LOGGER.error(strReturn.getMsg());
                      }
                  }

                  if (status == PreRevealing) {
                      LOGGER.info("预开奖进行中， 不进行任何操作");
                  }
                  if (status == AcceptingBets) {
                      LOGGER.info("接受投注中， 不进行任何操作");
                  }
                  if (status == DelayRevealing) {
                      LOGGER.info("延迟开奖中， 不进行任何操作");
                  }
              }
          }finally {
              LOCK.unlock();
          }
        }

    }
}
