package com.web3.config;

import com.web3.contracts.Lottery;
import com.web3.provider.DynamicGasProvider;
import com.web3.utils.Utils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.web3j.crypto.Credentials;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.http.HttpService;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.TransactionManager;

import javax.annotation.Resource;

@Configuration
public class Web3jConfig {

    @Resource
    Web3jProperties web3jProperties;

    @Bean
    public Web3j web3j(){
        return Web3j.build(new HttpService(web3jProperties.getWeb3jService()));
    }
    @Bean
    public Credentials credentials() {
        return Credentials.create(web3jProperties.getPrivateKey());
    }

    @Bean
    public DynamicGasProvider dynamicGasProvider(Web3j web3j){
        return new DynamicGasProvider(web3j);
    }

    @Bean
    public Lottery lottery(Web3j web3j, Credentials credentials,DynamicGasProvider dynamicGasProvider ){
        TransactionManager txManager = new RawTransactionManager(web3j, credentials, web3jProperties.getChainId()); // Polygon 主网 chainId
        return new Lottery(Utils.loadFileFromClasspath(web3jProperties.getBinFilePath()),web3jProperties.getContractAddress(),web3j,txManager,dynamicGasProvider);
    }


}
