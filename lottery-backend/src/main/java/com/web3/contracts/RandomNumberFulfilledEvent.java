package com.web3.contracts;

import com.web3.config.Web3jProperties;
import com.web3.service.ContractService;
import io.reactivex.Flowable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.web3j.abi.EventEncoder;
import org.web3j.abi.FunctionReturnDecoder;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Event;
import org.web3j.abi.datatypes.Type;

import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.abi.datatypes.generated.Uint8;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameter;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.EthFilter;
import org.web3j.protocol.core.methods.response.Log;
import org.web3j.utils.Numeric;

import javax.annotation.Resource;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

@Component
public class RandomNumberFulfilledEvent implements ApplicationRunner {
    private static final Logger LOGGER = LoggerFactory.getLogger(RandomNumberFulfilledEvent.class);
    @Resource
    Web3jProperties web3jProperties;

    @Resource
    Web3j web3j;

    @Resource
    Lottery lottery;

    @Resource
    ContractService contractService;

    public void openListen(BigInteger startBlockNumber){
        Event randomNumberFulfilledEvent = new Event("RandomNumberFulfilled",
                Arrays.asList(
                        new TypeReference<Uint256>(true) {}, // requestId (indexed)
                        new TypeReference<Uint8>() {},       // randomNumber
                        new TypeReference<Uint256>() {}      // originalRandomNumber
                )
        );

        // 创建 filter
        EthFilter filter = new EthFilter(
                DefaultBlockParameter.valueOf(startBlockNumber),
                DefaultBlockParameterName.LATEST,
                web3jProperties.getContractAddress()
        );

        filter.addSingleTopic(EventEncoder.encode(randomNumberFulfilledEvent));

        Flowable<Log> logFlowable = web3j.ethLogFlowable(filter);

       // 监听事件
        logFlowable.subscribe(log -> {
            // 1. 解析 indexed 参数 requestId
            Uint256 requestId = new Uint256(Numeric.toBigInt(log.getTopics().get(1)));

            // 2. 解析 data 中的非 indexed 参数
            List<Type> decoded = FunctionReturnDecoder.decode(
                    log.getData(),
                    randomNumberFulfilledEvent.getNonIndexedParameters()
            );

            Uint8 randomNumber = (Uint8) decoded.get(0);
            Uint256 originalRandomNumber = (Uint256) decoded.get(1);

            LOGGER.info("requestId: {}", requestId.getValue());
            LOGGER.info("randomNumber: {}", randomNumber.getValue());
            LOGGER.info("originalRandomNumber: {}", originalRandomNumber.getValue());

            //监听到事件
            contractService.autoOperationLottery();;

        }, error -> {
            LOGGER.error("监听失败：{}", error.getMessage(), error);
        });

    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        LOGGER.info("开启监听 ");
        BigInteger startBlockNumber = lottery.getBlockNumber().getData();
        openListen(startBlockNumber);
    }
}
