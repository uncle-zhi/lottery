package com.web3.contracts;

import com.web3.config.Web3jProperties;
import com.web3.struct.LotteryInfo;
import com.web3.utils.Utils;
import com.web3.vo.ReturnDataVO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Function;
import org.web3j.abi.datatypes.generated.Uint8;
import org.web3j.ens.EnsResolver;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.RemoteFunctionCall;
import org.web3j.protocol.core.methods.response.EthBlockNumber;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.Contract;
import org.web3j.tx.TransactionManager;
import org.web3j.tx.gas.ContractGasProvider;

import javax.annotation.Resource;
import java.io.IOException;
import java.math.BigInteger;
import java.util.Collections;

public class Lottery extends Contract {
    private static final Logger LOGGER = LoggerFactory.getLogger(Lottery.class);

    @Resource
    Web3jProperties web3jProperties;
    public Lottery(String contractBinary, String contractAddress, Web3j web3j, TransactionManager transactionManager, ContractGasProvider gasProvider) {
        super( new EnsResolver(web3j),contractBinary, contractAddress, web3j, transactionManager, gasProvider);
    }

    private <T> ReturnDataVO<T> commonRemoteCallSingleValueReturn(Function function, Class<T> clazz){
        ReturnDataVO<T> returnDataVO;
        try {
            RemoteFunctionCall<T> call = executeRemoteCallSingleValueReturn(function, clazz);
            returnDataVO = ReturnDataVO.success(call.send());
        }catch (Exception e){
            LOGGER.error(e.getMessage(),e);
            returnDataVO = ReturnDataVO.fail(e.getMessage());
        }
        return returnDataVO;
    }

    private <T> ReturnDataVO<T> commonRemoteCallTransaction(Function function){
        ReturnDataVO<T> returnDataVO;
        try {
            //使用ethcall模拟调用
            Utils.canCallFunction(this.web3j, web3jProperties.getFromAddress(), this.contractAddress, function);
            RemoteFunctionCall<TransactionReceipt> call = executeRemoteCallTransaction(function);
            TransactionReceipt receipt = call.send();
            if(receipt.isStatusOK()){
                returnDataVO= ReturnDataVO.success();
            }else{
                returnDataVO = ReturnDataVO.fail(receipt.getRevertReason());
            }

        }catch (Exception e) {
            LOGGER.error(e.getMessage(),e);
            returnDataVO = ReturnDataVO.fail(e.getMessage());
        }
        return returnDataVO;
    }



    public ReturnDataVO<LotteryInfo> getLotteryInfo() {
        Function function = new Function("lotteryInfo", Collections.emptyList(),
                Collections.singletonList(new TypeReference<LotteryInfo>() {
                }));
        return commonRemoteCallSingleValueReturn(function,LotteryInfo.class);
    }

    public ReturnDataVO<BigInteger> getLotteryStatus() {
        Function function = new Function("getLotteryStatus", Collections.emptyList(),
                Collections.singletonList(new TypeReference<Uint8>() {
                }));
        return commonRemoteCallSingleValueReturn(function,BigInteger.class);
    }



    public ReturnDataVO<?> preDistributePrizes() {

            Function function = new Function("preDistributePrizes",
                    Collections.emptyList(),
                    Collections.emptyList());
            return commonRemoteCallTransaction(function);

    }

    public ReturnDataVO<?> distributePrizesAndEndCurrentRound() {
            Function function = new Function("distributePrizesAndEndCurrentRound",
                    Collections.emptyList(),
                    Collections.emptyList());
            return commonRemoteCallTransaction(function);
    }

    public ReturnDataVO<?> startNewRound(){

            Function function = new Function("startNewRound",
                    Collections.emptyList(),
                    Collections.emptyList());
            return commonRemoteCallTransaction(function);

    }

    public ReturnDataVO<BigInteger> getBlockNumber() {
        ReturnDataVO<BigInteger> returnDataVO;
        try {
            EthBlockNumber blockNumberResponse = web3j.ethBlockNumber().send();
            returnDataVO = ReturnDataVO.success(blockNumberResponse.getBlockNumber());
        } catch (IOException e) {
            returnDataVO = ReturnDataVO.fail(e.getMessage());
            LOGGER.error(e.getMessage(),e);
        }
        return  returnDataVO;
    }

}
