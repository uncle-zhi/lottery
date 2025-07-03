package com.web3.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;


@Component
@ConfigurationProperties(prefix = "web3")
@Data
public class Web3jProperties {

    private String web3jService;
    private String fromAddress;
    private String contractAddress;
    private String privateKey;
    private String binFilePath;
    private Long chainId;

}
