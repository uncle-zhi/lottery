package com.web3.task;

import com.web3.service.ContractService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

@Component
public class LotteryTask {

    private static final Logger LOGGER = LoggerFactory.getLogger(LotteryTask.class);
    @Resource
    ContractService contractService;
    // 每 10 秒执行一次
    @Scheduled(fixedDelay  = 30000)
    public void autoOpLottery() {
        LOGGER.info("执行自动运营任务");
//        contractService.autoOperationLottery();
    }
}
