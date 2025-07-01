package com.web3.provider;

import org.web3j.protocol.Web3j;
import org.web3j.tx.gas.ContractGasProvider;
import org.web3j.tx.gas.DefaultGasProvider;

import java.io.IOException;
import java.math.BigInteger;

public class DynamicGasProvider implements ContractGasProvider {

    private final Web3j web3j;

    public DynamicGasProvider(Web3j web3j) {
        this.web3j = web3j;
    }

    @Override
    public BigInteger getGasPrice(String contractFunc) {
        try {
            return web3j.ethGasPrice().send().getGasPrice()
                    .multiply(BigInteger.valueOf(12)).divide(BigInteger.TEN); // 提高 20%
        } catch (IOException e) {
            return DefaultGasProvider.GAS_PRICE; // fallback
        }
    }

    @Override
    public BigInteger getGasPrice() {
        return getGasPrice("");
    }

    @Override
    public BigInteger getGasLimit(String contractFunc) {
        return BigInteger.valueOf(500_000);
    }

    @Override
    public BigInteger getGasLimit() {
        return BigInteger.valueOf(500_000);
    }
}
