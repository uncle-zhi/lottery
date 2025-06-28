package com.web3.utils;

import com.web3.service.ContractService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StreamUtils;
import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.datatypes.Function;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.core.methods.response.EthCall;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class Utils {
    private static final Logger LOGGER = LoggerFactory.getLogger(ContractService.class);

    public static String loadFileFromClasspath(String fileName) {
        InputStream inputStream =Utils.class.getClassLoader().getResourceAsStream(fileName);
        if (inputStream == null) {
            throw new RuntimeException("File not found in classpath");
        }
        String content = "";
        try{
            content = StreamUtils.copyToString(inputStream, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        return content;
    }





        /**
         * 模拟调用合约函数，判断是否能成功执行（不会 revert）
         *
         * @param web3j        Web3j 实例
         * @param fromAddress  调用者地址
         * @param contractAddress 合约地址
         * @return true 表示可以正常执行；false 表示会被 revert
         */
        public static void canCallFunction(Web3j web3j, String fromAddress, String contractAddress,
                                                           Function function) throws Exception {
                String encodedFunction = FunctionEncoder.encode(function);

                EthCall response = web3j.ethCall(
                        Transaction.createEthCallTransaction(fromAddress, contractAddress, encodedFunction),
                        DefaultBlockParameterName.LATEST
                ).send();
                if (response.isReverted()) {
                    LOGGER.info("模拟调用失败: " + response.getRevertReason());
                    throw new Exception(response.getRevertReason());
                }
        }


}
